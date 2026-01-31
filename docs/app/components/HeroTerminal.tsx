"use client";

import Image from "next/image";
import { useCallback, useEffect, useRef, useState } from "react";
import TerminalScreen from "./TerminalScreen";

/**
 * Synthesizes a CRT power-on hum using the Web Audio API.
 *
 * Combines a low-frequency mains hum (~100 Hz) with a high-frequency sweep
 * (2 kHz → 4 kHz) that mimics the characteristic whine of a CRT monitor
 * powering up. Both tones have a quick attack and ~0.8s exponential decay.
 */
function playCrtPowerOnSound(): void {
  const audioCtx = new AudioContext();
  const now = audioCtx.currentTime;

  /* ── Low mains hum (100 Hz) ── */
  const humOsc = audioCtx.createOscillator();
  const humGain = audioCtx.createGain();
  humOsc.type = "sine";
  humOsc.frequency.setValueAtTime(100, now);
  humGain.gain.setValueAtTime(0.15, now);
  humGain.gain.exponentialRampToValueAtTime(0.001, now + 0.8);
  humOsc.connect(humGain).connect(audioCtx.destination);

  /* ── High-frequency CRT whine (2 kHz → 4 kHz sweep) ── */
  const whineOsc = audioCtx.createOscillator();
  const whineGain = audioCtx.createGain();
  whineOsc.type = "sine";
  whineOsc.frequency.setValueAtTime(2000, now);
  whineOsc.frequency.exponentialRampToValueAtTime(4000, now + 0.3);
  whineGain.gain.setValueAtTime(0.06, now);
  whineGain.gain.exponentialRampToValueAtTime(0.001, now + 0.6);
  whineOsc.connect(whineGain).connect(audioCtx.destination);

  /* Start both oscillators and clean up after decay. */
  humOsc.start(now);
  whineOsc.start(now);
  humOsc.stop(now + 0.9);
  whineOsc.stop(now + 0.7);

  setTimeout(() => audioCtx.close(), 1000);
}

/**
 * Interactive hero terminal with power-on animation.
 *
 * Initially shows the CRT logo at 320×320 with a static "Welcome to TUIkit"
 * message. When the user clicks the red power button on the monitor, the logo
 * zooms to center screen at double size, the background dims, and the full
 * terminal boot sequence begins.
 *
 * Uses CSS `transform: scale()` for the zoom animation so the element animates
 * smoothly from its inline position to viewport center.
 *
 * Clicking outside the zoomed terminal or pressing Escape returns to the
 * normal view.
 */
export default function HeroTerminal() {
  const [powered, setPowered] = useState(false);
  const [zoomed, setZoomed] = useState(false);
  const [mounted, setMounted] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  /** Offset to translate the element from its inline position to viewport center. */
  const [centerOffset, setCenterOffset] = useState({ x: 0, y: 0 });

  useEffect(() => {
    setMounted(true);
  }, []);

  /** Computes the translation needed to center the element in the viewport. */
  const computeCenterOffset = useCallback(() => {
    const element = containerRef.current;
    if (!element) return { x: 0, y: 0 };
    const rect = element.getBoundingClientRect();
    const elementCenterX = rect.left + rect.width / 2;
    const elementCenterY = rect.top + rect.height / 2;
    const viewportCenterX = window.innerWidth / 2;
    const viewportCenterY = window.innerHeight / 2;
    return {
      x: viewportCenterX - elementCenterX,
      y: viewportCenterY - elementCenterY,
    };
  }, []);

  /** Power on: play CRT hum, glow the button, compute offset, zoom the terminal, start boot. */
  const handlePowerOn = useCallback(() => {
    if (powered) return;
    playCrtPowerOnSound();
    setPowered(true);
    /* Compute offset before zooming so it captures the inline position. */
    setCenterOffset(computeCenterOffset());
    /* Small delay so the glow appears before zoom. */
    setTimeout(() => setZoomed(true), 200);
  }, [powered, computeCenterOffset]);

  /** Power off: zoom back, stop terminal. */
  const handlePowerOff = useCallback(() => {
    setZoomed(false);
    /* Wait for zoom-out animation to finish before killing power. */
    setTimeout(() => setPowered(false), 500);
  }, []);

  /** Close on Escape key. */
  useEffect(() => {
    if (!zoomed) return;
    const handleKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") handlePowerOff();
    };
    window.addEventListener("keydown", handleKey);
    return () => window.removeEventListener("keydown", handleKey);
  }, [zoomed, handlePowerOff]);

  return (
    <>
      {/* Dimming overlay — behind the zoomed terminal */}
      <div
        className="fixed inset-0 z-[100] bg-black/80 backdrop-blur-sm transition-opacity duration-500"
        style={{
          opacity: zoomed ? 1 : 0,
          pointerEvents: zoomed ? "auto" : "none",
        }}
        onClick={handlePowerOff}
      />

      {/* Terminal container — uses transform for smooth zoom from inline position */}
      <div
        ref={containerRef}
        className="relative transition-all duration-500 ease-in-out"
        style={{
          width: 320,
          height: 320,
          zIndex: zoomed ? 200 : 1,
          transform: zoomed
            ? `translate(${centerOffset.x}px, ${centerOffset.y}px) scale(2)`
            : "translate(0, 0) scale(1)",
        }}
      >
        {/* CRT Monitor image */}
        <Image
          src="/tuikit-logo.png"
          alt="TUIkit Logo"
          width={640}
          height={640}
          className="h-full w-full rounded-3xl"
          style={{ objectFit: "contain" }}
          priority
        />

        {/* Terminal screen overlay */}
        <TerminalScreen powered={powered} zoomed={zoomed} />

        {/* Red power button — positioned over the physical button in the logo */}
        {mounted && (
          <button
            onClick={powered ? handlePowerOff : handlePowerOn}
            className="absolute z-10 cursor-pointer rounded-none bg-transparent p-0 transition-all duration-300"
            style={{
              /* Button position on the CRT monitor (bottom-left area). */
              bottom: zoomed ? "24.9%" : "24.6%",
              left: zoomed ? "24.1%" : "23.8%",
              width: zoomed ? "3.9%" : "4.5%",
              height: zoomed ? "3.9%" : "4.5%",

              /* Glow effect when powered on. */
              boxShadow: powered
                ? "0 0 6px 2px rgba(255, 50, 50, 0.8), 0 0 14px 5px rgba(255, 50, 50, 0.4)"
                : "none",
            }}
            aria-label={powered ? "Power off terminal" : "Power on terminal"}
            title={powered ? "Power off" : "Power on"}
          />
        )}
      </div>
    </>
  );
}

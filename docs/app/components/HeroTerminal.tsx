"use client";

import Image from "next/image";
import { useCallback, useEffect, useRef, useState } from "react";
import TerminalScreen from "./TerminalScreen";

/**
 * Synthesizes a CRT power-on sound using the Web Audio API.
 *
 * Three layers mimicking a real CRT monitor powering up:
 * 1. **Degauss thump** — Short burst of filtered noise + deep 50 Hz sine
 *    simulating the degaussing coil firing (the "fumpp").
 * 2. **Mains hum** — 100 Hz sine with 0.8s decay (transformer buzz).
 * 3. **Flyback whine** — 800 Hz → 4 kHz sweep with 0.6s decay
 *    (high-voltage transformer spooling up).
 */
function playCrtPowerOnSound(): void {
  const audioCtx = new AudioContext();
  const now = audioCtx.currentTime;

  /* ── Degauss thump (filtered noise burst + deep sine) ── */
  const noiseBuffer = audioCtx.createBuffer(1, audioCtx.sampleRate * 0.15, audioCtx.sampleRate);
  const noiseData = noiseBuffer.getChannelData(0);
  for (let sample = 0; sample < noiseData.length; sample++) {
    noiseData[sample] = (Math.random() * 2 - 1) * (1 - sample / noiseData.length);
  }
  const noiseSource = audioCtx.createBufferSource();
  noiseSource.buffer = noiseBuffer;
  const noiseFilter = audioCtx.createBiquadFilter();
  noiseFilter.type = "lowpass";
  noiseFilter.frequency.setValueAtTime(200, now);
  const noiseGain = audioCtx.createGain();
  noiseGain.gain.setValueAtTime(0.25, now);
  noiseGain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);
  noiseSource.connect(noiseFilter).connect(noiseGain).connect(audioCtx.destination);

  const thumpOsc = audioCtx.createOscillator();
  const thumpGain = audioCtx.createGain();
  thumpOsc.type = "sine";
  thumpOsc.frequency.setValueAtTime(50, now);
  thumpGain.gain.setValueAtTime(0.3, now);
  thumpGain.gain.exponentialRampToValueAtTime(0.001, now + 0.15);
  thumpOsc.connect(thumpGain).connect(audioCtx.destination);

  /* ── Mains hum (100 Hz, delayed slightly after thump) ── */
  const humOsc = audioCtx.createOscillator();
  const humGain = audioCtx.createGain();
  humOsc.type = "sine";
  humOsc.frequency.setValueAtTime(100, now + 0.1);
  humGain.gain.setValueAtTime(0.001, now);
  humGain.gain.linearRampToValueAtTime(0.12, now + 0.15);
  humGain.gain.exponentialRampToValueAtTime(0.001, now + 0.9);
  humOsc.connect(humGain).connect(audioCtx.destination);

  /* ── Flyback whine (800 Hz → 4 kHz sweep, after thump) ── */
  const whineOsc = audioCtx.createOscillator();
  const whineGain = audioCtx.createGain();
  whineOsc.type = "sine";
  whineOsc.frequency.setValueAtTime(800, now + 0.12);
  whineOsc.frequency.exponentialRampToValueAtTime(4000, now + 0.45);
  whineGain.gain.setValueAtTime(0.001, now);
  whineGain.gain.linearRampToValueAtTime(0.06, now + 0.18);
  whineGain.gain.exponentialRampToValueAtTime(0.001, now + 0.7);
  whineOsc.connect(whineGain).connect(audioCtx.destination);

  /* Start all layers and clean up after decay. */
  noiseSource.start(now);
  thumpOsc.start(now);
  thumpOsc.stop(now + 0.2);
  humOsc.start(now + 0.1);
  humOsc.stop(now + 1.0);
  whineOsc.start(now + 0.12);
  whineOsc.stop(now + 0.8);

  setTimeout(() => audioCtx.close(), 1200);
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
        {/* Layer 1: Black backing surface — hinterste Ebene hinter dem transparenten Frame */}
        <div
          className="absolute"
          style={{
            top: "calc(14% + 2px - 13px)",
            left: "calc(21% - 10px)",
            width: "calc(58% + 20px)",
            height: "calc(45% + 20px)",
            borderRadius: "31px",
            background: "#000",
            zIndex: 1,
          }}
        />

        {/* Layer 2: Terminal content — über dem Backing, unter dem Glow */}
        <div
          className="pointer-events-none absolute overflow-hidden"
          style={{
            top: "calc(14% + 2px)",
            left: "21%",
            width: "58%",
            height: "45%",
            zIndex: 2,
          }}
        >
          <TerminalScreen powered={powered} zoomed={zoomed} />
        </div>

        {/* Layer 3: CRT edge glow + scanline sweep — über dem Content, unter dem Frame.
            Inner glow simuliert die Randabdunklung eines echten CRT-Monitors. */}
        <div
          className="pointer-events-none absolute"
          style={{
            top: "calc(14% + 2px - 18px)",
            left: "calc(21% - 15px)",
            width: "calc(58% + 30px)",
            height: "calc(45% + 30px)",
            borderRadius: "31px",
            boxShadow:
              "inset 0 0 16px 7px rgba(var(--accent-glow), 0.42), inset 0 0 38px 14px rgba(var(--accent-glow), 0.15)",
            overflow: "hidden",
            zIndex: 3,
          }}
        >
          {/* Scanline sweep — faint band moving top to bottom */}
          {powered && (
            <div
              style={{
                position: "absolute",
                left: 0,
                top: 0,
                width: "100%",
                height: "100%",
                background:
                  "linear-gradient(to bottom, transparent 0%, rgba(var(--accent-glow), 0.2) 50%, transparent 100%)",
                backgroundSize: "100% 30%",
                backgroundRepeat: "no-repeat",
                animation: "crt-scanline 3.14s linear infinite",
              }}
            />
          )}
        </div>

        {/* Layer 4: CRT glass sheen — subtle specular highlight on curved glass.
            Only visible when powered off, fades out when terminal boots. */}
        <div
          className="pointer-events-none absolute"
          style={{
            top: "calc(14% + 2px - 13px)",
            left: "calc(21% - 10px)",
            width: "calc(58% + 20px)",
            height: "calc(45% + 20px)",
            borderRadius: "31px",
            background: [
              /* Diagonal specular highlight — light reflecting off convex glass with theme tint */
              "linear-gradient(135deg, rgba(var(--accent-glow), 0.15) 0%, rgba(var(--accent-glow), 0.05) 35%, transparent 60%)",
              /* Soft edge vignette — darkens toward edges like curved glass */
              "radial-gradient(ellipse 80% 80% at 48% 45%, rgba(var(--accent-glow), 0.03) 0%, rgba(60,60,70,0.4) 100%)",
            ].join(", "),
            opacity: 1,
            zIndex: 4,
          }}
        />

        {/* CRT Monitor frame — on top of everything, transparent center reveals content behind */}
        <Image
          src="/tuikit-logo.png"
          alt="TUIkit Logo"
          width={640}
          height={640}
          className="relative h-full w-full rounded-3xl"
          style={{ objectFit: "contain", zIndex: 5 }}
          priority
        />

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

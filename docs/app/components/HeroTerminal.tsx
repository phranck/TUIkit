"use client";

import Image from "next/image";
import { useCallback, useEffect, useRef, useState } from "react";
import { Howl } from "howler";
import TerminalScreen from "./TerminalScreen";

/**
 * CRT layer geometry — centralizes the repeated calc() strings used
 * to position backing, content, glow, and glass layers over the logo.
 */
const CRT = {
  /** Content area (terminal text). */
  content: { top: "calc(14% + 2px)", left: "21%", width: "58%", height: "45%" },
  /** Backing surface (black fill behind the transparent logo center). */
  backing: { top: "calc(14% + 2px - 13px)", left: "calc(21% - 10px)", width: "calc(58% + 20px)", height: "calc(45% + 20px)", borderRadius: "31px" },
  /** Glow overlay (edge vignette + scanline sweep). */
  glow: { top: "calc(14% + 2px - 18px)", left: "calc(21% - 15px)", width: "calc(58% + 30px)", height: "calc(45% + 30px)", borderRadius: "31px" },
} as const;

/** Duration of the zoom-out CSS transition in ms. */
const ZOOM_OUT_DURATION_MS = 500;
/** Delay before boot spin loop starts (slightly before boot audio ends). */
const SPIN_START_DELAY_MS = 19900;
/** Delay before random seek sounds begin (after boot finishes). */
const SEEK_START_DELAY_MS = 20300;

/**
 * Interactive hero terminal with power-on animation.
 *
 * Initially shows the CRT logo at 320×320. When the user clicks the red
 * power button, the logo zooms to center screen at double size, the
 * background dims, and the full terminal boot sequence begins.
 *
 * Uses CSS `transform: scale()` for the zoom animation so the element
 * animates smoothly from its inline position to viewport center.
 */
export default function HeroTerminal() {
  const [powered, setPowered] = useState(false);
  const [zoomed, setZoomed] = useState(false);
  const [mounted, setMounted] = useState(false);
  /** Guards against rapid double-clicks bypassing the `powered` state check. */
  const poweringOnRef = useRef(false);
  const containerRef = useRef<HTMLDivElement>(null);

  /** Offset to translate the element from its inline position to viewport center. */
  const [centerOffset, setCenterOffset] = useState({ x: 0, y: 0 });

  /** Audio references for hard drive sounds. */
  const powerOnAudioRef = useRef<Howl | null>(null);
  const bootAudioRef = useRef<Howl | null>(null);
  const spinAudioRef = useRef<Howl | null>(null);
  const powerOffAudioRef = useRef<Howl | null>(null);
  /** Reusable seek sound — avoids creating new Howl instances per seek. */
  const seekAudioRef = useRef<Howl | null>(null);
  /** Tracks all pending setTimeout handles for cleanup on power-off/unmount. */
  const pendingTimersRef = useRef<Set<ReturnType<typeof setTimeout>>>(new Set());

  /** Helper: schedule a timeout and track it for cleanup. */
  const scheduleTimer = useCallback((callback: () => void, delayMs: number) => {
    const handle = setTimeout(() => {
      pendingTimersRef.current.delete(handle);
      callback();
    }, delayMs);
    pendingTimersRef.current.add(handle);
    return handle;
  }, []);

  /** Helper: clear all pending timers. */
  const clearAllTimers = useCallback(() => {
    for (const handle of pendingTimersRef.current) clearTimeout(handle);
    pendingTimersRef.current.clear();
  }, []);

  // Preload audio on mount
  useEffect(() => {
    powerOnAudioRef.current = new Howl({ src: ["/sounds/power-on.mp3"], volume: 0.3 });
    bootAudioRef.current = new Howl({ src: ["/sounds/hard-drive-boot.m4a"], volume: 0.6 });
    spinAudioRef.current = new Howl({ src: ["/sounds/hard-drive-spin.m4a"], volume: 0.6, loop: true });
    powerOffAudioRef.current = new Howl({ src: ["/sounds/hard-drive-power-off.m4a"], volume: 0.6 });
    seekAudioRef.current = new Howl({ src: ["/sounds/hard-drive-seek1.m4a"], volume: 0.4 });
    
    return () => {
      clearAllTimers();
      [powerOnAudioRef, bootAudioRef, spinAudioRef, powerOffAudioRef, seekAudioRef].forEach(ref => {
        if (ref.current) {
          ref.current.stop();
          ref.current.unload();
        }
      });
    };
  }, [clearAllTimers]);

  // Handle client-side hydration for power button
  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
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

  /** Power on: play boot sound, start spin loop, add random seeks. */
  const handlePowerOn = useCallback(() => {
    if (powered || poweringOnRef.current) return;
    poweringOnRef.current = true;
    
    setPowered(true);
    setCenterOffset(computeCenterOffset());
    
    if (powerOnAudioRef.current && bootAudioRef.current && spinAudioRef.current) {
      powerOnAudioRef.current.seek(0);
      powerOnAudioRef.current.play();
      bootAudioRef.current.seek(0);
      bootAudioRef.current.play();
      
      // Start gapless spin loop slightly before boot ends for seamless transition
      scheduleTimer(() => {
        spinAudioRef.current?.play();
      }, SPIN_START_DELAY_MS);
      
      // Recursive seek scheduling — each invocation picks a fresh random delay.
      // All timeouts go through scheduleTimer so clearAllTimers catches them.
      const scheduleNextSeek = () => {
        scheduleTimer(() => {
          seekAudioRef.current?.seek(0);
          seekAudioRef.current?.play();
          
          // 30% chance for a second seek shortly after
          if (Math.random() < 0.3) {
            scheduleTimer(() => {
              seekAudioRef.current?.seek(0);
              seekAudioRef.current?.play();
            }, 200 + Math.random() * 200);
          }
          
          scheduleNextSeek();
        }, 15000 + Math.random() * 10000);
      };
      
      // Start seek loop after boot finishes
      scheduleTimer(scheduleNextSeek, SEEK_START_DELAY_MS);
    }
    
    // Zoom after 200ms delay
    scheduleTimer(() => setZoomed(true), 200);
  }, [powered, computeCenterOffset, scheduleTimer]);

  /** Power off: stop all sounds, play power-off sound, zoom back. */
  const handlePowerOff = useCallback(() => {
    setZoomed(false);
    clearAllTimers();
    poweringOnRef.current = false;
    
    // Stop all running sounds
    powerOnAudioRef.current?.stop();
    bootAudioRef.current?.stop();
    spinAudioRef.current?.stop();
    
    // Play power-off sound
    if (powerOffAudioRef.current) {
      powerOffAudioRef.current.seek(0);
      powerOffAudioRef.current.play();
    }
    
    /* Wait for zoom-out animation to finish before killing power. */
    scheduleTimer(() => setPowered(false), ZOOM_OUT_DURATION_MS);
  }, [clearAllTimers, scheduleTimer]);

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
        {/* Layer 1: Black backing surface — behind the transparent frame center */}
        <div
          className="absolute"
          style={{
            ...CRT.backing,
            background: "#000",
            zIndex: 1,
          }}
        />

        {/* Layer 2: Terminal content — above backing, below glow */}
        <div
          className="pointer-events-none absolute overflow-hidden"
          style={{
            ...CRT.content,
            zIndex: 2,
          }}
        >
          <TerminalScreen powered={powered} />
        </div>

        {/* Layer 3: CRT edge glow + scanline sweep — above content, below frame.
            Inner glow simulates the edge darkening of a real CRT monitor. */}
        <div
          className="pointer-events-none absolute"
          style={{
            ...CRT.glow,
            boxShadow:
              "inset 0 0 16px 7px rgba(var(--accent-glow), 0.42), inset 0 0 38px 14px rgba(var(--accent-glow), 0.15)",
            overflow: "hidden",
            zIndex: 3,
          }}
        >
          {/* Scanline sweep — cathode ray with sharp bottom edge, trailing upward */}
          {powered && (
            <div
              style={{
                position: "absolute",
                left: 0,
                top: 0,
                width: "100%",
                height: "150px",
                animation: "crt-scanline-move 15s linear infinite",
              }}
            >
              {/* Trailing glow above - blurred */}
              <div
                style={{
                  position: "absolute",
                  left: 0,
                  top: 0,
                  width: "100%",
                  height: "100%",
                  background:
                    "linear-gradient(to bottom, transparent 0%, rgba(var(--accent-glow), 0.01) 40%, rgba(var(--accent-glow), 0.02) 70%, rgba(var(--accent-glow), 0.04) 90%, rgba(var(--accent-glow), 0.05) 100%)",
                  filter: "blur(3px)",
                }}
              />
              {/* Sharp bottom edge - no blur */}
              <div
                style={{
                  position: "absolute",
                  left: 0,
                  bottom: 0,
                  width: "100%",
                  height: "2px",
                  background: "rgba(var(--accent-glow), 0.04)",
                }}
              />
            </div>
          )}
        </div>

        {/* Layer 4: CRT glass sheen — permanent specular highlight on curved glass */}
        <div
          className="pointer-events-none absolute"
          style={{
            ...CRT.backing,
            background: [
              /* Diagonal specular highlight — light reflecting off convex glass with theme tint */
              "linear-gradient(135deg, rgba(var(--accent-glow), 0.15) 0%, rgba(var(--accent-glow), 0.05) 35%, transparent 60%)",
              /* Soft edge vignette — darkens toward edges like curved glass */
              "radial-gradient(ellipse 80% 80% at 48% 45%, rgba(var(--accent-glow), 0.03) 0%, rgba(60,60,70,0.4) 100%)",
            ].join(", "),
            zIndex: 4,
          }}
        />

        {/* CRT Monitor frame — on top of everything, transparent center reveals content */}
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

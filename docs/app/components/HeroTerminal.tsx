"use client";

import Image from "next/image";
import { useCallback, useEffect, useRef, useState } from "react";
import { Howl } from "howler";
import TerminalScreen from "./TerminalScreen";

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
  const zoomTimerRef = useRef<ReturnType<typeof setTimeout>>(undefined);
  const powerOffTimerRef = useRef<ReturnType<typeof setTimeout>>(undefined);

  /** Offset to translate the element from its inline position to viewport center. */
  const [centerOffset, setCenterOffset] = useState({ x: 0, y: 0 });

  /** Audio references for hard drive sounds */
  const powerOnAudioRef = useRef<Howl | null>(null);
  const bootAudioRef = useRef<Howl | null>(null);
  const spinAudioRef = useRef<Howl | null>(null);
  const powerOffAudioRef = useRef<Howl | null>(null);
  const seekIntervalRef = useRef<ReturnType<typeof setInterval>>(undefined);

  useEffect(() => {
    setMounted(true);
    
    // Preload all audio files with Howler.js
    powerOnAudioRef.current = new Howl({
      src: ["/sounds/power-on.mp3"],
      volume: 0.3,
    });
    
    bootAudioRef.current = new Howl({
      src: ["/sounds/hard-drive-boot.m4a"],
      volume: 0.6,
    });
    
    // Spin sound with loop enabled for gapless playback
    spinAudioRef.current = new Howl({
      src: ["/sounds/hard-drive-spin.m4a"],
      volume: 0.6,
      loop: true, // Howler.js handles gapless looping automatically
    });
    
    powerOffAudioRef.current = new Howl({
      src: ["/sounds/hard-drive-power-off.m4a"],
      volume: 0.6,
    });
    
    return () => {
      if (zoomTimerRef.current) clearTimeout(zoomTimerRef.current);
      if (powerOffTimerRef.current) clearTimeout(powerOffTimerRef.current);
      if (seekIntervalRef.current) clearInterval(seekIntervalRef.current);
      
      // Stop all audio
      [powerOnAudioRef, bootAudioRef, spinAudioRef, powerOffAudioRef].forEach(ref => {
        if (ref.current) {
          ref.current.stop();
          ref.current.unload();
        }
      });
    };
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

  /** Power on: play boot sound, start spin loop, add random seeks */
  const handlePowerOn = useCallback(() => {
    if (powered) return;
    
    setPowered(true);
    setCenterOffset(computeCenterOffset());
    
    // Play power-on beep first, then boot sound
    if (powerOnAudioRef.current && bootAudioRef.current && spinAudioRef.current) {
      powerOnAudioRef.current.seek(0);
      powerOnAudioRef.current.play();
      
      bootAudioRef.current.seek(0);
      bootAudioRef.current.play();
      
      // Start gapless spin loop slightly before boot ends for seamless transition
      setTimeout(() => {
        if (spinAudioRef.current) {
          spinAudioRef.current.play(); // Howler.js handles gapless looping with loop: true
        }
      }, 19900); // Start 280ms before boot ends (~20.18s) for overlap
      
      // Random seek sounds every 15-25 seconds (only seek1), sometimes double-seek
      setTimeout(() => {
        seekIntervalRef.current = setInterval(() => {
          const seekSound = new Howl({
            src: ["/sounds/hard-drive-seek1.m4a"],
            volume: 0.4, // Quieter than boot/spin
          });
          seekSound.play();
          
          // 30% chance for a second seek shortly after (200-400ms delay)
          if (Math.random() < 0.3) {
            setTimeout(() => {
              const seekSound2 = new Howl({
                src: ["/sounds/hard-drive-seek1.m4a"],
                volume: 0.4,
              });
              seekSound2.play();
            }, 200 + Math.random() * 200); // 200-400ms delay
          }
        }, 15000 + Math.random() * 10000); // 15-25s random interval
      }, 20300); // Start after boot finishes (~20.18s)
    }
    
    // Zoom after 200ms delay
    zoomTimerRef.current = setTimeout(() => setZoomed(true), 200);
  }, [powered, computeCenterOffset]);

  /** Power off: stop all sounds, play power-off sound, zoom back */
  const handlePowerOff = useCallback(() => {
    setZoomed(false);
    
    // Stop seek interval
    if (seekIntervalRef.current) {
      clearInterval(seekIntervalRef.current);
      seekIntervalRef.current = undefined;
    }
    
    // Stop all running sounds
    if (powerOnAudioRef.current) {
      powerOnAudioRef.current.stop();
    }
    if (bootAudioRef.current) {
      bootAudioRef.current.stop();
    }
    if (spinAudioRef.current) {
      spinAudioRef.current.stop(); // Howler.js stop() method
    }
    
    // Play power-off sound
    if (powerOffAudioRef.current) {
      powerOffAudioRef.current.seek(0);
      powerOffAudioRef.current.play();
    }
    
    /* Wait for zoom-out animation to finish before killing power. */
    powerOffTimerRef.current = setTimeout(() => setPowered(false), 500);
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

        {/* Layer 4: CRT glass sheen — permanent specular highlight on curved glass. */}
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

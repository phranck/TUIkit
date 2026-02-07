import { useCallback, useEffect, useRef, useState } from "react";
import type { Howl } from "howler";
import TerminalScreen from "./TerminalScreen";

/** Lazy-loaded Howl factory to avoid bundling howler.js on initial load. */
let HowlClass: typeof Howl | null = null;
async function createHowl(options: { src: string[]; volume: number; loop?: boolean }): Promise<Howl> {
  if (!HowlClass) {
    const module = await import("howler");
    HowlClass = module.Howl;
  }
  return new HowlClass(options);
}

/**
 * CRT layer geometry: centralizes the repeated calc() strings used
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

/**
 * CRT power-on animation timing.
 * The vertical deflection coils need a moment to reach full amplitude,
 * so the image starts as a bright horizontal line and expands vertically.
 * Less dramatic than power-off: no visible dot phase.
 */
const CRT_EXPAND_VERTICAL_MS = 300;

/**
 * CRT power-off animation timing.
 * Real CRTs collapse the image vertically to a bright horizontal line,
 * then horizontally to a glowing dot, which slowly fades as the phosphor
 * afterglow decays.
 */
const CRT_COLLAPSE_VERTICAL_MS = 150;
const CRT_COLLAPSE_HORIZONTAL_MS = 200;
const CRT_AFTERGLOW_MS = 600;
const CRT_SHUTDOWN_TOTAL_MS =
  CRT_COLLAPSE_VERTICAL_MS + CRT_COLLAPSE_HORIZONTAL_MS + CRT_AFTERGLOW_MS;
/** Delay before boot spin loop starts (slightly before boot audio ends). */
const SPIN_START_DELAY_MS = 19900;
/** Delay before random seek sounds begin (after boot finishes). */
const SEEK_START_DELAY_MS = 20300;

/**
 * Interactive hero terminal with power-on animation.
 *
 * Initially shows the CRT logo at 320x320. When the user clicks the red
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
  /**
   * CRT boot phase: null (not booting), or a phase number.
   * 1 = horizontal line (scaleY~0), 2 = expanding vertically to full image.
   */
  const [bootPhase, setBootPhase] = useState<1 | 2 | null>(null);
  /**
   * CRT shutdown phase: null (not shutting down), or a phase number.
   * 1 = vertical collapse (scaleY -> 0), 2 = horizontal collapse (scaleX -> 0),
   * 3 = afterglow dot fading out.
   */
  const [shutdownPhase, setShutdownPhase] = useState<1 | 2 | 3 | null>(null);
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
  /** Reusable seek sound: avoids creating new Howl instances per seek. */
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

  /** Whether audio has been loaded (lazy-loaded on first power-on). */
  const audioLoadedRef = useRef(false);

  /** Lazy-load all audio files on first power-on click. */
  const ensureAudioLoaded = useCallback(async () => {
    if (audioLoadedRef.current) return;
    audioLoadedRef.current = true;

    const [powerOn, boot, spin, powerOff, seek] = await Promise.all([
      createHowl({ src: ["/sounds/power-on.mp3"], volume: 0.3 }),
      createHowl({ src: ["/sounds/hard-drive-boot.m4a"], volume: 0.6 }),
      createHowl({ src: ["/sounds/hard-drive-spin.m4a"], volume: 0.6, loop: true }),
      createHowl({ src: ["/sounds/hard-drive-power-off.m4a"], volume: 0.6 }),
      createHowl({ src: ["/sounds/hard-drive-seek1.m4a"], volume: 0.4 }),
    ]);

    powerOnAudioRef.current = powerOn;
    bootAudioRef.current = boot;
    spinAudioRef.current = spin;
    powerOffAudioRef.current = powerOff;
    seekAudioRef.current = seek;
  }, []);

  // Cleanup audio on unmount
  useEffect(() => {
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

  // Handle client-side hydration for power button and detect phone-sized screens
  const [isPhone, setIsPhone] = useState(false);
  useEffect(() => {
    setMounted(true);
    // Check if phone (< 768px): tablets and larger keep the power button
    const checkPhone = () => setIsPhone(window.innerWidth < 768);
    checkPhone();
    window.addEventListener("resize", checkPhone);
    return () => window.removeEventListener("resize", checkPhone);
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

  /** Power on: CRT raster expansion, then play boot sound, start spin loop, add random seeks. */
  const handlePowerOn = useCallback(async () => {
    if (powered || poweringOnRef.current) return;
    poweringOnRef.current = true;

    // Lazy-load audio on first power-on (no-op on subsequent calls)
    await ensureAudioLoaded();
    
    // Start with horizontal line, then expand vertically
    setBootPhase(1);
    setPowered(true);
    setCenterOffset(computeCenterOffset());

    // Phase 2: vertical expansion (CSS transition handles the animation)
    // Use requestAnimationFrame to ensure phase 1 is painted first
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        setBootPhase(2);
      });
    });
    // Clear boot phase after expansion completes
    scheduleTimer(() => setBootPhase(null), CRT_EXPAND_VERTICAL_MS + 50);
    
    if (powerOnAudioRef.current && bootAudioRef.current && spinAudioRef.current) {
      powerOnAudioRef.current.seek(0);
      powerOnAudioRef.current.play();
      bootAudioRef.current.seek(0);
      bootAudioRef.current.play();
      
      // Start gapless spin loop slightly before boot ends for seamless transition
      scheduleTimer(() => {
        spinAudioRef.current?.play();
      }, SPIN_START_DELAY_MS);
      
      // Recursive seek scheduling: each invocation picks a fresh random delay.
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
  }, [powered, computeCenterOffset, scheduleTimer, ensureAudioLoaded]);

  /** Power off: run CRT shutdown animation, then zoom back and kill power. */
  const handlePowerOff = useCallback(() => {
    if (shutdownPhase !== null) return; // Already shutting down
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
    
    // Phase 1: Vertical collapse
    setShutdownPhase(1);
    
    // Phase 2: Horizontal collapse
    scheduleTimer(() => setShutdownPhase(2), CRT_COLLAPSE_VERTICAL_MS);
    
    // Phase 3: Afterglow dot
    scheduleTimer(
      () => setShutdownPhase(3),
      CRT_COLLAPSE_VERTICAL_MS + CRT_COLLAPSE_HORIZONTAL_MS,
    );
    
    // Complete: kill power immediately (screen is already black),
    // then zoom back. Order matters: powered must be false before
    // shutdownPhase clears, otherwise the content flashes back briefly.
    scheduleTimer(() => {
      setPowered(false);
      setShutdownPhase(null);
      setZoomed(false);
    }, CRT_SHUTDOWN_TOTAL_MS);
  }, [shutdownPhase, clearAllTimers, scheduleTimer]);

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
      {/* Dimming overlay: behind the zoomed terminal */}
      <div
        className="fixed inset-0 z-[100] bg-black/80 backdrop-blur-sm transition-opacity duration-500"
        style={{
          opacity: zoomed ? 1 : 0,
          pointerEvents: zoomed ? "auto" : "none",
        }}
        onClick={handlePowerOff}
      />

      {/* Terminal container: uses transform for smooth zoom from inline position */}
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
        {/* Layer 1: Black backing surface: behind the transparent frame center */}
        <div
          className="absolute"
          style={{
            ...CRT.backing,
            background: "#000",
            zIndex: 1,
          }}
        />

        {/* Layer 2: Terminal content: above backing, below glow.
            Boot-up: starts as bright horizontal line (scaleY~0), expands vertically.
            Shutdown: collapses vertically -> horizontally -> afterglow dot. */}
        <div
          className="pointer-events-none absolute overflow-hidden"
          style={{
            ...CRT.content,
            zIndex: 2,
            /* Boot animation */
            ...(bootPhase === 1 ? {
              transform: "scaleY(0.008)",
              filter: `brightness(3) drop-shadow(0 0 6px rgba(var(--accent-glow), 0.9))`,
            } : bootPhase === 2 ? {
              transform: "scaleY(1)",
              transition: `transform ${CRT_EXPAND_VERTICAL_MS}ms ease-out, filter ${CRT_EXPAND_VERTICAL_MS}ms ease-out`,
              filter: "brightness(1)",
            } : {}),
            /* Shutdown animation (overrides boot if both somehow active) */
            ...(shutdownPhase === 1 ? {
              transform: "scaleY(0.005)",
              transition: `transform ${CRT_COLLAPSE_VERTICAL_MS}ms ease-in`,
              filter: `brightness(2.5) drop-shadow(0 0 8px rgba(var(--accent-glow), 0.8))`,
            } : shutdownPhase === 2 ? {
              transform: "scaleY(0.005) scaleX(0)",
              transition: `transform ${CRT_COLLAPSE_HORIZONTAL_MS}ms ease-in`,
              filter: `brightness(2.5) drop-shadow(0 0 8px rgba(var(--accent-glow), 0.8))`,
            } : shutdownPhase === 3 ? {
              transform: "scale(0)",
            } : {}),
          }}
        >
          <TerminalScreen powered={powered} />
        </div>

        {/* CRT afterglow dot: bright phosphor dot that fades after the image collapses */}
        {shutdownPhase === 3 && (
          <div
            className="pointer-events-none absolute"
            style={{
              ...CRT.content,
              zIndex: 2,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <div
              style={{
                width: 6,
                height: 6,
                borderRadius: "50%",
                background: `rgba(var(--accent-glow), 0.9)`,
                boxShadow: `0 0 12px 6px rgba(var(--accent-glow), 0.6), 0 0 30px 12px rgba(var(--accent-glow), 0.3)`,
                animation: `crt-afterglow ${CRT_AFTERGLOW_MS}ms ease-out forwards`,
              }}
            />
          </div>
        )}

        {/* Layer 3: CRT edge glow + scanline sweep: above content, below frame.
            Inner glow simulates the edge darkening of a real CRT monitor.
            Only visible when powered on and not shutting down. */}
        <div
          className="pointer-events-none absolute"
          style={{
            ...CRT.glow,
            boxShadow: powered && !shutdownPhase
              ? "inset 0 0 16px 7px rgba(var(--accent-glow), 0.42), inset 0 0 38px 14px rgba(var(--accent-glow), 0.15)"
              : "none",
            overflow: "hidden",
            zIndex: 3,
            transition: `box-shadow ${CRT_COLLAPSE_VERTICAL_MS}ms ease-out`,
          }}
        >
          {/* Scanline sweep: cathode ray with sharp bottom edge, trailing upward */}
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

        {/* Layer 4: CRT glass sheen: permanent specular highlight on curved glass */}
        <div
          className="pointer-events-none absolute"
          style={{
            ...CRT.backing,
            background: [
              /* Diagonal specular highlight: light reflecting off convex glass with theme tint */
              "linear-gradient(135deg, rgba(var(--accent-glow), 0.15) 0%, rgba(var(--accent-glow), 0.05) 35%, transparent 60%)",
              /* Soft edge vignette: darkens toward edges like curved glass */
              "radial-gradient(ellipse 80% 80% at 48% 45%, rgba(var(--accent-glow), 0.03) 0%, rgba(60,60,70,0.4) 100%)",
            ].join(", "),
            zIndex: 4,
          }}
        />

        {/* CRT Monitor frame: on top of everything, transparent center reveals content */}
        <img
          src="/tuikit-logo.png"
          alt="TUIkit Logo"
          width={640}
          height={640}
          className="relative h-full w-full rounded-3xl"
          style={{ objectFit: "contain", zIndex: 5 }}
        />

        {/* Red power button: positioned over the physical button in the logo.
            Disabled on phones (< 768px) to prevent the zoomed view on small screens. */}
        {mounted && !isPhone && (
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

"use client";

import { useEffect, useRef, useState } from "react";

/** Movement behavior of a spinner light. */
type DriftMode = "static" | "inward";

/** A single distant light with position, lifecycle, and optional drift. */
interface SpinnerLight {
  /** Unique key for React reconciliation. */
  id: number;
  /** Horizontal start position as viewport percentage. */
  xPercent: number;
  /** Vertical start position as viewport percentage. */
  yPercent: number;
  /** Total visible duration in ms (fade in + hold + fade out). */
  duration: number;
  /** Size of the light dot in pixels. */
  size: number;
  /** Peak opacity (0–1). */
  peakOpacity: number;
  /** Whether this light drifts toward center or stays put. */
  driftMode: DriftMode;
  /** Horizontal drift toward center in viewport percentage (only for "inward"). */
  driftX: number;
  /** Vertical drift toward center in viewport percentage (only for "inward"). */
  driftY: number;
}

/** How many lights can be visible simultaneously. */
const MAX_VISIBLE = 8;

/** Interval range for spawning a new light (ms). */
const SPAWN_MIN_MS = 800;
const SPAWN_MAX_MS = 3000;

/** Duration range for a single light's lifecycle (ms). */
const DURATION_MIN_MS = 3000;
const DURATION_MAX_MS = 8000;

/** Viewport center target for inward drift. */
const CENTER_X = 50;
const CENTER_Y = 40;

/** How much of the distance toward center to cover (0–1). */
const DRIFT_FACTOR = 0.35;

let nextId = 0;

/**
 * Distant spinner lights that appear randomly across the viewport,
 * pulse softly, then fade out and reappear elsewhere.
 *
 * Some lights drift slowly toward the viewport center while shrinking,
 * creating the illusion of flying into the scene — like distant Blade
 * Runner spinner craft approaching through rain and haze.
 */
export default function SpinnerLights() {
  const [lights, setLights] = useState<SpinnerLight[]>([]);
  const timeoutRef = useRef<ReturnType<typeof setTimeout>>(undefined);
  const removalTimersRef = useRef<Set<ReturnType<typeof setTimeout>>>(new Set());

  useEffect(() => {
    /** Spawn a new light at a random position. */
    const spawnLight = () => {
      const xStart = 5 + Math.random() * 90;
      const yStart = 5 + Math.random() * 70;

      /* ~60% of lights drift inward, the rest pulse in place. */
      const driftMode: DriftMode = Math.random() < 0.6 ? "inward" : "static";

      /* Calculate drift vector toward center in px. */
      const viewW = window.innerWidth;
      const viewH = window.innerHeight;
      const towardCenterX = ((CENTER_X - xStart) / 100) * viewW * DRIFT_FACTOR;
      const towardCenterY = ((CENTER_Y - yStart) / 100) * viewH * DRIFT_FACTOR;

      const light: SpinnerLight = {
        id: nextId++,
        xPercent: xStart,
        yPercent: yStart,
        duration: DURATION_MIN_MS + Math.random() * (DURATION_MAX_MS - DURATION_MIN_MS),
        size: driftMode === "inward" ? 3 + Math.random() * 3 : 2 + Math.random() * 3,
        peakOpacity: 0.3 + Math.random() * 0.5,
        driftMode,
        driftX: driftMode === "inward" ? towardCenterX : 0,
        driftY: driftMode === "inward" ? towardCenterY : 0,
      };

      setLights((prev) => {
        const trimmed = prev.length >= MAX_VISIBLE ? prev.slice(1) : prev;
        return [...trimmed, light];
      });

      /* Remove after its lifecycle completes. Timer is tracked for cleanup. */
      const removalTimer = setTimeout(() => {
        removalTimersRef.current.delete(removalTimer);
        setLights((prev) => prev.filter((entry) => entry.id !== light.id));
      }, light.duration);
      removalTimersRef.current.add(removalTimer);

      /* Schedule next spawn. */
      const nextDelay = SPAWN_MIN_MS + Math.random() * (SPAWN_MAX_MS - SPAWN_MIN_MS);
      timeoutRef.current = setTimeout(spawnLight, nextDelay);
    };

    /* Initial spawn after short delay. */
    timeoutRef.current = setTimeout(spawnLight, 1000);

    return () => {
      if (timeoutRef.current) clearTimeout(timeoutRef.current);
      for (const timer of removalTimersRef.current) clearTimeout(timer);
      removalTimersRef.current.clear();
    };
  }, []);

  return (
    <div className="pointer-events-none fixed inset-0 -z-5 overflow-hidden">
      {lights.map((light) => {
        const isInward = light.driftMode === "inward";

        return (
          <div
            key={light.id}
            className="absolute rounded-full"
            style={{
              left: `${light.xPercent}%`,
              top: `${light.yPercent}%`,
              width: light.size,
              height: light.size,
              background: "rgba(var(--accent-glow), 0.9)",
              boxShadow: [
                `0 0 ${light.size * 2}px ${light.size}px rgba(var(--accent-glow), 0.4)`,
                `0 0 ${light.size * 6}px ${light.size * 2}px rgba(var(--accent-glow), 0.12)`,
              ].join(", "),
              animation: isInward
                ? `spinner-pulse-inward ${light.duration}ms ease-in-out forwards`
                : `spinner-pulse ${light.duration}ms ease-in-out forwards`,
              "--peak-opacity": light.peakOpacity,
              "--drift-x": `${light.driftX}px`,
              "--drift-y": `${light.driftY}px`,
            } as React.CSSProperties}
          />
        );
      })}
    </div>
  );
}

"use client";

/**
 * CRT Monitor Visual Effects
 * 
 * Applies vintage CRT monitor effects inspired by cool-retro-term:
 * - Scanlines (horizontal raster lines)
 * - Screen curvature
 * - Glow/bloom effect
 * - Subtle flicker animation
 * - Noise overlay
 * - Vignette darkening at edges
 */

import { useEffect, useRef } from "react";

interface CRTEffectsProps {
  /** Enable/disable all effects */
  enabled?: boolean;
  /** Scanline intensity (0-1, default 0.15) */
  scanlineIntensity?: number;
  /** Screen curvature amount (0-1, default 0.1) */
  curvature?: number;
  /** Glow intensity (0-1, default 0.3) */
  glowIntensity?: number;
  /** Flicker intensity (0-1, default 0.03) */
  flickerIntensity?: number;
  /** Noise intensity (0-1, default 0.05) */
  noiseIntensity?: number;
}

export default function CRTEffects({
  enabled = true,
  scanlineIntensity = 0.15,
  curvature = 0.1,
  glowIntensity = 0.3,
  flickerIntensity = 0.03,
  noiseIntensity = 0.05,
}: CRTEffectsProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    if (!enabled) return;

    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animationFrame: number;

    // Noise animation
    const drawNoise = () => {
      const { width, height } = canvas;
      const imageData = ctx.createImageData(width, height);
      const data = imageData.data;

      for (let i = 0; i < data.length; i += 4) {
        const noise = Math.random() * 255 * noiseIntensity;
        data[i] = noise;     // R
        data[i + 1] = noise; // G
        data[i + 2] = noise; // B
        data[i + 3] = noise * 0.5; // A
      }

      ctx.putImageData(imageData, 0, 0);
      animationFrame = requestAnimationFrame(drawNoise);
    };

    // Set canvas size to match window
    const resizeCanvas = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    };

    resizeCanvas();
    window.addEventListener("resize", resizeCanvas);
    
    if (noiseIntensity > 0) {
      drawNoise();
    }

    return () => {
      window.removeEventListener("resize", resizeCanvas);
      if (animationFrame) {
        cancelAnimationFrame(animationFrame);
      }
    };
  }, [enabled, noiseIntensity]);

  if (!enabled) return null;

  return (
    <div
      className="pointer-events-none fixed inset-0 z-[200]"
      style={{ mixBlendMode: "screen" }}
    >
      {/* Scanlines */}
      <div
        className="absolute inset-0"
        style={{
          backgroundImage: `repeating-linear-gradient(
            0deg,
            rgba(0, 0, 0, ${scanlineIntensity}) 0px,
            transparent 1px,
            transparent 2px,
            rgba(0, 0, 0, ${scanlineIntensity * 0.5}) 3px
          )`,
          pointerEvents: "none",
        }}
      />

      {/* Screen curvature simulation via subtle vignette */}
      <div
        className="absolute inset-0"
        style={{
          background: `radial-gradient(
            ellipse at center,
            transparent 0%,
            transparent ${100 - curvature * 50}%,
            rgba(0, 0, 0, ${curvature * 0.3}) 100%
          )`,
          pointerEvents: "none",
        }}
      />

      {/* Glow/bloom effect */}
      <div
        className="absolute inset-0"
        style={{
          background: `radial-gradient(
            ellipse at center,
            rgba(var(--accent-glow), ${glowIntensity * 0.15}) 0%,
            transparent 60%
          )`,
          pointerEvents: "none",
        }}
      />

      {/* Flicker animation */}
      <div
        className="absolute inset-0 animate-crt-flicker"
        style={{
          backgroundColor: `rgba(255, 255, 255, ${flickerIntensity})`,
          pointerEvents: "none",
        }}
      />

      {/* Noise overlay canvas */}
      {noiseIntensity > 0 && (
        <canvas
          ref={canvasRef}
          className="absolute inset-0 opacity-30"
          style={{ pointerEvents: "none" }}
        />
      )}

      {/* Horizontal scanline glow */}
      <div
        className="absolute inset-0"
        style={{
          background: `linear-gradient(
            to bottom,
            transparent 0%,
            rgba(var(--accent-glow), ${scanlineIntensity * 0.3}) 50%,
            transparent 100%
          )`,
          height: "8px",
          animation: "crt-scanline 30s linear infinite",
          pointerEvents: "none",
        }}
      />
    </div>
  );
}

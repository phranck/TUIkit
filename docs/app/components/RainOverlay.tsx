"use client";

import { useEffect, useRef } from "react";

/** A single raindrop with position, speed, and visual properties. */
interface Raindrop {
  /** Horizontal position in pixels. */
  xPos: number;
  /** Vertical position in pixels. */
  yPos: number;
  /** Fall speed in pixels per frame. */
  speed: number;
  /** Streak length in pixels. */
  length: number;
  /** Opacity (0–1). */
  opacity: number;
  /** Wind drift in pixels per frame (positive = right). */
  drift: number;
  /** Stroke width in pixels (fixed per drop to avoid per-frame jitter). */
  strokeWidth: number;
}

/** Number of simultaneous raindrops. */
const DROP_COUNT = 120;

/**
 * Full-screen rain overlay rendered on a canvas element.
 *
 * Draws subtle, semi-transparent diagonal streaks that fall continuously,
 * tinted to the current theme color via CSS custom properties. The canvas
 * covers the entire viewport and is pointer-events-none so it never
 * interferes with page interaction.
 */
export default function RainOverlay() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animationId: number;

    /** Resize canvas to fill viewport. */
    const resize = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    };
    resize();
    window.addEventListener("resize", resize);

    /** Create a raindrop with random properties. */
    const createDrop = (startAtTop = false): Raindrop => ({
      xPos: Math.random() * (canvas.width + 100) - 50,
      yPos: startAtTop ? -Math.random() * canvas.height : Math.random() * canvas.height,
      speed: 2 + Math.random() * 4,
      length: 15 + Math.random() * 25,
      opacity: 0.1 + Math.random() * 0.18,
      drift: (Math.random() - 0.5) * 0.4,
      strokeWidth: 0.8 + Math.random() * 0.5,
    });

    /** Initialize drop pool — spread across the full viewport. */
    const drops: Raindrop[] = Array.from({ length: DROP_COUNT }, () => createDrop(false));

    /**
     * Reads the current --accent-glow CSS variable (R, G, B triplet)
     * so rain color follows the active theme.
     */
    const readThemeColor = (): string => {
      const raw = getComputedStyle(document.documentElement)
        .getPropertyValue("--accent-glow")
        .trim();
      return raw || "102, 255, 102";
    };

    let themeColor = readThemeColor();

    /** Watch for theme changes via data-theme attribute on <html>. */
    const observer = new MutationObserver(() => {
      themeColor = readThemeColor();
    });
    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["data-theme"],
    });

    /** Animation loop — clear, update, draw. */
    const frame = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      for (const drop of drops) {
        /* Draw streak. */
        ctx.beginPath();
        ctx.moveTo(drop.xPos, drop.yPos);
        ctx.lineTo(
          drop.xPos + drop.drift * (drop.length / drop.speed),
          drop.yPos + drop.length
        );
        ctx.strokeStyle = `rgba(${themeColor}, ${drop.opacity})`;
        ctx.lineWidth = drop.strokeWidth;
        ctx.stroke();

        /* Move drop. */
        drop.yPos += drop.speed;
        drop.xPos += drop.drift;

        /* Reset when off screen. */
        if (drop.yPos > canvas.height + drop.length) {
          drop.xPos = Math.random() * (canvas.width + 100) - 50;
          drop.yPos = -drop.length;
          drop.speed = 2 + Math.random() * 4;
          drop.opacity = 0.1 + Math.random() * 0.18;
        }
      }

      animationId = requestAnimationFrame(frame);
    };

    animationId = requestAnimationFrame(frame);

    return () => {
      cancelAnimationFrame(animationId);
      observer.disconnect();
      window.removeEventListener("resize", resize);
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      className="pointer-events-none fixed inset-0"
      style={{ zIndex: 0 }}
    />
  );
}

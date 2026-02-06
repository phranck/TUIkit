/**
 * Animated cloudy background tinted to the active theme color.
 *
 * Uses CSS custom properties (--accent-glow, --accent-glow-secondary,
 * --accent-glow-tertiary) so the clouds automatically recolor on theme switch.
 * Each blob has its own animation timing, position, and intensity.
 */

/** Build a radial gradient string using the theme glow CSS variables. */
function cloudGradient(
  shape: "circle" | "ellipse",
  innerVar: string,
  innerOpacity: number,
  outerVar?: string,
  outerOpacity?: number,
): string {
  const inner = `rgba(var(--accent-glow${innerVar}),${innerOpacity})`;
  if (outerVar !== undefined && outerOpacity !== undefined) {
    const outer = `rgba(var(--accent-glow${outerVar}),${outerOpacity})`;
    return `radial-gradient(${shape}, ${inner} 0%, ${outer} 40%, transparent 70%)`;
  }
  return `radial-gradient(${shape}, ${inner} 0%, transparent 60%)`;
}

export default function CloudBackground() {
  return (
    <div aria-hidden="true" className="pointer-events-none fixed inset-0 -z-10 overflow-hidden">
      {/* Large cloud: top left */}
      <div
        className="absolute -left-32 -top-32 h-[800px] w-[800px] rounded-full blur-[150px] transition-[background] duration-700"
        style={{
          background: cloudGradient("circle", "", 0.50, "-secondary", 0.20),
          animation: "cloud-drift 90s ease-in-out infinite",
        }}
      />

      {/* Medium cloud: top right */}
      <div
        className="absolute -right-20 top-1/4 h-[700px] w-[700px] rounded-full blur-[130px] transition-[background] duration-700"
        style={{
          background: cloudGradient("circle", "-secondary", 0.40, "-tertiary", 0.15),
          animation: "cloud-drift-reverse 110s ease-in-out infinite",
        }}
      />

      {/* Accent cloud: center */}
      <div
        className="absolute left-1/3 top-1/2 h-[600px] w-[600px] rounded-full blur-[120px] transition-[background] duration-700"
        style={{
          background: cloudGradient("circle", "", 0.35, "-secondary", 0.12),
          animation: "cloud-drift-slow 120s ease-in-out infinite",
        }}
      />

      {/* Bottom-left glow */}
      <div
        className="absolute -bottom-40 -left-20 h-[700px] w-[700px] rounded-full blur-[140px] transition-[background] duration-700"
        style={{
          background: cloudGradient("circle", "-tertiary", 0.38, "-secondary", 0.14),
          animation: "cloud-drift-reverse 100s ease-in-out infinite",
          animationDelay: "-30s",
        }}
      />

      {/* Wide upper cloud for depth */}
      <div
        className="absolute left-1/2 -top-20 h-[500px] w-[900px] -translate-x-1/2 rounded-full blur-[150px] transition-[background] duration-700"
        style={{
          background: cloudGradient("ellipse", "", 0.30),
          animation: "cloud-drift-slow 130s ease-in-out infinite",
          animationDelay: "-50s",
        }}
      />

      {/* Extra cloud: bottom right */}
      <div
        className="absolute -bottom-20 -right-32 h-[600px] w-[600px] rounded-full blur-[130px] transition-[background] duration-700"
        style={{
          background: cloudGradient("circle", "-secondary", 0.32, "", 0.10),
          animation: "cloud-drift 105s ease-in-out infinite",
          animationDelay: "-40s",
        }}
      />
    </div>
  );
}

/**
 * Animated cloudy background tinted to the active theme color.
 *
 * Uses CSS custom properties (--accent-glow, --accent-glow-secondary,
 * --accent-glow-tertiary) so the clouds automatically recolor on theme switch.
 * Each blob has its own animation timing, position, and intensity.
 */
export default function CloudBackground() {
  return (
    <div aria-hidden="true" className="pointer-events-none fixed inset-0 -z-10 overflow-hidden">
      {/* Large cloud — top left */}
      <div
        className="absolute -left-32 -top-32 h-[800px] w-[800px] rounded-full blur-[150px] transition-[background] duration-700"
        style={{
          background:
            "radial-gradient(circle, rgba(var(--accent-glow),0.50) 0%, rgba(var(--accent-glow-secondary),0.20) 40%, transparent 70%)",
          animation: "cloud-drift 90s ease-in-out infinite",
        }}
      />

      {/* Medium cloud — top right */}
      <div
        className="absolute -right-20 top-1/4 h-[700px] w-[700px] rounded-full blur-[130px] transition-[background] duration-700"
        style={{
          background:
            "radial-gradient(circle, rgba(var(--accent-glow-secondary),0.40) 0%, rgba(var(--accent-glow-tertiary),0.15) 40%, transparent 70%)",
          animation: "cloud-drift-reverse 110s ease-in-out infinite",
        }}
      />

      {/* Accent cloud — center */}
      <div
        className="absolute left-1/3 top-1/2 h-[600px] w-[600px] rounded-full blur-[120px] transition-[background] duration-700"
        style={{
          background:
            "radial-gradient(circle, rgba(var(--accent-glow),0.35) 0%, rgba(var(--accent-glow-secondary),0.12) 40%, transparent 70%)",
          animation: "cloud-drift-slow 120s ease-in-out infinite",
        }}
      />

      {/* Bottom-left glow */}
      <div
        className="absolute -bottom-40 -left-20 h-[700px] w-[700px] rounded-full blur-[140px] transition-[background] duration-700"
        style={{
          background:
            "radial-gradient(circle, rgba(var(--accent-glow-tertiary),0.38) 0%, rgba(var(--accent-glow-secondary),0.14) 40%, transparent 70%)",
          animation: "cloud-drift-reverse 100s ease-in-out infinite",
          animationDelay: "-30s",
        }}
      />

      {/* Wide upper cloud for depth */}
      <div
        className="absolute left-1/2 -top-20 h-[500px] w-[900px] -translate-x-1/2 rounded-full blur-[150px] transition-[background] duration-700"
        style={{
          background:
            "radial-gradient(ellipse, rgba(var(--accent-glow),0.30) 0%, transparent 60%)",
          animation: "cloud-drift-slow 130s ease-in-out infinite",
          animationDelay: "-50s",
        }}
      />

      {/* Extra cloud — bottom right */}
      <div
        className="absolute -bottom-20 -right-32 h-[600px] w-[600px] rounded-full blur-[130px] transition-[background] duration-700"
        style={{
          background:
            "radial-gradient(circle, rgba(var(--accent-glow-secondary),0.32) 0%, rgba(var(--accent-glow),0.10) 40%, transparent 70%)",
          animation: "cloud-drift 105s ease-in-out infinite",
          animationDelay: "-40s",
        }}
      />
    </div>
  );
}

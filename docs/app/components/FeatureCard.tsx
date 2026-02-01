import { ReactNode } from "react";

interface FeatureCardProps {
  icon: ReactNode;
  title: string;
  description: string;
}

/** A feature highlight card with icon, title, and description. */
export default function FeatureCard({
  icon,
  title,
  description,
}: FeatureCardProps) {
  return (
    <div
      className="group rounded-xl border border-border p-6 backdrop-blur-xl transition-all duration-300 hover:border-accent/30"
      style={{ backgroundColor: "color-mix(in srgb, var(--container-body) 50%, transparent)" }}
    >
      <div className="mb-3 flex items-center gap-3">
        <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg bg-accent/10 text-accent transition-colors group-hover:bg-accent/15">
          {icon}
        </div>
        <h3 className="text-2xl font-semibold text-foreground">{title}</h3>
      </div>
      <p className="text-xl leading-relaxed text-muted">{description}</p>
    </div>
  );
}

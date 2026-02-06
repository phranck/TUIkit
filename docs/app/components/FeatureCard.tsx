"use client";

import type { IconName } from "./Icon";
import Icon from "./Icon";

interface FeatureCardProps {
  icon: IconName;
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
      className="group rounded-xl border border-border bg-frosted-glass p-6 backdrop-blur-xl transition-all duration-300 hover:border-accent/30"
    >
      <div className="mb-3 flex items-center gap-3">
        <Icon name={icon} size={20} className="text-accent" />
        <h3 className="text-xl font-semibold text-foreground">{title}</h3>
      </div>
      <p className="text-lg leading-relaxed text-muted">{description}</p>
    </div>
  );
}

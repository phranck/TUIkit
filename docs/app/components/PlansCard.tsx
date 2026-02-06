"use client";

import { useState, useRef, useEffect } from "react";
import { usePlansCache } from "../hooks/usePlansCache";
import ReactMarkdown from "react-markdown";
import Icon from "./Icon";

/**
 * Animated collapsible container.
 * Measures content height via ref so it correctly animates open/close.
 */
function AnimatedCollapse({ expanded, children }: { expanded: boolean; children: React.ReactNode }) {
  const contentRef = useRef<HTMLDivElement>(null);
  const [height, setHeight] = useState(0);

  useEffect(() => {
    const element = contentRef.current;
    if (!element) return;

    if (!expanded) {
      setHeight(0);
      return;
    }

    setHeight(element.scrollHeight);

    const observer = new ResizeObserver(() => {
      setHeight(element.scrollHeight);
    });
    observer.observe(element);

    return () => observer.disconnect();
  }, [expanded]);

  return (
    <div
      className="overflow-hidden transition-all duration-300 ease-in-out"
      style={{ maxHeight: expanded ? height : 0, opacity: expanded ? 1 : 0 }}
    >
      <div ref={contentRef}>
        {children}
      </div>
    </div>
  );
}

/** Number of plans shown before expanding. */
const COLLAPSED_COUNT = 1;

/** Maximum number of plans to display per section. */
const MAX_PLANS = 6;

interface Plan {
  date: string;
  slug: string;
  title: string;
  preface: string;
}

/**
 * Renders a plan item with date, title, and preface (with markdown support).
 */
function PlanItem({ plan, isDone }: { plan: Plan; isDone: boolean }) {
  const [year, month, day] = plan.date.split("-");

  return (
    <div className="border-l-2 border-accent/30 pl-4 py-3">
      {/* Date + Title */}
      <div className="flex items-baseline gap-2">
        <span className="text-sm font-mono text-muted/60">{year}-{month}-{day}</span>
        <h4 className="text-lg font-semibold text-foreground">{plan.title}</h4>
      </div>

      {/* Preface with markdown rendering */}
      <div className="mt-2 text-lg text-muted prose prose-lg max-w-none [&_strong]:font-semibold [&_strong]:text-foreground [&_em]:italic [&_em]:text-muted [&_code]:bg-background/50 [&_code]:px-1 [&_code]:py-0.5 [&_code]:rounded [&_code]:text-accent [&_a]:text-accent [&_a]:underline [&_a:hover]:no-underline">
        <ReactMarkdown
          components={{
            p: ({ children }) => <p className="m-0 leading-relaxed">{children}</p>,
            strong: ({ children }) => <strong>{children}</strong>,
            em: ({ children }) => <em>{children}</em>,
            code: ({ children }) => <code>{children}</code>,
            a: ({ href, children }) => (
              <a href={href} target="_blank" rel="noopener noreferrer">
                {children}
              </a>
            ),
          }}
        >
          {plan.preface}
        </ReactMarkdown>
      </div>
    </div>
  );
}

/**
 * Collapsible section with header badge and expand/collapse toggle.
 */
function PlansSection({
  title,
  plans: allPlans,
  isDone,
}: {
  title: string;
  plans: Plan[];
  isDone: boolean;
}) {
  const [expanded, setExpanded] = useState(false);
  const plans = allPlans.slice(0, MAX_PLANS);
  const hasMore = plans.length > COLLAPSED_COUNT;
  const hiddenCount = plans.length - COLLAPSED_COUNT;

  return (
    <div>
      {/* Section header with toggle */}
      <button
        onClick={() => hasMore && setExpanded(!expanded)}
        className={`mb-3 inline-flex items-center gap-2 rounded bg-muted px-3 py-1 text-xs font-bold uppercase tracking-wider text-background ${hasMore ? "cursor-pointer hover:bg-muted/80" : "cursor-default"}`}
        disabled={!hasMore}
      >
        {hasMore && (
          <span className={`transition-transform duration-200 ${expanded ? "rotate-90" : ""}`}>
            <Icon name="chevronRight" size={12} />
          </span>
        )}
        {title}
        {hasMore && !expanded && (
          <span className="font-normal opacity-70">+{hiddenCount}</span>
        )}
      </button>

      {/* Always visible plans */}
      <div className="space-y-4">
        {plans.slice(0, COLLAPSED_COUNT).map((plan) => (
          <PlanItem key={plan.slug} plan={plan} isDone={isDone} />
        ))}
      </div>

      {/* Animated extra plans */}
      {hasMore && (
        <AnimatedCollapse expanded={expanded}>
          <div className="space-y-4 pt-4">
            {plans.slice(COLLAPSED_COUNT).map((plan) => (
              <PlanItem key={plan.slug} plan={plan} isDone={isDone} />
            ))}
          </div>
        </AnimatedCollapse>
      )}
    </div>
  );
}

/**
 * Plans Card: displays top 5 open and top 5 done plans from plans.json.
 * Includes markdown rendering for prefaces (bold, italics, code, links).
 * Each section is collapsible, showing 2 plans by default.
 */
export default function PlansCard() {
  const { data, loading, error, isFromCache } = usePlansCache();

  if (loading) {
    return (
      <div className="rounded-xl border border-border bg-frosted-glass p-6 backdrop-blur-xl">
        <h3 className="mb-4 flex items-center gap-3 text-xl font-semibold text-foreground">
          <Icon name="document" size={20} className="text-accent" />
          Development Plans
        </h3>
        <div className="space-y-3">
          {[...Array(3)].map((_, i) => (
            <div key={i} className="h-16 w-full animate-skeleton rounded bg-accent/10" />
          ))}
        </div>
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="rounded-xl border border-red-500/30 bg-red-500/10 p-6 backdrop-blur-xl text-sm text-red-400">
        <strong>Error loading plans:</strong> {error || "No data"}
      </div>
    );
  }

  return (
    <div className="rounded-xl border border-border bg-frosted-glass p-6 backdrop-blur-xl">
      {/* Header */}
      <h3 className="mb-4 flex items-center gap-3 text-xl font-semibold text-foreground">
        <Icon name="document" size={20} className="text-accent" />
        Development Plans
      </h3>

      {/* Open Plans Section */}
      {data.open.length > 0 && (
        <div className="mb-6">
          <PlansSection title="Open" plans={data.open} isDone={false} />
        </div>
      )}

      {/* Divider */}
      {data.open.length > 0 && data.done.length > 0 && (
        <div className="my-6 border-t border-border/10" />
      )}

      {/* Done Plans Section */}
      {data.done.length > 0 && (
        <PlansSection title="Recently Completed" plans={data.done} isDone={true} />
      )}
    </div>
  );
}

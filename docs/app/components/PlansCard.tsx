"use client";

import { usePlansCache } from "../hooks/usePlansCache";
import ReactMarkdown from "react-markdown";
import Icon from "./Icon";

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
        <span className="text-xs font-mono text-muted/60">{month}/{day}</span>
        <h4 className="text-sm font-semibold text-foreground">{plan.title}</h4>
      </div>

      {/* Preface with markdown rendering */}
      <div className="mt-2 text-sm text-muted prose prose-sm max-w-none [&_strong]:font-semibold [&_strong]:text-foreground [&_em]:italic [&_em]:text-muted [&_code]:bg-background/50 [&_code]:px-1 [&_code]:py-0.5 [&_code]:rounded [&_code]:text-accent [&_a]:text-accent [&_a]:underline [&_a:hover]:no-underline">
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
 * Plans Card — displays top 5 open and top 5 done plans from plans.json.
 * Includes markdown rendering for prefaces (bold, italics, code, links).
 */
export default function PlansCard() {
  const { data, loading, error, isFromCache } = usePlansCache();

  if (loading) {
    return (
      <div className="rounded-lg border border-border/20 bg-gradient-to-br from-background to-background/50 p-6">
        <div className="space-y-3">
          <div className="h-6 w-32 animate-pulse rounded bg-muted/20" />
          <div className="space-y-2">
            {[...Array(3)].map((_, i) => (
              <div key={i} className="h-4 w-full animate-pulse rounded bg-muted/10" />
            ))}
          </div>
        </div>
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="rounded-lg border border-red-500/30 bg-red-500/10 p-6 text-sm text-red-400">
        <strong>Error loading plans:</strong> {error || "No data"}
      </div>
    );
  }

  return (
    <div className="rounded-lg border border-border/20 bg-gradient-to-br from-background to-background/50 p-6">
      {/* Header */}
      <div className="mb-6 flex items-center justify-between">
        <h2 className="text-lg font-bold text-foreground">Development Plans</h2>
        <span className="text-xs text-muted/60">
          {isFromCache && "cached"}
        </span>
      </div>

      {/* Open Plans Section */}
      {data.open.length > 0 && (
        <div className="mb-6">
          <h3 className="mb-3 text-xs font-semibold uppercase tracking-wider text-accent/80">
            In Progress
          </h3>
          <div className="space-y-4">
            {data.open.map((plan) => (
              <PlanItem key={plan.slug} plan={plan} isDone={false} />
            ))}
          </div>
        </div>
      )}

      {/* Divider */}
      {data.open.length > 0 && data.done.length > 0 && (
        <div className="my-6 border-t border-border/10" />
      )}

      {/* Done Plans Section */}
      {data.done.length > 0 && (
        <div>
          <h3 className="mb-3 text-xs font-semibold uppercase tracking-wider text-muted/60">
            Recently Completed
          </h3>
          <div className="space-y-4">
            {data.done.map((plan) => (
              <PlanItem key={plan.slug} plan={plan} isDone={true} />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

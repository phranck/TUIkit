"use client";

import { useState, useEffect } from "react";

interface Plan {
  date: string;
  slug: string;
  title: string;
  preface: string;
}

interface PlansData {
  generated: string;
  open: Plan[];
  done: Plan[];
}

const CACHE_KEY = "tuikit_plans_cache";
const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

interface CacheEntry {
  data: PlansData;
  timestamp: number;
}

/**
 * Fetches and caches plan data from public/data/plans.json.
 * Cache is stored in localStorage with 5-minute TTL.
 */
export function usePlansCache() {
  const [data, setData] = useState<PlansData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isFromCache, setIsFromCache] = useState(false);
  const [lastFetchedAt, setLastFetchedAt] = useState<number | null>(null);

  useEffect(() => {
    const fetchPlans = async () => {
      try {
        // Check cache first
        const cached = localStorage.getItem(CACHE_KEY);
        if (cached) {
          const entry: CacheEntry = JSON.parse(cached);
          const age = Date.now() - entry.timestamp;

          if (age < CACHE_DURATION) {
            setData(entry.data);
            setIsFromCache(true);
            setLastFetchedAt(entry.timestamp);
            setLoading(false);
            return;
          }
        }

        // Fetch fresh data
        setIsFromCache(false);
        const response = await fetch("/data/plans.json");

        if (!response.ok) {
          throw new Error(`Failed to fetch plans: ${response.statusText}`);
        }

        const plansData: PlansData = await response.json();
        const now = Date.now();

        // Cache it
        localStorage.setItem(CACHE_KEY, JSON.stringify({ data: plansData, timestamp: now }));

        setData(plansData);
        setLastFetchedAt(now);
        setError(null);
      } catch (err) {
        setError(err instanceof Error ? err.message : "Unknown error");
        setData(null);
      } finally {
        setLoading(false);
      }
    };

    fetchPlans();
  }, []);

  return {
    data,
    loading,
    error,
    isFromCache,
    lastFetchedAt,
  };
}

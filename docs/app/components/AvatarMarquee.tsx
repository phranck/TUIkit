"use client";

import { useRef, useEffect, useCallback, useState, useMemo, type ReactNode } from "react";
import HoverPopover from "./HoverPopover";

/** Avatar size in pixels. */
const AVATAR_SIZE = 72;
/** Gap between avatars in pixels. */
const AVATAR_GAP = 24;
/** Base scroll speed in pixels per frame. */
const SCROLL_SPEED = 0.8;
/** Interpolation factor for smooth speed changes (0-1, lower = smoother). */
const SPEED_LERP = 0.06;
/** Fade gradient for edge masks. */
const FADE_GRADIENT = "linear-gradient(to right, transparent 0%, black 15%, black 85%, transparent 100%)";
/** Padding above/below avatars + title line height. */
const VERTICAL_PADDING = 34;

interface AvatarMarqueeProps<T> {
  /** Array of items to display as avatars. */
  items: T[];
  /** Extract avatar URL from item. */
  getAvatarUrl: (item: T) => string;
  /** Extract display label from item (shown in popover). */
  getLabel: (item: T) => string;
  /** Extract profile URL from item (link destination). */
  getProfileUrl: (item: T) => string;
  /** Optional custom popover content renderer. */
  renderPopover?: (item: T) => ReactNode;
  /** Whether the marquee is visible/expanded. */
  open: boolean;
  /** Title displayed in the top border line. */
  title?: string;
  /** Callback when marquee requests to close (e.g., ESC key). */
  onClose?: () => void;
}

interface HoverState<T> {
  item: T;
  x: number;
  y: number;
}

/**
 * A horizontally scrolling marquee of avatars with smooth hover interaction.
 *
 * Features:
 * - Infinite scroll from right to left
 * - Fade-in on right edge, fade-out on left edge
 * - Smooth deceleration on hover, acceleration on leave
 * - Popover with custom content on hover
 */
export default function AvatarMarquee<T>({
  items,
  getAvatarUrl,
  getLabel,
  getProfileUrl,
  renderPopover,
  open,
  title,
  onClose,
}: AvatarMarqueeProps<T>) {
  const containerRef = useRef<HTMLDivElement>(null);
  const trackRef = useRef<HTMLDivElement>(null);
  const wrapperRef = useRef<HTMLDivElement>(null);
  const hideTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Animation state (refs to avoid re-renders)
  const scrollPosRef = useRef(0);
  const speedRef = useRef(1);
  const targetSpeedRef = useRef(1);
  const animationRef = useRef<number | null>(null);
  
  // Drag/swipe state
  const isDraggingRef = useRef(false);
  const dragStartXRef = useRef(0);
  const dragScrollStartRef = useRef(0);
  const hasDraggedRef = useRef(false); // Track if drag exceeded threshold (to prevent click)
  const velocityRef = useRef(0); // Momentum velocity
  const lastDragXRef = useRef(0);
  const lastDragTimeRef = useRef(0);
  const momentumRef = useRef<number | null>(null); // Momentum animation frame

  // Hover state for popover
  const [hover, setHover] = useState<HoverState<T> | null>(null);
  // Track if expand animation is complete (to delay scroll animation)
  const [isExpanded, setIsExpanded] = useState(false);
  // Track if we're in the process of closing (animation stopping)
  const [isClosing, setIsClosing] = useState(false);

  // Memoize duplicated items and widths to avoid recreating on every render
  const duplicatedItems = useMemo(() => [...items, ...items, ...items], [items]);
  const singleSetWidth = useMemo(() => items.length * (AVATAR_SIZE + AVATAR_GAP), [items.length]);

  // Cleanup timeout on unmount
  useEffect(() => {
    return () => {
      if (hideTimeoutRef.current) {
        clearTimeout(hideTimeoutRef.current);
      }
    };
  }, []);

  // Animation loop - only runs when fully expanded
  useEffect(() => {
    if (!isExpanded || items.length === 0) {
      if (animationRef.current) {
        cancelAnimationFrame(animationRef.current);
        animationRef.current = null;
      }
      return;
    }

    const animate = () => {
      // Interpolate speed toward target (smooth brake/accelerate)
      speedRef.current += (targetSpeedRef.current - speedRef.current) * SPEED_LERP;

      // Update scroll position
      scrollPosRef.current += SCROLL_SPEED * speedRef.current;

      // Reset when one full set has scrolled (seamless loop)
      if (scrollPosRef.current >= singleSetWidth) {
        scrollPosRef.current -= singleSetWidth;
      }

      // Apply transform to track
      if (trackRef.current) {
        trackRef.current.style.transform = `translateX(-${scrollPosRef.current}px)`;
      }

      animationRef.current = requestAnimationFrame(animate);
    };

    animationRef.current = requestAnimationFrame(animate);

    return () => {
      if (animationRef.current) {
        cancelAnimationFrame(animationRef.current);
        animationRef.current = null;
      }
    };
  }, [isExpanded, items.length, singleSetWidth]);

  // Height animation for open/close
  useEffect(() => {
    const wrapper = wrapperRef.current;
    const container = containerRef.current;
    if (!wrapper || !container) return;

    if (open && !isClosing) {
      // Measure actual content height
      const contentHeight = container.scrollHeight + 24; // container + title line (~20px) + borders
      wrapper.style.height = `${contentHeight}px`;
      wrapper.style.opacity = "1";
      
      // Wait for transition to complete before starting scroll animation
      const onTransitionEnd = () => {
        wrapper.style.overflow = "visible";
        setIsExpanded(true);
      };
      wrapper.addEventListener("transitionend", onTransitionEnd, { once: true });
      
      return () => wrapper.removeEventListener("transitionend", onTransitionEnd);
    } else if (!open || isClosing) {
      setIsExpanded(false);
      wrapper.style.overflow = "hidden";
      wrapper.style.height = "0px";
      wrapper.style.opacity = "0";
      setIsClosing(false);
    }
  }, [open, isClosing]);

  const handleMouseEnter = useCallback((item: T, event: React.MouseEvent<HTMLAnchorElement>) => {
    // Cancel any pending hide
    if (hideTimeoutRef.current) {
      clearTimeout(hideTimeoutRef.current);
      hideTimeoutRef.current = null;
    }

    const target = event.currentTarget;
    const container = containerRef.current;
    if (!container) return;

    const containerRect = container.getBoundingClientRect();
    const targetRect = target.getBoundingClientRect();
    
    // Calculate position relative to container
    const relativeX = targetRect.left - containerRect.left + targetRect.width / 2;
    const containerWidth = containerRect.width;
    
    // Only hide popover if avatar is completely in the invisible zone (beyond fade edges)
    const edgeMargin = containerWidth * 0.05;
    
    if (relativeX < edgeMargin || relativeX > containerWidth - edgeMargin) {
      return; // Don't show popover at extreme edges
    }

    // Brake auto-scroll only when showing a popover for a visible avatar
    targetSpeedRef.current = 0; // Brake

    setHover({
      item,
      x: relativeX,
      y: targetRect.top - containerRect.top,
    });
  }, []);

  const handleMouseLeave = useCallback((event?: React.MouseEvent) => {
    // If leaving to a child (popover), do nothing here — the popover handlers manage hide.
    if (event) {
      const related = event.relatedTarget as Node | null;
      const popoverRoot = wrapperRef.current?.querySelector('.hover-popover-root') as Node | null;
      if (related && popoverRoot && popoverRoot.contains(related)) {
        return;
      }
    }

    // Delay hiding to allow mouse to reach popover
    hideTimeoutRef.current = setTimeout(() => {
      targetSpeedRef.current = 1; // Accelerate
      setHover(null);
    }, 150);
  }, []);

  const handlePopoverEnter = useCallback(() => {
    // Cancel hide when entering popover
    if (hideTimeoutRef.current) {
      clearTimeout(hideTimeoutRef.current);
      hideTimeoutRef.current = null;
    }
  }, []);

  const handlePopoverLeave = useCallback(() => {
    targetSpeedRef.current = 1; // Accelerate
    setHover(null);
  }, []);

  // Momentum animation for iOS-like deceleration
  const startMomentum = useCallback(() => {
    if (momentumRef.current) {
      cancelAnimationFrame(momentumRef.current);
    }

    const friction = 0.95; // Deceleration factor
    const minVelocity = 0.5; // Stop when velocity is below this

    const animateMomentum = () => {
      velocityRef.current *= friction;

      if (Math.abs(velocityRef.current) < minVelocity) {
        velocityRef.current = 0;
        momentumRef.current = null;
        targetSpeedRef.current = 1; // Resume auto-scroll
        return;
      }

      let newPos = scrollPosRef.current + velocityRef.current;
      
      // Wrap around for seamless loop
      while (newPos < 0) newPos += singleSetWidth;
      while (newPos >= singleSetWidth) newPos -= singleSetWidth;
      
      scrollPosRef.current = newPos;
      
      if (trackRef.current) {
        trackRef.current.style.transform = `translateX(-${scrollPosRef.current}px)`;
      }

      momentumRef.current = requestAnimationFrame(animateMomentum);
    };

    momentumRef.current = requestAnimationFrame(animateMomentum);
  }, [singleSetWidth]);

  // Drag/swipe handlers
  const handleDragStart = useCallback((clientX: number) => {
    // Cancel any ongoing momentum
    if (momentumRef.current) {
      cancelAnimationFrame(momentumRef.current);
      momentumRef.current = null;
    }

    isDraggingRef.current = true;
    hasDraggedRef.current = false;
    dragStartXRef.current = clientX;
    dragScrollStartRef.current = scrollPosRef.current;
    lastDragXRef.current = clientX;
    lastDragTimeRef.current = performance.now();
    velocityRef.current = 0;
    targetSpeedRef.current = 0; // Stop auto-scroll during drag
  }, []);

  const handleDragMove = useCallback((clientX: number) => {
    if (!isDraggingRef.current) return;
    
    const deltaX = dragStartXRef.current - clientX;
    
    // Mark as dragged if moved more than 5px (prevents accidental drag on click)
    if (Math.abs(deltaX) > 5) {
      hasDraggedRef.current = true;
    }
    
    // Calculate velocity for momentum
    const now = performance.now();
    const dt = now - lastDragTimeRef.current;
    if (dt > 0) {
      velocityRef.current = (lastDragXRef.current - clientX) / dt * 16; // Normalize to ~60fps
    }
    lastDragXRef.current = clientX;
    lastDragTimeRef.current = now;
    
    let newPos = dragScrollStartRef.current + deltaX;
    
    // Wrap around for seamless loop
    while (newPos < 0) newPos += singleSetWidth;
    while (newPos >= singleSetWidth) newPos -= singleSetWidth;
    
    scrollPosRef.current = newPos;
    
    if (trackRef.current) {
      trackRef.current.style.transform = `translateX(-${scrollPosRef.current}px)`;
    }
  }, [singleSetWidth]);

  const handleDragEnd = useCallback(() => {
    if (!isDraggingRef.current) return;
    isDraggingRef.current = false;

    // Start momentum if velocity is significant
    if (Math.abs(velocityRef.current) > 1) {
      startMomentum();
    } else {
      targetSpeedRef.current = 1; // Resume auto-scroll
    }
  }, [startMomentum]);

  // Prevent click if dragged
  const handleLinkClick = useCallback((e: React.MouseEvent) => {
    if (hasDraggedRef.current) {
      e.preventDefault();
      e.stopPropagation();
    }
  }, []);

  // Mouse drag handlers
  const onMouseDown = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    handleDragStart(e.clientX);
  }, [handleDragStart]);

  const onMouseMove = useCallback((e: React.MouseEvent) => {
    handleDragMove(e.clientX);
  }, [handleDragMove]);

  const onMouseUp = useCallback(() => {
    handleDragEnd();
  }, [handleDragEnd]);

  // Touch handlers
  const onTouchStart = useCallback((e: React.TouchEvent) => {
    handleDragStart(e.touches[0].clientX);
  }, [handleDragStart]);

  const onTouchMove = useCallback((e: React.TouchEvent) => {
    handleDragMove(e.touches[0].clientX);
  }, [handleDragMove]);

  const onTouchEnd = useCallback(() => {
    handleDragEnd();
  }, [handleDragEnd]);

  if (items.length === 0) return null;

  return (
    <div
      ref={wrapperRef}
      className="relative transition-[height,opacity] duration-300 ease-in-out"
      style={{ height: 0, opacity: 0, overflow: "hidden" }}
    >
      {/* Top border with centered title */}
      <div className="flex items-center gap-4">
        <div
          className="h-px flex-1 bg-border"
          style={{
            maskImage: "linear-gradient(to right, transparent 0%, black 20%)",
            WebkitMaskImage: "linear-gradient(to right, transparent 0%, black 20%)",
          }}
        />
        {title && (
          <span className="text-sm font-medium text-muted">{title}</span>
        )}
        <div
          className="h-px flex-1 bg-border"
          style={{
            maskImage: "linear-gradient(to left, transparent 0%, black 20%)",
            WebkitMaskImage: "linear-gradient(to left, transparent 0%, black 20%)",
          }}
        />
      </div>

      {/* Marquee container with fade masks */}
      <div
        ref={containerRef}
        className="relative cursor-grab overflow-visible py-4 active:cursor-grabbing"
        style={{
          maskImage: FADE_GRADIENT,
          WebkitMaskImage: FADE_GRADIENT,
        }}
        onMouseDown={onMouseDown}
        onMouseMove={onMouseMove}
        onMouseUp={onMouseUp}
        onMouseLeave={onMouseUp}
        onTouchStart={onTouchStart}
        onTouchMove={onTouchMove}
        onTouchEnd={onTouchEnd}
      >
        {/* Scrolling track */}
        <div
          ref={trackRef}
          className="flex items-center"
          style={{ gap: AVATAR_GAP, willChange: "transform" }}
        >
          {duplicatedItems.map((item, index) => (
            <a
              key={`${getLabel(item)}-${index}`}
              href={getProfileUrl(item)}
              target="_blank"
              rel="noopener noreferrer"
              className="group flex-shrink-0"
              onClick={handleLinkClick}
              onMouseEnter={(e) => handleMouseEnter(item, e)}
              onMouseLeave={handleMouseLeave}
            >
              <img
                src={`${getAvatarUrl(item)}&s=128`}
                alt={getLabel(item)}
                width={AVATAR_SIZE}
                height={AVATAR_SIZE}
                className="avatar-tinted rounded-full ring-1 ring-border transition-[ring,box-shadow] duration-200 ease-out group-hover:ring-2 group-hover:ring-accent/60"
                loading="lazy"
              />
            </a>
          ))}
        </div>
      </div>

      {/* Popover - positioned relative to wrapper, outside masked container */}
      <div className="pointer-events-none absolute inset-x-0 top-0" style={{ height: AVATAR_SIZE + VERTICAL_PADDING }}>
        <HoverPopover
          visible={!!hover}
          x={hover?.x ?? 0}
          y={(hover?.y ?? 0) + 16}
          minWidth="140px"
          onMouseEnter={handlePopoverEnter}
          onMouseLeave={handlePopoverLeave}
        >
          {hover && renderPopover ? (
            renderPopover(hover.item)
          ) : (
            <p className="whitespace-nowrap text-center text-sm font-medium text-foreground">
              {hover ? getLabel(hover.item) : ""}
            </p>
          )}
        </HoverPopover>
      </div>

      {/* Bottom border - apply same fade mask */}
      <div
        className="h-px bg-border"
        style={{
          maskImage: FADE_GRADIENT,
          WebkitMaskImage: FADE_GRADIENT,
        }}
      />
    </div>
  );
}

# Plan: Dashboard Redesign - Avatar Marquee

## Preface

A generic `AvatarMarquee` component now displays scrolling avatar lists (stargazers, contributors, etc.) with smooth infinite scroll, fade edges, and hover popovers. The marquee arrow targets the relevant stat card above (Stars, Contributors, etc.). Hover decelerates scroll smoothly; mouseleave accelerates it back. Generic TypeScript props make it reusable for any avatar collection. The Stargazers panel now uses this component, replacing a static grid.

## Completed

**0: AvatarMarquee component implemented with infinite scroll, smooth braking, fade masks, arrow targeting, and popover integration. StargazersPanel migrated.

---

## Checklist

- [x] Reorder StatCards in dashboard
- [x] Unify spacing to mb-8
- [x] Create AvatarMarquee.tsx with generic TypeScript props
- [x] Implement horizontal scroll container
- [x] Add CSS gradient mask for fade effect
- [x] Implement border lines (top with arrow, bottom plain)
- [x] Implement infinite scroll with requestAnimationFrame
- [x] Add speed interpolation for smooth brake/accelerate
- [x] Integrate HoverPopover component
- [x] Update StargazersPanel to use AvatarMarquee
- [x] Test with current stargazers data

---

## Summary

Redesign the dashboard stat cards layout and replace the grid-based StargazersPanel with a horizontally scrolling avatar marquee. The marquee component will be generic and reusable for both Stargazers and Contributors.

---

## Changes

### 1. StatCards Reordering

**Current:**
- Row 1: Commits, Stars, Open PRs, Merged PRs
- Row 2: Branches, Tags, Contributors, Releases

**New:**
- Row 1: Stars, Contributors, Forks, Releases
- Row 2: Commits, Branches, Open PRs, Merged PRs

Additionally: Consistent spacing (mb-8 everywhere instead of mb-5).

### 2. Generic AvatarMarquee Component

A reusable component for displaying avatars in a horizontally scrolling marquee:

```tsx
interface AvatarMarqueeProps<T> {
  items: T[];
  getAvatarUrl: (item: T) => string;
  getLabel: (item: T) => string;
  getProfileUrl: (item: T) => string;
  renderPopover?: (item: T) => ReactNode;
  open: boolean;
  arrowTargetId?: string; // ID of the card the arrow points to
}
```

**Features:**
- Horizontal marquee with avatars scrolling right → left (infinite loop)
- Fade-in on right edge, fade-out on left edge (CSS gradient mask)
- Border lines above and below (consistent with stat cards)
- Top border has an arrow pointing up to the triggering stat card
- Smooth height animation when opening/closing

### 3. Hover Interaction

- **On hover:** Scrolling smoothly decelerates (ease-out brake effect)
- **Popover appears** with custom content via `renderPopover` callback
- **On leave:** Scrolling smoothly accelerates back to normal speed

---

## Workplan

### Phase 1: Layout Changes
- [x] Reorder StatCards in `page.tsx` (Row 1: Stars, Contributors, Forks, Releases)
- [x] Reorder StatCards Row 2 (Commits, Branches, Open PRs, Merged PRs)
- [x] Unify spacing to `mb-8` for all sections
- [x] Add `id` attributes to StatCards for arrow targeting

### Phase 2: AvatarMarquee Component
- [x] Create `AvatarMarquee.tsx` with generic TypeScript props
- [x] Implement horizontal scroll container with `overflow: hidden`
- [x] Add CSS gradient mask for left/right fade effect
- [x] Implement border lines (top with arrow, bottom plain)
- [x] Calculate arrow position dynamically from `arrowTargetId`

### Phase 3: Scroll Animation
- [x] Implement infinite scroll with `requestAnimationFrame`
- [x] Duplicate items to create seamless loop
- [x] Add speed interpolation (current → target) for smooth brake/accelerate
- [x] On hover: target speed = 0, on leave: target speed = 1

### Phase 4: Popover Integration
- [x] Integrate existing `HoverPopover` component
- [x] Calculate popover position relative to scrolling container
- [x] Use `renderPopover` callback for custom content

### Phase 5: Migration
- [x] Update `StargazersPanel.tsx` to use `AvatarMarquee`
- [x] Extract social link popover content to separate component
- [x] Test with current stargazers data

### Phase 6: Future (Contributors)
- [ ] Create `ContributorsPanel.tsx` using same `AvatarMarquee`
- [ ] Add contributor-specific popover content (commits count, etc.)

---

## Technical Details

### Scroll Animation with Smooth Braking

```tsx
const scrollRef = useRef(0);           // Current scroll position
const speedRef = useRef(1);            // Current speed (0-1)
const targetSpeedRef = useRef(1);      // Target speed

useEffect(() => {
  let animationId: number;
  
  const animate = () => {
    // Interpolate speed toward target (smooth brake/accelerate)
    speedRef.current += (targetSpeedRef.current - speedRef.current) * 0.08;
    
    // Update scroll position
    scrollRef.current += SCROLL_SPEED * speedRef.current;
    
    // Reset when one full set has scrolled
    if (scrollRef.current >= totalWidth / 2) {
      scrollRef.current = 0;
    }
    
    // Apply transform
    trackRef.current.style.transform = `translateX(-${scrollRef.current}px)`;
    
    animationId = requestAnimationFrame(animate);
  };
  
  animationId = requestAnimationFrame(animate);
  return () => cancelAnimationFrame(animationId);
}, []);

// Hover handlers
const handleMouseEnter = () => { targetSpeedRef.current = 0; };
const handleMouseLeave = () => { targetSpeedRef.current = 1; };
```

### CSS Fade Mask

```css
.marquee-container {
  mask-image: linear-gradient(
    to right,
    transparent 0%,
    black 8%,
    black 92%,
    transparent 100%
  );
  -webkit-mask-image: linear-gradient(
    to right,
    transparent 0%,
    black 8%,
    black 92%,
    transparent 100%
  );
}
```

### Arrow Element

```
              ╱╲
─────────────╱  ╲─────────────
│  Avatar  │  Avatar  │  Avatar  │ ...
──────────────────────────────────────
```

The arrow is an SVG or CSS triangle positioned absolutely, with its horizontal position calculated from the center of the `arrowTargetId` element.

### Infinite Loop Strategy

Duplicate the items array so there are always enough avatars to fill the screen:

```tsx
const duplicatedItems = [...items, ...items, ...items];
// Render all, scroll continuously, reset position when halfway through
```

---

## Component Usage

```tsx
// For Stargazers:
<AvatarMarquee
  items={stargazers}
  getAvatarUrl={(s) => s.avatarUrl}
  getLabel={(s) => s.login}
  getProfileUrl={(s) => s.profileUrl}
  renderPopover={(s) => <StargazerPopoverContent user={s} />}
  open={showStargazers}
  arrowTargetId="stat-card-stars"
/>

// For Contributors (future):
<AvatarMarquee
  items={contributors}
  getAvatarUrl={(c) => c.avatarUrl}
  getLabel={(c) => c.login}
  getProfileUrl={(c) => c.profileUrl}
  renderPopover={(c) => <ContributorPopoverContent user={c} />}
  open={showContributors}
  arrowTargetId="stat-card-contributors"
/>
```

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `docs/app/components/AvatarMarquee.tsx` | Create (new generic component) |
| `docs/app/components/StargazerPopoverContent.tsx` | Create (extracted from StargazersPanel) |
| `docs/app/components/StargazersPanel.tsx` | Modify (use AvatarMarquee) |
| `docs/app/components/StatCard.tsx` | Modify (add id prop) |
| `docs/app/dashboard/page.tsx` | Modify (reorder cards, add IDs) |

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Performance with many avatars | Virtualization if needed, lazy loading |
| Popover position drift during scroll | Pause scroll on hover before showing popover |
| Arrow position on resize | Recalculate on window resize |
| Mobile touch interaction | Consider touch-friendly alternative (swipe?) |

# Landing Page Assets - Required Images & Media

**Status**: 🚀 Landing page live with real hero image + SVG placeholders for other assets

**Landing Page**: https://docs-tuikit.layered.work/

---

## 📋 Asset Requirements

### 1. Hero Section - Terminal UI Preview
**Location**: Hero Section (above CTA buttons)
**Current Status**: ✅ SVG Placeholder (professional mockup)
**Replacement**: When ready

**Specifications:**
- **Aspect Ratio**: 16:9 (landscape)
- **Recommended Size**: 1000×560px or larger (up to 2000px width for retina)
- **Format**: PNG, JPG, or WebP (lossless recommended)
- **Content**: Screenshot/demo of TUIKit in action
  - Terminal UI showing an interactive application
  - Nice visualization of TUIKit components
  - Colors: Green (#10b981), dark background (#030712)
  - Examples: Menu selection, modal dialogs, text input, etc.

**HTML Location**: `docs/index.html` - Line ~555-591
```html
<div class="hero-video">
    <!-- Replace this SVG with: <img src="images/hero-demo.png" alt="TUIKit Demo"> -->
    <svg>...</svg>
</div>
```

**Placeholder Preview**:
- Terminal window with green border
- Shows TUIKit menu example
- Command: `$ swift run MyApp`
- Interactive menu selection

---

### 2. Advanced Section - Terminal UI Features Screenshot
**Location**: "Built for Developers" section (left side of 2-column layout)
**Current Status**: ✅ SVG Placeholder (advanced demo mockup)
**Replacement**: When ready

**Specifications:**
- **Aspect Ratio**: 16:9 or Square (1:1)
- **Recommended Size**: 600×400px (or 600×600px)
- **Format**: PNG, JPG, or WebP
- **Content**: Professional screenshot of TUIKit features
  - Shows real TUIKit app with actual components
  - Terminal UI showcase with multiple features
  - Examples of: Menu, Button, Text, Panel, Dialog, etc.
  - Color scheme: Green theme with different appearance styles
  - Focus highlights visible
  - Ideally shows: menu navigation, state management, theming

**HTML Location**: `docs/index.html` - Line ~641-685
```html
<div class="advanced-image">
    <!-- Replace this SVG with: <img src="images/advanced-demo.png" alt="Advanced TUIKit Features"> -->
    <svg>...</svg>
</div>
```

**Placeholder Preview**:
- Advanced TUIKit Demo terminal window
- Two feature boxes: "Theme: Green Phosphor" + "Components"
- Live example: Interactive menu with selection

---

### 3. Testimonial Avatars (Optional)
**Location**: Testimonials section (6 testimonial cards)
**Current Status**: ✅ Gradient avatars with initials
**Replacement**: Optional - currently works well with initials

**Specifications:**
- **Size**: 40×40px (can be larger, will scale)
- **Format**: PNG with transparency, or JPG
- **Count**: 6 avatars (for 6 testimonials)
- **Style**: Professional headshots or branded avatars
- **Names**:
  1. Jane Parker (JP) - Lead Developer
  2. Michael Chen (MC) - Software Engineer
  3. Sarah Anderson (SA) - Full Stack Developer
  4. David Kim (DK) - DevOps Engineer
  5. Emma Rodriguez (ER) - CLI Tool Creator
  6. Thomas Gray (TG) - Open Source Maintainer

**HTML Location**: `docs/index.html` - Lines ~721-768
```html
<div class="testimonial-avatar">JP</div>
<!-- Replace with: <img src="images/avatars/jane-parker.jpg" alt="Jane Parker" class="testimonial-avatar"> -->
```

**Current Behavior**: Shows initials on gradient background (looks professional)

---

## 🎨 Current Design Guidelines

**Color Palette:**
- Primary: `#10b981` (Emerald Green)
- Secondary: `#6366f1` (Indigo)
- Accent Light: `#34d399` (Light Green)
- Dark Background: `#030712` (Very Dark Blue)
- Text Light: `#e5e7eb` (Light Gray)
- Text Muted: `#9ca3af` (Medium Gray)

**Typography:**
- Font: Inter (Web Font via Google Fonts)
- Monospace: Monaco, Courier New (for code/terminal)

**Design Style:**
- Modern, dark SaaS landing page
- Terminal/Developer-focused
- Clean, minimal aesthetic
- Gradient accents (green → indigo)

---

## 📦 File Organization

Create image assets in this structure:

```
docs/
├── images/
│   ├── hero-demo.png (1000×560px)
│   ├── advanced-demo.png (600×400px)
│   └── avatars/
│       ├── jane-parker.jpg (40×40px)
│       ├── michael-chen.jpg (40×40px)
│       ├── sarah-anderson.jpg (40×40px)
│       ├── david-kim.jpg (40×40px)
│       ├── emma-rodriguez.jpg (40×40px)
│       └── thomas-gray.jpg (40×40px)
└── index.html
```

**Note**: The `docs/` folder is in `.gitignore`, but images can be committed with `-f` flag if needed.

---

## 🔄 How to Replace Placeholders

### 1. **Hero Section Image**
Find this in `docs/index.html` around line 554:
```html
<div class="hero-video">
    <svg viewBox="0 0 1000 560" ...>...</svg>
</div>
```

Replace with:
```html
<div class="hero-video">
    <img src="images/hero-demo.png" alt="TUIKit Demo Application" style="width: 100%; height: 100%; object-fit: cover; border-radius: 1rem;">
</div>
```

### 2. **Advanced Section Image**
Find this in `docs/index.html` around line 641:
```html
<div class="advanced-image">
    <svg viewBox="0 0 600 400" ...>...</svg>
</div>
```

Replace with:
```html
<div class="advanced-image">
    <img src="images/advanced-demo.png" alt="Advanced TUIKit Features" style="width: 100%; height: 100%; object-fit: cover; border-radius: 1rem;">
</div>
```

### 3. **Testimonial Avatars**
Find testimonials around line 721, replace:
```html
<div class="testimonial-avatar">JP</div>
```

With:
```html
<img src="images/avatars/jane-parker.jpg" alt="Jane Parker" class="testimonial-avatar" style="background: none;">
```

---

## ✨ SVG Placeholders

All current images are high-quality SVG placeholders that:
- ✅ Match the dark theme and color scheme
- ✅ Show relevant TUIKit UI examples
- ✅ Are vector-based (scale perfectly)
- ✅ Look professional on their own
- ✅ Are easy to replace

**You can use the site as-is with placeholders, or swap in real images anytime.**

---

## 📝 Notes

- Placeholders are automatically generated and don't require external files
- Real images should be optimized (compressed, sized appropriately)
- Recommend WebP format for web (with PNG fallback)
- All images should have descriptive alt text for accessibility
- Image paths are relative: `images/` refers to `docs/images/`

**Last Updated**: 2026-01-29
**Landing Page Status**: ✅ Live with SVG Placeholders

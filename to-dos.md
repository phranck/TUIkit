# TUIKit - Tasks & Feature Ideas

## 🚀 In Progress
- [ ] Verify MkDocs deployment on GitHub Pages (https://docs-tuikit.layered.work/)
- [ ] Test all documentation links and functionality

## 📋 Open Tasks

### Documentation
- [ ] Auto-generate Swift API documentation from code comments (consider custom solution since mkdocstrings only supports Python)
- [ ] Create interactive code examples in documentation
- [ ] Add more getting started tutorials
- [ ] Document all 8 themes with examples
- [ ] Add keyboard shortcut reference guide

### Landing Page
- [ ] Decide if landing page should be restored (was removed during documentation pivot)
- [ ] If yes, set up separate landing page (consider static site or separate domain)

### Testing & Validation
- [ ] Verify GitHub Actions workflow runs successfully on next push
- [ ] Test documentation on mobile/tablet
- [ ] Validate all external links (GitHub, etc.)

### Code Examples
- [ ] Create example: Simple counter app
- [ ] Create example: Todo list app
- [ ] Create example: Form with validation
- [ ] Create example: Table/list view
- [ ] Document Spotnik (Spotify player) as main example

## ✅ Completed

### Documentation System (2026-01-29)
- ✅ Replaced DocC with MkDocs after path resolution issues
- ✅ Set up Material theme with dark/light mode
- ✅ Created comprehensive markdown documentation:
  - Home page with quick start
  - Getting started guide with code examples
  - Complete API reference
  - Contributing guidelines
- ✅ Implemented GitHub Actions workflow for auto-deployment
- ✅ Color scheme configured: Emerald (primary), Indigo (accent)

### Git Cleanup (2026-01-29)
- ✅ Removed `.claude/` folder from entire Git history
- ✅ Added `.claude/` to .gitignore
- ✅ Kept `.claude/` folder locally

### Infrastructure
- ✅ README.md updated with Spotnik screenshot
- ✅ GitHub Pages configured with custom domain

## 🔍 Notes

### Why MkDocs (not DocC)
- DocC had complex path problems (`/js/`, `/css/` not loading)
- Missing `theme-settings.json` required by Vue.js frontend
- Too many hidden dependencies
- MkDocs is simpler, more reliable, easier to maintain

### Why not Jazzy
- Ruby version too old (2.6 installed, 3.0+ required)
- Would need to upgrade Ruby

### Why not SourceDocs
- Had issues parsing Swift package correctly
- More complex setup than needed

---

**Last Updated:** 2026-01-29

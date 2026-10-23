# Investment Tracker - Project Instructions & Guidelines

> **Notice to any AI Agent working on this project**: Read this file and `ARCHITECTURE.md` before making modifications. Follow all instructions strictly to maintain efficiency, keep token usage minimal, and prevent clutter.

---

## 1. Project Overview & Target Platform
- **Project Name:** Investment Tracker (`investment_tracker`)
- **Type:** Mobile App built with Flutter.
- **Current Target/Preview:** Windows desktop (`flutter run -d windows`) used for rapid desktop virtualization and fast UI iteration during development, but designed solely with **mobile viewport, mobile UX, and mobile navigation** in mind.
- **Primary Modules:**
  1. **Investments:** Tracking personal portfolios, assets, holdings, purchase history, cost basis, and current asset values.
  2. **Analytics:** Visualizing portfolio performance, asset allocation, returns/P&L charts, and metrics.

---

## 2. Mandatory Agent Rules & Instructions

### Rule 1: Zero Dead / Unused Code Policy (Strict Cleanup)
- Whenever modifying, refactoring, or removing features, **all unrelated, superseded, or dead code must be deleted immediately**.
- Never leave behind orphaned classes, unused helper functions, commented-out dead code blocks, or unused imports.
- Keep widgets concise, reusable, and focused. Avoid duplicate widgets where a single parameterized widget suffices.

### Rule 2: Token-Efficient Context Discovery
- **Do not read the entire project or scan all files repeatedly.**
- Refer directly to [`ARCHITECTURE.md`](ARCHITECTURE.md) to locate the exact file/module needed for your task before opening files.
- Use targeted searches and line ranges rather than reading full directories.

### Rule 3: Quality & Code Health
- Always run static verification or ensure compatibility with `flutter analyze`.
- Keep code clean with modern Flutter practices (e.g. use `.withValues(alpha: ...)` instead of deprecated `.withOpacity()`, use `initialValue` for form fields, avoid unnecessary underscores).

### Rule 4: Visuals & Design Standards
- Consistent modern Dark Theme (`#0F172A` background, `#1E293B` cards/surface, `#10B981` primary emerald accent).
- Responsive mobile layout using bottom navigation bars, clear app bars, and high contrast typography.

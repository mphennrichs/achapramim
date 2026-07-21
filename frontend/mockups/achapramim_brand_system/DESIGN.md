---
name: Achapramim Brand System
colors:
  surface: '#031427'
  surface-dim: '#031427'
  surface-bright: '#2a3a4f'
  surface-container-lowest: '#000f21'
  surface-container-low: '#0b1c30'
  surface-container: '#102034'
  surface-container-high: '#1b2b3f'
  surface-container-highest: '#26364a'
  on-surface: '#d3e4fe'
  on-surface-variant: '#d4c5ab'
  inverse-surface: '#d3e4fe'
  inverse-on-surface: '#213145'
  outline: '#9c8f78'
  outline-variant: '#4f4632'
  surface-tint: '#fabd00'
  primary: '#ffe4af'
  on-primary: '#3f2e00'
  primary-container: '#ffc107'
  on-primary-container: '#6d5100'
  inverse-primary: '#785900'
  secondary: '#bec6e0'
  on-secondary: '#283044'
  secondary-container: '#3f465c'
  on-secondary-container: '#adb4ce'
  tertiary: '#dce7ff'
  on-tertiary: '#263143'
  tertiary-container: '#c0cbe3'
  on-tertiary-container: '#4b566a'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdf9e'
  primary-fixed-dim: '#fabd00'
  on-primary-fixed: '#261a00'
  on-primary-fixed-variant: '#5b4300'
  secondary-fixed: '#dae2fd'
  secondary-fixed-dim: '#bec6e0'
  on-secondary-fixed: '#131b2e'
  on-secondary-fixed-variant: '#3f465c'
  tertiary-fixed: '#d8e3fb'
  tertiary-fixed-dim: '#bcc7de'
  on-tertiary-fixed: '#111c2d'
  on-tertiary-fixed-variant: '#3c475a'
  background: '#031427'
  on-background: '#d3e4fe'
  surface-variant: '#26364a'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  data-mono:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: -0.01em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  xs: 0.25rem
  sm: 0.5rem
  md: 1rem
  lg: 1.5rem
  xl: 2.5rem
  admin-gutter: 0.75rem
  user-margin: 2rem
---

## Brand & Style
The design system is engineered for high-performance marketplace monitoring, balancing rapid data consumption with professional reliability. The brand personality is authoritative, vigilant, and analytical. 

The aesthetic follows a **Modern Corporate** direction with a focus on high-density information architecture. It prioritizes clarity and speed, utilizing a structured layout that minimizes visual noise while highlighting critical data points. The interface transitions seamlessly between a rigorous, utility-driven Admin experience and a clean, results-oriented User dashboard.

Key characteristics include:
- **High Information Density:** Optimized for complex data tables and multi-pane monitoring.
- **Precision:** Mathematical alignment and consistent scaling to ensure trust in the data presented.
- **Vigilance:** Using the primary golden yellow as a beacon for attention against a sober, high-contrast background.

## Colors
The palette is anchored by a vibrant **Golden Yellow (#FFC107)**, used strategically for primary actions, active states, and critical alerts. This is grounded by a deep **Slate/Navy** foundation to provide maximum contrast and reduce eye strain during long monitoring sessions.

### Color Strategy
- **Primary:** Golden Yellow is the high-visibility driver. Use it for primary buttons, selection indicators, and brand-defining accents.
- **Backgrounds:** Dark mode uses a deep slate (#0F172A) for base layers, with #1E293B for elevated cards/containers. Light mode utilizes #F8FAFC for backgrounds.
- **Semantic Feedback:** 
    - **Success (#10B981):** Confirmed marketplace syncs or positive price movements.
    - **Error (#EF4444):** API failures, listing violations, or critical drops.
    - **Warning (#F59E0B):** Low stock or pending reviews.
    - **Info (#3B82F6):** General system notifications and tooltips.

## Typography
This design system utilizes **Inter** for its exceptional legibility in data-heavy environments. The typeface is systematic and utilitarian, ensuring that numerical data remains readable at small sizes.

- **Weight Usage:** Use `600` (Semi-bold) for headers and interactive labels. Use `400` (Regular) for standard body text and metadata.
- **Data Display:** For table cells and price monitoring, use the `data-mono` role to ensure alignment and rapid scanning.
- **Hierarchy:** Maintain a clear distinction between administrative labels (Caps) and user-facing content (Standard) to help users navigate complex dashboards.

## Layout & Spacing
The layout philosophy employs a **Fluid Grid** for the monitoring engine and a **Fixed Grid** (max 1440px) for general user settings and landing pages.

### Density Models
- **Admin Density:** Uses a 12-column grid with a narrow **12px gutter** to maximize screen real estate. Spacing between table rows is minimized to 8px to allow for high-volume data visualization.
- **User Dashboard:** Switches to a broader 12-column grid with **24px gutters**, emphasizing card-based layouts and comfortable vertical rhythm for readability.

### Adaptive Behavior
- **Desktop:** Sidebar-driven navigation (fixed 260px) with a fluid content area.
- **Tablet:** Sidebar collapses into a compact icon-only rail or drawer.
- **Mobile:** Single column layout with 16px horizontal safe-margins.

## Elevation & Depth
In this design system, depth is communicated through **Tonal Layering** and **Low-Contrast Outlines** rather than heavy shadows, ensuring the interface remains lightweight and performance-oriented.

- **Surface Levels:** 
    - `Level 0 (Base)`: Background layer (#0F172A).
    - `Level 1 (Card)`: Primary container layer (#1E293B) with a subtle 1px border (#334155).
    - `Level 2 (Dropdown/Modal)`: Elevated surface (#1E293B) with a soft, 10% opacity black shadow and a slightly lighter border to simulate lift.
- **Contrast Strategy:** Elements are separated by color variance (Slate 800 vs Slate 900) rather than physical metaphors, maintaining a flat, modern aesthetic suitable for professional monitoring.

## Shapes
The shape language is **Soft (0.25rem)**. This subtle rounding provides a modern touch without sacrificing the professional, "engineered" feel of a data tool.

- **Components (Buttons, Inputs):** 4px (0.25rem) radius.
- **Containers (Cards, Modals):** 8px (0.5rem) radius for `rounded-lg`.
- **Status Pills:** 9999px (Pill-shaped) to distinguish status indicators from interactive buttons.

## Components
Consistent implementation of these components ensures the efficiency of the monitoring workflow.

- **Buttons:** Primary buttons use the Golden Yellow background with Slate-950 text. Ghost buttons use a subtle Slate-700 border. High-density Admin buttons use `sm` padding (4px 8px).
- **Data Tables (Admin):** No cell padding on the left/right of the first/last columns. Header rows are Slate-800 with `label-caps` typography. Alternating row colors (zebra striping) are encouraged for visibility.
- **Cards (User):** White (Light Mode) or Slate-800 (Dark Mode) backgrounds. Include a subtle 1px top-border in Golden Yellow for "Featured" or "Active" monitoring cards.
- **Input Fields:** Default state is a Slate-700 border. Focus state uses a 2px Golden Yellow ring. Labels are always positioned above the input for clarity.
- **Chips/Status:** Use the semantic colors with 10% opacity backgrounds and 100% opacity text of the same hue (e.g., Success text on a light green background).
- **KPI Widgets:** Large numerical displays using `headline-lg` with a secondary `label-caps` description underneath.
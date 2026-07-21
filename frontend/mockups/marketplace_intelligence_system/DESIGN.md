---
name: Marketplace Intelligence System
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#424656'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#727687'
  outline-variant: '#c2c6d8'
  surface-tint: '#0054d6'
  primary: '#0050cb'
  on-primary: '#ffffff'
  primary-container: '#0066ff'
  on-primary-container: '#f8f7ff'
  inverse-primary: '#b3c5ff'
  secondary: '#8c5000'
  on-secondary: '#ffffff'
  secondary-container: '#fe9400'
  on-secondary-container: '#633700'
  tertiary: '#00673e'
  on-tertiary: '#ffffff'
  tertiary-container: '#008350'
  on-tertiary-container: '#e5ffea'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dae1ff'
  primary-fixed-dim: '#b3c5ff'
  on-primary-fixed: '#001849'
  on-primary-fixed-variant: '#003fa4'
  secondary-fixed: '#ffdcbf'
  secondary-fixed-dim: '#ffb874'
  on-secondary-fixed: '#2d1600'
  on-secondary-fixed-variant: '#6a3b00'
  tertiary-fixed: '#67fdaf'
  tertiary-fixed-dim: '#44e094'
  on-tertiary-fixed: '#002111'
  on-tertiary-fixed-variant: '#005230'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
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
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
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
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.05em
  data-mono:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 40px
  container-max: 1280px
  gutter: 16px
---

## Brand & Style
The design system is built for "Acha Pra Mim," a high-performance marketplace monitoring tool. The brand personality is **authoritative, efficient, and vigilant**. It positions itself as an indispensable tool for power users who need to process vast amounts of pricing data quickly.

The visual style is **Industrial Minimalism**. It prioritizes information density and clarity over decorative elements. By utilizing a systematic approach to whitespace and hierarchy, the UI reduces cognitive load, allowing users to identify "hot deals" and price anomalies instantly. The aesthetic is clean and professional, evoking the reliability of a financial terminal while maintaining the accessibility of a modern SaaS platform.

## Colors
The palette is engineered for functional signaling:
- **Primary (Modern Blue):** Used for primary actions, active states, and brand presence. It represents stability and professional intent.
- **Secondary (Alert Orange):** Reserved strictly for "Hot Deals," urgent price drops, and high-priority notifications. Its high-energy vibration ensures it breaks through the blue/gray interface.
- **Success (Tertiary Green):** Used for positive price trends and "Best Match" classification scores.
- **Neutrals:** A sophisticated range of cool grays. Use `#F8FAFC` for backgrounds and `#1E293B` for primary text to ensure maximum readability and reduced eye strain during long monitoring sessions.

## Typography
**Inter** is the workhorse of the design system, chosen for its exceptional legibility in data-heavy contexts. For numeric data, price points, and SKU identifiers, **JetBrains Mono** is introduced to provide a technical, "scannable" feel that prevents character confusion.

Type scales are tight to allow for high data density. Headlines use slight negative letter-spacing to appear more cohesive, while labels use uppercase tracking to differentiate them from body copy.

## Layout & Spacing
This design system utilizes a **4px baseline grid** with a **12-column fluid grid** for desktop. 

- **Desktop (1280px+):** 12 columns, 24px margins, 16px gutters.
- **Tablet (768px - 1279px):** 8 columns, 16px margins, 16px gutters.
- **Mobile (Up to 767px):** 4 columns, 16px margins, 12px gutters.

The layout philosophy is "Top-Down Efficiency." Navigation is pinned to the left to maximize vertical scanning area for marketplace results. Use `md` (16px) spacing for internal card padding and `lg` (24px) for section separation.

## Elevation & Depth
Elevation is achieved through **Tonal Layering** rather than heavy shadows. This keeps the interface feeling "flat" and performant.

1.  **Level 0 (Background):** `#F8FAFC` - The canvas.
2.  **Level 1 (Cards/Surface):** `#FFFFFF` - With a subtle 1px border in `#E2E8F0`. 
3.  **Level 2 (Interactive/Hover):** A soft, ultra-diffused shadow (`0 4px 12px rgba(0,0,0,0.05)`) to indicate pick-up.
4.  **Level 3 (Modals/Overlays):** A crisp border and a medium shadow to separate query configuration tools from the data stream.

## Shapes
The design system uses **Soft (0.25rem)** roundedness to maintain a professional, systematic edge. 

- **Small Components (Buttons, Inputs):** 4px (0.25rem) radius.
- **Containers (Cards, Modals):** 8px (0.5rem) radius.
- **Data Badges:** 2px radius or sharp to emphasize the "technical" nature of the data scores.

Avoid fully rounded "pill" shapes except for status indicators to prevent the UI from looking too casual or consumer-oriented.

## Components

### Offer Cards
Cards are the primary data vehicle. They must feature a rigid internal grid:
- **Header:** Title (Title-MD) and Source Icon.
- **Body:** Price (Data-Mono, Primary Color) and Price Change indicator.
- **Footer:** Match Score Badge and Timestamp.
- **Border:** 1px `#E2E8F0`. On "Hot Deals," the border becomes 2px `Secondary Color`.

### Form Inputs
Configuration fields for monitoring must be highly structured. Labels are always visible (Label-Caps). Use a focus state with a 2px Primary Blue outline. Error states use a high-contrast red without changing the layout height to prevent "jitter."

### Badges & Classification
Classification scores (e.g., "98% Match") use a small, high-contrast badge format. 
- **High Match:** Green background / White text.
- **Low Match:** Light Gray background / Dark text.
- **Alert:** Secondary Orange background / White text.

### Buttons
- **Primary:** Solid Blue, White Text. No gradients.
- **Secondary:** White Background, Blue 1px Border.
- **Tertiary (Ghost):** Blue Text, no background. Used for secondary dashboard actions.

### Data Tables
For bulk monitoring, use condensed rows (32px height) with zebra-striping (`#F8FAFC`). Columns containing currency must be right-aligned using `Data-Mono`.
---
name: Modern Industrial Light
colors:
  surface: '#f7f9fb'
  surface-dim: '#d8dadc'
  surface-bright: '#f7f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f6'
  surface-container: '#eceef0'
  surface-container-high: '#e6e8ea'
  surface-container-highest: '#e0e3e5'
  on-surface: '#191c1e'
  on-surface-variant: '#4f4632'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f3'
  outline: '#827660'
  outline-variant: '#d4c5ab'
  surface-tint: '#785900'
  primary: '#785900'
  on-primary: '#ffffff'
  primary-container: '#ffc107'
  on-primary-container: '#6d5100'
  inverse-primary: '#fabd00'
  secondary: '#545f73'
  on-secondary: '#ffffff'
  secondary-container: '#d5e0f8'
  on-secondary-container: '#586377'
  tertiary: '#595f66'
  on-tertiary: '#ffffff'
  tertiary-container: '#c5cbd3'
  on-tertiary-container: '#4f565c'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdf9e'
  primary-fixed-dim: '#fabd00'
  on-primary-fixed: '#261a00'
  on-primary-fixed-variant: '#5b4300'
  secondary-fixed: '#d8e3fb'
  secondary-fixed-dim: '#bcc7de'
  on-secondary-fixed: '#111c2d'
  on-secondary-fixed-variant: '#3c475a'
  tertiary-fixed: '#dde3eb'
  tertiary-fixed-dim: '#c1c7cf'
  on-tertiary-fixed: '#161c22'
  on-tertiary-fixed-variant: '#41474e'
  background: '#f7f9fb'
  on-background: '#191c1e'
  surface-variant: '#e0e3e5'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
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
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  button:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 40px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 64px
---

## Brand & Style

The design system is a high-clarity, utility-driven framework that balances industrial energy with corporate precision. It targets professional environments where efficiency and rapid information processing are paramount. By transitioning to a light-mode foundation, the system emphasizes cleanliness, airiness, and an approachable "white-label" feel while retaining its signature yellow accents.

The design style is a hybrid of **Minimalism** and **Modern Corporate**. It utilizes heavy whitespace to reduce cognitive load and sharp, systematic layouts to convey reliability. The emotional response is one of organized energy—feeling both productive and optimistic.

## Colors

The palette is anchored by the primary yellow (#FFC107), which serves exclusively as an action color or high-priority signal. To ensure accessibility in light mode, this yellow is paired with dark slate ink for high-contrast text.

- **Primary:** Vibrant Yellow (#FFC107). Used for primary buttons, active states, and critical highlights.
- **Secondary:** Slate Deep (#1E293B). Used for primary typography, icons, and heavy-weight strokes to provide grounding.
- **Tertiary:** Cool Fog (#E2E8F0). Used for borders, dividers, and secondary button backgrounds.
- **Surface/Background:** The background is a clean White (#FFFFFF), while containers use "Ice" (#F8FAFC) to create subtle structural differentiation.
- **Success/Error:** Systematic green and red are utilized sparingly, maintaining the high-saturation characteristic of the primary palette.

## Typography

This design system uses **Inter** exclusively to leverage its systematic, utilitarian nature. The hierarchy is built on tight leading and slight negative letter-spacing for headlines to mimic an editorial, high-impact aesthetic. 

Body text uses standard tracking for maximum legibility. Label styles are set in uppercase with increased letter spacing to provide a clear distinction from body content in data-heavy views. All text colors must adhere to a minimum 4.5:1 contrast ratio against their respective backgrounds, primarily using the Secondary Slate color for text.

## Layout & Spacing

The layout philosophy follows a **Fluid Grid** model based on an 8px square-grid system. 

- **Desktop:** 12-column grid with 24px gutters and 64px side margins. 
- **Tablet:** 8-column grid with 24px gutters and 32px side margins.
- **Mobile:** 4-column grid with 16px gutters and 16px side margins.

Horizontal spacing is used to group related elements, while vertical "air" (xl spacing) is used to separate distinct content sections. Use strict alignment to the grid to maintain the industrial, structured feel of the design system.

## Elevation & Depth

In this light-mode iteration, depth is conveyed through **Tonal Layers** and **Low-contrast outlines** rather than heavy shadows.

- **Level 0 (Background):** Pure White (#FFFFFF).
- **Level 1 (Cards/Containers):** Ice (#F8FAFC) with a 1px border of Cool Fog (#E2E8F0).
- **Level 2 (Dropdowns/Modals):** Pure White with a very soft, diffused ambient shadow (8% opacity Slate) and a 1px border.

Shadows should never be "black." They must be tinted with the secondary slate color to keep the UI looking clean and integrated. Surface transitions are immediate or use very fast (150ms) linear fades to maintain a "snappy" feel.

## Shapes

The shape language is defined by **Rounded** geometry (0.5rem base). This specific level of roundedness (ROUND_FOUR) strikes a balance between the friendliness of a consumer app and the precision of an enterprise tool.

- **Standard Elements:** 0.5rem (Buttons, Input fields).
- **Large Containers:** 1rem (Cards, Modals).
- **Extra Large:** 1.5rem (Hero sections, Floating Action Buttons).

## Components

- **Buttons:** Primary buttons use the #FFC107 background with #1E293B text for maximum impact. Secondary buttons use a #E2E8F0 background. All buttons have a height of 40px or 48px.
- **Input Fields:** Use a 1px #E2E8F0 border with a 0.5rem corner radius. Focus states should switch the border to #FFC107 with a subtle 2px outer glow.
- **Cards:** Cards should be flat with a 1px border. Avoid shadows unless the card is draggable or floating.
- **Chips:** Small, highly rounded (pill-shaped) elements with a #F1F5F9 background and #475569 text.
- **Lists:** Clean rows with 1px horizontal dividers. Use the primary yellow for active list-item indicators (a 4px vertical bar on the left edge).
- **Checkboxes/Radios:** When selected, these should be solid #FFC107 with a dark checkmark/dot to maintain the industrial theme.
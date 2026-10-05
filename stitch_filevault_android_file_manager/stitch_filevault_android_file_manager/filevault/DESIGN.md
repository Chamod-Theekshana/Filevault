---
name: FileVault
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
  on-surface-variant: '#40484e'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#70787f'
  outline-variant: '#bfc7cf'
  surface-tint: '#00658e'
  primary: '#005578'
  on-primary: '#ffffff'
  primary-container: '#0b6e99'
  on-primary-container: '#cfeaff'
  inverse-primary: '#84cfff'
  secondary: '#835400'
  on-secondary: '#ffffff'
  secondary-container: '#fdb244'
  on-secondary-container: '#6e4600'
  tertiary: '#0045b9'
  on-tertiary: '#ffffff'
  tertiary-container: '#185ce4'
  on-tertiary-container: '#e0e5ff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#c7e7ff'
  primary-fixed-dim: '#84cfff'
  on-primary-fixed: '#001e2e'
  on-primary-fixed-variant: '#004c6c'
  secondary-fixed: '#ffddb5'
  secondary-fixed-dim: '#ffb956'
  on-secondary-fixed: '#2a1800'
  on-secondary-fixed-variant: '#633f00'
  tertiary-fixed: '#dbe1ff'
  tertiary-fixed-dim: '#b4c5ff'
  on-tertiary-fixed: '#00174b'
  on-tertiary-fixed-variant: '#003ea8'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  headline-lg:
    fontFamily: Roboto Flex
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Roboto Flex
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Roboto Flex
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.04em
  code-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style
The design system embodies a modern, technical, yet hyper-accessible mobile utility aesthetic tailored for high-frequency Android storage management. Blending the surgical precision of archival power-tools with the fluid, friendly ergonomics of modern Material You paradigms, it prioritizes immediate visual triage, structural trust, and low-latency interaction feedback. 

Visual density is tuned for speed: clear spatial separation, crisp edge boundaries, and distinct file-signature identities allow users to distinguish directory paths and content categories instantaneously. Micro-surfaces rely on gentle tonal shifts rather than heavy shadows to preserve performance and clarity on high-density mobile screens. The emotional resonance is dependable, secure, and effortlessly organized.

## Colors
The color palette uses deliberate functional zoning anchored by a deep teal-blue primary core (#0B6E99), balanced by a warm functional amber (#F2A93B) for highlights, pending operations, and storage-alert actions. Backgrounds reside on a crisp, cool paper base (#F8FAFB), paired with pure white surfaces (#FFFFFF) for active cards and low-contrast grey-teal (#EEF2F5) for container wells and inactive chips.

Semantic file categories possess high-contrast, dedicated color-coding to bypass language barriers and expedite rapid scanning:
- **Images**: Violet `#7C3AED`
- **Videos**: Crimson `#E11D48`
- **Audio**: Bright Amber-Orange `#EA580C`
- **Documents**: Royal Blue `#2563EB`
- **Downloads & Folders**: Deep Teal `#0B6E99`
- **APKs & Installers**: Forest Emerald `#16A34A`
- **Archives & Compressed Files**: Dark Gold `#CA8A04`
- **System, Logs & Trash**: Cool Slate `#64748B`
- **Destructive/Error Actions**: Crimson Oxide `#BA1A1A`

Category colors must always be rendered with matching low-saturation container fills (at 10-12% opacity) when used as badge or tile backdrops to maintain AA accessibility compliance for text and icons.

## Typography
Typographic scale utilizes structural weight rather than extreme size shifts to differentiate file types, sizes, and path segments. Roboto Flex delivers punchy, mechanical authority across structural screens, headers, and section groupings, while Inter ensures distortion-free legibility across file paths, Unix timestamps, and byte counts.

Numerical metadata (sizes, dates, item counts) always leverages tabular figure alignment where supported to ensure list entries align perfectly across vertical scanning axes. All file extensions (`.zip`, `.apk`, `.tar.gz`) use medium weight to isolate format identity from standard title naming.

## Layout & Spacing
Designed explicitly around hand ergonomics on mobile portrait viewpoints (360dp - 440dp width). The layout uses a strict 4-column layout on standard phones with 16dp margins and 16dp gutters. All primary action anchors reside in the lower two-thirds of the viewport to accommodate one-handed operation.

Touch targets are enforced at a strict minimum boundary of 48dp × 48dp, even when visual asset representations (such as action overflow dots or compact sort buttons) measure smaller. Grid modes for file browsing adapt from a 2-column card view on standard portrait widths to a 4-column matrix on foldables and tablets. List rows maintain a consistent vertical baseline height of 64dp to accommodate secondary metadata rows without visual clipping.

## Elevation & Depth
Elevation is constructed via Material Design 3 surface tinting and soft tonal layers, avoiding high-contrast drop shadows that clutter dense utility tools. Visual hierarchy is achieved across four core tiers:

1. **Base (0dp)**: Background `#F8FAFB` for inactive canvas areas and underlying scroll views.
2. **Surface Low (1dp)**: Storage breakdown cards and grouped lists use `#FFFFFF` bordered by a 1dp crisp boundary in `#EEF2F5`.
3. **Surface High (3dp)**: Floating App Bars, Action Sheets, and Navigation Bars utilize `#FFFFFF` backed by an ultra-diffused, ambient drop-shadow: `0 4px 20px -2px rgba(11, 110, 153, 0.08)`.
4. **Modal / FAB (6dp)**: The primary Floating Action Button (New Archive / Add Folder) uses primary `#0B6E99` accompanied by a directional lift shadow: `0 8px 16px -4px rgba(11, 110, 153, 0.24)`.

Separators across directory trees avoid solid dark lines; instead, they utilize subtle `#EEF2F5` full-bleed divider rules or 8dp whitespace offsets between card groups.

## Shapes
Shapes express a smooth, rounded physical metaphor calibrated for utility widgets and mobile interactions. Major container cards and storage metrics panels feature an explicit 16dp radius (`rounded-2xl` equivalent in mobile design tokens), conveying safe physical enclosures for critical files. 

Interactive chips and filter bars utilize full pill radii for clear affordance against rectangular file cells. Contextual menus, bottom sheets, and selection sheets apply asymmetric rounding: top edges terminate at 24dp radii to clearly communicate modal presence rising from the system shell, while interior file thumbnail previews maintain a conservative 8dp radius to preserve aspect ratio fidelity.

## Components

### Action Buttons & Floating Action Buttons
- **Primary Buttons**: Filled `#0B6E99` with white bold typography, 48dp height, 16dp corner radius. Ripple effects use an overlaid white flash at 12% alpha.
- **Floating Action Button (FAB)**: 56dp × 56dp square-rounded surface with a 16dp corner radius, centered or right-aligned 16dp from screen edges, sporting clear monochromatic iconography.

### Filter & Category Chips
- Pill-shaped (height: 36dp), minimum horizontal padding of 12dp.
- Inactive state: `#EEF2F5` background, text in `#64748B`, zero border.
- Selected state: Primary tint `#0B6E99` at 12% background with a 1.5dp `#0B6E99` perimeter outline and high-contrast text.

### File List Items & Grid Cards
- **List Item**: 64dp fixed height. Left-hand side anchored by a 44dp category tile (low-opacity category background with dynamic category icon). Center content stacks file title (14sp Inter Semi-Bold, single-line truncated) over date and size (12sp Inter Regular in `#64748B`). Right edge features a 48dp touch footprint for the contextual menu trigger.
- **Grid Tile**: 16dp rounded card, white fill, 1dp `#EEF2F5` outline. High-density preview quadrant at the top, bottom anchored with a two-line text wrapper and multi-select indicator.

### Input Fields & Search Bars
- Search inputs use an integrated "docked search" capsule: 48dp height, full pill radius, filled with `#EEF2F5`, using 16dp inset icons. Active focus shifts the surface to `#FFFFFF` with a 1.5dp `#0B6E99` stroke.

### Checkboxes & Multi-Select Bars
- Multi-selection activates a contextual action bar replacing the app bar in deep teal (`#0B6E99`), changing system status colors. Checkbox nodes feature circular indicators with an animated scale transition and amber `#F2A93B` active tick marks for immediate selected-state verification.

### Storage Usage Meter
- Multi-segment linear progress bar (12dp track height, rounded-full caps) displaying color-matched slices mirroring the category palette (Images, Videos, Archives, System). Accompanied by analytical byte counts rendered in tabular digits.
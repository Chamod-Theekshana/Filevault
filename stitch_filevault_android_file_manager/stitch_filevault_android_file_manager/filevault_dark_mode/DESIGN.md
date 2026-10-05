---
name: FileVault Dark Mode
colors:
  surface: '#101418'
  surface-dim: '#101418'
  surface-bright: '#363a40'
  surface-container-lowest: '#0b0f12'
  surface-container-low: '#191d21'
  surface-container: '#1d2126'
  surface-container-high: '#282c31'
  surface-container-highest: '#33373c'
  on-surface: '#e1e2e8'
  on-surface-variant: '#c4c6cf'
  inverse-surface: '#e0e3e8'
  inverse-on-surface: '#2d3135'
  outline: '#8e9099'
  outline-variant: '#43474e'
  surface-tint: '#7bd0ff'
  primary: '#8ed5ff'
  on-primary: '#00354a'
  primary-container: '#004c6c'
  on-primary-container: '#c7e7ff'
  inverse-primary: '#00658e'
  secondary: '#ffb956'
  on-secondary: '#462b00'
  secondary-container: '#9e6600'
  on-secondary-container: '#fff7f1'
  tertiary: '#bccbff'
  on-tertiary: '#1c2e5e'
  tertiary-container: '#9eafe8'
  on-tertiary-container: '#304173'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#c4e7ff'
  primary-fixed-dim: '#7bd0ff'
  on-primary-fixed: '#001e2c'
  on-primary-fixed-variant: '#004c69'
  secondary-fixed: '#ffddb5'
  secondary-fixed-dim: '#ffb956'
  on-secondary-fixed: '#2a1800'
  on-secondary-fixed-variant: '#643f00'
  tertiary-fixed: '#dbe1ff'
  tertiary-fixed-dim: '#b4c5ff'
  on-tertiary-fixed: '#021848'
  on-tertiary-fixed-variant: '#334576'
  background: '#101418'
  on-background: '#e0e3e8'
  surface-variant: '#31353a'
  category-images: '#a78bfa'
  category-videos: '#fb7185'
  category-audio: '#fb923c'
  category-documents: '#60a5fa'
  category-downloads: '#38bdf8'
  category-installers: '#4ade80'
  category-archives: '#facc15'
  category-system: '#94a3b8'
  category-destructive: '#f87171'
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
    letterSpacing: 0em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0em
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.01em
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
    letterSpacing: 0em
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

This design system translates a technical, high-frequency Android storage management environment into an OLED-optimized, deep dark mode. It bridges utilitarian system architecture with fluid Material Design 3 ergonomics, engineered specifically for prolonged nocturnal usage, low eye strain, and hyper-legible file triage.

The aesthetic fuses deep tactical slate surfaces with high-energy luminous cyan/teal accents. It communicates absolute security, surgical precision, and immediate structural hierarchy. Information density remains compact and rapid: content layers sit on differentiated tonal surface tiers rather than harsh contrast dividers or heavy cast shadows, preserving visual calm while keeping metadata instantly scannable.

## Colors

The dark mode palette replaces blinding light paper backdrops with deep carbon hues, anchoring system canvas at `#101418` with stepped surface containers extending from `#191d21` up to `#33373c`.

Primary interactions leverage an amplified, luminous sky-teal (`#38bdf8`) paired with an inverted container (`#004c6c`), satisfying WCAG AAA contrast against dark backgrounds. Functional amber (`#ffb956`) provides high-visibility storage warnings, active operations, and selected tick indicators.

Semantic category signatures are calibrated to 400-level lightness tones to avoid ocular vibrations against dark surfaces:
- **Images**: Soft Violet `#a78bfa`
- **Videos**: Neon Rose `#fb7185`
- **Audio**: Vivid Amber `#fb923c`
- **Documents**: Sky Blue `#60a5fa`
- **Downloads & System Folders**: Electric Teal `#38bdf8`
- **APKs & Installers**: Mint Emerald `#4ade80`
- **Archives & Compressed Files**: Solar Yellow `#facc15`
- **System, Logs & Trash**: Muted Slate `#94a3b8`
- **Destructive / Error**: Crimson `#f87171`

All category badges and tile backdrops render these hues with low-saturation container fills (at 12–16% alpha) against dark containers to maintain effortless legibility for overlaid white and tinted glyphs.

## Typography

Typography prioritizes fast vertical scanning and tabular consistency. Roboto Flex delivers dense, mechanical hierarchy across headers, directory titles, and storage metric callouts. Inter governs file titles, system paths, dates, and file-size metadata.

In this dark mode environment, optical weight shifts slightly lighter to counteract font irradiation ("glow" effect on OLED screens): primary body text utilizes crisp `#e1e2e8`, while sub-labels, timestamps, and item counts adopt `#c4c6cf` and `#8e9099`. Tabular figures (`font-variant-numeric: tabular-nums`) must be enforced for all byte counts, partition capacities, and file dates to preserve absolute vertical column alignment in dense lists.

## Layout & Spacing

The layout is built for one-handed thumb ergonomics on mobile viewports (360dp to 440dp width). A standard 4-column layout on phones expands to 8 columns on foldables and 12 columns on large tablets. Outer horizontal margins are locked at 16dp (`1rem`) with 16dp inter-column gutters.

All interactive row items preserve a 64dp vertical baseline height to ensure generous touch zones. High-frequency action targets (FAB, batch action bar, bottom sheet triggers) are anchored in the lower two-thirds of the viewport. Touch targets strictly respect the 48dp minimum box model, using padding expansions when visible icons or chips measure smaller. Grid layouts scale from 2 columns in portrait mobile to 3 or 4 columns on expanded horizontal viewports.

## Elevation & Depth

In dark mode, physical drop shadows lose perceived depth against dark backgrounds. Elevation is expressed primarily via Material Design 3 surface tinting, luminance stepping, and ultra-subtle ambient highlights:

- **Level 0 (Canvas Base)**: Surface `#101418`. Inactive scroll wells and system scaffolding.
- **Level 1 (Low Container)**: Storage meters, category matrices, and grouped listing sections use `#191d21` bordered by a 1px ghost border in `#282c31`.
- **Level 2 (Standard Container)**: Floating list cards and unselected docked search capsules utilize `#1d2126` with a hairline top highlight of `rgba(255, 255, 255, 0.04)`.
- **Level 3 (High Elevation / App Bars / Sheets)**: Bottom sheets, navigation bars, and top app bars use `#282c31` paired with a directional glow shadow: `0 8px 24px -4px rgba(0, 0, 0, 0.6)`.
- **Level 4 (FAB / Modals)**: Floating Action Buttons and modal dialogs use `#33373c` (or filled `#38bdf8` for primary actions) with an ambient cyan-tinted glow shadow: `0 8px 24px -2px rgba(56, 189, 248, 0.25)`.

Dividers between directory nodes never use solid high-contrast borders; they rely on 1px rules in `#282c31` or pure vertical spacing gaps.

## Shapes

The shape vocabulary maintains approachable utility through softened corners that segment data cleanly. Primary card containers, storage metric panels, and list groups share an explicit 16dp corner radius (`rounded-lg`), providing safe visual enclosures for file clusters.

Interactive filter chips, docked search bars, and operation pills use full 9999px pill radii (`rounded-full`) to contrast immediately against rectangular file content. Modals, drawer sheets, and contextual bottom actions apply asymmetric rounding, featuring 24dp radii on top corners and flat baselines. Thumbnail previews maintain an 8dp corner radius to prevent visual clipping of nested media details.

## Components

### Buttons & Floating Action Buttons
- **Primary Buttons**: Filled `#38bdf8` with bold `#001e2e` typography, 48dp height, 16dp radius. Hover/active states add an overlaid white flash at 8% alpha.
- **Secondary Buttons**: Outlined container using 1.5dp `#43474e` border, `#191d21` surface, and `#38bdf8` text.
- **Floating Action Button (FAB)**: 56dp × 56dp container with a 16dp radius. Background is `#38bdf8` with a `#001e2e` icon, elevated with a cyan-tinted ambient shadow.

### Filter & Category Chips
- Pill-shaped (36dp height), 12dp horizontal padding.
- **Inactive State**: `#1d2126` fill, `#c4c6cf` text, 1px `#282c31` border.
- **Selected State**: 16% `#38bdf8` background tint with a 1.5dp `#38bdf8` perimeter stroke and `#38bdf8` text.

### File List Items & Grid Cards
- **List Item**: 64dp height. The leading element is a 44dp rounded-md (8dp) category tile tinted with the respective semantic color at 14% opacity. Title text in `#e1e2e8` (Inter Semi-Bold 14px), metadata in `#8e9099` (Inter Regular 12px with tabular numbers). Contextual action trigger on the far right has a 48dp touch target.
- **Grid Tile**: 16dp rounded card, `#191d21` fill, 1px `#282c31` border. Media previews sit in an upper container, with bottom-anchored file metadata and a top-right selection node.

### Input Fields & Search Bars
- Docked search bar uses a 48dp pill container filled with `#1d2126` and a 1px `#282c31` border. Leading search icon in `#8e9099`. On focus, the container elevates to `#282c31` with a 1.5dp `#38bdf8` stroke.

### Checkboxes & Multi-Select Bar
- Contextual multi-selection converts the top navigation bar into a `#1d2126` action header with `#38bdf8` batch actions.
- Checkboxes use circular glyphs with a 2dp `#8e9099` border in idle state, filling with amber `#ffb956` and a dark `#2a1800` checkmark upon selection.

### Storage Usage Meter
- Multi-segment linear track (12dp height, rounded-full) set against a `#101418` channel. Segment fills directly correspond to the semantic dark category palette (Images `#a78bfa`, Videos `#fb7185`, Archives `#facc15`, System `#94a3b8`). Accompanied by tabular-digit analytical storage totals in `#e1e2e8`.
# Design Principles for ArkUI Apps

Apply these principles when designing the visual and interaction structure of any ArkUI app.

## 1. Design the screen as a component hierarchy, not a pile of widgets

Think in ArkUI terms: Column for the page, Row for action groups, Grid for repeated cells, and separate custom components for header, content, status, and bottom actions. For example, a clean screen structure could be PageHeader → ModeSelector → MainContentCard → SummaryCards → FooterAction, rather than random buttons placed around the screen. ArkUI layout docs emphasize structured layout primitives and responsive layouts such as row, column, grid, list, and atomic layouts.

## 2. Create a clear visual hierarchy before choosing colors

The user should instantly understand what the screen is about, what the current state is, and what action matters most. For example, the title can be large, the current status can be smaller under it, the main content can occupy the largest area, and secondary controls can be visually quieter.

## 3. Use one primary action per screen section

A bad UI often makes every button look equally important, which forces the user to think too much. For example, "Continue", "Save", "Start", or "New Round" should be the strongest filled button, while "Reset", "Cancel", "Hint", or "Settings" should use outline, text, or icon-button styles.

## 4. Group related controls into predictable patterns

Mode switching should look like mode switching, settings should look like settings, and destructive actions should not sit next to harmless actions. For example, 2 Players / Easy Bot / Smart Bot belongs in one segmented control, while Sound, Hint, and Reset should be separated because they have different intent.

## 5. Use a spacing system and never rely on "looks okay" positioning

Define spacing tokens such as 4 / 8 / 12 / 16 / 24 / 32 and use them consistently for padding, gaps, card margins, and section separation. For example, cards should not have different random paddings; all major containers should feel like they belong to the same layout rhythm.

## 6. Make UI state explicit in the data model

Selected, disabled, loading, empty, success, warning, and error states should come from state variables, not from scattered hardcoded styles. For example, selectedMode, isSoundEnabled, isLoading, and resultState should drive the UI; ArkUI state management and two-way synchronization patterns are designed around observable state changes updating the UI.

## 7. Treat color as a semantic system, not decoration

Define roles like primary, surface, textPrimary, textSecondary, success, warning, danger, and disabled, then reuse them everywhere. For example, blue can mean primary action, red only destructive/error, amber warning or neutral score, and gray passive information; OpenHarmony supports light/dark adaptation through color mode and resource-based color definitions.

## 8. Design repeated content as reusable components

If three cards share the same structure, they should be the same component with different data, not three separate handmade layouts. For example, use one StatCard(title, value, icon, tone) pattern for counters, one ActionChip(label, icon, selected) pattern for mode buttons, and one InfoBanner(status, description, tone) pattern for messages.

## 9. Make touch targets obvious, forgiving, and accessible

Users should never wonder whether something is clickable, and small icon-only buttons should have enough padding plus a clear label or accessibility text. ArkUI provides accessibility attributes and touch target support, so examples like icon buttons, cards, custom tiles, and gesture areas should be made accessible deliberately rather than visually only.

## 10. Test the same screen across sizes, themes, and content lengths

A good mobile UI should survive small phones, large phones, long translated strings, dark mode, light mode, large font scale, and empty/error states. For example, check what happens when a label becomes twice as long, when the system switches to dark mode, or when accessibility font scaling is enabled; OpenHarmony exposes environment values such as colorMode, fontScale, and accessibilityEnabled, which should be part of UI verification.

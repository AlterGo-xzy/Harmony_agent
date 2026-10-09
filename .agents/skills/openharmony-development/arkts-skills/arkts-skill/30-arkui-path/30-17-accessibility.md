# Accessibility

Use this when the blocker is making UI readable by screen readers or other accessibility services.

## Load this doc when you see
- `.accessibilityText()`, `.accessibilityLevel()`, `.accessibilityGroup()`, `.accessibilityDescription()`
- Screen reader, TalkBack, accessibility requirements

## Set the spoken label on an icon or image
```ts
Image($r('app.media.ic_settings'))
    .width(24).height(24)
    .accessibilityText('Settings')
```

## Add description for a complex element
```ts
Column() {
    Image($r('app.media.chart'))
    Text('Revenue')
}
.accessibilityGroup(true)
.accessibilityText('Revenue chart')
.accessibilityDescription('Bar chart showing monthly revenue. January: $120k, February: $145k')
```

## Exclude decorative elements from screen reader
```ts
// Decorative divider — not useful for screen readers:
Divider()
    .strokeWidth('100%')
    .height(1)
    .accessibilityLevel('no')

// Entire section is decorative:
Column() {
    // purely visual decoration
}
.accessibilityLevel('no-hide-descendants')
```

## Group related elements as one announcement
```ts
Row() {
    Image($r('app.media.avatar'))
    Column() {
        Text('Alice').fontWeight(FontWeight.Bold)
        Text('Online')
    }
}
.accessibilityGroup(true)
.accessibilityText('Alice, Online')
```

## Make an interactive element announce its role
```ts
Button('Submit')
    .accessibilityText('Submit form')
    .accessibilityDescription('Sends your application to the review team')

// Or on a custom interactive surface:
Row() { Text('Tap to select') }
    .onClick(() => { this.selected = true })
    .accessibilityText('Select item')
```

## Hide entire subtree from accessibility
```ts
// A purely decorative illustration panel:
Stack() {
    Image($r('app.media.bg'))
    Image($r('app.media.overlay'))
}
.accessibilityLevel('no-hide-descendants')
```

## Control focus order for keyboard/screen-reader navigation
```ts
Column() {
    TextInput({ placeholder: 'Name' })
        .accessibilityText('Full name')

    TextInput({ placeholder: 'Email' })
        .accessibilityText('Email address')
        .accessibilityNextFocusId('submitBtn')

    Button('Submit')
        .id('submitBtn')
}
```

## Verify
- enable TalkBack/screen reader, navigate to each labeled element, confirm correct text is spoken
- set accessibilityLevel to 'no', confirm screen reader skips the element
- group multiple children, confirm one announcement is read

## Return
- text styling, font color, and contrast token reference → `30-15-styling-and-layout.md`
- form controls → `30-35-form-controls.md`
- if the first direct fix fails → `30-40-arkui-failures.md`

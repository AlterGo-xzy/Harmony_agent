# Form controls: input, toggle, slider, picker, select

Use this when the blocker is adding a text field, switch, checkbox, radio group, slider, date picker, or dropdown to a page.

## Text input -> `TextInput`

Do NOT pass `text:` in the constructor when using `onChange`.
The `text:` parameter creates a two-way binding with the `@State` field.
Combined with `onChange`, this forms an infinite update loop:
`text:` renders → `onChange` fires → `@State` updates → rebuild → `text:` re-renders → crash.

Use `placeholder:` only. Track the value via `onChange` into a `@State` field.
Read the `@State` field for search/filter logic.

```ts
@State searchQuery: string = ''

TextInput({ placeholder: 'Search...' })
    .height(42).layoutWeight(1).fontSize(15)
    .backgroundColor('#F2F2F7').borderRadius(21)
    .padding({ left: 16, right: 16 })
    .onChange((val: string): void => { this.searchQuery = val })
```

When filtering a ForEach list with the search text, bump a separate
`@State int` version counter in `onChange` and include it in the ForEach key:

```ts
@State feedVersion: int = 0
// in onChange:
.onChange((val: string): void => { this.searchQuery = val; this.feedVersion++ })
// ForEach key:
}, (post, idx): string => 'post-' + post.id + '-' + this.feedVersion)
```

**Why the old `text:` pattern crashed**: `text: this.searchQuery` binds the TextInput
display to `@State`. `onChange` writes back to the same `@State`. The `@State`
change triggers rebuild, which re-renders `text:`, which fires `onChange` again —
infinite loop, runtime crash. Removing `text:` breaks the loop.

## Multi-line text input -> `TextArea`
```ts
@State description: string = ''

TextArea({ placeholder: 'Write a description...' })
    .height(120)
    .fontSize(15)
    .backgroundColor('#F2F2F7')
    .borderRadius(14)
    .padding(16)
    .onChange((value: string): void => {
        this.description = value
    })
```

## Switch toggle -> `Toggle(type: Switch)`
```ts
@State notificationsOn: boolean = true

Toggle({ type: ToggleType.Switch, isOn: this.notificationsOn })
    .onChange((isOn: boolean): void => {
        this.notificationsOn = isOn
    })
```

## Checkbox -> `Checkbox` or `Toggle(type: Checkbox)`
```ts
@State agreeTerms: boolean = false

Row() {
    Checkbox()
        .select(this.agreeTerms)
        .onChange((value: boolean): void => {
            this.agreeTerms = value
        })
    Text('I agree to the terms')
}

// Group of checkboxes sharing one group name:
Checkbox({ name: 'Apple', group: 'fruitGroup' })
    .onChange((value: boolean): void => { /* ... */ })
Checkbox({ name: 'Orange', group: 'fruitGroup' })
    .onChange((value: boolean): void => { /* ... */ })
```

## Radio group -> `Radio`
```ts
@State selectedFruit: string = 'apple'

Column() {
    Radio({ group: 'fruitGroup', value: 'apple' })
        .checked(this.selectedFruit == 'apple')
        .onChange((isChecked: boolean): void => {
            if (isChecked) { this.selectedFruit = 'apple' }
        })
    Radio({ group: 'fruitGroup', value: 'orange' })
        .checked(this.selectedFruit == 'orange')
        .onChange((isChecked: boolean): void => {
            if (isChecked) { this.selectedFruit = 'orange' }
        })
}
```

## Slider with snap-to-step -> `Slider`
```ts
@State brightness: double = 50

Slider({
    value: this.brightness,
    min: 0,
    max: 100,
    step: 5,
    style: SliderStyle.OutSet
} as SliderOptions)
    .showTips(true)
    .onChange((value: double): void => {
        this.brightness = value
    })
```

## Dropdown picker -> `Select`
```ts
@State selectedIndex: int = 0
private options: SelectOption[] = [
    { value: 'Light' } as SelectOption,
    { value: 'Dark' } as SelectOption,
    { value: 'Auto' } as SelectOption
]

Select(this.options)
    .selected(this.selectedIndex)
    .value(this.options[this.selectedIndex].value)
    .onSelect((index: int, text: string): void => {
        this.selectedIndex = index
    })
```

## Date picker inline -> `DatePicker`
```ts
@State selectedDate: Date = new Date()

DatePicker({
    start: new Date('2020-1-1'),
    end: new Date('2030-12-31'),
    selected: this.selectedDate,
    mode: DatePickerMode.DATE
} as DatePickerOptions)
    .onDateChange((date: Date): void => {
        this.selectedDate = date
    })
```

## Slide to confirm or reject -> `Slider` with custom style
```ts
@State confirmValue: double = 0

Slider({
    value: this.confirmValue,
    min: 0,
    max: 100,
    step: 100,
    style: SliderStyle.InSet
} as SliderOptions)
    .blockColor('#FF4444')
    .trackColor('#F0F0F0')
    .selectedColor('#FF4444')
    .onChange((value: double, mode: SliderChangeMode): void => {
        this.confirmValue = value
        if (mode == SliderChangeMode.End && value >= 100) {
            this.onConfirmed()
        }
    })
```

## Form submit fires on soft-keyboard Done
```ts
TextInput({ placeholder: 'Search' })
    .type(InputType.Normal)
    .enterKeyType(EnterKeyType.Search)
    .onSubmit((enterKey: EnterKeyType): void => {
        this.doSearch(this.query)
    })
```

## Verify
- type into a TextInput, confirm `.onChange` fires each keystroke
- toggle a switch, confirm `.onChange` fires with the new boolean
- select one radio, confirm only one is checked at a time
- drag a slider, confirm snap-to-step works
- pick a date, confirm `.onDateChange` fires

## Return
- styling the controls (colors, sizes, fonts) → `30-15-styling-and-layout.md`
- picker dialogs (TextPickerDialog) → `30-34-input-display-and-web.md`
- if the first direct fix fails → `30-40-arkui-failures.md`

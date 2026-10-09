# Dialogs

Use this when the blocker is showing a modal dialog, alert, action sheet, or custom dialog overlay.

## Default custom dialog shape
```ts
@CustomDialog
struct ConfirmDialog {
    controller: CustomDialogController = new CustomDialogController({ builder: undefined })
    private message: string = ''
    private onConfirm?: () => void = undefined

    build() {
        Column() {
            Text(this.message)
                .padding(16)
            Row() {
                Button('Cancel')
                    .onClick(() => { this.controller.close() })
                Button('Confirm')
                    .onClick(() => {
                        if (this.onConfirm != undefined) { this.onConfirm() }
                        this.controller.close()
                    })
            }
            .padding({ bottom: 16 } as Padding)
        }
        .borderRadius(12)
        .backgroundColor(Color.White)
    }
}
```

## Open one custom dialog from a page
```text
one button tap should show a custom-styled confirmation
```
```ts
@Component
struct SettingsPage {
    private confirmDialog: CustomDialogController = new CustomDialogController({
        builder: ConfirmDialog({
            message: 'Delete this item?',
            onConfirm: (): void => { this.deleteItem() }
        }),
        autoCancel: true,
        alignment: DialogAlignment.Center,
        isModal: true
    } as CustomDialogControllerOptions)

    deleteItem(): void { /* remove item */ }

    build() {
        Column() {
            Button('Delete')
                .onClick(() => { this.confirmDialog.open() })
        }
    }
}
```

## Alert dialog with two buttons (confirm / cancel)
```text
one quick warning or prompt with standard system look
```
```ts
this.getUIContext().showAlertDialog({
    title: 'Delete',
    message: 'This action cannot be undone.',
    autoCancel: true,
    alignment: DialogAlignment.Center,
    primaryButton: {
        value: 'Cancel',
        action: (): void => { /* do nothing */ }
    },
    secondaryButton: {
        value: 'Delete',
        fontColor: Color.Red,
        action: (): void => { this.deleteItem() }
    }
})
```

## Alert dialog with custom button list (three or more choices)
```text
need more than two buttons — discard, cancel, save
```
```ts
this.getUIContext().showAlertDialog({
    title: 'Unsaved Changes',
    message: 'You have unsaved changes.',
    autoCancel: true,
    alignment: DialogAlignment.Center,
    buttons: [
        {
            value: 'Cancel',
            action: (): void => { /* dismiss */ }
        },
        {
            value: 'Discard',
            fontColor: '#F44336',
            action: (): void => { this.discard() }
        },
        {
            value: 'Save',
            fontColor: '#4CAF50',
            action: (): void => { this.save() }
        }
    ]
})
```

## Action sheet for multi-option choice
```text
tap icon → choose from a short list of actions
```
```ts
ActionSheet.show({
    title: 'Choose action',
    message: 'Select one option',
    confirm: {
        value: 'Cancel',
        action: (): void => { /* dismiss */ }
    } as ActionSheetButtonOptions,
    sheets: [
        {
            title: 'Edit',
            action: (): void => { this.startEdit() }
        } as SheetInfo,
        {
            title: 'Share',
            action: (): void => { this.shareItem() }
        } as SheetInfo,
        {
            title: 'Delete',
            icon: $r('app.media.ic_delete'),
            action: (): void => { this.deleteItem() }
        } as SheetInfo
    ]
} as ActionSheetOptions)
```

## Dialog won't open or the controller is undefined
```text
open() doesn't nothing or throws null controller
```
Next move:
- make sure the controller is a field on the component, not a local in `build()`
- pass it down to the `@CustomDialog` struct via the constructor
- keep exactly one dialog controller instance per dialog

## Prevent dialog dismiss on outside tap
```text
user should not dismiss by tapping outside
```
```ts
// inside CustomDialogControllerOptions:
autoCancel: false,
isModal: true
```

## Custom positioning — bottom sheet
```text
dialog should slide up from the bottom
```
```ts
private bottomSheet: CustomDialogController = new CustomDialogController({
    builder: SheetContent({ /* ... */ }),
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: -24 } as Offset,
    customStyle: true,
    autoCancel: true,
    isModal: true
} as CustomDialogControllerOptions)
```

## Dismiss detection — run cleanup when dialog closes
```text
reset state or start an action after the dialog is gone
```
```ts
private editDialog: CustomDialogController = new CustomDialogController({
    builder: EditorContent({ onSave: (): void => { this.refresh() } }),
    onWillDismiss: (action: DismissDialogAction): void => {
        if (action.reason == DismissReason.PRESS_BACK) {
            // user dismissed without saving
        }
    },
    autoCancel: true
} as CustomDialogControllerOptions)
```

## Verify
- open one custom dialog and dismiss by tapping the cancel button
- open one alert dialog and confirm both buttons fire once
- prove action sheet launches and the correct option fires
- open a bottom sheet and dismiss by tapping outside (autoCancel) or by tapping cancel (not autoCancel)

## Return
- for text or date picker dialogs → `30-34-input-display-and-web.md`
- component tree or state wiring → `30-10-ui-structure-and-state.md`
- if the first direct fix fails → `30-40-arkui-failures.md`

# Widget cards (FormExtensionAbility)

Use this when the blocker is creating or updating home-screen widget cards.

## Minimal FormExtensionAbility
```ts
import { FormExtensionAbility } from '@kit.FormKit'
import { formBindingData } from '@kit.FormKit'
import { Want } from '@kit.AbilityKit'

export default class MyFormAbility extends FormExtensionAbility {
    onAddForm(want: Want): formBindingData.FormBindingData {
        let data: Record<string, Object> = {
            'title': 'My Widget',
            'count': 0
        }
        return formBindingData.createFormBindingData(data)
    }

    onUpdateForm(formId: string, wantParams?: Record<string, Object>): void {
        // Refresh widget data when the system triggers an update
        let data: Record<string, Object> = {
            'count': this.getCurrentCount()
        }
        let bindData = formBindingData.createFormBindingData(data)
        let { formProvider } = requireNapi('@ohos.app.form.formProvider') as {
            formProvider: { updateForm(formId: string, bindData: formBindingData.FormBindingData): Promise<void> }
        }
        formProvider.updateForm(formId, bindData)
    }

    onCastToNormalForm(formId: string): void {
        // Widget converted to normal form
    }

    private getCurrentCount(): int { return 42 }
}
```

## Update a widget from the main app
```ts
import { formProvider } from '@kit.FormKit'
import { formBindingData } from '@kit.FormKit'

async function updateWidget(formId: string, title: string, count: int): Promise<void> {
    let data: Record<string, Object> = {
        'title': title,
        'count': count
    }
    let bindData = formBindingData.createFormBindingData(data)
    await formProvider.updateForm(formId, bindData)
}

// Get all widget IDs for this app:
import { formInfo } from '@kit.FormKit'

async function getWidgetIds(): Promise<string[]> {
    let forms = await formProvider.getFormsInfo()
    let ids: string[] = []
    for (let i: int = 0; i < forms.length; i++) {
        ids.push(forms[i].formId)
    }
    return ids
}

// Set periodic refresh interval (minimum 5 minutes):
async function setRefresh(formId: string, minutes: int): Promise<void> {
    await formProvider.setFormNextRefreshTime(formId, Math.max(minutes, 5))
}
```

## Register the FormExtensionAbility in module.json5
```json
{
  "module": {
    "extensionAbilities": [
      {
        "name": "MyFormAbility",
        "srcEntry": "./ets/formability/MyFormAbility.ets",
        "type": "form",
        "metadata": [
          {
            "name": "ohos.extension.form",
            "resource": "$profile:form_config"
          }
        ]
      }
    ]
  }
}
```

## Form config resource (entry/src/main/resources/base/profile/form_config.json)
```json
{
  "forms": [
    {
      "name": "widget",
      "description": "My Widget",
      "src": "./ets/widget/pages/WidgetCard.ets",
      "uiSyntax": "ets",
      "window": {
        "designWidth": 720,
        "autoDesignWidth": true
      },
      "colorMode": "auto",
      "isDefault": true,
      "updateEnabled": true,
      "scheduledUpdateTime": "10:30",
      "updateDuration": 30,
      "defaultDimension": "2*2",
      "supportDimensions": ["2*2"]
    }
  ]
}
```

## Widget layout file (entry/src/main/ets/widget/pages/WidgetCard.ets)
```ts
@Entry
@Component
struct WidgetCard {
    readonly TITLE_KEY: string = 'title'
    readonly COUNT_KEY: string = 'count'
    @State title: string = ''
    @State count: int = 0

    build() {
        Column() {
            Text(this.title)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
            Text(this.count.toString())
                .fontSize(24)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
    }
}
```

## Verify
- add a widget to the home screen, confirm the initial data appears
- call updateForm from the main app, confirm the widget updates
- set the refresh interval, wait, confirm the system triggers onUpdateForm

## Return
- data storage for widget state → `35-50-rdb-and-storage.md` or `35-55-preferences-and-light-store.md`
- project layout for config files → `35-30-project-layout-and-build-surfaces.md`
- if the first direct fix fails → `35-40-ohos-app-failures.md`

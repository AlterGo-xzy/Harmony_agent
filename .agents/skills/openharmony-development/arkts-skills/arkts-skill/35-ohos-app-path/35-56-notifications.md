# Local notifications

Use this when the blocker is posting a system notification from inside the app.

## Load this doc when you see
- `notificationManager`, `publish`, `NotificationRequest`
- `@kit.NotificationKit`
- "show a notification" or "push a local alert"

## Send one basic notification
```ts
import { notificationManager } from '@kit.NotificationKit'

function sendNotification(title: string, text: string): void {
    let request: notificationManager.NotificationRequest = {
        id: 1,
        content: {
            notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
            normal: {
                title: title,
                text: text
            }
        }
    } as notificationManager.NotificationRequest

    notificationManager.publish(request).then((): void => {
        console.info('Notification published')
    }).catch((err: Error): void => {
        console.error('Publish failed: ' + err.message)
    })
}
```

## Notification with a tap action — open a page
```ts
import { notificationManager } from '@kit.NotificationKit'
import { wantAgent, WantAgentFlags, WantAgentInfo, WantAgentTriggerInfo } from '@kit.AbilityKit'

function sendNotificationWithAction(context: common.UIAbilityContext): void {
    let wantInfo: WantAgentInfo = {
        wants: [{
            deviceId: '',
            bundleName: context.abilityInfo.bundleName,
            abilityName: 'EntryAbility',
            parameters: { page: 'pages/Detail', itemId: 42 }
        }],
        operationType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        wantAgentFlags: [WantAgentFlags.UPDATE_PRESENT_FLAG]
    } as WantAgentInfo

    wantAgent.getWantAgent(wantInfo).then((agent: WantAgent): void => {
        let request: notificationManager.NotificationRequest = {
            id: 10,
            content: {
                notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
                normal: { title: 'New Message', text: 'Tap to view' }
            },
            wantAgent: agent
        } as notificationManager.NotificationRequest

        notificationManager.publish(request)
    })
}
```

## Update an existing notification (same id replaces it)
```ts
// Use the same id to replace the previous notification:
let request: notificationManager.NotificationRequest = {
    id: 1,
    content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: { title: 'Updated', text: 'Progress: 75%' }
    }
} as notificationManager.NotificationRequest

notificationManager.publish(request)
```

## Ongoing notification (non-dismissible)
```ts
let request: notificationManager.NotificationRequest = {
    id: 100,
    content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: { title: 'Recording', text: 'Audio recording in progress' }
    },
    isOngoing: true         // cannot be swiped away by user
} as notificationManager.NotificationRequest
```

## Notification type (slot) selection
```ts
// SlotType controls the notification category (importance, sound, vibration):
let request: notificationManager.NotificationRequest = {
    // ...
    notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION
} as notificationManager.NotificationRequest

// Common slot types:
// SOCIAL_COMMUNICATION  - chat, messages (priority)
// SERVICE_INFORMATION   - app updates, download progress
// CONTENT_INFORMATION   - content updates, news
// OTHER_TYPES           - misc, lowest priority
```

## Notification with action buttons (max 2)
```ts
let request: notificationManager.NotificationRequest = {
    id: 20,
    content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: { title: 'Alarm', text: 'Time is up' }
    },
    actionButtons: [
        {
            title: 'Snooze',
            wantAgent: snoozeAgent
        } as notificationManager.NotificationActionButton,
        {
            title: 'Dismiss',
            wantAgent: dismissAgent
        } as notificationManager.NotificationActionButton
    ]
} as notificationManager.NotificationRequest
```

## Notification content too long -> use long text
```ts
let request: notificationManager.NotificationRequest = {
    id: 30,
    content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_LONG_TEXT,
        longText: {
            title: 'Update Summary',
            text: 'Short preview',
            longText: 'Full summary text that supports up to 1024 bytes...',
            briefText: 'Summary',
            expandedTitle: 'Expanded Update Summary'
        }
    }
} as notificationManager.NotificationRequest
```

## Verify
- send one basic notification and confirm it appears in notification center
- send a second with the same id, confirm it replaces the first
- tap a notification with a WantAgent, confirm the target page opens

## Return
- app context retrieval → `35-10-app-model-and-system-apis.md`
- calling more complex system APIs → `35-60-specialized-ohos-apis.md`
- if the first direct fix fails → `35-40-ohos-app-failures.md`

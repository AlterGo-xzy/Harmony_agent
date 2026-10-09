# Calendar events

Use this when the blocker is creating or reading calendar events.

## Add an event to the device calendar
```ts
import { calendarManager } from '@kit.CalendarKit'

async function addEvent(
    context: common.UIAbilityContext,
    title: string,
    startDate: Date,
    endDate: Date
): Promise<boolean> {
    try {
        let mgr = calendarManager.getCalendarManager(context)
        let calendars = mgr.createCalendar({
            name: 'localAccount',
            type: calendarManager.CalendarType.LOCAL
        } as calendarManager.CalendarAccount)
        if (calendars == undefined) { return false }

        let event: calendarManager.Event = {
            type: calendarManager.EventType.NORMAL,
            title: title,
            startDate: startDate.getTime() as long,
            endDate: endDate.getTime() as long,
            isAllDay: false,
            description: '',
            location: ''
        } as calendarManager.Event

        await calendars.addEvent(event)
        return true
    } catch (err) {
        console.error('Add event failed: ' + (err as Error).message)
        return false
    }
}
```

## Read events from the calendar
```ts
import { calendarManager } from '@kit.CalendarKit'

async function getUpcomingEvents(context: common.UIAbilityContext): Promise<calendarManager.Event[]> {
    try {
        let mgr = calendarManager.getCalendarManager(context)
        let calendars = mgr.getCalendar({
            name: 'localAccount',
            type: calendarManager.CalendarType.LOCAL
        } as calendarManager.CalendarAccount)
        if (calendars == undefined) { return [] }

        let nowMs = new Date().getTime() as long
        let weekMs = nowMs + (7 as long * 86400000 as long)

        // range = [now, now + 7 days]
        let options: calendarManager.EventsFetchOptions = {
            range: {
                startTimeMs: nowMs,
                endTimeMs: weekMs
            }
        } as calendarManager.EventsFetchOptions

        let events = await calendars.getEvents(options)
        return events
    } catch (err) {
        return []
    }
}
```

## Delete an event
```ts
async function deleteEvent(
    context: common.UIAbilityContext,
    eventId: string
): Promise<void> {
    let mgr = calendarManager.getCalendarManager(context)
    let calendars = mgr.getCalendar({
        name: 'localAccount',
        type: calendarManager.CalendarType.LOCAL
    } as calendarManager.CalendarAccount)
    if (calendars == undefined) { return }
    await calendars.deleteEvent(eventId)
}
```

## Verify
- call addEvent, confirm the event appears in the system Calendar app
- read events for the next 7 days, confirm the added event is returned
- delete the event, confirm it disappears

## Return
- permission: no explicit permission needed for local calendar
- context retrieval → `35-10-app-model-and-system-apis.md`
- if the first direct fix fails → `35-40-ohos-app-failures.md`

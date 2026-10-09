# Location services

Use this when the blocker is getting the device location or subscribing to location updates.

## Load this doc when you see
- `geoLocationManager`, `getCurrentLocation`, `onLocationChange`
- `@ohos.geoLocationManager`
- "GPS", "get device location", "current position"

## Get one-time current location
```ts
import geoLocationManager from '@ohos.geoLocationManager'

async function getCurrentPosition(): Promise<geoLocationManager.Location | null> {
    try {
        let request: geoLocationManager.CurrentLocationRequest = {
            priority: geoLocationManager.LocationRequestPriority.ACCURACY,
            scenario: geoLocationManager.LocationRequestScenario.UNSET,
            timeoutMs: 10000
        } as geoLocationManager.CurrentLocationRequest
        let location = await geoLocationManager.getCurrentLocation(request)
        return location
    } catch (err) {
        console.error('Location failed: ' + (err as Error).message)
        return null
    }
}

// Usage:
let loc = await getCurrentPosition()
if (loc != null) {
    console.info('lat: ' + loc.latitude + ', lng: ' + loc.longitude)
    console.info('accuracy: ' + loc.accuracy + 'm')
}
```

## Subscribe to continuous location updates
```ts
import geoLocationManager from '@ohos.geoLocationManager'

@Component
struct MapPage {
    @State latitude: double = 0
    @State longitude: double = 0
    @State accuracy: double = 0

    startTracking(): void {
        let request: geoLocationManager.LocationRequest = {
            priority: geoLocationManager.LocationRequestPriority.ACCURACY,
            scenario: geoLocationManager.LocationRequestScenario.NAVIGATION,
            timeInterval: 1,       // seconds
            distanceInterval: 10   // meters
        } as geoLocationManager.LocationRequest

        geoLocationManager.onLocationChange(request, (location: geoLocationManager.Location): void => {
            this.latitude = location.latitude
            this.longitude = location.longitude
            this.accuracy = location.accuracy
        })
    }

    stopTracking(): void {
        geoLocationManager.offLocationChange()
    }

    aboutToAppear(): void { this.startTracking() }
    aboutToDisappear(): void { this.stopTracking() }
}
```

## Get last known location (cached, no new fix)
```ts
let lastLoc = geoLocationManager.getLastLocation()
// lastLoc may be null if no prior location has been determined
```

## Check if location is enabled
```ts
let enabled = geoLocationManager.isLocationEnabled()
if (!enabled) {
    // prompt user to enable location in settings
}
```

## Listen for location enabled/disabled changes
```ts
geoLocationManager.onLocationEnabledChange((enabled: boolean): void => {
    this.locationAvailable = enabled
})
geoLocationManager.offLocationEnabledChange()
```

## Location permissions (module.json5)
```json
{
  "name": "ohos.permission.APPROXIMATELY_LOCATION",
  "reason": "$string:location_reason",
  "usedScene": { "abilities": ["EntryAbility"], "when": "inuse" }
}
```
For precise location (GPS-level): also request `ohos.permission.LOCATION`.

## Low-power background tracking -> `ContinuousLocationRequest`
```ts
let request: geoLocationManager.ContinuousLocationRequest = {
    interval: 60,   // seconds between reports
    locationScenario: geoLocationManager.UserActivityScenario.NAVIGATION
} as geoLocationManager.ContinuousLocationRequest
```

## Verify
- call getCurrentLocation outdoors, confirm lat/lng/accuracy values are reasonable
- subscribe to onLocationChange, walk a few meters, confirm new fixes arrive
- call isLocationEnabled, confirm it returns correct state
- unsubscribe and confirm no more callbacks fire

## Return
- permission requests → `35-10-app-model-and-system-apis.md`
- background tasks → `35-22-background-tasks-and-workers.md`
- app lifecycle → `30-20-routing-lifecycle-and-app-flow.md`
- if the first direct fix fails → `35-40-ohos-app-failures.md`

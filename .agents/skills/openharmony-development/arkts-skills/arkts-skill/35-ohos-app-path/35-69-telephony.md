# Telephony

Use this when the blocker is reading SIM/network info or observing call state.

## Get SIM info
```ts
import { sim } from '@kit.TelephonyKit'

async function getSimInfo(): Promise<void> {
    try {
        let active = sim.isSimActive(0)    // slot 0
        if (active) {
            let simInfo = sim.getSimInfo(0)
            console.info('Operator: ' + simInfo.operatorName)
            console.info('ICCID: ' + simInfo.iccid)
            console.info('Phone: ' + simInfo.phoneNumber)
        }
    } catch (err) {
        console.error('SIM error: ' + (err as Error).message)
    }
}
```

## Get network state (WiFi/cellular)
```ts
import { radio } from '@kit.TelephonyKit'

function getNetworkState(): void {
    try {
        let networkState = radio.getNetworkState(0)
        console.info('Network type: ' + networkState.nsaState)
        // values: unknown, registered, emergency-only, no-service
    } catch (err) {
        console.error('Radio error: ' + (err as Error).message)
    }
}
```

## Observe SIM state changes
```ts
import { observer } from '@kit.TelephonyKit'

observer.on('simStateChange', (data: observer.SimStateData): void => {
    // data.simState: SIM_STATE_READY, SIM_STATE_NOT_PRESENT, etc.
    if (data.simState == observer.SimState.SIM_STATE_READY) {
        console.info('SIM ready: slot ' + data.simId)
    }
})

// Stop observing:
observer.off('simStateChange')
```

## Observe network state changes
```ts
observer.on('networkStateChange', (data: observer.NetworkStateData): void => {
    // data.networkState reflects current registration state
    console.info('Network state changed: slot ' + data.simId)
})

observer.off('networkStateChange')
```

## Verify
- call getSimInfo on a device with a SIM, confirm operator name is non-empty
- register for simStateChange, remove SIM, confirm callback fires
- call getNetworkState, confirm a valid state string is returned

## Return
- permissions: `ohos.permission.GET_NETWORK_INFO` for network state
- if the first direct fix fails → `35-40-ohos-app-failures.md`

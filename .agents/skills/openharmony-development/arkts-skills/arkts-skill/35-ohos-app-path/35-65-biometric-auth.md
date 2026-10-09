# Biometric authentication

Use this when the blocker is authenticating the user with fingerprint or face recognition.

## Permission and syscap

`@ohos.userIAM.userAuth` requires `systemapi` privileges and is marked deprecated. Requires `ohos.permission.ACCESS_BIOMETRIC`.

## Check if fingerprint or face is available
```ts
import userAuth from '@ohos.userIAM.userAuth'

function checkBiometricSupport(): boolean {
    try {
        let status = userAuth.getAvailableStatus(
            userAuth.UserAuthType.FINGERPRINT,
            userAuth.AuthTrustLevel.ATL1
        )
        return true
    } catch (err) {
        return false
    }
}

// Check face separately:
function hasFaceAuth(): boolean {
    try {
        userAuth.getAvailableStatus(
            userAuth.UserAuthType.FACE,
            userAuth.AuthTrustLevel.ATL1
        )
        return true
    } catch (err) {
        return false
    }
}
```

## Authenticate with fingerprint (or fallback to PIN)
```ts
import userAuth from '@ohos.userIAM.userAuth'

function authenticateWithFingerprint(): Promise<boolean> {
    return new Promise<boolean>((resolve: (v: boolean) => void): void => {
        // 1. Create a challenge (random bytes, at least 16)
        let challengeData = new Uint8Array([1, 2, 3, 4, 5, 6, 7, 8])

        // 2. Configure auth parameters
        let authParam: userAuth.AuthParam = {
            challenge: challengeData,
            authType: [userAuth.UserAuthType.FINGERPRINT],
            authTrustLevel: userAuth.AuthTrustLevel.ATL1
        } as userAuth.AuthParam

        // 3. Configure widget text
        let widgetParam: userAuth.WidgetParam = {
            title: 'Verify your fingerprint'
        } as userAuth.WidgetParam

        // 4. Create instance and subscribe to result
        let authInstance = userAuth.getUserAuthInstance(authParam, widgetParam)

        authInstance.on('result', {
            onResult: (result: userAuth.UserAuthResult): void => {
                if (result.result == userAuth.UserAuthResultCode.SUCCESS) {
                    resolve(true)
                } else {
                    resolve(false)
                }
                authInstance.off('result')
            }
        })

        // 5. Start authentication
        authInstance.start()
    })
}
```

## Authenticate with face recognition
```ts
let authParam: userAuth.AuthParam = {
    challenge: new Uint8Array(16),   // 16 random bytes
    authType: [userAuth.UserAuthType.FACE],
    authTrustLevel: userAuth.AuthTrustLevel.ATL1
} as userAuth.AuthParam

let widgetParam: userAuth.WidgetParam = {
    title: 'Look at the screen to verify'
} as userAuth.WidgetParam

let authInstance = userAuth.getUserAuthInstance(authParam, widgetParam)
authInstance.on('result', {
    onResult: (result: userAuth.UserAuthResult): void => {
        if (result.result == userAuth.UserAuthResultCode.SUCCESS) {
            // user verified — proceed to sensitive operation
        } else if (result.result == userAuth.UserAuthResultCode.CANCELED) {
            // user cancelled
        } else {
            // authentication failed
        }
        authInstance.off('result')
    }
})
authInstance.start()
```

## Cancel an in-progress authentication
```ts
authInstance.cancel()
```

## Auth type values
| `UserAuthType` | Value | Description |
|---|---|---|
| `PIN` | 1 | PIN/password |
| `FACE` | 2 | Face recognition |
| `FINGERPRINT` | 4 | Fingerprint |

## Trust level values
| `AuthTrustLevel` | Value | Use case |
|---|---|---|
| `ATL1` | 10000 | Lowest — unlock screen |
| `ATL2` | 20000 | Medium — in-app authentication |
| `ATL3` | 30000 | High — payment/financial |
| `ATL4` | 40000 | Highest — enterprise key |

## Result codes
| `UserAuthResultCode` | Meaning |
|---|---|
| `SUCCESS` | Authentication passed |
| `CANCELED` | User cancelled |
| `LOCKED` | Too many failed attempts |
| `NOT_ENROLLED` | No biometric enrolled |

## Non-system display: `@ohos.userIAM.userAuthIcon`

For showing the auth icon in UI (non-system, non-deprecated):
```ts
import { UserAuthIcon } from '@ohos.userIAM.userAuthIcon'

@Component
struct BiometricIcon {
    build() {
        UserAuthIcon({
            authParam: {
                challenge: new Uint8Array(16),
                authType: [userAuth.UserAuthType.FINGERPRINT],
                authTrustLevel: userAuth.AuthTrustLevel.ATL1
            },
            widgetParam: { title: 'Unlock' }
        })
            .width(64)
            .height(64)
            .onClick((): void => {
                // trigger actual auth via userAuth...
            })
    }
}
```

## Verify
- call getAvailableStatus with FINGERPRINT on a device with a fingerprint sensor, confirm it returns without error
- start authentication, place finger on sensor, confirm SUCCESS in callback
- cancel authentication mid-flow, confirm CANCELED result
- test with lock screen already unlocked (ATL1), confirm auth succeeds immediately

## Return
- permission requests → `35-10-app-model-and-system-apis.md`
- if the first direct fix fails → `35-40-ohos-app-failures.md`

# HTTP requests and network connectivity

Use this when the blocker is fetching data from an HTTP API or checking network connectivity.

## GET request -> `http.createHttp()`
```ts
import { http } from '@kit.NetworkKit'

async function fetchJson(url: string): Promise<Object | null> {
    let request = http.createHttp()
    try {
        let response: http.HttpResponse = await request.request(url, {
            method: http.RequestMethod.GET,
            expectDataType: http.HttpDataType.OBJECT
        } as http.HttpRequestOptions)
        if (response.responseCode == http.ResponseCode.OK) {
            return response.result as Object
        }
        return null
    } catch (err) {
        let e = err as Error
        console.error('HTTP GET failed: ' + e.message)
        return null
    } finally {
        request.destroy()
    }
}
```

## POST request with JSON body
```ts
async function postJson(url: string, body: Object): Promise<http.HttpResponse | null> {
    let request = http.createHttp()
    try {
        let response = await request.request(url, {
            method: http.RequestMethod.POST,
            header: { 'Content-Type': 'application/json' },
            extraData: body,
            expectDataType: http.HttpDataType.OBJECT,
            connectTimeout: 10000,
            readTimeout: 30000
        } as http.HttpRequestOptions)
        return response
    } catch (err) {
        return null
    } finally {
        request.destroy()
    }
}
```

## Download a file -> `http` + `fileIo`
```ts
import { http } from '@kit.NetworkKit'
import { fileIo as fs } from '@kit.CoreFileKit'

async function downloadFile(url: string, savePath: string): Promise<boolean> {
    let request = http.createHttp()
    try {
        // expectDataType ARRAY_BUFFER for binary data:
        let response: http.HttpResponse = await request.request(url, {
            method: http.RequestMethod.GET,
            expectDataType: http.HttpDataType.ARRAY_BUFFER
        } as http.HttpRequestOptions)

        if (response.responseCode == http.ResponseCode.OK) {
            let file = fs.openSync(savePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY)
            fs.writeSync(file.fd, response.result as ArrayBuffer)
            fs.closeSync(file.fd)
            return true
        }
        return false
    } catch (err) {
        return false
    } finally {
        request.destroy()
    }
}
```

## Check if the device has internet connectivity
```ts
import { connection } from '@kit.NetworkKit'

function hasInternet(): boolean {
    try {
        let netHandle = connection.getDefaultNetSync()
        let caps = connection.getNetCapabilitiesSync(netHandle)
        if (caps.networkCap != undefined) {
            for (let cap of caps.networkCap) {
                if (cap == connection.NetCap.NET_CAPABILITY_INTERNET) {
                    return true
                }
            }
        }
        return false
    } catch (err) {
        return false
    }
}
```

## Detect network type (WiFi vs Cellular)
```ts
function getNetworkType(): string {
    try {
        let netHandle = connection.getDefaultNetSync()
        let caps = connection.getNetCapabilitiesSync(netHandle)
        if (caps.bearerTypes != undefined) {
            for (let bearer of caps.bearerTypes) {
                if (bearer == connection.NetBearType.BEARER_WIFI) {
                    return 'wifi'
                }
                if (bearer == connection.NetBearType.BEARER_CELLULAR) {
                    return 'cellular'
                }
                if (bearer == connection.NetBearType.BEARER_ETHERNET) {
                    return 'ethernet'
                }
            }
        }
        return 'unknown'
    } catch (err) {
        return 'unknown'
    }
}
```

## Listen for connectivity changes
```ts
import { connection } from '@kit.NetworkKit'

let netConnection = connection.createNetConnection()
netConnection.register((err: Error): void => {
    if (err != null) {
        console.error('Failed to register: ' + err.message)
    }
})
// onNetAvailable and onNetLost fire when networks appear/disappear
// Check connectivity with hasInternet() on each event
```

## HTTP call freezes the UI -> offload to taskpool
```ts
async function fetchInBackground(url: string): Promise<string> {
    let task = new taskpool.Task(fetchJson, url)
    let result = await taskpool.execute(task) as Object
    if (result != undefined) {
        return JSON.stringify(result)
    }
    return '{}'
}

// From a component:
aboutToAppear(): void {
    fetchInBackground('https://api.example.com/data').then((json: string): void => {
        this.data = json
    })
}
```

## Verify
- call fetchJson against a known-good URL, confirm response arrives
- call hasInternet() offline, confirm it returns false
- call downloadFile, confirm the file exists at savePath

## Return
- download with progress bar → `30-34-input-display-and-web.md` (Progress component) and `35-10-app-model-and-system-apis.md` (request.agent)
- file I/O details → `35-10-app-model-and-system-apis.md`
- concurrency offloading → `20-references/28-taskpool-and-synchronization.md`
- if the first direct fix fails → `35-40-ohos-app-failures.md`

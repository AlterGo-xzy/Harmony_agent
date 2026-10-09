# Audio playback

Use this when the blocker is playing audio files or streams with `AVPlayer`.

## Load this doc when you see
- `media.createAVPlayer`, `AVPlayer`, `play()`, `pause()`, `stop()`
- `@kit.MediaKit`, `@ohos.multimedia.media`
- "play audio" or "background music"

## Play a local audio file
```ts
import { media } from '@kit.MediaKit'

@Component
struct AudioPlayerPage {
    private player: media.AVPlayer | undefined = undefined
    @State isPlaying: boolean = false
    @State currentTime: int = 0
    @State duration: int = 0

    async initPlayer(): Promise<void> {
        let avPlayer = await media.createAVPlayer()
        if (avPlayer == undefined) { return }
        this.player = avPlayer

        avPlayer.onStateChange((state: media.AVPlayerState, reason: media.StateChangeReason): void => {
            if (state == 'prepared') { this.isPlaying = false }
            if (state == 'playing') { this.isPlaying = true }
            if (state == 'paused') { this.isPlaying = false }
            if (state == 'completed') { this.isPlaying = false }
            if (state == 'error') { console.error('AVPlayer error') }
        })

        avPlayer.onTimeUpdate((time: int): void => {
            this.currentTime = time
        })

        avPlayer.onDurationUpdate((dur: int): void => {
            this.duration = dur
        })

        avPlayer.onError((err: Error): void => {
            console.error('AVPlayer error: ' + err.message)
        })

        avPlayer.url = 'file://' + this.getAssetPath('music.mp3')
        await avPlayer.prepare()
    }

    play(): void {
        if (this.player != undefined) { this.player.play() }
    }

    pause(): void {
        if (this.player != undefined) { this.player.pause() }
    }

    stop(): void {
        if (this.player != undefined) { this.player.stop() }
    }

    release(): void {
        if (this.player != undefined) {
            this.player.release()
            this.player = undefined
        }
    }

    getAssetPath(filename: string): string { /* return sandbox path */ return '' }
}
```

## Play a network stream (URL)
```ts
async function playStream(url: string): Promise<media.AVPlayer | undefined> {
    let avPlayer = await media.createAVPlayer()
    if (avPlayer == undefined) { return undefined }
    avPlayer.url = url
    await avPlayer.prepare()
    await avPlayer.play()
    return avPlayer
}
```

## Play audio from app rawfile
```ts
async function playRawfile(context: common.UIAbilityContext, filename: string): Promise<void> {
    let descriptor = context.resourceManager.getRawFdSync(filename)
    let avPlayer = await media.createAVPlayer()
    if (avPlayer == undefined) { return }
    avPlayer.fdSrc = { fd: descriptor.fd, offset: descriptor.offset, length: descriptor.length }
    await avPlayer.prepare()
    await avPlayer.play()
    context.resourceManager.closeRawFdSync(filename)
}
```

## Playback of app-generated files (fdSrc)

**Format support caveat.** Despite what the official documentation may list, device verification confirmed the only music file container formats supported by ArkTS-STA AVPlayer are **mp3** and **ogg**. WAV files were rejected with `Unsupported Format: CONTAINER_ERR-null-unsupport interface` in testing. Platform Vorbis encoding was unavailable or rejected on the test device. Encode app-generated audio to OGG/FLAC — it passed all device playback checks.

**fd lifecycle rule (device-verified).**

Starting from a file already written to app sandbox (e.g. `data/storage/el2/base/files/my_app/_playback.ogg`):

1. Open a raw native fd via `open(path.c_str(), O_RDONLY)` — do **not** use `@ohos.file.fs` managed `File` objects; they trigger FDSAN double-close on device.
2. Register AVPlayer callbacks (`onStateChange`, `onError`) **before** assigning `fdSrc`. Use a captured `p` variable to guard stale callbacks if the player is replaced.
3. Drive transitions from callbacks — do **not** call `await p.prepare()` in user code:
   - `'initialized'` → `p.prepare()`
   - `'prepared'` → `p.play()`
   - `'completed'` / `'error'` → `p.release()`
4. Assign `fdSrc` with an explicit `as media.AVFileDescriptor` cast:
   ```ts
   p.fdSrc = { fd: playerFd, offset: 0, length: fileSize } as media.AVFileDescriptor
   ```
5. After a successful `fdSrc` assignment, **do not close the fd yourself** — AVPlayer takes ownership. Explicit `close()` call after `fdSrc` produced `SetSource FileDescriptor failed` on device. Explicit `close()` after `p.release()` produced FDSAN double-close.
6. If setup fails **before** `fdSrc` succeeds, close the raw fd yourself. Track an `avPlayerOwnedFd: int = -1` marker; set it to the fd value after successful `fdSrc` and reset to `-1` on every `p.release()` path.

```ts
import media from '@ohos.multimedia.media'
import fileIo from '@ohos.file.fs'
import { YourNativeApi } from './YourNativeApi'

async function playGeneratedOgg(filePath: string): Promise<boolean> {
    let playerFd: int = -1
    let p: media.AVPlayer | undefined = undefined
    try {
        let fileSize: int = fileIo.statSync(filePath).size.toInt()
        playerFd = YourNativeApi.openReadOnlyFd(filePath)
        if (playerFd < 0) { return false }

        let avPlayer = await media.createAVPlayer()
        if (avPlayer == undefined) { return false }
        p = avPlayer

        let started: boolean = false
        avPlayer.onStateChange((state: string, _reason: media.StateChangeReason): void => {
            if (p == undefined || avPlayer != p) { return }
            let activePlayer = p
            if (activePlayer == undefined) { return }
            if (state === 'initialized') { activePlayer.prepare() }
            if (state === 'prepared') {
                activePlayer.play()
                if (!started) { started = true }
            }
            if (state === 'completed') { activePlayer.release(); p = undefined }
            if (state === 'error')     { activePlayer.release(); p = undefined }
        })
        avPlayer.onError((_e: Error): void => {
            if (avPlayer == p && p != undefined) {
                let activePlayer = p
                if (activePlayer != undefined) { activePlayer.release(); p = undefined }
            }
        })

        avPlayer.fdSrc = { fd: playerFd, offset: 0, length: fileSize } as media.AVFileDescriptor
        playerFd = -1
        return true
    } catch (_e) {
        if (playerFd >= 0) { YourNativeApi.closeFd(playerFd) }
        if (p != undefined) { p.release() }
        return false
    }
}
```

## Seek to a position
```ts
if (this.player != undefined) {
    this.player.seek(30000)  // jump to 30 seconds, in ms
}
```

## Loop playback
```ts
avPlayer.loop = true   // replay automatically after completion
```

## Set volume
```ts
avPlayer.setVolume(0.8)  // 0.0 to 1.0
```

## AVPlayer state lifecycle
```
idle → initialized → prepared → playing ⇄ paused
                       ↑            ↓
                       ←  completed ←
                       ↑
                       ←  stopped ←
                       ←  error
                       ←  released
```
Call `prepare()` to move from `initialized` to `prepared`. Only after `prepared` can you `play()`.

## Verify
- play a local audio file, confirm onStateChange fires prepared→playing
- pause and resume, confirm state transitions
- seek to 10 seconds, confirm onTimeUpdate reflects new position
- release the player, confirm memory is freed

## Return
- rawfile access → `30-16-resources-and-assets.md`
- network streaming → `35-57-network-and-http.md`
- file paths → `35-10-app-model-and-system-apis.md`
- if the first direct fix fails → `35-40-ohos-app-failures.md`

# OHOS SDK Static Modules Reference

> **875** modules with static (`'use static'`) availability. **507** public. **813** ship in the static agentsdk.
>
> Import every `@ohos.*` module with a default-namespace import in static mode:
> ```ts
> import notificationManager from '@ohos.notificationManager'
> ```

## Flags

| Flag | Meaning |
|---|---|
| `@systemapi` | Restricted to system apps; may not compile in ordinary apps |
| `@deprecated` | Marked deprecated; prefer replacement module |
| `@crossplatform` | Available across phone, tablet, 2in1 device types |

---

## ArkUI

95 modules — 75 public, 20 @systemapi, 0 deprecated, 87 in agentsdk

| Import name | Flags | Intent |
|---|---|---|
| `@kit.ArkUI` | — | Top-level kit that re-exports all ArkUI components, state management, advanced components, and node APIs |
| `@ohos.arkui.ArcAlphabetIndexer` | — | Jump to letter sections in a contact list or sorted catalog via a circular index bar on wearables |
| `@ohos.arkui.ArcList` | — | Display a list that follows a circular arc rather than a straight line for curved watch-face UIs |
| `@ohos.arkui.ArcScrollBar` | — | Show scroll position on a curved layout for wearables |
| `@ohos.arkui.ArcSwiper` | — | Display swipeable carousel pages on a curved surface for round watch faces |
| `@ohos.arkui.Parallelize` | — | Offload component creation to background threads to avoid frame drops during heavy rendering |
| `@ohos.arkui.Prefetcher` | — | Preload resources for a complex view or image-heavy screen so it renders instantly |
| `@ohos.arkui.Test` | — | Write automated UI tests — find components by ID, simulate clicks and swipes, and assert visual state |
| `@ohos.arkui.UIContext` | `@systemapi` `@crossplatform` | Inspect the active UI environment — query component focus, access the component tree, run UI operations imperatively |
| `@ohos.arkui.WithEnv` | — | Adapt component appearance to device context — phone vs tablet, dark vs light mode, different screen densities |
| `@ohos.arkui.advanced.ArcButton` | — | Display a tappable button that curves along a circular arc on wearables |
| `@ohos.arkui.advanced.ArcSlider` | — | Adjust a value — volume, brightness, progress — by dragging along a curved track on wearables |
| `@ohos.arkui.advanced.Chip` | — | Choose from multiple filter or tag options — select categories, genres, or labels from tappable tokens |
| `@ohos.arkui.advanced.ChipGroup` | — | Present multiple related chips together — genre filters, ingredient selectors — with automatic wrapping and spacing |
| `@ohos.arkui.advanced.ChipGroupV2` | — | Advanced chip groups — multi-row layout with overflow handling, animated chip additions and removals |
| `@ohos.arkui.advanced.ChipV2` | — | Chips with richer visual states — custom icons, badges, swipe-to-dismiss, or animated selection transitions |
| `@ohos.arkui.advanced.ComposeListItem` | — | Build consistently styled list rows — icon, title, subtitle, trailing control — without hand-laying-out each row |
| `@ohos.arkui.advanced.ComposeListItemV2` | — | Richer list item layouts — multi-line summaries, embedded toggles, customized accessory views |
| `@ohos.arkui.advanced.ComposeTitleBar` | — | Compose a standardized title bar — back button, title text, optional actions — and reuse it on every screen |
| `@ohos.arkui.advanced.ComposeTitleBarV2` | — | A richer title bar — subtitle text, custom leading/trailing widgets, animated transitions between screens |
| `@ohos.arkui.advanced.Counter` | — | Enter a numeric quantity — shopping cart item count, passenger count, step count — via +/− stepper buttons |
| `@ohos.arkui.advanced.CounterV2` | — | A counter with richer UX — configurable min/max bounds, hold-to-increment, custom button styling |
| `@ohos.arkui.advanced.DatePickerComponent` | — | Select a date — birthday entry, booking date, event scheduling — with a scrolling date picker |
| `@ohos.arkui.advanced.Dialog` | — | Interrupt the user for a decision — confirm deletion, show an alert, ask for confirmation — with a modal dialog |
| `@ohos.arkui.advanced.DialogV2` | — | Show a dialog with custom body layouts, multiple action buttons, and rich text in the message area |
| `@ohos.arkui.advanced.DownloadFileButton` | — | Offer a downloadable resource — document, media file, update package — with a button that shows download progress inline |
| `@ohos.arkui.advanced.EditableTitleBar` | — | Rename something in-place — edit a document title, rename a playlist — by tapping the title bar and typing |
| `@ohos.arkui.advanced.EditableTitleBarV2` | — | Inline editing with richer behavior — validation feedback, character limits, commit-on-blur, or undo support |
| `@ohos.arkui.advanced.ExceptionPrompt` | — | Show an error state — network failure, empty search results, permission denied — with a consistent error screen |
| `@ohos.arkui.advanced.ExceptionPromptV2` | — | Show error/empty states with richer customization — custom illustrations, retry actions, detailed error descriptions |
| `@ohos.arkui.advanced.Filter` | — | Narrow down a list by multiple criteria — price range, rating, category — with a filter panel UI |
| `@ohos.arkui.advanced.FoldSplitContainer` | — | Switch between single-pane and two-pane layouts when the device folds or unfolds |
| `@ohos.arkui.advanced.FormMenu` | — | Show a context menu — copy, share, delete, rename — anchored to the pressed position on long-press |
| `@ohos.arkui.advanced.FullScreenLaunchComponent` | — | Show a full-screen onboarding flow or splash screen before the main UI loads |
| `@ohos.arkui.advanced.GridObjectSortComponent` | `@crossplatform` | Reorder items in a grid — rearrange photos in an album, reorder app icons, or sort widgets by drag-and-drop |
| `@ohos.arkui.advanced.MultiNavigation` | — | Manage complex navigation — tab bar at root, stack within each tab, plus master-detail split — with coordinated multi-level routing |
| `@ohos.arkui.advanced.Popup` | — | Show a small overlay near a UI element — tooltip on hover, quick-action menu, or a brief informational popover |
| `@ohos.arkui.advanced.PopupV2` | — | Show popups with richer content — form inputs, nested lists, or animated entrance/exit transitions |
| `@ohos.arkui.advanced.ProgressButton` | — | Trigger a long-running action — uploading a file, processing payment, generating a report — and show progress directly on the button |
| `@ohos.arkui.advanced.ProgressButtonV2` | — | Show more button states — indeterminate mode, pause/resume, cancel, or custom progress shapes beyond a simple ring |
| `@ohos.arkui.advanced.SegmentButton` | `@systemapi` | A segmented control — choose between "Day", "Week", "Month" views — with one segment highlighted at a time |
| `@ohos.arkui.advanced.SegmentButtonV2` | `@systemapi` | Segment controls with more segments, scrolling overflow, or a richer selected-state appearance |
| `@ohos.arkui.advanced.SelectTitleBar` | — | Switch the title bar into selection mode — checkboxes appear, selected count is shown, action buttons change to "Delete", "Move", "Share" |
| `@ohos.arkui.advanced.SelectionMenu` | — | Show a floating toolbar with Delete, Copy, Move, Share for the current multi-selection |
| `@ohos.arkui.advanced.SplitLayout` | — | A master-detail layout on tablets — list on the left, content on the right — with draggable divider between panes |
| `@ohos.arkui.advanced.SubHeader` | — | Group content into logical sections with a consistent section header — "Today", "Yesterday", "Older" — with optional action links |
| `@ohos.arkui.advanced.SubHeaderV2` | — | Section headers with richer layout — count badges, expand/collapse toggles, or swipe-to-reveal actions |
| `@ohos.arkui.advanced.SwipeRefresher` | — | Pull down on a list to refresh content — pull-to-refresh for a news feed, inbox, or social media timeline |
| `@ohos.arkui.advanced.SwipeRefresherV2` | — | Customize pull-to-refresh — custom refresh animations, haptic feedback on trigger, or multi-stage refresh gestures |
| `@ohos.arkui.advanced.TabTitleBar` | — | Show tab labels in the title bar area that the user can swipe or tap between for multiple content tabs |
| `@ohos.arkui.advanced.ToolBar` | — | Display a persistent action bar — bottom toolbar with primary actions like Add, Edit, Search, Settings — always visible across screens |
| `@ohos.arkui.advanced.ToolBarV2` | — | Toolbars with richer controls — overflow menus for extra actions, collapsible sections, or dynamic action visibility |
| `@ohos.arkui.advanced.TreeView` | — | Display hierarchical data — file browser, org chart, category drill-down — with expand/collapse for nested levels |
| `@ohos.arkui.advanced.TreeViewV2` | — | Tree views with richer interactions — drag-and-drop reordering, multi-select with checkboxes, or lazy-loaded children |
| `@ohos.arkui.component` | — | Define any ArkUI component — import Column, Row, Text, Button, Image, List, ForEach, Scroll, enums (FlexAlign, ImageFit), and resource helpers ($r, $rawfile) |
| `@ohos.arkui.componentSnapshot` | — | Capture a screenshot of a component programmatically — generate thumbnail previews, save component state as an image, or create shareable snapshots |
| `@ohos.arkui.componentUtils` | `@systemapi` | Walk the component tree — find a component by ID, read its properties, or compute its screen coordinates |
| `@ohos.arkui.components.ArkDynamicLayout` | — | Generate layouts at runtime from data — render a form from a JSON schema, build a dashboard from a server response — without hardcoding the structure |
| `@ohos.arkui.components.ArkLazyColumnLayout` | — | Render a long list with complex item layouts and full control over lazy-loading and recycling behavior |
| `@ohos.arkui.components.ArkLazyWaterFlowLayout` | — | Display a waterfall/masonry layout with items of varying heights flowing into columns |
| `@ohos.arkui.components.SelectionContainer` | — | Select multiple items from a list — long-press to enter selection mode, tap to toggle items, show count of selected items |
| `@ohos.arkui.dragController` | — | Programmatically start or end a drag operation — trigger drag from a custom gesture, cancel a drag mid-flight, or handle drop targeting |
| `@ohos.arkui.drawableDescriptor` | `@systemapi` | Inspect drawable resources — read a drawable's intrinsic size, pixel format, or color profile before rendering |
| `@ohos.arkui.inspector` | — | Debug the UI hierarchy — traverse the component tree at runtime, print component bounds and properties, or find which view is at a given screen position |
| `@ohos.arkui.intelligence.imageGeneration` | — | Add AI image generation — generate illustrations from text prompts, create variations of user photos, or fill missing parts of an image |
| `@ohos.arkui.layoutAlgorithm` | — | Write a custom measure-and-layout algorithm when built-in containers (Column, Row, Flex, Grid) cannot achieve the desired arrangement |
| `@ohos.arkui.modifier` | `@crossplatform` | Apply style attributes (width, height, background, margin) to components dynamically from code rather than in build |
| `@ohos.arkui.node` | `@crossplatform` | Create, move, or modify UI nodes imperatively — build UIs from code without decorators, access FrameNodes, or manipulate the component tree at runtime |
| `@ohos.arkui.observer` | `@crossplatform` | Listen for component lifecycle (attach/detach), layout changes, or rendering completion to trigger side effects |
| `@ohos.arkui.performanceMonitor` | `@systemapi` | Measure frame rate, layout duration, or rendering performance to debug jank and optimize UI |
| `@ohos.arkui.shape` | — | Draw vector shapes — Circle, Rect, Path, Ellipse, Polygon, Polyline — for icons, charts, diagrams, or custom graphics |
| `@ohos.arkui.stateManagement` | — | Reactive state — import @State, @Link, @PropRef, @Provide, @Consume, @Watch, @StorageLink, @StorageProp for automatic UI re-render on state changes |
| `@ohos.arkui.theme` | — | Apply system-wide theming — dark/light mode colors, fonts, and component style tokens to the entire app |
| `@ohos.arkui.uiExtension` | `@systemapi` | Embed a UIExtensionAbility's UI — host a widget, sharing sheet, or other app's extension surface |
| `@ohos.arkui.uiMaterial` | `@systemapi` | Pre-built Material Design components with consistent system-level styling and theming |
| `@ohos.file.AlbumPickerComponent` | — | Browse and select a photo album from the device gallery |
| `@ohos.file.PhotoPickerComponent` | — | Pick one or more photos from the device gallery for upload, profile picture, or sharing |
| `@ohos.file.RecentPhotoComponent` | — | Show recently taken photos inline — quick-access recent photos in a chat attachment bar or editor |
| `@ohos.pluginComponent` | `@systemapi` | Embed a third-party plugin's UI surface into the component tree |
| `@ohos.arkui.component` | — | Define a reusable custom component — the `customComponent` base type for building your own UI components with @Component decorator |
| `@ohos.arkui.component` | `@systemapi` | `depthComponent` — Apply spatial depth/z-order layering effects — stack components with 3D-like depth ordering |
| `@ohos.arkui.component` | `@systemapi` | `distortionComponent` — Apply visual distortion effects — wave, ripple, or lens-like image deformation on a component |
| `@ohos.arkui.component` | `@systemapi` | `dynamicComponent` — Host a container that loads components dynamically at runtime from external sources |
| `@ohos.arkui.component` | `@systemapi` | `effectComponent` — Apply visual post-processing effects — blur, shadow, glow, or color transformations — to a component subtree |
| `@ohos.arkui.component` | — | `embeddedComponent` — Host an external UI component (from another module or plugin) inside the component tree |
| `@ohos.arkui.component` | — | `extendableComponent` — Use a component base type that supports extension patterns — build a component that others can inherit from and customize |
| `@ohos.arkui.component` | `@systemapi` | `formComponent` — Embed a Form widget (home screen widget) into the app's UI |
| `@ohos.arkui.component` | — | `indicatorcomponent` — Show a page indicator dot bar showing scroll/swipe progress — onboarding carousel, image gallery, or content pages |
| `@ohos.arkui.component` | `@systemapi` | `pluginComponent` — Embed a third-party plugin's UI surface into the component tree |
| `@ohos.arkui.component` | `@systemapi` | `securityComponent` — Embed privacy-sensitive UI elements — location picker, save dialog, paste button — with system-guaranteed security |
| `@ohos.arkui.component` | `@systemapi` | `securityUIExtensionComponent` — Embed a security-verified UI extension component — protected pickers or dialogs from a trusted extension |
| `@ohos.arkui.component` | `@systemapi` | `uiExtensionComponent` — Embed UIExtensionAbility content — host a widget, sharing panel, or other extension UI surface in the component tree |
| `@ohos.arkui.component` | — | `uiPickerComponent` — Display a composite UI picker dialog — time picker, date picker, or option picker wrapped in a ready-to-use component |
| `@ohos.arkui.component` | `@systemapi` | `xcomponent` — Embed a native view (Camera, Map, WebView, 3D rendering surface) inside the ArkUI layout |

## App & Ability

107 modules — 54 public, 52 @systemapi, 10 deprecated, 105 in agentsdk

| Import name | Flags | Intent |
|---|---|---|
| `@ohos.app.ability.Ability` | — | Define any type of ability (UIAbility, Service, Extension) — the base class all abilities inherit from |
| `@ohos.app.ability.AbilityConstant` | `@systemapi` `@deprecated` `@crossplatform` | Check why an ability was launched (onNewIntent reason), determine ability type, or interpret result codes |
| `@ohos.app.ability.AbilityLifecycleCallback` | `@crossplatform` | Observe and react to ability lifecycle events — onCreate, onDestroy, onForeground, onBackground |
| `@ohos.app.ability.AbilityStage` | `@crossplatform` | Run app-level initialization — register lifecycle callbacks, set up global config, or initialize SDKs before any ability runs |
| `@ohos.app.ability.ActionExtensionAbility` | `@deprecated` | Expose a share-sheet action — handle Share, Copy, Save, or custom actions from the system share menu |
| `@ohos.app.ability.AppServiceExtensionAbility` | — | Run a long-running background service extension — music playback, file sync, or data processing while the app is minimized |
| `@ohos.app.ability.ApplicationStateChangeCallback` | `@crossplatform` | Monitor whether the app is in foreground or background to pause/resume timers, animations, or network requests |
| `@ohos.app.ability.AtomicServiceOptions` | — | Configure how an atomic service (mini-app) launches — floating window mode, split screen, or full screen |
| `@ohos.app.ability.AutoFillExtensionAbility` | `@systemapi` | Build a password manager or autofill provider that fills usernames, passwords, and form fields in other apps |
| `@ohos.app.ability.ChildProcess` | — | Spawn a separate child process — offload heavy computation, run a renderer, or isolate unstable code |
| `@ohos.app.ability.ChildProcessArgs` | — | Configure startup parameters for a child process — entry point, arguments, and isolation flags |
| `@ohos.app.ability.ChildProcessOptions` | — | Configure lifecycle and isolation settings for a child process — sandbox level, memory limits, and resource constraints |
| `@ohos.app.ability.CompletionHandler` | — | Handle the result of an async ability operation — ability start result, service connection result |
| `@ohos.app.ability.CompletionHandlerForAbilityStartCallback` | — | Launch an ability with a typed callback to handle its start result — success, failure, or cancellation |
| `@ohos.app.ability.CompletionHandlerForAtomicService` | — | Launch an atomic service (mini-app) with a typed callback to handle its operation result |
| `@ohos.app.ability.Configuration` | `@crossplatform` | Read the current system configuration — locale, orientation, screen density, color mode, or font scale |
| `@ohos.app.ability.ConfigurationConstant` | `@crossplatform` | Detect what changed in system configuration — orientation flipped, locale switched, dark mode toggled, or font size adjusted |
| `@ohos.app.ability.DriverExtensionAbility` | — | Build a hardware driver extension that provides access to a peripheral or hardware component from user space |
| `@ohos.app.ability.EmbeddedUIExtensionAbility` | — | Embed an extension's UI in the same process as the host — lighter-weight than full UIExtensionAbility for in-app extensions |
| `@ohos.app.ability.EnvironmentCallback` | — | React to environment changes — system locale, language, or regional settings updates — across the app |
| `@ohos.app.ability.ExtensionAbility` | — | Define any type of extension ability — the base class for all extension scenarios (widgets, sharing, services, drivers) |
| `@ohos.app.ability.InsightIntentContext` | — | Implement an insight intent handler and need context — query intent parameters, access resources, and manage lifecycle |
| `@ohos.app.ability.InsightIntentDecorator` | — | Declare which insight intents your app can handle — register intent handlers that the system can discover and dispatch |
| `@ohos.app.ability.InsightIntentEntryExecutor` | — | Route incoming insight intents to the correct handler at the entry point |
| `@ohos.app.ability.InsightIntentExecutor` | — | Implement the core logic that processes a matched insight intent — execute the action, prepare results, and report completion |
| `@ohos.app.ability.InteropAbilityLifecycleCallback` | — | Run an ability in interoperability mode (cross-platform runtime) — observe its lifecycle events |
| `@ohos.app.ability.MediaControlExtensionAbility` | `@systemapi` | Build a media app that needs to appear in the system media control panel — playback controls, track info, and transport buttons |
| `@ohos.app.ability.OpenLinkOptions` | — | Open a deep link or URL — control how it opens — app chooser, specific browser, or background behavior |
| `@ohos.app.ability.PhotoEditorExtensionAbility` | — | Build a photo editing extension that the system gallery can invoke — crop, filters, annotations, or other edits on selected images |
| `@ohos.app.ability.PrintExtensionAbility` | `@systemapi` | Build a custom printer driver extension — register a printer that the system print dialog can discover and print to |
| `@ohos.app.ability.ServiceExtensionAbility` | `@systemapi` | A long-running background service — download manager, health monitor, location tracker, or sync engine |
| `@ohos.app.ability.ShareExtensionAbility` | — | Receive shared text, images, files, or links from other apps |
| `@ohos.app.ability.StartOptions` | `@systemapi` | Launch an ability — fine-grained control — window mode (floating, split), display ID, or custom animations |
| `@ohos.app.ability.UIAbility` | `@crossplatform` | `UIAbilityContext` — Build any app with a user interface — the UIAbility base class (and UIAbilityContext) for your app's main entry point with a screen |
| `@ohos.app.ability.UIExtensionAbility` | — | Widgets, sharing panels, file pickers, or any extension with a visual surface |
| `@ohos.app.ability.UIExtensionContentSession` | `@systemapi` | Manage the lifecycle of embedded extension content — create, update, and destroy extension UI sessions from the host side |
| `@ohos.app.ability.UIServiceExtensionAbility` | `@systemapi` | Build a system-level UI service — status bar tile, notification shade widget, or quick settings panel |
| `@ohos.app.ability.UserAuthExtensionAbility` | `@systemapi` | Build a custom authentication method — biometric unlock app, third-party identity provider, or custom PIN entry |
| `@ohos.app.ability.Want` | `@crossplatform` | Pass data between abilities — the standard intent object with action, URI, bundle name, and extra parameters |
| `@ohos.app.ability.abilityDelegatorRegistry` | `@crossplatform` | Set up an automated test harness — register ability delegators to control ability lifecycle during integration tests |
| `@ohos.app.ability.abilityManager` | `@systemapi` `@deprecated` | Query or manage running abilities, processes, and mission stacks — list recent apps, check if an ability is running, or kill a process |
| `@ohos.app.ability.appManager` | `@systemapi` `@deprecated` | Query which apps are running and their states — is app X in foreground, list all running apps, or get app process info |
| `@ohos.app.ability.appRecovery` | — | The app to automatically recover after a crash — save state before crash and restore the last screen and data on restart |
| `@ohos.app.ability.application` | `@systemapi` | Define app-level configuration — the Application base class where you set global app settings, register callbacks, and initialize services |
| `@ohos.app.ability.autoFillManager` | `@systemapi` | Interact with the system autofill service — request autofill for a form field, integrate password manager suggestions, or trigger save prompts |
| `@ohos.app.ability.autoStartupManager` | `@systemapi` | Start automatically at device boot — alarm clock, health monitor, or always-on background service |
| `@ohos.app.ability.childProcessManager` | — | Spawn and manage child processes — start a subprocess, send/receive IPC messages, monitor child process health |
| `@ohos.app.ability.common` | `@systemapi` `@crossplatform` | `Context` — The `Context` base type and common ability types — AbilityStage, Context, UIExtensionContentSession — shared across all ability scenarios |
| `@ohos.app.ability.contextConstant` | `@systemapi` | Identify or compare context types — constants that distinguish UIAbilityContext, ServiceExtensionContext, FormExtensionContext, etc. |
| `@ohos.app.ability.continueManager` | — | Want to hand off their current task from one device to another — start watching a video on phone, pick it up on tablet |
| `@ohos.app.ability.dataUriUtils` | — | Parse or construct data:// URIs — extract MIME type, ID, or path from a data URI, or build one from components |
| `@ohos.app.ability.dialogRequest` | — | Show a dialog to another ability — request a modal dialog interaction across ability boundaries |
| `@ohos.app.ability.dialogSession` | `@systemapi` | Manage the full lifecycle of a cross-ability dialog — create session, send requests, receive responses, and close the dialog |
| `@ohos.app.ability.errorManager` | `@crossplatform` | Capture and handle ability lifecycle errors — crashes, load failures, or unresponsive abilities in your app |
| `@ohos.app.ability.hyperSnapManager` | — | Take screenshots or snapshots programmatically — capture a screenshot of an ability, save to gallery, or use for app previews |
| `@ohos.app.ability.insightIntent` | `@systemapi` | Declare contextual intents — "play music", "navigate to work", "order coffee" — that the system AI can surface proactively to users |
| `@ohos.app.ability.insightIntentDriver` | `@systemapi` | Route and dispatch insight intents — the driver layer that matches incoming intents to registered handlers |
| `@ohos.app.ability.insightIntentProvider` | — | Publish your app's intent capabilities to the system — tell the system which user intents your app can handle for proactive suggestions |
| `@ohos.app.ability.kioskManager` | `@systemapi` | Configure a device in kiosk/lockdown mode — restrict to a single app, disable system UI, for retail, education, or enterprise deployments |
| `@ohos.app.ability.missionManager` | `@systemapi` `@deprecated` | `MissionDeviceInfo` — Query or manage the mission (recent apps) stack — list recent missions, lock a mission, or move a mission to front |
| `@ohos.app.ability.quickFixManager` | `@systemapi` | Deploy a hotfix to your app without requiring users to reinstall — patch a critical bug or security issue in the running app |
| `@ohos.app.ability.scriptManager` | — | Manage the lifecycle and execution of agent scripts — start, pause, resume, or terminate automated UI/navigation scripts |
| `@ohos.app.ability.systemConfiguration` | — | Read current system configuration values — locale, orientation, screen density, color mode, or font scale |
| `@ohos.app.ability.verticalPanelManager` | `@systemapi` | Manage panel layouts on foldable devices — control panel visibility, size, and position when the device is folded or unfolded |
| `@ohos.app.ability.wantAgent` | `@systemapi` | A deferred intent — schedule a notification tap action, alarm trigger, or reminder that launches an ability later |
| `@ohos.app.ability.wantConstant` | `@systemapi` | Configure Want parameters — constants for action types, flag values, and entity types used in intent construction |
| `@ohos.app.appstartup.StartupConfig` | — | Define initialization task ordering at app startup — specify which SDKs, databases, or services load first, and their dependencies |
| `@ohos.app.appstartup.StartupConfigEntry` | — | Register an individual startup task — declare an entry with its dependencies, execution thread, and timeout |
| `@ohos.app.appstartup.StartupListener` | — | Know when a startup task finishes — execute follow-up logic after SDK initialization, DB migration, or config loading completes |
| `@ohos.app.appstartup.StartupTask` | — | Define a single initialization task — database setup, analytics SDK init, logging config — that runs during app launch in a defined order |
| `@ohos.app.appstartup.startupManager` | — | Orchestrate the full app initialization sequence — run all startup tasks in order, handle failures, and report completion |
| `@ohos.app.form.FormEditExtensionAbility` | — | Build a widget editing UI — provide the interface that appears when users long-press a widget and tap "Edit" to configure it |
| `@ohos.app.form.FormExtensionAbility` | `@systemapi` | Build a widget provider — the base class for creating, updating, and managing home-screen widget content |
| `@ohos.app.form.LiveFormExtensionAbility` | — | Build a widget that updates in real time — weather widget, stock ticker, live sports score, or countdown timer |
| `@ohos.app.form.formAgent` | `@systemapi` | Manage widget lifecycle — request widget updates, delete a widget, or query widget state from the host side |
| `@ohos.app.form.formBindingData` | — | Send structured data to a widget — pass key-value pairs, objects, or arrays that the widget template renders |
| `@ohos.app.form.formHost` | `@systemapi` | Embed and displaying a widget inside your app — host a home-screen widget within your own app's UI surface |
| `@ohos.app.form.formInfo` | `@systemapi` `@deprecated` | Query widget metadata and state — form dimensions, update interval, provider info, or current display state |
| `@ohos.app.form.formObserver` | `@systemapi` | Monitor widget lifecycle events — detect when a widget is added, removed, or updated on the home screen |
| `@ohos.app.form.formProvider` | `@systemapi` `@deprecated` | Publish and managing widgets — register a widget provider, trigger updates, or remove a widget from the system |
| `@ohos.application.AccessibilityExtensionAbility` | `@systemapi` `@deprecated` | Build an accessibility service — screen reader, voice control, or assistive technology that interacts with other apps on behalf of users |
| `@ohos.application.BackupExtensionAbility` | `@systemapi` | Your app data to participate in system backup/restore — mark data for backup, handle restore events, and migrate data across devices |
| `@ohos.application.DataShareExtensionAbility` | `@systemapi` | Provide a data source that other apps can query via URI — contacts DB, calendar provider, or custom content provider |
| `@ohos.application.DistributedExtensionAbility` | — | Build a distributed app feature — share data, actions, or UI across multiple devices in the same distributed network |
| `@ohos.application.DistributedExtensionContext` | — | Query remote device info, access distributed resources, or manage cross-device communication |
| `@ohos.application.NotificationSubscriberExtensionAbility` | — | Build a notification listener — read, filter, or process notifications from other apps for smart watch relay, notification log, or automation |
| `@ohos.application.NotificationSubscriberExtensionContext` | — | Access subscribed notification lists, manage notification channels, or filter by app |
| `@ohos.application.StaticSubscriberExtensionAbility` | `@systemapi` | Subscribe to system events at boot time — receive broadcast events, boot-completed signals, or system broadcasts without the app running |
| `@ohos.application.StaticSubscriberExtensionContext` | `@systemapi` | Access the triggering event data, query subscription info, or respond to broadcasts |
| `@ohos.application.formError` | `@systemapi` | Handle widget operation errors — identify why a widget update failed, detect invalid form IDs, or interpret form error codes |
| `@ohos.application.testRunner` | — | Run automated app tests — execute test suites, discover test cases, and report pass/fail results from the test framework |
| `@ohos.application.uriPermissionManager` | `@systemapi` | Grant temporary URI access permissions to another app — share a file URI with read/write permissions for a limited time |
| `@ohos.bundle.appControl` | `@systemapi` | Launch or control another app's process — start an app, stop an app, or enforce app launch policies |
| `@ohos.bundle.appDomainVerify` | `@systemapi` | Verify that your app owns a web domain — confirm app-website association for deep linking and verified app links |
| `@ohos.bundle.bundleManager` | `@systemapi` `@deprecated` `@crossplatform` | `BundlePackInfo` — Query installed app packages — list all installed apps, get app info, check permissions, or inspect bundle metadata |
| `@ohos.bundle.bundleMonitor` | `@systemapi` | Listen for for app install/update/uninstall events — detect when a new app is installed, updated, or removed on the device |
| `@ohos.bundle.bundleResourceManager` | `@systemapi` | Access resources from another app's bundle — read strings, images, or assets from a specific installed package |
| `@ohos.bundle.defaultAppManager` | `@systemapi` | Query or set default app handlers — check which app opens links, handles images, or plays media by default |
| `@ohos.bundle.distributedBundleManager` | `@systemapi` | Query apps installed on remote devices in a distributed network — find which apps are available on a tablet, watch, or TV |
| `@ohos.bundle.freeInstall` | `@systemapi` | On-demand app or module installation — download and install an app feature module only when the user needs it |
| `@ohos.bundle.installer` | `@systemapi` `@deprecated` | Install or updating apps programmatically — trigger APK/package install, monitor install progress, or handle install errors |
| `@ohos.bundle.launcherBundleManager` | `@systemapi` | `LauncherAbilityResourceInfo` — Build a launcher app and need to query launchable abilities — get app icon, label, and entry ability for all installed apps |
| `@ohos.bundle.overlay` | `@systemapi` | Apply theme or skin overlays — change app icons, colors, fonts, or layouts via a system overlay package |
| `@ohos.bundle.pluginBundleManager` | — | Manage plugin modules — install, uninstall, enable, or disable app plugins that extend your app's functionality |
| `@ohos.bundle.shortcutManager` | `@systemapi` | Add dynamic shortcuts to the home screen — create "New Message", "Play Favorites", or "Scan QR" shortcuts that users can add |
| `@ohos.enterprise.adminManager` | `@systemapi` | Build an MDM/enterprise admin app — manage device policies, enforce security settings, and control app installations across fleet devices |
| `@ohos.enterprise.securityManager` | `@systemapi` | Manage enterprise security policies — enforce password rules, disk encryption, camera restrictions, or VPN requirements on managed devices |

## Data & Storage

17 modules — 6 public, 10 @systemapi, 2 deprecated, 17 in agentsdk

| Import name | Flags | Intent |
|---|---|---|
| `@ohos.data.DataShareResultSet` | `@systemapi` | Iterate over query results from DataShare — accessing rows and columns of cross-app shared data |
| `@ohos.data.UdmfComponents` | — | Unified Data Management Framework (UDMF) component types — cross-app data drag-and-drop or paste operations |
| `@ohos.data.ValuesBucket` | `@crossplatform` | Pass a key-value set for inserting or updating rows in relational databases or DataShare operations |
| `@ohos.data.cloudData` | `@systemapi` | Sync local app data with the cloud — cloud backup, restore, and data change notifications |
| `@ohos.data.cloudExtension` | `@systemapi` | Extend cloud sync behavior — implement custom cloud sync logic for your app's data |
| `@ohos.data.commonType` | `@crossplatform` | Shared type definitions (Asset, File, Folder, Form, etc.) used across data services, clipboard, and drag-drop operations |
| `@ohos.data.dataShare` | `@systemapi` | Share data between applications via URI-based DataShare — create or consume shared data providers |
| `@ohos.data.dataSharePredicates` | `@systemapi` `@crossplatform` | Build filter conditions (equal, like, between, in, etc.) for DataShare queries against shared data |
| `@ohos.data.distributedDataObject` | `@deprecated` | A real-time distributed object that auto-syncs state across devices — deprecated; prefer distributedKVStore |
| `@ohos.data.distributedKVStore` | `@systemapi` `@crossplatform` | A distributed key-value database that syncs data between devices in a trusted network — cross-device data sharing and collaboration |
| `@ohos.data.intelligence` | — | On-device data intelligence — schema extraction, entity recognition, and metadata generation from local data |
| `@ohos.data.preferences` | `@crossplatform` | Persist lightweight key-value app settings, user preferences, or configuration flags across app restarts |
| `@ohos.data.relationalStore` | `@systemapi` `@crossplatform` | A local SQLite relational database — structured data with tables, SQL queries, transactions, and result sets |
| `@ohos.data.unifiedDataChannel` | `@systemapi` `@crossplatform` | Transfer structured data (text, images, files) between apps via the unified data channel — drag-drop and copy-paste data exchange |
| `@ohos.data.uniformDataStruct` | — | Standardized uniform data struct types (text, image, file, plainText, hyperlink, etc.) for UDMF-based data exchange |
| `@ohos.data.uniformTypeDescriptor` | `@systemapi` `@crossplatform` | Describe or match MIME-like uniform data types for cross-app data exchange and clipboard operations |
| `@ohos.pasteboard` | `@systemapi` `@deprecated` `@crossplatform` | Read from or write to the system clipboard — copy-paste operations with text, images, and UDMF data |

## Multimedia

17 modules — 7 public, 10 @systemapi, 7 deprecated, 17 in agentsdk

| Import name | Flags | Intent |
|---|---|---|
| `@ohos.multimedia.MovingPhotoView` | `@systemapi` | Display live/motion photos with playback controls — embed interactive motion photo previews in your UI |
| `@ohos.multimedia.audio` | `@systemapi` `@deprecated` `@crossplatform` | Audio playback, recording, volume control, or audio routing — playing audio files, capturing microphone input, and managing audio streams |
| `@ohos.multimedia.audioHaptic` | `@systemapi` | Synchronized audio and haptic (vibration) feedback — coordinated sound-and-vibration effects in ringtones, notifications, or interactive UI |
| `@ohos.multimedia.avCastPicker` | `@crossplatform` | Present a UI for users to select a cast or screen-mirroring target device |
| `@ohos.multimedia.avCastPickerParam` | — | Configure parameters (device filters, mode) passed to the AV cast picker UI |
| `@ohos.multimedia.avInputCastPicker` | — | Present a UI for users to select an input casting source (camera, microphone) from available devices |
| `@ohos.multimedia.avMusicTemplate` | `@systemapi` | Display a music player notification (album art, track info, playback controls) in the system notification panel |
| `@ohos.multimedia.avVolumePanel` | — | Embed a system-style volume control panel in your UI for adjusting media, call, or ringtone volume |
| `@ohos.multimedia.avsession` | `@systemapi` `@deprecated` | Expose media session controls — report playback state, track metadata, and handle transport controls (play, pause, skip) from system UI |
| `@ohos.multimedia.camera` | `@systemapi` `@deprecated` | Camera capture — taking photos, recording video, controlling flash, focus, zoom, and switching cameras |
| `@ohos.multimedia.cameraPicker` | — | Launch the system camera UI to let the user take a photo or record video and return the result to your app |
| `@ohos.multimedia.drm` | — | Play DRM-protected content — license acquisition, content decryption, and enforcing playback rights |
| `@ohos.multimedia.image` | `@systemapi` `@deprecated` `@crossplatform` | Image processing — decoding/encoding image files, transforming pixels, creating PixelMaps, and manipulating image properties |
| `@ohos.multimedia.media` | `@systemapi` `@deprecated` `@crossplatform` | Media playback, recording, or transcoding — creating AVPlayers to play audio/video, AVRecorders to capture media, and transcoding between formats |
| `@ohos.multimedia.systemSoundManager` | `@systemapi` `@deprecated` | Play system sounds — ringtones, alarm tones, notification sounds, and UI feedback clicks |
| `@ohos.multimedia.videoProcessingEngine` | — | Advanced video processing — building transformation pipelines with filters, scaling, rotation, color adjustment, and format conversion |
| `@ohos.vibrator` | `@systemapi` `@deprecated` `@crossplatform` | Trigger device vibration — haptic feedback on button presses, custom vibration patterns, and notification alerts |

## Communication

39 modules — 10 public, 26 @systemapi, 7 deprecated, 28 in agentsdk

| Import name | Flags | Intent |
|---|---|---|
| `@ohos.FusionConnectivity.PartnerAgentExtensionAbility` | — | Implement a partner agent extension ability for fusion connectivity scenarios |
| `@ohos.FusionConnectivity.PartnerAgentExtensionContext` | — | The context object for a fusion connectivity partner agent extension ability |
| `@ohos.FusionConnectivity.partnerAgent` | `@systemapi` | Multi-radio fusion connectivity — coordinating Wi-Fi, Bluetooth, and other radios for seamless device connectivity |
| `@ohos.FusionConnectivity.ranging` | — | Measure distance between devices using fusion connectivity — proximity detection and distance estimation |
| `@ohos.bluetooth.a2dp` | `@systemapi` `@crossplatform` | High-quality Bluetooth audio streaming (A2DP) — connect to speakers or headphones for stereo audio playback |
| `@ohos.bluetooth.access` | `@systemapi` `@crossplatform` | Check or request Bluetooth access permissions — determine if your app is allowed to use Bluetooth connections |
| `@ohos.bluetooth.bas` | `@systemapi` | Read battery level from a connected Bluetooth device using the Battery Service (BAS) profile |
| `@ohos.bluetooth.baseProfile` | `@systemapi` `@crossplatform` | Base types for implementing custom Bluetooth profiles — shared profile state, connection callbacks, and profile identifiers |
| `@ohos.bluetooth.ble` | `@systemapi` `@crossplatform` | Bluetooth Low Energy (BLE) — scanning BLE peripherals, advertising as a peripheral, connecting to GATT services, and reading/writing characteristics |
| `@ohos.bluetooth.common` | — | Common Bluetooth type definitions — device class constants, standard UUIDs, profile codes, and capability enums |
| `@ohos.bluetooth.connection` | `@systemapi` `@deprecated` `@crossplatform` | Manage Bluetooth connections — pairing, bonding, connecting/disconnecting devices, and querying connected profiles |
| `@ohos.bluetooth.constant` | `@systemapi` `@crossplatform` | Bluetooth constant values — profile ID enums, connection state constants, and Bluetooth error codes |
| `@ohos.bluetooth.hfp` | `@systemapi` | Hands-Free Profile (HFP) — routing phone call audio through a Bluetooth headset or car kit, including call answer/end/hold |
| `@ohos.bluetooth.hid` | `@systemapi` | Human Interface Device (HID) profile — connecting Bluetooth keyboards, mice, game controllers, or other input devices |
| `@ohos.bluetooth.map` | `@systemapi` | Message Access Profile (MAP) — exchanging SMS/MMS and email messages between devices over Bluetooth |
| `@ohos.bluetooth.opp` | `@systemapi` | Object Push Profile (OPP) — sending and receiving files (vCard, images, documents) between Bluetooth devices |
| `@ohos.bluetooth.pan` | `@systemapi` | Personal Area Network (PAN) profile — sharing internet connectivity or creating ad-hoc networks over Bluetooth |
| `@ohos.bluetooth.pbap` | `@systemapi` | Phone Book Access Profile (PBAP) — syncing contacts and call history from a phone to a car kit or headset |
| `@ohos.bluetooth.socket` | — | Raw Bluetooth socket communication — RFCOMM serial data streams or L2CAP channel connections between devices |
| `@ohos.bluetooth.wearDetection` | `@systemapi` | Detect and pair with Bluetooth wearables (watches, bands) — discovering nearby wearable devices and initiating pairing |
| `@ohos.distributedsched.abilityConnectionManager` | `@systemapi` | Connect to and call abilities running on other devices — distributed cross-device ability invocation |
| `@ohos.net.connection` | `@systemapi` `@crossplatform` | Query or monitor network connectivity — check if the device is online, detect network type (Wi-Fi, cellular, Ethernet), and get connection capabilities |
| `@ohos.net.eap` | — | Configure enterprise Wi-Fi with EAP authentication — setting up EAP-TLS, PEAP, or other enterprise Wi-Fi security profiles |
| `@ohos.net.ethernet` | `@systemapi` | Manage Ethernet connections — configuring static IP, checking Ethernet status, and monitoring Ethernet availability |
| `@ohos.net.http` | `@deprecated` `@crossplatform` | Make HTTP/REST API calls — create requests, set headers, send GET/POST/PUT/DELETE, and handle JSON/string responses |
| `@ohos.net.networkSecurity` | — | Configure network security — TLS settings, certificate pinning, and setting trusted CA certificates for your app's network requests |
| `@ohos.net.policy` | `@systemapi` | Enforce network policies — setting data usage limits, managing background data restrictions, and configuring network access rules |
| `@ohos.net.sharing` | `@systemapi` | Set up network sharing — configuring and enabling Wi-Fi hotspot, USB tethering, or Bluetooth tethering |
| `@ohos.net.socket` | `@crossplatform` | Raw TCP or UDP socket communication — custom protocols, direct server connections, and low-level network data exchange |
| `@ohos.net.statistics` | `@systemapi` | Network traffic statistics — tracking data usage by app, network interface, or UID, and querying traffic history |
| `@ohos.net.vpn` | `@systemapi` | Configure or manage VPN connections — starting/stopping VPN tunnels and querying VPN state |
| `@ohos.net.vpnExtension` | `@systemapi` | Implement a custom VPN client — create a VPN extension ability that handles tunnel establishment and packet forwarding |
| `@ohos.net.webSocket` | `@crossplatform` | Real-time bidirectional communication — WebSocket connections to send and receive messages over a persistent full-duplex channel |
| `@ohos.nfc.cardEmulation` | `@systemapi` `@deprecated` | NFC Host Card Emulation (HCE) — make your app respond to NFC readers as an emulated smart card (payment, access, transit) |
| `@ohos.nfc.controller` | `@deprecated` | Control the NFC adapter — enabling/disabling NFC and checking the NFC hardware state |
| `@ohos.nfc.tag` | `@systemapi` `@deprecated` | Read from or write to NFC tags — handling NDEF messages and interacting with various NFC tag technologies (ISO 15693, NfcA/B, Mifare, etc.) |
| `@ohos.rpc` | `@deprecated` | Inter-process communication (IPC) — Remote Procedure Calls between abilities, services, and system components via stub and proxy patterns |
| `@ohos.wifiManager` | `@systemapi` `@deprecated` `@crossplatform` | Manage Wi-Fi — scanning access points, connecting/disconnecting from networks, querying Wi-Fi state, and getting connection info (SSID, IP, RSSI) |
| `nfctech` | — | NFC tag technology type definitions — NFC-A, NFC-B, NFC-F, NFC-V, ISO-DEP, NDEF, and Mifare tag technology constants and operations |

## Security & Crypto

10 modules — 4 public, 5 @systemapi, 2 deprecated, 10 in agentsdk

| Import name | Flags | Intent |
|---|---|---|
| `@ohos.file.securityLabel` | — | Set or query a file's security classification level — applying data protection labels (S0-S4) to files and directories |
| `@ohos.security.cert` | `@deprecated` `@crossplatform` | Create or manage X.509 certificates — certificate encoding/decoding, extension querying, and certificate chain building |
| `@ohos.security.certManager` | `@systemapi` | Manage and validate X.509 certificates — certificate installation, revocation checking, CRL management, and trust anchor configuration |
| `@ohos.security.certManagerDialog` | — | Present a system dialog for the user to select a certificate — letting users choose a client certificate for authentication |
| `@ohos.security.cryptoFramework` | `@crossplatform` | Cryptographic operations — symmetric/asymmetric encryption, digital signing, hashing (SHA, MD), key generation (AES, RSA, ECC), and MAC computation |
| `@ohos.userIAM.companionDeviceAuth` | `@systemapi` | Authenticate a companion device — trusted device pairing and verifying that a companion device (watch, band) is authorized to interact with your app |
| `@ohos.userIAM.faceAuth` | `@systemapi` | Face authentication — enrolling facial data, authenticating users by face, and managing face recognition templates |
| `@ohos.userIAM.userAccessCtrl` | `@systemapi` | Gate a sensitive operation behind user authentication — require fingerprint, face, or PIN/password confirmation before executing protected actions |
| `@ohos.userIAM.userAuth` | `@systemapi` `@deprecated` | Authenticate the current user — triggering fingerprint, face, PIN, or password authentication and receiving auth result and tokens |
| `@ohos.userIAM.userAuthIcon` | — | Show a biometric authentication prompt icon — displaying fingerprint or face unlock icons in your app's auth UI flow |

## System & Device

59 modules — 13 public, 43 @systemapi, 16 deprecated, 59 in agentsdk

| Import name | Flags | Intent |
|---|---|---|
| `@ohos.InputMethodExtensionAbility` | — | Build a custom keyboard or input method — use InputMethodExtensionAbility as the base class for your IME implementation |
| `@ohos.InputMethodExtensionContext` | `@systemapi` `@deprecated` | The runtime context inside a custom input method extension — provides access to input method service lifecycle, window management, and resources |
| `@ohos.InputMethodSubtype` | — | Define keyboard layout variants — use InputMethodSubtype to declare subtypes like QWERTY, AZERTY, or number pad for your input method |
| `@ohos.account.appAccount` | `@deprecated` | Manage app-specific user accounts — creating, authenticating, and managing accounts scoped to your application |
| `@ohos.account.distributedAccount` | `@systemapi` `@deprecated` | Synchronize user accounts across distributed devices — cross-device account login state and credential sharing |
| `@ohos.account.osAccount` | `@systemapi` `@deprecated` | Manage system-level user accounts and profiles — creating, switching, or querying OS user accounts on the device |
| `@ohos.batteryInfo` | `@systemapi` | Read battery state — checking current charge level, charging status (plugged/unplugged), battery health, and temperature |
| `@ohos.batteryStatistics` | `@systemapi` | Audit power consumption — querying which apps or hardware components are draining the battery |
| `@ohos.brightness` | `@systemapi` | Adjust screen brightness programmatically — reading or setting the display brightness level |
| `@ohos.charger` | `@systemapi` | Detect charger connection and type — monitoring whether the device is plugged in and what type of charger (USB, wireless, fast charge) is connected |
| `@ohos.cooperate` | `@systemapi` `@deprecated` | Coordinated multi-screen workflows — enabling cross-device cooperation where multiple devices share a unified workspace |
| `@ohos.deviceInfo` | — | The device's model, brand, OS version, device type, or serial number — adaptive UI, analytics, or device identification |
| `@ohos.deviceStatus.dragInteraction` | `@systemapi` | Cross-device drag-and-drop — enabling users to drag content from one device screen to another |
| `@ohos.display` | `@systemapi` `@deprecated` `@crossplatform` | Screen and display information — querying screen resolution, refresh rate, display state (on/off), and display cutout areas |
| `@ohos.graphics.displaySync` | — | Vsync-aligned rendering — scheduling frame callbacks synchronized to the display refresh rate |
| `@ohos.inputMethod` | `@systemapi` `@deprecated` | Interact with the active keyboard or IME — showing/hiding the soft keyboard, switching input methods, or listening to keyboard state changes |
| `@ohos.inputMethod.ExtraConfig` | — | Advanced input method configuration — use ExtraConfig to pass custom settings (e.g., language, theme, correction options) to the IME |
| `@ohos.inputMethod.Panel` | — | Control the soft keyboard panel — use Panel for managing the input method panel's display state, size, and position |
| `@ohos.inputMethodEngine` | `@systemapi` `@deprecated` | Build a full custom keyboard application — use the input method engine for keyboard rendering, key processing, and candidate word management |
| `@ohos.inputMethodList` | — | List all installed keyboards and input methods — presenting an IME picker or checking available input method types |
| `@ohos.inputMethodSystemPanelManager` | `@systemapi` | Integrate with the system keyboard panel — managing the system-level input method panel and keyboard display |
| `@ohos.multimodalAwareness.deviceStatus` | `@systemapi` | Detect device posture, motion, or orientation — foldable posture states, device flip, or physical orientation changes |
| `@ohos.multimodalAwareness.metadataBinding` | `@systemapi` | Bind user context metadata to UI elements — associating awareness data such as user attention with specific components |
| `@ohos.multimodalAwareness.motion` | `@systemapi` | Recognize user gestures and movement patterns — detecting shakes, waves, or other physical gestures without touch input |
| `@ohos.multimodalAwareness.onScreen` | `@systemapi` | Detect whether the user is looking at the screen — attention-aware UI that adapts to user gaze |
| `@ohos.multimodalAwareness.spatialAwareness` | `@systemapi` | Spatial context about the device's environment — detecting nearby objects, spatial layout, or environmental context |
| `@ohos.multimodalAwareness.userStatus` | `@systemapi` `@deprecated` | Detect user activity and posture — recognizing whether the user is walking, sitting, standing, or running |
| `@ohos.multimodalInput.gestureEvent` | `@systemapi` | System-level gesture recognition — detecting global gestures such as back swipe or home gestures |
| `@ohos.multimodalInput.infraredEmitter` | `@systemapi` | Control the infrared emitter — sending IR signals for remote control or proximity detection |
| `@ohos.multimodalInput.inputConsumer` | `@systemapi` | Intercept raw input events before they reach apps — consuming touch, key, or pointer events at the system level |
| `@ohos.multimodalInput.inputDevice` | `@systemapi` `@deprecated` | Query connected input devices — discovering keyboards, mice, touchscreens, gamepads, and their capabilities |
| `@ohos.multimodalInput.inputEvent` | — | Work with raw input event data — accessing key codes, mouse coordinates, touch points, and event timestamps |
| `@ohos.multimodalInput.inputEventClient` | `@systemapi` | Subscribe to system input events — receiving keyboard, mouse, and touch events via a callback-based client |
| `@ohos.multimodalInput.inputMonitor` | `@systemapi` | Monitor or intercept input events globally — observing all input events across the system |
| `@ohos.multimodalInput.intentionCode` | — | Semantic input classification — use intentionCode constants to categorize input by user intent such as navigation, selection, or editing |
| `@ohos.multimodalInput.keyCode` | — | Key code constants — mapping physical or virtual keyboard keys to their standard key code values |
| `@ohos.multimodalInput.keyEvent` | — | Handle raw keyboard events — detecting key down, key up, and key repeat events with key code and modifier state |
| `@ohos.multimodalInput.mouseEvent` | — | Handle raw mouse events — tracking pointer movement, button clicks, scroll wheel, and mouse enter/leave |
| `@ohos.multimodalInput.pointer` | `@systemapi` | Customize the pointer or cursor appearance — changing cursor style, size, or visibility |
| `@ohos.multimodalInput.shortKey` | `@systemapi` | Register or manage system-wide keyboard shortcuts — defining and responding to global hotkey combinations |
| `@ohos.multimodalInput.touchEvent` | `@systemapi` | Handle raw multi-touch events — detecting finger down, move, up, and multi-touch gesture data |
| `@ohos.power` | `@systemapi` `@deprecated` | Manage device power state — controlling screen on/off, acquiring wake locks to prevent sleep, or initiating shutdown |
| `@ohos.resourceschedule.deviceStandby` | `@systemapi` | Manage low-power standby — transitioning the device into or out of standby mode to conserve battery |
| `@ohos.runningLock` | `@deprecated` | Keep the device awake during critical tasks — use runningLock to prevent the CPU from suspending while your operation completes |
| `@ohos.selectionInput.SelectionExtensionAbility` | `@systemapi` | Build a custom text selection service — use SelectionExtensionAbility as the base class for custom text selection and clipboard operations |
| `@ohos.selectionInput.SelectionExtensionContext` | `@systemapi` | The runtime context inside a custom selection extension — provides access to selection service lifecycle, selected content, and clipboard data |
| `@ohos.selectionInput.SelectionPanel` | `@systemapi` | Display a custom selection panel — use SelectionPanel for showing selection handles, copy/paste menus, and context actions |
| `@ohos.selectionInput.selectionManager` | `@systemapi` `@deprecated` | Programmatically manage text selection — selecting, deselecting, or manipulating selected text in input fields |
| `@ohos.systemCapability` | `@systemapi` | Check if a device supports a specific feature at runtime — querying hardware or software capabilities such as NFC, camera, or Bluetooth before using them |
| `@ohos.thermal` | `@deprecated` | Monitor device thermal state — checking temperature levels and whether thermal throttling is active to adjust performance |
| `@ohos.update` | `@systemapi` | Check for or initiate system updates — querying available OS updates and triggering download or installation |
| `@ohos.usbManager` | `@systemapi` `@deprecated` | Detect and interact with connected USB devices — enumerating USB peripherals, requesting permissions, and transferring data |
| `@ohos.usbManager.serial` | `@systemapi` | Serial-over-USB communication — connecting to and exchanging data with USB serial devices |
| `@ohos.wallpaper` | `@systemapi` `@deprecated` | Set the device wallpaper from your app — applying images as home screen or lock screen wallpaper |
| `@ohos.arkui.node` | — | Update component attributes programmatically — use `AttributeUpdater` for changing styles, properties, and layout of ArkUI components at runtime |
| `AutoStartupCallback` | `@systemapi` | Respond to auto-startup completion — use AutoStartupCallback to handle the result of an app's automatic launch on device boot |
| `AutoStartupInfo` | `@systemapi` | Configure auto-startup behavior — use AutoStartupInfo to specify conditions and settings for automatic app launch on device boot |
| `@ohos.distributedMissionManager` | `@systemapi` | `ContinueDeviceInfo` — Identify candidate devices for task migration — use to enumerate and describe devices that can receive a migrated task |
| `@ohos.app.ability.missionManager` | `@systemapi` | `MissionDeviceInfo` — Device capability info for task migration — use to query a remote device's ability to run a migrated mission |

## File & IO

22 modules — 10 public, 12 @systemapi, 2 deprecated, 22 in agentsdk

| Import name | Flags | Intent |
|---|---|---|
| `@ohos.file.BackupExtensionContext` | — | The runtime context inside a backup/restore extension — provides access to backup service lifecycle, storage paths, and data recovery operations |
| `@ohos.file.backup` | `@systemapi` | Back up or restore app data — triggering full or incremental backups and restoring application data from backup archives |
| `@ohos.file.cloudDiskManager` | `@systemapi` | Sync files with cloud disk storage — managing cloud disk file operations, sync status, and conflict resolution |
| `@ohos.file.cloudSync` | `@systemapi` | Synchronize files across devices via cloud — enabling, disabling, or checking the status of cloud file sync |
| `@ohos.file.cloudSyncManager` | `@systemapi` | Manage cloud file sync settings and policies — configuring sync behavior, checking sync progress, and handling sync conflicts |
| `@ohos.file.encryptedVolumeManager` | `@systemapi` | Manage encrypted storage volumes — creating, mounting, and accessing encrypted file volumes with password or key protection |
| `@ohos.file.environment` | `@systemapi` | Resolve standard storage paths — getting the app's sandbox directory, temp directory, or shared storage root paths |
| `@ohos.file.fileuri` | — | Convert between file paths and URIs — constructing file:// URIs from paths or extracting paths from URIs for file sharing |
| `@ohos.file.fs` | — | Direct file system access — opening, reading, writing, closing files, creating/deleting directories, or getting file metadata (stat) |
| `@ohos.file.hash` | `@crossplatform` | Compute file integrity checksums — generating MD5, SHA-1, or SHA-256 hashes to verify file integrity or detect duplicates |
| `@ohos.file.keyManager` | `@systemapi` | Manage file encryption keys — generating, storing, and rotating encryption keys for file-level security |
| `@ohos.file.photoAccessHelper` | `@systemapi` `@deprecated` `@crossplatform` | Read or write photos to the device gallery — accessing the system photo library to browse, import, or save images |
| `@ohos.file.picker` | `@systemapi` `@deprecated` `@crossplatform` | Let users pick files or directories — opening the system file picker dialog to select documents, images, or folders |
| `@ohos.file.statvfs` | `@crossplatform` | Filesystem capacity and usage info — checking total, available, and free space on a storage volume |
| `@ohos.file.storageStatistics` | `@systemapi` | Detailed storage usage statistics — querying total capacity, used space, and per-app storage consumption |
| `@ohos.file.volumeManager` | `@systemapi` | Query or manage storage volumes — listing mounted volumes, checking volume state, and mounting/unmounting storage |
| `@ohos.fileshare` | `@systemapi` | Share files between applications — passing file descriptors or URIs to other apps with access permissions |
| `@ohos.arkui.stateManagement` | — | Application-wide global state — use `appStorage` for sharing reactive state across all pages and components in your app |
| `@ohos.arkui.stateManagement` | — | Enhanced application-wide global state — use `appStorageV2` for improved reactive state management with better performance and type safety |
| `@ohos.arkui.stateManagement` | — | Page- or component-local reactive state — use `localStorage` for state that is scoped to a single page or component tree |
| `@ohos.arkui.stateManagement` | — | State that survives app restarts — use `persistentStorage` for automatically saving and restoring reactive state to disk |
| `@ohos.arkui.stateManagement` | — | Bind stored state to UI components — use `storageProperty` as a decorator for linking persistent or local state to component properties |

## Graphics & Window

22 modules — 8 public, 14 @systemapi, 4 deprecated, 22 in agentsdk

| Import name | Flags | Intent |
|---|---|---|
| `@ohos.PiPWindow` | `@systemapi` | Picture-in-picture video playback — use PiPWindow to display video in a floating overlay window while the user uses other apps |
| `@ohos.ability.screenLockFileManager` | `@systemapi` | Access files protected behind the lock screen — reading/writing files that are only accessible when the device is unlocked |
| `@ohos.animation.windowAnimationManager` | `@systemapi` | Custom window transition animations — defining enter, exit, and cross-window animations between pages or apps |
| `@ohos.effectKit` | `@systemapi` `@deprecated` `@crossplatform` | Visual effects on images or UI elements — applying blur, shadow, gradients, masking, and color filters |
| `@ohos.graphics.colorSpaceManager` | `@crossplatform` | Wide-gamut or HDR color management — converting between color spaces, checking HDR support, and managing display color profiles |
| `@ohos.graphics.common2D` | `@crossplatform` | 2D graphics primitive types — Point, Rect, Color, and other foundational 2D geometry and color data structures |
| `@ohos.graphics.drawing` | `@crossplatform` | Draw 2D graphics programmatically — Canvas drawing with Paint, Path, Text, and Image operations for custom rendering |
| `@ohos.graphics.hdrCapability` | — | Check if the display supports HDR — querying HDR format support, peak brightness, and color gamut before rendering HDR content |
| `@ohos.graphics.scene` | `@systemapi` | 3D scene rendering — setting up 3D scenes with camera positioning, lighting, mesh rendering, and material management |
| `@ohos.graphics.text` | `@crossplatform` | Advanced text layout and typesetting — measuring text, managing fonts, handling line breaks, and computing text metrics |
| `@ohos.graphics.uiEffect` | `@systemapi` | UI visual effects — applying blur, shadow, color filters, and lighting effects to ArkUI components |
| `@ohos.screen` | `@systemapi` `@deprecated` | Screen properties — querying screen size, density, orientation, and display cutout information |
| `@ohos.screenLock` | `@systemapi` `@deprecated` | Interact with the screen lock — locking the screen, checking lock state, or verifying the user's unlock credentials |
| `@ohos.screenshot` | `@systemapi` | Capture the screen programmatically — taking a screenshot of the current display content and saving it as an image |
| `@ohos.window` | `@systemapi` `@deprecated` `@crossplatform` | Manage app windows — creating windows, setting orientation, configuring status/navigation bars, or controlling window focus and layout |
| `@ohos.window.floatView` | — | A floating overlay window for PiP — use FloatView to embed video content in a movable, resizable floating window |
| `@ohos.window.floatingBall` | — | A floating ball overlay control — displaying a minimizable floating control that provides quick access to app features |
| `@ohos.graphics.drawing` | `@systemapi` | Low-level graphics rendering utilities — use `Graphics` for direct framebuffer access and hardware-accelerated drawing operations |
| `@ohos.arkui.component` | `@systemapi` | Share a window across devices — use `remoteWindow` to display content from a remote device's window in your local UI |
| `@ohos.arkui.component` | `@systemapi` | A full-screen display component — use `screen` for rendering content across the entire display surface |
| `@ohos.arkui.component` | `@systemapi` | A window-level rendering context — use `windowScene` as the root rendering node for a window's UI content |

## Sensors & Location

2 modules — 0 public, 2 @systemapi, 1 deprecated, 2 in agentsdk

| Import name | Flags | Intent |
|---|---|---|
| `@ohos.geoLocationManager` | `@systemapi` `@crossplatform` | Device location — getting current GPS/GNSS position, subscribing to continuous location updates, or setting up geofence triggers |
| `@ohos.sensor` | `@systemapi` `@deprecated` | Read physical sensor data — accessing accelerometer, gyroscope, magnetometer, proximity, ambient light, barometer, or heart rate sensors |

## Notification, Telephony & Bundle

28 modules — 7 public, 21 @systemapi, 10 deprecated, 28 in agentsdk

| Import name | Flags | Intent |
|---|---|---|
| `@ohos.notificationExtensionSubscription` | `@systemapi` | Configure a custom notification extension subscription — use `NotificationExtensionSubscriptionInfo` to define which notifications your extension should handle |
| `@ohos.notificationManager` | `@systemapi` `@deprecated` `@crossplatform` | Publish, cancel, or manage local notifications — alerting users with notification banners, badges, sound, and managing notification slots |
| `@ohos.notificationSubscribe` | `@systemapi` `@deprecated` | Subscribe to notifications published by other apps — use `NotificationExtensionSubscriptionInfo` to define notification listening filters |
| `@ohos.reminderAgentManager` | `@systemapi` | Schedule reminders, timers, or alarms — creating calendar-based reminders, countdown timers, and system alarms with custom triggers |
| `@ohos.telephony.call` | `@systemapi` `@deprecated` | Manage phone calls — dialing numbers, answering or rejecting incoming calls, hanging up, and monitoring call state |
| `@ohos.telephony.data` | `@systemapi` | Manage cellular data — enabling/disabling mobile data, configuring APN settings, and checking data connection state |
| `@ohos.telephony.esim` | `@systemapi` | Provision or manage eSIM profiles — downloading, activating, switching, or removing embedded SIM profiles |
| `@ohos.telephony.observer` | `@systemapi` | Observe telephony state changes — monitoring call state, network type, signal strength, and SIM state in real time |
| `@ohos.telephony.radio` | `@systemapi` `@deprecated` | Radio and network information — querying network type (4G/5G), signal strength, SIM state, and operator name |
| `@ohos.telephony.sim` | `@systemapi` | Query SIM card information — reading SIM state, ICCID, IMSI, operator name, and SIM lock status |
| `@ohos.telephony.sms` | `@systemapi` `@deprecated` | Send or manage SMS messages — sending text messages, reading incoming SMS, and managing message storage |
| `@ohos.telephony.vcard` | `@systemapi` | Parse or generate vCard contact data — importing/exporting contacts in vCard (.vcf) format |
| `@ohos.notificationManager` | — | Notification type definitions and enums — use `NotificationCommonDef` for standard notification content types, slot types, and status constants |
| `@ohos.notificationExtensionSubscription` | `@crossplatform` | Define custom notification extension content — use `NotificationExtensionContent` to specify the UI and data for your notification extension |
| `@ohos.notificationExtensionSubscription` | — | Configure notification extension subscriptions — use `NotificationExtensionSubscriptionInfo` to set up subscription filters and parameters |
| `@ohos.notification` | — | Define a notification's slot metadata — use `notificationSlot` to set the notification's ID, slot type, importance level, and delivery timing |
| `@ohos.notificationManager` | — | Interactive action buttons on notifications — use `notificationActionButton` to add Reply, Mark as Read, or custom action buttons to your notifications |
| `@ohos.notificationManager` | `@systemapi` `@deprecated` `@crossplatform` | Build notification content — use `notificationContent` to set the title, body text, picture, and tap intent for a notification |
| `@ohos.notificationManager` | `@systemapi` |Configure notification behavior flags — use `notificationFlags` to set sound, vibration, LED color, and privacy display options|
| `@ohos.notificationManager` | `@systemapi` `@deprecated` `@crossplatform` | Publish a notification — use `notificationRequest` to assemble all notification settings into a publishable request |
| `@ohos.notificationManager` | `@systemapi` `@deprecated` | Create a notification channel/slot — use `notificationSlot` to define a notification category with importance level, sound, vibration, and display settings |
| `@ohos.notificationManager` | `@systemapi` | Sort and rank notifications — use `notificationSorting` to define how notifications should be ordered in the notification center |
| `@ohos.notificationManager` | `@systemapi` | Ordered notification display data — use `notificationSortingMap` to access notifications sorted by priority, time, or custom rules |
| `@ohos.notificationSubscribe` | `@systemapi` | Filter which notifications to listen for — use `notificationSubscribeInfo` to specify app packages, notification types, or keywords to subscribe to |
| `@ohos.notificationSubscribe` | `@systemapi` `@deprecated` | Set up a notification subscriber — use `notificationSubscribeInfo` to configure a subscriber that receives callbacks when notifications are published |
| `@ohos.notificationManager` | — | A predefined notification layout template — use `notificationTemplate` for standard notification content patterns like big text, big picture, or inbox style |
| `@ohos.notificationManager` | — | Inline reply input on notifications — use `notificationUserInput` to let users type and send replies directly from the notification shade |
| `wantAgentInfo` | `@systemapi` `@deprecated` | Configure a deferred intent — use wantAgentInfo to set up a WantAgent that can be triggered later, such as from a notification tap or reminder |

## AI & Intelligence

3 modules — 2 public, 1 @systemapi, 0 deprecated, 3 in agentsdk

| Import name | Flags | Intent |
|---|---|---|
| `@ohos.ai.intelligentVoice` | `@systemapi` | Speech synthesis or voice interaction — text-to-speech, voice command recognition, and integrating voice assistant capabilities |
| `@ohos.ai.mindSporeLite` | — | On-device neural network inference — use MindSpore Lite to run pre-trained AI models locally without a network connection |
| `@ohos.intelligentScene` | — | Context-aware intelligent scene detection — recognizing user scenarios such as driving, sleeping, or meeting and adapting app behavior accordingly |

## Cross-device & Distributed

6 modules — 2 public, 4 @systemapi, 1 deprecated, 6 in agentsdk

| Import name | Flags | Intent |
|---|---|---|
| `@ohos.distributedDeviceManager` | `@systemapi` `@deprecated` | Discover and manage nearby distributed devices — finding, connecting to, and monitoring peer devices on the same network |
| `@ohos.distributedHardware.hardwareManager` | `@systemapi` | Access hardware on a remote device — using a remote device's camera, speaker, display, or other hardware as if it were local |
| `@ohos.distributedHardware.mechanicManager` | `@systemapi` | Discover and pair distributed hardware — finding available hardware resources on other devices and establishing connections |
| `@ohos.distributedMissionManager` | `@systemapi` | Migrate tasks across devices — continuing an app's current task (mission) from one device to another seamlessly |
| `@ohos.distributedsched.linkEnhance` | — | Optimize distributed network links — improving bandwidth, latency, and reliability of connections between distributed devices |
| `@ohos.distributedsched.proxyChannelManager` | — | Set up a distributed service proxy channel — creating and managing proxy connections to remote services across devices |

## Misc & Utilities

112 modules — 67 public, 38 @systemapi, 12 deprecated, 106 in agentsdk

| Import name | Flags | Intent |
|---|---|---|
| `@arkts.collections` | — | Specialized container types optimized for ArkTS static mode that offer better performance than standard collections |
| `@arkts.math.Decimal` | `@crossplatform` | Handle currency or financial calculations — high-precision decimal arithmetic that avoids floating-point rounding errors |
| `@ohos.WorkSchedulerExtensionAbility` | — | Schedule and execute background work — syncing, indexing, periodic cleanup — while the app is not in the foreground |
| `@ohos.annotation` | — | Define custom decorators and annotations — `@interface`, `@Retention` — for metadata-driven code generation and compile-time checks |
| `@ohos.app.agent.AgentExtensionAbility` | `@systemapi` | Build an AI agent extension that registers with the system and responds to agent lifecycle events — startup, teardown, service binding |
| `@ohos.app.agent.AgentUIExtensionAbility` | — | Render a UI — conversation cards, action panels, or interactive agent views — for user-facing agent interactions |
| `@ohos.buffer` | `@crossplatform` | Read, write, or manipulate raw binary data — network packets, file I/O, or encoding conversions — with typed accessors |
| `@ohos.configPolicy` | `@systemapi` | Read system-level feature flags, device-customized settings, and carrier-specific configuration policies |
| `@ohos.customization.customConfig` | — | Deploy to OEM or enterprise-managed devices — read custom configuration values set by the manufacturer or IT admin |
| `@ohos.hiSysEvent` | `@systemapi` | Report fault events, usage metrics, or system-level diagnostics to the device monitoring infrastructure |
| `@ohos.hiTraceChain` | — | Debug a distributed flow — trace a request across multiple devices or processes to identify cross-service bottlenecks |
| `@ohos.hiTraceMeter` | `@crossplatform` | Instrument code with trace markers — measuring method duration, tracking slow paths, or profiling startup and frame rendering |
| `@ohos.hichecker` | `@deprecated` | Debug — runtime detection of issues like slow operations on the main thread or excessive memory use during development |
| `@ohos.hidebug` | `@deprecated` | Profile your app — capture native heap dumps, CPU usage snapshots, or memory allocation traces |
| `@ohos.hilog` | `@crossplatform` | Emit structured log messages — tagged by domain, severity, and module — for debugging and production monitoring |
| `@ohos.hiviewdfx.FaultLogExtensionAbility` | — | Build a fault-reporting extension that collects and uploads crash logs, ANR traces, or system error reports from the device |
| `@ohos.hiviewdfx.FaultLogExtensionContext` | — | Data, configuration, and extension lifecycle resources |
| `@ohos.hiviewdfx.hiAppEvent` | `@crossplatform` | Track user behavior or application events — button taps, page visits, purchases — for analytics and monitoring |
| `@ohos.promptAction` | `@systemapi` | Show quick feedback to the user — a toast notification, a confirmation dialog, or a bottom action menu — without building custom UI |
| `@ohos.resourceManager` | `@deprecated` `@crossplatform` | Load bundled resources — strings, images, colors — by resource ID at runtime |
| `@ohos.resourceschedule.backgroundProcessManager` | — | Suspend, resume, or check the status of background processes that your app manages |
| `@ohos.resourceschedule.backgroundTaskManager` | `@systemapi` | Request a time window to finish work after the user leaves — completing a download, sync, or upload in the background |
| `@ohos.resourceschedule.systemload` | — | Check current CPU, memory, or I/O load on the device to decide whether to defer heavy work or throttle processing |
| `@ohos.resourceschedule.usageStatistics` | `@systemapi` | Query how often apps are used, screen time, or device usage patterns — for parental controls, digital wellbeing features, or usage reports |
| `@ohos.resourceschedule.workScheduler` | `@systemapi` `@deprecated` | Schedule work that runs only under the right conditions — device is idle, battery charging, WiFi connected, or at periodic intervals |
| `@ohos.settings` | `@systemapi` `@deprecated` | Read or modify system-level settings — volume, brightness, language — from within the app |
| `@ohos.systemParameterEnhance` | `@systemapi` | Query extended system properties — device model, OS build version, hardware features — beyond the standard parameter set |
| `@ohos.uiExtensionHost` | `@systemapi` | Embed UI content from another app or service — a payment sheet, a map, or a third-party widget — inside your own layout |
| `@ohos.url` | `@deprecated` `@crossplatform` | Navigate via deep links or you need to parse, construct, or extract URL components — scheme, host, path, query parameters |
| `@ohos.util.ArrayList` | `@crossplatform` | An expandable array — add and remove items dynamically with fast O(1) indexed read/write |
| `@ohos.util.Deque` | `@crossplatform` | Add or remove items efficiently from both the front and back — sliding window algorithms, undo history, or a work-stealing queue |
| `@ohos.util.HashMap` | `@crossplatform` | Fast key-value lookups — mapping user IDs to profiles, caching computed results, or building lookup tables |
| `@ohos.util.HashSet` | `@crossplatform` | Store unique items and check membership quickly — deduplicating IDs, tracking visited nodes, or building a deny-list |
| `@ohos.util.LightWeightMap` | `@crossplatform` | Store a small number of key-value pairs with lower memory overhead than HashMap — small caches or configuration maps |
| `@ohos.util.LightWeightSet` | `@deprecated` `@crossplatform` | Store a small number of unique items with lower memory overhead than HashSet — flag tracking or small whitelists |
| `@ohos.util.LinkedList` | `@crossplatform` | Frequent insertions and deletions at arbitrary positions — managing a playlist, an undo stack, or an ordered event queue |
| `@ohos.util.List` | `@crossplatform` | Design APIs that accept any ordered collection — the shared interface over ArrayList, LinkedList, and other list implementations |
| `@ohos.util.PlainArray` | `@crossplatform` | A key-value store keyed by integers — sparse arrays, ID-to-object mapping, or array-like data with gaps |
| `@ohos.util.Queue` | `@crossplatform` | First-in-first-out ordering — processing tasks in arrival order, buffering incoming messages, or implementing breadth-first search |
| `@ohos.util.Stack` | `@crossplatform` | Last-in-first-out ordering — parsing expressions, managing navigation back-stack, or implementing undo/redo |
| `@ohos.util.TreeMap` | `@crossplatform` | Key-value entries sorted by key — displaying a leaderboard, range queries, or ordered settings |
| `@ohos.util.TreeSet` | `@crossplatform` | Unique values maintained in sorted order — sorted suggestions, a ranked leaderboard, or ordered search results |
| `@ohos.util` | — | Any standard collection type — the unified import that re-exports all ArkTS collections from one module |
| `@ohos.util.stream` | `@crossplatform` | Chain functional operations — map, filter, reduce — over a collection without writing imperative for-loops |
| `@ohos.web.WebNativeMessagingExtensionAbility` | — | Build a web-messaging extension that enables your app's web content to send and receive messages with native code |
| `@ohos.web.WebNativeMessagingExtensionContext` | — | Context, message channels, and extension lifecycle resources |
| `@ohos.web.webNativeMessagingExtensionManager` | — | Create, connect, or manage web native messaging extension instances from the host app |
| `@ohos.xml` | `@deprecated` `@crossplatform` | Parse XML configuration files or RSS feeds, or serialize structured data into XML for external system integration |
| `AccessibilityExtensionContext` | `@systemapi` `@deprecated` | Build an accessibility service that needs to interact with the screen reader, retrieve node info, or perform accessibility actions on behalf of users |
| `AgentExtensionConnectCallback` | `@systemapi` | React to connection state changes — agent bound, disconnected, or service terminated — during lifecycle management |
| `AgentExtensionContext` | — | Service connections, ability lifecycle, and agent-specific resources |
| `@ohos.bundle.bundleManager` | `@systemapi` | `AppProvisionInfo` — Verify an app's provisioning profile — checking signing certificates, entitlements, and distribution permissions |
| `AppServiceExtensionContext` | — | Service lifecycle hooks, IPC channels, and extension configuration |
| `ApplicationContext` | `@systemapi` `@deprecated` `@crossplatform` | Global application context — accessing app-wide resources, environment info, and process-level lifecycle — outside any specific ability |
| `@ohos.bundle.bundleManager` | `@systemapi` `@deprecated` `@crossplatform` | `ApplicationInfo` — Inspect another app's metadata — its bundle name, version code, or installed device ID — for inter-app scenarios |
| `ApplicationStateObserver` | — | Monitor app lifecycle changes — foreground/background transitions, termination — for resource cleanup or analytics |
| `built-in` | — | `ArrayBuffer` — A fixed-size raw binary buffer — allocating memory for network payloads, file chunks, or low-level binary protocol encoding |
| `AutoFillExtensionContext` | `@systemapi` | Build an auto-fill service that provides users' saved passwords, addresses, or form data to apps during text input |
| `@ohos.bundle.bundleManager` | `@systemapi` | `BundleResourceInfo` — Fetch another app's display metadata — its icon, name, or description — for launcher displays or app management UI |
| `@ohos.distributedMissionManager` | `@systemapi` | `ContinueMissionInfo` — Supports cross-device task handoff — inspect or configure the state of a migrating task |
| `DriverExtensionContext` | — | Build a driver extension that needs runtime access to hardware abstraction, driver lifecycle hooks, and system service bindings |
| `@ohos.bundle.bundleManager` | — | `ExtensionAbilityInfo` — Query another app's extension abilities — their types, permissions, and configuration — for extension discovery and matching |
| `@ohos.app.ability.common` | — | `ExtensionContext` — Write any extension ability — the base context providing access to its own resources, theme, and service bindings |
| `ExtensionRunningInfo` | `@systemapi` | Inspect currently running extensions — their PID, uptime, and resource usage — for task management or diagnostics |
| `@ohos.arkui.component` | — | `FolderStackModifier` — Customize the visual style of a folder-stack layout — fold animation, cover flow, or layered card appearance |
| `FormEditExtensionContext` | — | Build a form editing extension that lets users customize widget appearance, data sources, or layout options |
| `FormExtensionContext` | `@systemapi` | Build a form widget — access to the widget lifecycle — creation, update, deletion — and its data-binding resources |
| `@ohos.app.ability.UIAbility` | — | `KioskStatus` — Deploy to kiosk or locked-down devices — check or configure kiosk mode — restricted app access, single-purpose mode, system bar visibility |
| `@ohos.bundle.launcherBundleManager` | `@systemapi` | `LauncherAbilityResourceInfo` — Build a custom launcher — display app icons, shortcuts, and names from installed apps on the home screen |
| `LiveFormExtensionContext` | `@systemapi` | Build a live-updating widget that shows real-time data — weather, stock prices, scores — and needs periodic refresh and data-binding hooks |
| `MediaControlExtensionContext` | `@systemapi` | Build media controls for the notification center — play/pause, skip, seek — with media session and command bindings |
| `@ohos.app.ability.missionManager` | `@systemapi` | `MissionCallbacks` — Support cross-device task migration — callbacks for migration start, progress, completion, or failure |
| `@ohos.app.ability.missionManager` | `@systemapi` | `MissionInfo` — Build a task-manager or recent-apps view — display task thumbnails, names, and running states |
| `@ohos.app.ability.missionManager` | `@systemapi` | `MissionListener` — React to task changes — a mission created, paused, resumed, or closed — for custom task-management behavior |
| `@ohos.app.ability.missionManager` | `@systemapi` | `MissionParameter` — Specify how a task should migrate to another device — target device, migration mode, and data-transfer options |
| `@ohos.app.ability.missionManager` | `@systemapi` | `MissionSnapshot` — Capture or retrieve a screenshot snapshot of a task — for the recent-apps card, task switcher, or migration preview |
| `@ohos.arkui.component` | — | `NavDestinationModifier` — Customize the visual style of a navigation destination page — transitions, background, or title bar appearance |
| `@ohos.arkui.component` | — | `NavigationModifier` — Customize the visual style of the navigation bar — bar appearance, back button style, or transition animations |
| `@ohos.bundle.bundleManager` | `@systemapi` | `PermissionDef` — Look up a system permission's definition — its name, user-facing description, and grant mode — for permission explanation UI |
| `PermissionRequestResult` | `@crossplatform` | User |
| `PhotoEditorExtensionContext` | — | Build a photo editor extension that provides cropping, filters, or adjustments to the system gallery or camera app |
| `PrintExtensionContext` | — | Build a print service extension that connects the device to a printer — handling job submission, status tracking, and printer discovery |
| `ProcessData` | — | The current process's runtime identity — PID, process name — for logging or diagnostics |
| `ProcessInformation` | `@crossplatform` | Monitor the current process's memory, CPU, and PID for diagnostics or resource tracking |
| `@ohos.arkui.component` | — | `RadioModifier` — Customize the look of radio buttons — selected color, size, disabled state — within a selection group |
| `@ohos.bundle.bundleManager` | `@systemapi` | `RecoverableApplicationInfo` — Support app data restoration — identify which apps have recoverable data — after device replacement, factory reset, or backup restore |
| `ScenePostProcessSettings` | — | Render 3D scenes — apply post-processing effects — bloom, color grading, or tone mapping — for visual polish |
| `SceneResources` | `@systemapi` | Build a 3D scene — load or manage rendering resources — textures, shader programs, and material definitions |
| `@ohos.arkui.component` | — | `SelectionContainerModifier` — Customize the visual style of text selection — selection handles, highlight color, or selection toolbars |
| `@ohos.app.ability.common` | `@systemapi` | `ServiceExtensionContext` — Build a background service extension that needs service lifecycle hooks, IPC connections, and system service bindings |
| `@ohos.arkui.component` | — | `StackModifier` — Customize the visual style of a stack layout — alignment, spacing, z-order, or clipping for overlapping children |
| `UIExtensionContext` | `@systemapi` | Component's lifecycle, layout, and data exchange |
| `UIServiceExtensionConnectCallback` | — | Success, failure, or disconnection events |
| `UIServiceExtensionContext` | `@systemapi` | Build a UI service extension — access to the rendering surface, lifecycle hooks, and client communication channels |
| `WorkSchedulerExtensionContext` | `@systemapi` | Build a work scheduler extension — access to work parameters, scheduling lifecycle, and task completion reporting |
| `@ohos.arkui.component` | `@systemapi` | `actionSheet` — Need to choose from a list of actions — share, delete, copy — presented as a bottom-sheet overlay |
| `built-in` | — | `annotation` — Define or use decorators — @Component, @State, @Prop — to declare UI components and their reactive state |
| `@ohos.app.ability.common` | — | `connectOptions` — Connect to another ability or service — specify connection parameters — flags, timeouts, or callback configuration |
| `@ohos.arkui.component` | — | `folderStack` — A foldable card-stack layout — folding and unfolding panels like a book cover, wallet, or layered card deck |
| `@ohos.arkui.component` | — | `navDestination` — Build multi-page navigation — define the content that appears when the user navigates to a specific route |
| `@ohos.arkui.component` | — | `navigation` — Has multiple screens — the navigation bar, back stack, and route management that drives page transitions |
| `@ohos.arkui.component` | — | `pageTransition` — Customize page transition animations — slide in/out, fade, shared-element — between navigation destinations |
| `permissions` | — | Reference system permission strings — camera, location, contacts — by constant name instead of hardcoded strings |
| `@ohos.app.ability.appManager` | — | `processInfo` — Identify the current app process — getting process name, PID, or status — for debugging or process-level operations |
| `@ohos.arkui.component` | — | `button` — Need to pick one option from a group — selecting a payment method, shipping speed, or filter setting — using radio button controls |
| `@ohos.arkui.component` | `@crossplatform` | `resources` — Reference or resolve app resources — $r() syntax, resource-to-value conversion — in your UI code |
| `@ohos.arkui.component` | — | `resource` — Manage app resource bundles — loading, releasing, or switching resource packs at runtime for theming or localization |
| `built-in` | — | `retention` — Control how annotations persist — source-only, binary, or runtime — for compile-time versus runtime annotation processing |
| `@ohos.arkui.component` | `@systemapi` | `stack` — Overlay content — a badge on an icon, text on an image, or a floating button over a list |
| `tagSession` | `@deprecated` | Interact with NFC tags — reading tag data, writing NDEF messages, or detecting tag types in real time |
| `@ohos.arkui.component` | `@systemapi` | `unionEffectContainer` — Combine multiple visual effects — blur, shadow, color overlay — on a single UI element for a composite result |
| `@ohos.arkui.component` | — | `utils` — Measure or lay out components programmatically — calculating text dimensions, child sizes, or custom alignment before rendering |

## Other

336 modules — 242 public, 89 @systemapi, 16 deprecated, 301 in agentsdk

| Import name | Flags | Intent |
|---|---|---|
| `@ohos.UiTest` | `@deprecated` `@crossplatform` | Write automated UI tests — query components, simulate clicks and swipes, and assert visual state |
| `@ohos.ability.ability` | — | Define any type of ability (UIAbility, Service, Extension) — the base class all abilities inherit from |
| `@ohos.ability.errorCode` | — | Check why an ability operation failed — look up the error code constants returned from ability lifecycle calls |
| `@ohos.abilityAccessCtrl` | `@systemapi` `@deprecated` `@crossplatform` | Request and verify runtime permissions — microphone, camera, location — from the user |
| `@ohos.accessibility` | `@systemapi` `@deprecated` `@crossplatform` | Build an accessibility service that provides screen reading, magnification, or interaction assistance to users with disabilities |
| `@ohos.accessibility.config` | `@systemapi` | Configure accessibility service settings — enable or disable capabilities, set service feature flags |
| `@ohos.animator` | — | Animate component properties — position, opacity, scale, rotation — over time with frame-by-frame control |
| `@ohos.app.agent.agentConstant` | `@systemapi` | Configure an app agent — use the enumeration values and constants for agent behavior settings |
| `@ohos.app.agent.agentManager` | `@systemapi` | Control an app agent's lifecycle — start, stop, pause, resume — and manage its operations |
| `@ohos.app.businessAbilityRouter` | `@systemapi` | Route business intents to the correct business ability based on action and data matching |
| `@ohos.base` | — | Build APIs that return results or errors — the `Callback<T>` and `BusinessError<T>` base types shared across the SDK |
| `@ohos.busManager.serial` | `@systemapi` | Read from and write to serial ports connected to external hardware |
| `@ohos.commonEventManager` | `@systemapi` `@deprecated` `@crossplatform` | Notify other parts of the system about an event, or listen for system-wide broadcasts like network changes and battery updates |
| `@ohos.curves` | — | Define how an animation accelerates or decelerates — pick from built-in ease, spring, and bezier timing curves |
| `@ohos.driver.deviceManager` | `@systemapi` `@deprecated` | Discover, enumerate, and manage externally connected hardware devices through their drivers |
| `@ohos.events.emitter` | `@crossplatform` | Decouple components with custom events — broadcast a named event from one part of the app and handle it in another |
| `@ohos.font` | — | Register font files and apply font family, weight, and style on text components |
| `@ohos.fontManager` | `@systemapi` | Dynamically load and manage font resources at runtime — install, uninstall, or enumerate available fonts |
| `@ohos.hiviewdfx.hiRetrieval` | — | Pull diagnostic and troubleshooting data from your app — retrieve crash logs, performance traces, and system state snapshots |
| `@ohos.hiviewdfx.jsLeakWatcher` | — | Detect and trace which objects are not being garbage-collected |
| `@ohos.i18n` | `@systemapi` `@deprecated` `@crossplatform` | Display locale-sensitive numbers, dates, and text — format currency, sort strings by locale rules, detect text direction |
| `@ohos.i18n` | `@systemapi` `@crossplatform` | Display locale-sensitive numbers, dates, and text — format currency, sort strings by locale rules, detect text direction |
| `@ohos.intl` | `@deprecated` `@crossplatform` | ECMAScript-standard internationalization — number formatting, date formatting, collation, and plural rules |
| `@ohos.intl` | `@crossplatform` | ECMAScript-standard internationalization — number formatting, date formatting, collation, and plural rules |
| `@ohos.logLibrary` | `@systemapi` | Manage log rotation, compression, and file-based logging pipelines |
| `@ohos.matrix4` | — | Apply 3D transformations — rotation, translation, scaling, perspective — to components using matrix math |
| `@ohos.measure` | — | Measure a component's rendered size before placing it — calculate text width, image dimensions, or layout bounds programmatically |
| `@ohos.mediaquery` | — | Build responsive layouts that adapt to screen width, height, or orientation — adjust columns, font sizes, or visibility at breakpoints |
| `@ohos.nearlink.advertising` | — | Broadcast its presence to nearby NearLink peers — advertise services and device capabilities for discovery |
| `@ohos.nearlink.cdsm` | — | Coordinate services across multiple NearLink devices — manage which device runs which service in a distributed setup |
| `@ohos.nearlink.constant` | `@systemapi` | Work with NearLink and need the protocol constants — version numbers, error codes, and capability flag values |
| `@ohos.nearlink.dataTransfer` | — | Exchange files or data directly — transfer photos, documents, or payloads between peers |
| `@ohos.nearlink.manager` | `@systemapi` | Scan for, pair with, and connect to nearby NearLink devices |
| `@ohos.nearlink.remoteDevice` | `@systemapi` | Information about a connected NearLink device — device name, address, connection state, and capabilities |
| `@ohos.nearlink.scan` | `@systemapi` | Actively scan the area for discoverable NearLink devices |
| `@ohos.nearlink.ssap` | `@systemapi` | Establish authenticated, encrypted channels between devices |
| `@ohos.print` | `@systemapi` `@deprecated` | Send documents or images to a printer — discover printers, configure print jobs, and manage the print queue |
| `@ohos.privacyManager` | `@systemapi` | Track user privacy consent — record permission grants, audit access logs, and manage privacy settings |
| `@ohos.request` | `@systemapi` `@deprecated` `@crossplatform` | Fetch data from a server or download files — send HTTP requests, upload content, or download large files with progress tracking |
| `@ohos.request.cacheDownload` | — | Download a file with local caching — skip re-downloading unchanged files by checking cached integrity before fetching |
| `@ohos.router` | — | Navigate between pages in your app — push new screens, pop back to previous, replace the current page, or manage the navigation history stack |
| `@ohos.scan` | `@systemapi` | Capture, crop, and enhance document scans from the camera — produce clean, readable document images |
| `@ohos.systemDateTime` | `@systemapi` `@deprecated` `@crossplatform` | Read the current device time or set the system clock programmatically |
| `@ohos.systemTimer` | `@systemapi` | A timer that survives app backgrounding — schedule callbacks that fire after a delay or repeat on an interval at the system level |
| `@ohos.test.PerfTest` | — | Benchmark app performance — measure startup time, frame rendering, memory usage, and operation latency in automated tests |
| `@ohos.transfer` | `@crossplatform` | Exchange data — pass structured payloads, streams, or file descriptors across process boundaries |
| `@ohos.uiAppearance` | `@systemapi` | Adapt to dark or light mode — detect the current system theme and switch your UI colors accordingly |
| `@ohos.uri` | `@deprecated` `@crossplatform` | Parse, construct, or manipulate URIs — extract scheme, host, path, and query parameters from URL strings |
| `@ohos.web.netErrorList` | — | Map the error code to a human-readable cause and show the user what went wrong |
| `@ohos.web.webview` | — | Display a web page inside a native screen — load URLs, inject JavaScript, and handle page navigation events |
| `@ohos.zlib` | `@deprecated` `@crossplatform` | Compress or decompress data — zip payloads for storage, unzip downloaded archives, or reduce network transfer sizes |
| `@system.mediaquery` | — | Build responsive layouts that adapt to device characteristics — query screen dimensions, orientation, or aspect ratio at the system level |
| `AbilityDelegator` | `@crossplatform` | Test abilities in isolation — monitor lifecycle events, trigger state transitions, and verify ability behavior under test |
| `@ohos.app.ability.UIAbility` | `@systemapi` | Know how long it took for the first frame to render — monitor and optimize cold-start performance |
| `@ohos.app.ability.UIAbility` | `@systemapi` | A callback the moment the first frame finishes rendering — trigger post-render actions or measure startup latency |
| `@ohos.app.ability.UIAbility` | `@systemapi` | React to an ability moving to the foreground or background — pause/resume animations, sync data, or adjust resource usage |
| `@ohos.bundle.bundleManager` | `@crossplatform` | Read an ability's declared metadata at runtime — name, type, requested permissions, and launch mode |
| `AbilityMonitor` | `@crossplatform` | Watch ability lifecycle events during testing — detect when an ability starts, stops, or changes state |
| `AbilityRunningInfo` | — | A snapshot of which abilities are currently running and their active states |
| `AbilityStageContext` | `@crossplatform` | Before any ability instance is created |
| `AbilityStageMonitor` | `@crossplatform` | Observe the ability stage lifecycle — detect when the module-level initialization phase begins and ends |
| `AbilityStartCallback` | — | Launch an ability and know the outcome — success, failure, or error reason |
| `AbilityStateData` | — | A snapshot of what state an ability just moved to — FOREGROUND, BACKGROUND, or DESTROYED |
| `AgentCard` | — | Browse available AI agents on device and need metadata for display — agent name, description, icon, and capabilities |
| `AgentHostProxy` | — | Send messages to an embedded agent — forward user input and receive agent responses |
| `AgentProxy` | `@systemapi` | Send messages between an agent and its host across process boundaries |
| `@ohos.arkui.component` | — | Programmatically style or configure an alphabet indexer — set popup text, color, font size on the letter-scrub bar |
| `AppForegroundStateObserver` | `@systemapi` | React to the entire app moving to the foreground or background — control global resources or power state |
| `AppStateData` | — | A snapshot of the current application lifecycle state — active, inactive, or terminated |
| `built-in` | — | An ordered list of items — iterate, map, filter, reduce, or access elements by index |
| `@ohos.app.ability.autoFillManager` | `@systemapi` | Configure how the auto-fill popup appears — position, size, and visual style of the suggestion overlay |
| `@ohos.app.ability.autoFillManager` | `@systemapi` | Specify which screen region corresponds to an auto-fillable field — bounding box coordinates for username/password inputs |
| `@ohos.app.ability.autoFillManager` | `@systemapi` | Send the request data — form context, triggering field, and expected data type |
| `@ohos.app.ability.autoFillManager` | `@systemapi` | Know what caused the auto-fill — whether the user tapped a suggestion or it fired automatically on focus |
| `@ohos.app.ability.autoFillManager` | `@systemapi` | Tell the system what kind of data to auto-fill — password, address, payment card, or username |
| `@ohos.app.ability.common` | `@crossplatform` | Access app environment — resources, files, configuration, and base identity |
| `@ohos.arkui.component` | — | Programmatically style or configure a blank spacer — set width, height, color, or visibility of empty layout space |
| `built-in` | — | Work with boolean values — convert between types, toggle state, or evaluate truth conditions |
| `@ohos.arkui.node` | — | Create components programmatically from builder functions instead of declarative markup — generate dynamic UI trees at runtime |
| `@ohos.bundle.bundleManager` | `@systemapi` `@crossplatform` | Inspect a bundle package at runtime — read the app's name, version, included modules, and declared permissions |
| `@ohos.bundle.bundleManager` | `@systemapi` | Packaging metadata for app distribution — bundle format, compression settings, and packaging structure details |
| `BusinessAbilityInfo` | `@systemapi` | Business type, supported intents, and routing configuration |
| `@ohos.arkui.component` | — | Programmatically style or configure a button — set background, border, text style, and interaction feedback |
| `@ohos.arkui.component` | — | Programmatically style or configure a calendar picker — set date range, selected date, and visual appearance |
| `built-in` | — | Work with individual Unicode characters — iterate over text, classify character types, or build strings character-by-character |
| `@ohos.arkui.component` | — | Programmatically style or configure a checkbox group — set select all behavior, group colors, and spacing between checkboxes |
| `@ohos.arkui.component` | — | Programmatically style or configure a checkbox — set checked state, colors, shape, and size |
| `built-in` | — | Runtime class information — check inheritance, get class metadata, or perform reflective operations |
| `@ohos.arkui.component` | — | Programmatically style or configure a column layout — set alignment, spacing, padding, and distribution of children |
| `@ohos.arkui.component` | — | Programmatically style or configure a column split layout — set divider position, resizable pane behavior, and spacing |
| `@ohos.arkui.component` | — | Apply or override common style attributes — width, height, margin, padding, border, background — on any component |
| `@ohos.arkui.node` | — | Wrap dynamic content and embed it into a component tree — host changing content without rebuilding the parent layout |
| `built-in` | — | Print debug messages to the console — log values, trace execution, or format warning and error output |
| `@ohos.arkui.component` | — | Programmatically style or configure a container span — set text decoration, color, font, and click behavior on grouped inline spans |
| `@ohos.arkui.node` | — | Embed UI content into a container that exposes a named slot — fill template slots with dynamic content |
| `@ohos.app.ability.common` | `@systemapi` `@deprecated` `@crossplatform` | Access app-scoped resources — get resource strings, file paths, configuration info, and permission status |
| `@ohos.distributedMissionManager` | `@systemapi` | Describe a task that can be continued to another device — bundle the state and metadata needed for seamless handoff |
| `@ohos.distributedMissionManager` | `@systemapi` | Initiate cross-device task continuation and receive a callback to learn whether the handoff succeeded or failed |
| `@ohos.arkui.component` | — | Programmatically style or configure a counter stepper — set min/max, step size, button style, and increment/decrement behavior |
| `@ohos.app.ability.UIAbility` | `@systemapi` | Store custom data scoped to its lifecycle — attach arbitrary key-value pairs that persist while the ability is active |
| `@ohos.arkui.component` | — | Programmatically style or configure a data panel — set chart type, data series, colors, and axis labels |
| `built-in` | — | Create, parse, or compare dates and times — timestamp creation, date arithmetic, formatting, and timezone handling |
| `@ohos.arkui.component` | — | Programmatically style or configure a date picker — set date range, selected date, and appearance |
| `@ohos.bundle.bundleManager` | `@systemapi` | Define rules for how intents are dispatched to abilities — set matching priorities and routing filters |
| `@ohos.arkui.component` | — | Programmatically style or configure a divider — set thickness, color, margin, and orientation |
| `built-in` | — | 64-bit floating point precision — high-precision calculations, scientific computation, or values exceeding Int32 range |
| `@ohos.bundle.bundleManager` | — | Identify a specific ability within a bundle — construct an element name with bundle name, ability name, and optional module |
| `built-in` | — | Throw or catch errors with detailed diagnostics — attach a message and stack trace to a failure for debugging |
| `@ohos.app.ability.UIAbility` | `@crossplatform` | Communicate without coupling — dispatch and listen for named events within the ability's scope |
| `@ohos.arkui.component` | — | Programmatically style or configure a flex layout — set direction, wrap, alignment, and distribution of flex children |
| `@ohos.arkui.component` | `@systemapi` | Programmatically style or configure a form widget — set widget dimensions, update interval, and card background |
| `@ohos.arkui.node` | — | Direct access to the underlying node tree — walk parent/child relationships, read layout data, or manipulate the render tree |
| `@ohos.arkui.component` | — | Programmatically style or configure a gauge — set min/max values, current value, color ranges, and dial appearance |
| `built-in` | — | Access to globally available functions and constants — the top-level scope available everywhere in your app |
| `@ohos.arkui.component` | — | Programmatically style or configure a grid column — set span, offset, and responsive column behavior |
| `@ohos.arkui.component` | — | Programmatically style or configure a grid item — set row/column position, span, and item-specific styling |
| `@ohos.arkui.component` | — | Programmatically style or configure a grid layout — set columns, rows, gaps, and scroll direction |
| `@ohos.arkui.component` | — | Programmatically style or configure a grid row — set gutter, columns, breakpoints, and direction |
| `@ohos.bundle.bundleManager` | `@crossplatform` | Inspect a HAP module at runtime — read its name, description, supported device types, and module capabilities |
| `@ohos.arkui.component` | — | Programmatically style or configure a hyperlink — set URL, link color, underline, and visited state |
| `@ohos.arkui.component` | — | Programmatically style or configure an image animator — set frame list, duration, loop count, and playback mode |
| `@ohos.arkui.component` | — | Programmatically style or configure an image — set source, fit mode, color filter, border radius, and loading behavior |
| `@ohos.arkui.component` | — | Programmatically style or configure an inline image span — set size, alignment, and margin of images embedded in text |
| `built-in` | — | A 32-bit integer — arithmetic, bitwise operations, or type-safe numeric parameters |
| `InteropAbilityMonitor` | — | Test abilities that run in interop mode and need to observe their lifecycle alongside non-ArkTS components |
| `built-in` | — | Parse JSON strings, serialize objects to JSON, or walk a parsed JSON tree |
| `@ohos.bundle.launcherBundleManager` | — | Display an app — read the ability's icon, label, and launch intent to show on the home screen |
| `@ohos.arkui.node` | — | A layout algorithm that the framework doesn't provide — implement your own container with custom child measurement and positioning rules |
| `@ohos.arkui.component` | — | Programmatically style or configure a line shape — set endpoints, stroke width, color, and dash pattern |
| `@ohos.arkui.component` | — | Programmatically style or configure a list item group — set header, footer, divider, and group-level styling |
| `@ohos.arkui.component` | — | Programmatically style or configure a list item — set background, swipe actions, and item-level styling |
| `@ohos.arkui.component` | — | Programmatically style or configure a list — set scroll direction, divider, sticky headers, and edge effect |
| `@ohos.arkui.component` | — | Programmatically style or configure a loading spinner — set size, color, and animation style |
| `built-in` | — | 64-bit integer values — large IDs, timestamps in nanoseconds, or integer math beyond Int32 range |
| `built-in` | — | Key-value storage with fast lookup — associate values with string keys, iterate entries, and check for key existence |
| `@ohos.arkui.component` | — | Programmatically style or configure a marquee — set scroll speed, direction, and text content |
| `built-in` | — | Mathematical operations — trigonometry, logarithms, rounding, random numbers, and numeric constants |
| `@ohos.arkui.component` | — | Programmatically style or configure a menu item — set label, icon, enabled state, and click action |
| `@ohos.arkui.component` | — | Programmatically style or configure a menu — set anchor, placement, items, and show/hide behavior |
| `@ohos.bundle.bundleManager` | `@crossplatform` | Read it — access custom configuration values declared in the manifest |
| `@ohos.app.ability.UIAbility` | `@systemapi` | Configure multi-instance support for an app — set the maximum number of concurrent instances and isolation mode |
| `@ohos.arkui.node` | — | Embed a node reference into a component slot — host an existing node inside a different part of the tree |
| `@ohos.arkui.node` | `@crossplatform` | Dynamically add or remove nodes from the component tree — create, attach, detach, or swap nodes at runtime |
| `@ohos.bundle.bundleManager` | — | Read overlay module metadata — resource path, target bundle, and priority |
| `@ohos.app.ability.UIAbility` | `@systemapi` | Page name, path, and parameters used for routing |
| `@ohos.arkui.component` | — | Programmatically style or configure a particle effect — set emitter position, particle count, velocity, and color gradient |
| `@ohos.arkui.component` | — | Programmatically style or configure a path shape — set the SVG-like path commands, stroke, and fill |
| `@ohos.arkui.component` | — | Programmatically style or configure a pattern lock — set grid size, dot appearance, path color, and input callback |
| `@ohos.bundle.bundleManager` | `@systemapi` | Inspect a plugin bundle — read the plugin's metadata, version, dependencies, and host requirements |
| `@ohos.arkui.component` | — | Programmatically style or configure a polygon — set vertices, stroke width, fill color, and rotation |
| `@ohos.arkui.component` | — | Programmatically style or configure a polyline — set sequence of points, line color, width, and dash pattern |
| `@ohos.arkui.component` | — | Programmatically style or configure a progress bar — set value, color, style (linear/ring/scale), and animation |
| `@ohos.arkui.component` | — | Programmatically style or configure a QR code — set content string, foreground/background color, and error correction level |
| `@ohos.arkui.component` | — | Programmatically style or configure a rating bar — set star count, step size, foreground/background images, and current rating |
| `@ohos.arkui.component` | — | Programmatically style or configure a rectangle shape — set width, height, corner radius, stroke, and fill |
| `built-in` | — | Read or write static fields of a class using reflection — access class-level properties at runtime |
| `built-in` | — | Instantiate a class at runtime whose type is not known at compile time — call constructors via reflection |
| `built-in` | — | Read or write an instance field dynamically — get or set properties on objects at runtime without knowing their type |
| `built-in` | — | Call a method on an object dynamically — invoke instance methods at runtime when the method name is not known at compile time |
| `built-in` | — | Intercept property access or method calls on an object — add logging, validation, or virtualization to object interactions |
| `built-in` | — | Call a static method via reflection — invoke class-level methods dynamically at runtime |
| `@ohos.arkui.component` | — | Programmatically style or configure a pull-to-refresh — set refresh animation, offset threshold, and refresh callback |
| `built-in` | — | Search, match, or replace text patterns — validate input formats, find substrings, or extract data from strings |
| `@ohos.arkui.component` | — | Programmatically style or configure a relative container — set anchor relationships, alignments, and bias between child components |
| `RemoteAbilityInfo` | `@systemapi` | Identity, connection state, and distributed capabilities |
| `@ohos.arkui.node` | — | Custom rendering that goes beyond built-in components — draw directly to the screen with low-level graphics operations |
| `@ohos.arkui.component` | — | Programmatically style or configure a rich text editor — set placeholder, text styling, toolbar visibility, and input type |
| `@ohos.arkui.component` | — | Programmatically style or configure a row layout — set alignment, spacing, padding, and horizontal distribution of children |
| `@ohos.arkui.component` | — | Programmatically style or configure a row split layout — set divider position, resizable pane behavior, and horizontal spacing |
| `RunningAppClone` | `@systemapi` | Check which cloned apps are running and their current state |
| `RunningMultiAppInfo` | `@systemapi` | Inspect multi-instance app configurations — see how many instances of an app are running and their individual states |
| `RunningMultiInstanceInfo` | `@systemapi` | Inspect multi-instance ability configurations — see how many instances of an ability are active and their states |
| `Scene` | `@systemapi` | Render interactive 3D graphics — the root container that holds a 3D camera, lights, models, and animation |
| `SceneBoidsSim` | `@systemapi` | Simulate flocking behavior in 3D — birds, fish, or crowds that move in groups with realistic swarm dynamics |
| `SceneNodes` | — | Build a 3D scene and need to place objects — create meshes, assign materials, and position items in a 3D transform hierarchy |
| `SceneTypes` | — | Work with 3D data and need the type definitions — vector math, color values, matrices, and geometry primitives for scene construction |
| `@ohos.arkui.component` | — | Programmatically style or configure a scroll container — set scroll direction, bounce, scroll bar visibility, and edge effect |
| `@ohos.arkui.component` | — | Programmatically style or configure a search bar — set placeholder, search icon, keyboard type, and submit callback |
| `@ohos.arkui.component` | — | Programmatically style or configure a select dropdown — set options, selected index, placeholder, and dropdown appearance |
| `built-in` | — | A collection of unique values — test membership, add and remove items, or iterate over distinct elements |
| `@ohos.arkui.component` | — | Programmatically style or configure a shape — set viewport, fill rule, stroke dash, and shape-level attributes |
| `@ohos.bundle.bundleManager` | `@systemapi` | Inspect the sharing configuration — read shared bundle metadata and dependencies |
| `@ohos.bundle.bundleManager` | `@systemapi` | Display app shortcuts — read the shortcut label, icon, and the intent it launches when tapped |
| `@ohos.arkui.component` | — | Programmatically style or configure a sidebar — set sidebar width, position, control button style, and auto-hide behavior |
| `@ohos.bundle.bundleManager` | — | Match a want (intent) to the right ability — define actions, entities, and URI patterns that an ability can handle |
| `@ohos.arkui.component` | — | Programmatically style or configure a slider — set min/max, step, track color, thumb style, and value label |
| `@ohos.arkui.component` | — | Programmatically style or configure a text span — set font, color, decoration, and gesture on inline text |
| `built-in` | — | An array with integer keys and sparse storage — store values at arbitrary positive integer indices without allocating for gaps |
| `built-in` | — | Work with text — concatenate, split, replace, search substrings, trim whitespace, or change case |
| `built-in` | — | Build strings efficiently — append many pieces incrementally without the overhead of creating intermediate string objects |
| `@ohos.arkui.component` | — | Programmatically style or configure a swiper — set loop, auto-play, indicator style, transition, and page margin |
| `@ohos.arkui.component` | — | Programmatically style or configure a symbol glyph icon — set symbol name, weight, tint color, and effect |
| `@ohos.arkui.component` | — | Programmatically style or configure a symbol span — set symbol glyph properties for inline symbol rendering |
| `SystemSoundPlayer` | — | Play a standard system sound effect — button click feedback, notification chime, or confirmation tone |
| `@ohos.arkui.component` | — | Programmatically style or configure a tabs container — set tab bar position, indicator, scrollable mode, and tab width |
| `@ohos.arkui.component` | — | Programmatically style or configure a text area — set max length, placeholder, input type, rows, and font styling |
| `@ohos.arkui.component` | — | Programmatically style or configure a text clock — set timezone, format (12/24h), and display style |
| `@ohos.arkui.component` | — | Programmatically style or configure a text input — set keyboard type, max length, placeholder, input filter, and secure text mode |
| `@ohos.arkui.component` | — | Programmatically style or configure a text component — set content, font, color, alignment, overflow, and line height |
| `@ohos.arkui.component` | — | Programmatically style or configure a text picker — set range, selected index, text style, and scroll behavior |
| `@ohos.arkui.component` | — | Programmatically style or configure a text timer — set count, format, font, and countdown behavior |
| `@ohos.arkui.component` | — | Programmatically style or configure a time picker — set selected hour/minute, 24-hour mode, and appearance |
| `@ohos.arkui.component` | — | Programmatically style or configure a toggle — set on/off state, switch color, text labels, and toggled callback |
| `built-in` | — | Typed numeric arrays — Int8Array, Uint8Array, Int16Array, Float32Array — for binary data buffers and efficient array math |
| `built-in` | — | Unsigned typed arrays — Uint8ClampedArray, Uint16Array — for pixel data, binary protocols, and buffer manipulation |
| `@ohos.app.ability.UIAbility` | `@systemapi` `@deprecated` `@crossplatform` | Get window reference, resource manager, navigation controller, and lifecycle info |
| `@ohos.arkui.component` | — | Programmatically style or configure a UI picker component — set range, value, font, and scroll behavior |
| `UIServiceHostProxy` | `@systemapi` | Communicate with an embedded UI service extension — forward requests and receive responses across the extension boundary |
| `UIServiceProxy` | — | Send messages to a UI service running in another process — invoke methods and receive callbacks from remote UI services |
| `@ohos.arkui.component` | — | Programmatically style or configure a video player — set source, controls, muted state, loop, and playback speed |
| `@ohos.app.ability.UIAbility` | `@systemapi` | A snapshot of the current view state in an ability — capture what's displayed for restoration or telemetry |
| `@ohos.arkui.component` | — | Programmatically style or configure a waterfall layout — set column count, item spacing, and stagger direction |
| `abilityDelegatorArgs` | `@crossplatform` | Write an ability test and need to pass configuration arguments to the test delegator — specify test parameters at launch time |
| `@ohos.app.ability.AbilityConstant` | — | Read the result code and data returned by a launched ability |
| `@ohos.arkui.component` | `@systemapi` | Show a modal alert to the user — confirmation prompts, warning dialogs, or simple OK/cancel choices |
| `@ohos.arkui.component` | — | Let users jump to contacts by first letter or browse alphabetically |
| `@ohos.arkui.component` | — | A small notification dot on an icon or tab — show unread counts, new-message indicators, or status badges |
| `@ohos.arkui.component` | — | Empty space in a layout — insert a gap, push items apart, or create placeholder areas without content |
| `@ohos.arkui.component` | — | Construct components from builder functions — wrap conditional or repeating UI in reusable builder patterns |
| `@ohos.arkui.component` | — | A tappable button — submit forms, trigger actions, or navigate with a labeled pressable element |
| `@ohos.arkui.component` | `@systemapi` | Let users select a date or date range from a visual calendar grid |
| `@ohos.arkui.component` | — | Draw custom graphics — lines, shapes, text, or images on a freeform pixel canvas |
| `@ohos.arkui.component` | — | A checkbox — let users toggle a single binary option on or off |
| `@ohos.arkui.component` | — | Multiple checkboxes and want to manage them as a group — select all, count checked, or enforce mutual exclusion |
| `@ohos.arkui.component` | — | A circular shape — draw a filled or outlined circle at a specific size and position |
| `@ohos.arkui.component` | `@systemapi` | A vertical layout — stack children top-to-bottom with alignment, spacing, and distribution control |
| `@ohos.arkui.component` | — | A vertically split layout where users can drag the divider — resizable panes side by side or stacked |
| `@ohos.arkui.component` | `@systemapi` `@deprecated` `@crossplatform` | The base attributes shared by all components — width, height, margin, padding, border, background, and visibility |
| `@ohos.arkui.component` | `@systemapi` | The base attributes shared by all components — width, height, margin, padding, border, background, and visibility |
| `@ohos.commonEventManager` | `@crossplatform` | Read the event name, bundle data, and parameters when a common event is received |
| `@ohos.commonEventManager` | `@crossplatform` | Publish a common event — configure delivery — set ordered delivery, sticky behavior, and required permissions |
| `@ohos.commonEventManager` | `@crossplatform` | Subscribe to common events — set filters — specify which events to receive and with what priority |
| `@ohos.commonEventManager` | `@crossplatform` | A subscriber object that receives event callbacks — hold a reference to the active subscription for later unsubscribe |
| `@ohos.arkui.component` | — | Render 3D graphics in a component — embed interactive 3D models alongside regular 2D UI elements |
| `@ohos.arkui.component` | — | Group inline text spans inside a container — apply shared styling or behavior to a block of text within a paragraph |
| `@ohos.arkui.component` | — | Fill a named slot in a template component — inject content into a specific placeholder in a parent layout |
| `@ohos.arkui.component` | — | A stepper for numeric input — let users increment and decrement a value with plus/minus buttons |
| `@ohos.arkui.component` | `@systemapi` | Programmatically control a custom dialog — show, dismiss, update content, or react to dialog lifecycle events |
| `@ohos.app.ability.common` | — | Perform CRUD operations on a data ability — query, insert, update, or delete records through the data ability helper |
| `@ohos.arkui.component` | — | Display chart data — bar charts, line charts, gauges, or numerical dashboards |
| `@ohos.arkui.component` | `@systemapi` | Let users select a date from a scrollable day/month/year selector |
| `@ohos.arkui.component` | — | Apply decorators to components — wrap components with structural or behavioral annotations |
| `@ohos.arkui.component` | — | A visual separator between UI sections — a horizontal or vertical line to divide content |
| `@ohos.arkui.component` | — | An elliptical shape — draw a filled or outlined oval at a specific size and position |
| `@ohos.arkui.component` | `@systemapi` | The enum values for component properties — reference direction, alignment, visibility, and other attribute constants |
| `@ohos.arkui.component` | — | React to configuration changes — rebuild the UI when language, color mode, or device orientation changes |
| `@ohos.arkui.component` | `@systemapi` | A flexible layout — arrange children horizontally or vertically with wrapping, alignment, and weighted distribution |
| `@ohos.arkui.component` | — | A child element inside a flow layout — each item in a wrapping, auto-reflowing container |
| `@ohos.arkui.component` | — | Control which component receives keyboard focus — set focus, request focus, or detect focus changes |
| `@ohos.arkui.component` | — | Render a list from an array — iterate over data and generate a component for each item |
| `@ohos.arkui.component` | — | Display a gauge or dial — show a value on a circular scale with marked ranges and a needle pointer |
| `@ohos.arkui.component` | — | The gesture type definitions — reference tap, swipe, pan, pinch, and rotation gesture event types |
| `built-in` | `@systemapi` | Work in ArkUI Lite and need globally available functions and constants — the top-level scope for lightweight UI environments |
| `@ohos.arkui.component` | `@systemapi` | A grid layout — arrange children in rows and columns with fixed or auto-sized cells |
| `@ohos.arkui.component` | — | A column inside a grid — define how a child spans and offsets within a grid row |
| `@ohos.arkui.component` | — | An item inside a grid — each cell element in a grid layout |
| `@ohos.arkui.component` | — | A row inside a grid — define row breakpoints, gutters, and column configuration |
| `@ohos.arkui.component` | — | Tappable text that opens a URL — link to websites, email addresses, or phone numbers from inline text |
| `@ohos.arkui.component` | — | Conditional rendering — show or hide a component based on a boolean expression |
| `@ohos.arkui.component` | `@systemapi` `@crossplatform` | Display an image — show photos, icons, or illustrations from local assets, network URLs, or pixel buffers |
| `@ohos.arkui.component` | — | Play an animated image — cycle through frames, control loop behavior, and set playback duration |
| `@ohos.arkui.component` | — | Shared image attribute definitions — reference object fit modes, interpolation types, and render modes |
| `@ohos.arkui.component` | — | An image embedded inside a line of text — place icons or emotes inline with surrounding text content |
| `@ohos.arkui.component` | `@systemapi` | Inspect the component tree at runtime — walk the hierarchy, read component properties, and debug layout issues |
| `@ohos.arkui.component` | — | Embed non-ArkTS content — host native views, WebView, or other platform content inside your component tree |
| `@ohos.arkui.component` | — | Load items on demand — only render visible items and recycle off-screen ones for memory efficiency |
| `@ohos.arkui.component` | — | A virtualized grid that loads lazily — large grids that only render visible cells to save memory |
| `@ohos.arkui.component` | — | Draw a line — a straight segment from one point to another with stroke styling |
| `@ohos.arkui.component` | `@systemapi` | A scrollable vertical list — display many items efficiently with built-in scroll, grouping, and sticky headers |
| `@ohos.arkui.component` | — | A single row item inside a list — the content cell for each row in a scrolling list |
| `@ohos.arkui.component` | — | Group list items with a header — section dividers with optional headers, footers, and collapsed state |
| `@ohos.arkui.component` | — | A loading indicator — show a spinning animation while content loads or a process completes |
| `@ohos.arkui.component` | — | Scrolling text — a ticker-like animation that scrolls long text horizontally when it overflows its container |
| `@ohos.arkui.component` | — | 2D matrix transformations — translate, rotate, scale, or skew components with matrix operations |
| `@ohos.arkui.component` | `@systemapi` | Display a cached media thumbnail — show album art, video previews, or gallery thumbnails from the media cache |
| `@ohos.arkui.component` | — | A popup menu — show a context menu or overflow menu anchored to a component with a list of actions |
| `@ohos.arkui.component` | — | A single action inside a menu — a clickable row with label, icon, and optional submenu |
| `@ohos.arkui.component` | — | Group related menu items — add a separator and optional group label to organize menu options |
| `@ohos.arkui.component` | — | Host a custom node tree inside a component — embed a dynamically built node hierarchy at a specific point in the layout |
| `@ohos.arkui.component` | — | Visual particle effects — sparks, confetti, smoke, or fire effects with configurable emitters and physics |
| `@ohos.arkui.component` | — | A paste button — let users paste content from the clipboard into a text field with one tap |
| `@ohos.arkui.component` | — | Draw a custom path — complex shapes defined by a sequence of line and curve commands |
| `@ohos.arkui.component` | — | A pattern lock input — let users draw a connect-the-dots pattern for authentication or access control |
| `@ohos.arkui.stateManagement` | — | Persist UI state across app restarts with improved serialization — save and restore component state automatically |
| `@ohos.arkui.component` | — | Draw a polygon — a closed shape with an arbitrary number of vertices, filled or outlined |
| `@ohos.arkui.component` | — | Draw a polyline — a connected sequence of line segments forming an open or closed path |
| `@ohos.arkui.component` | — | Show progress — a bar, ring, or segmented indicator showing completion percentage |
| `@ohos.arkui.component` | — | Display a QR code — encode a string as a scannable 2D barcode rendered in a component |
| `@ohos.arkui.component` | — | A star rating input — let users rate content by tapping stars, with configurable count and step size |
| `@ohos.resourceManager` | `@crossplatform` | Read a raw asset file — open a file descriptor to access bundled files in the rawfile directory |
| `@ohos.arkui.component` | — | Draw a rectangle — a simple filled or outlined rectangular shape |
| `@ohos.arkui.component` | — | Pull-to-refresh — let users swipe down at the top of a list to reload content with a loading indicator |
| `@ohos.arkui.component` | — | Constraint-based layout — position children relative to each other and the container with anchor rules |
| `@ohos.arkui.component` | — | Retain state across recompositions — keep a value alive even when the component function re-executes |
| `@ohos.arkui.component` | — | Repeat content — render multiple instances of a component for each item in a data collection |
| `@ohos.arkui.component` | `@systemapi` | Enable formatted text input with bold, italic, images, and hyperlinks |
| `@ohos.arkui.component` | — | Styled text — display text with mixed formatting using spans, font changes, and inline decorations |
| `ringtonePlayer` | `@systemapi` | Play a ringtone or alert — incoming call ringtone, alarm sound, or notification alert |
| `@ohos.arkui.component` | `@systemapi` | The top-level scene node for global-level UI operations |
| `@ohos.arkui.component` | `@systemapi` | A horizontal row layout — arrange children left-to-right with alignment, spacing, and distribution |
| `@ohos.arkui.component` | — | A horizontally split layout where users can drag the divider — resizable left and right panes |
| `@ohos.arkui.component` | `@systemapi` | Let users commit data or state changes with a system-styled save action |
| `@ohos.arkui.component` | — | Wrap it in a scrollable container with vertical or horizontal scrolling |
| `@ohos.arkui.component` | — | A scroll bar indicator — show the scroll position and let users drag to scroll quickly |
| `@ohos.arkui.component` | — | A search input field — let users type a query and submit to filter or find content |
| `@ohos.arkui.component` | `@systemapi` | Let users pick one option from a list with a tap-to-expand menu |
| `@ohos.arkui.component` | — | Shape drawing primitives — the base type for circle, rectangle, polygon, and other drawable shapes |
| `@ohos.app.ability.abilityManager` | — | Execute a shell command against an ability — capture stdout, stderr, and exit code |
| `@ohos.arkui.component` | — | A master-detail sidebar layout — a collapsible side panel alongside main content with a drag divider |
| `@ohos.arkui.component` | — | A slider — let users select a value from a range by dragging a thumb along a track |
| `soundPool` | `@systemapi` | Play UI sound effects, game SFX, or quick audio feedback without loading delay |
| `@ohos.arkui.component` | — | Inline styled text — format part of a text string with different font, color, or decoration from the surrounding text |
| `@ohos.arkui.stateManagement` | — | State management utility helpers — observe state changes, link state between components, or orchestrate reactive updates |
| `@ohos.arkui.component` | `@systemapi` | Display formatted text — rich text with mixed styles, indentation, and structured content |
| `@ohos.arkui.component` | — | A swipeable carousel — display multiple pages users can flip through horizontally with gesture navigation |
| `@ohos.arkui.component` | — | An inline symbol glyph — embed SF Symbols-style icons inside a line of text |
| `@ohos.arkui.component` | — | A symbol glyph icon — display a system-provided icon with configurable weight, color, and visual effect |
| `systemTonePlayer` | `@systemapi` | Play a notification or alert tone — incoming message ping, calendar alert, or system warning sound |
| `@ohos.arkui.component` | `@crossplatform` | Content for a specific tab page — the child component that renders when its tab is selected |
| `@ohos.arkui.component` | — | Tabbed navigation — let users switch between multiple content views by tapping tab labels at the top or bottom |
| `@ohos.arkui.component` | — | Display text — show a label, paragraph, or heading with configurable font, color, and alignment |
| `@ohos.arkui.component` | `@systemapi` | Let users enter longer text like messages, notes, or descriptions |
| `@ohos.arkui.component` | — | Display a live clock — show the current time in a text component that updates automatically |
| `@ohos.arkui.component` | `@systemapi` | Shared text attribute definitions — reference font weight, text case, text align, and overflow constants |
| `@ohos.arkui.component` | `@systemapi` | Let users type short text like names, emails, or search queries |
| `@ohos.arkui.component` | `@systemapi` | A scrollable selector for choosing from a list of text options |
| `@ohos.arkui.component` | — | Display a countdown or timer — show elapsed or remaining time with auto-updating text |
| `@ohos.arkui.component` | `@systemapi` | Let users select hours and minutes from a scrollable clock face selector |
| `@ohos.arkui.component` | — | An on/off switch — let users toggle a setting between two states with a sliding switch control |
| `@ohos.arkui.component` | — | A toolbar — show an action bar with buttons, icons, and overflow menu for context-specific actions |
| `triggerInfo` | `@systemapi` | Know what triggered an intent or operation — the source event and context that caused an ability to launch |
| `@ohos.arkui.component` | — | Unit constants for layout — reference vp, px, fp, or lpx units for sizing and positioning |
| `@ohos.arkui.component` | `@systemapi` | Embed a video player with controls, seek, and playback state control |
| `@ohos.arkui.component` | — | A masonry/waterfall layout — display items of varying heights in columns that flow like a cascading grid |
| `@ohos.arkui.component` | `@deprecated` | Display a web page inside a component — render HTML content within a scrollable WebView embedded in the native UI |
| `@ohos.arkui.component` | — | Apply a theme to a component subtree — inject the current theme colors, fonts, and styles into child components |

// ArkTS component snippets for Personal Planner. Copy patterns into a dynamic @Entry app.
// Keep snippets conservative: Column, Row, Stack, Text, Scroll, Blank, TextInput.
// Geometry assumes compact ArkUI viewport units while evidence screenshots are 1080x2340.

// App shell pattern:
// Stack() {
//   Column() {
//     Row() { Text('9:41').fontSize(DS_FONT_META).fontWeight('bold'); Blank().layoutWeight(1); Text('▮▮  ◔').fontSize(DS_FONT_META).fontWeight('bold') }
//       .height(DS_STATUS_HEIGHT).padding({ left: DS_SIDE_PAD, right: DS_SIDE_PAD })
//     Row() {
//       Column() { Text(title).fontSize(DS_FONT_TITLE).fontWeight('bold'); Text(subtitle).fontSize(DS_FONT_META).opacity(0.72) }.layoutWeight(1)
//       Stack() { Text('⌕').fontSize(20).fontWeight('bold') }.width(DS_TOUCH).height(DS_TOUCH).backgroundColor(DS_SURFACE).borderRadius(DS_TOUCH / 2)
//       Stack() { Text('+').fontSize(22).fontWeight('bold') }.width(DS_TOUCH).height(DS_TOUCH).backgroundColor(DS_PRIMARY).borderRadius(DS_TOUCH / 2)
//     }.height(DS_HEADER_HEIGHT).padding({ left: DS_SIDE_PAD, right: DS_SIDE_PAD })
//     Scroll() { Column() { /* screen content */ }.padding({ left: DS_SIDE_PAD, right: DS_SIDE_PAD }) }.layoutWeight(1)
//     Row() { /* four fixed tab items, each width 25%, icon Stack + label */ }
//       .height(DS_BOTTOM_NAV_HEIGHT).padding({ left: 8, right: 8, top: 4, bottom: 2 })
//       .backgroundColor(DS_SURFACE).borderRadius(DS_RADIUS_LG).margin({ left: DS_SIDE_PAD, right: DS_SIDE_PAD })
//     Row() { Blank().layoutWeight(1); Text('').width(116).height(4).backgroundColor('#111111').borderRadius(2); Blank().layoutWeight(1) }.height(DS_HOME_INDICATOR_HEIGHT)
//   }.width('100%').height('100%').backgroundColor(DS_BG)
// }

// Card pattern:
// Column() { Text(cardTitle).fontSize(DS_FONT_H2).fontWeight('bold'); Text(cardMeta).fontSize(DS_FONT_META).opacity(0.78) }
//   .width('100%').padding(14).backgroundColor(DS_SURFACE).borderRadius(DS_RADIUS_LG)

// Chip pattern:
// Text(label).fontSize(DS_FONT_META).fontWeight('bold').height(32).padding({ left: 14, right: 14 })
//   .backgroundColor(isSelected ? DS_PRIMARY : DS_PANEL).borderRadius(16)

// Fixed tab item pattern:
// Column() { Stack() { Text(icon).fontSize(17).fontWeight('bold') }.width(28).height(24); Text(label).fontSize(9).opacity(isActive ? 1 : 0.62) }
//   .width('25%').height('100%')

// Bottom sheet pattern:
// Column() { Blank().layoutWeight(1); Column() { /* title, fields, chips, actions */ }.height(360).backgroundColor(DS_SURFACE).borderRadius(22) }
//   .width('100%').height('100%').backgroundColor('#000000').opacity(0.72)

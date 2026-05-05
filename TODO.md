# TODO.md — RateBar

## [DONE] T01: 项目骨架
**Dependencies**: -
**Goal**: 建立可构建可运行的最小 Swift 6 macOS App 骨架（空 MenuBarExtra），`xcodebuild build` 与 `test` 均通过。
**Design**: 见 PLAN.md → T01。`project.yml` (xcodegen) + `RateBar/RateBarApp.swift` + `RateBarTests/SmokeTests.swift`。
**Test Cases**:
- `testAppCompiles` (timeout: 5s) — 占位断言 true
**Verification**: `xcodegen generate && xcodebuild -scheme RateBar -destination "platform=macOS,arch=$(uname -m)" clean test`
**Delivery Criteria**:
- [x] `project.yml` 存在且 xcodegen 可生成
- [x] build 0 warning 0 error
- [x] test 通过
- [x] README.md 写明开发环境与构建命令

---

## [DONE] T02: 汇率数据模型
**Dependencies**: T01
**Goal**: 定义 `Rate` / `RatesSnapshot` / `ExchangeRateHostResponse` 数据结构 + 解码。
**Design**: 见 PLAN.md → T02。`RateBar/Models/` 下两个文件。
**Test Cases**:
- `testDecodeResponse` (timeout: 5s)
- `testRateLookup` (timeout: 5s)
- `testEquatable` (timeout: 5s)
**Verification**: `xcodegen generate && xcodebuild -scheme RateBar -destination "platform=macOS,arch=$(uname -m)" clean test`
**Delivery Criteria**:
- [x] 3 测试通过
- [x] 0 warning

---

## [TODO] T03: ExchangeRateHost 客户端
**Dependencies**: T02
**Goal**: async/await 调用 `https://api.exchangerate.host/latest`，返回 `RatesSnapshot`，错误用 `RateClientError`。
**Design**: 见 PLAN.md → T03。`RateBar/Network/RateClient.swift` + `URLProtocol` mock。
**Test Cases**:
- `testFetchSuccess` (timeout: 5s)
- `testFetchHTTP500` (timeout: 5s)
- `testFetchBadJSON` (timeout: 5s)
**Verification**: `xcodebuild test`
**Delivery Criteria**:
- [ ] 3 测试通过
- [ ] 不打真网络

---

## [TODO] T04: RateService（缓存 + 状态）
**Dependencies**: T03
**Goal**: `@Observable` 服务封装 client + UserDefaults 缓存 + isStale 判定。
**Design**: 见 PLAN.md → T04。`RateBar/Services/RateService.swift` + `Storage/SnapshotStore.swift`。
**Test Cases**:
- `testRefreshSuccess` (timeout: 5s)
- `testRefreshFailureKeepsCache` (timeout: 5s)
- `testPersistAndReload` (timeout: 5s)
- `testStaleAfterOneHour` (timeout: 5s)
**Verification**: `xcodebuild test`
**Delivery Criteria**:
- [ ] 4 测试通过
- [ ] 0 warning

---

## [TODO] T05: MenuBarExtra UI
**Dependencies**: T04
**Goal**: 菜单栏文字 + 下拉显示 4 对汇率、最后刷新时间、Refresh / Quit 按钮。
**Design**: 见 PLAN.md → T05。`RateBar/UI/MenuBarLabel.swift` + `MenuContent.swift`。
**Test Cases**:
- `testMenuContentRendersFourRates` (timeout: 5s)
- `testStaleBadgeAppears` (timeout: 5s)
- `testRefreshButtonInvokesService` (timeout: 5s)
**Verification**: `xcodebuild test`；手动启动 .app 看效果。
**Delivery Criteria**:
- [ ] 3 测试通过
- [ ] 手动验证 UI
- [ ] README 截图

---

## [TODO] T06: 自动 + 手动刷新
**Dependencies**: T05
**Goal**: 启动立即刷新；每小时自动一次；菜单 Refresh 按钮含 loading 反馈。
**Design**: 见 PLAN.md → T06。`RateBar/Services/RefreshScheduler.swift`。
**Test Cases**:
- `testStartTriggersImmediateRefresh` (timeout: 5s)
- `testStopCancelsTimer` (timeout: 5s)
- `testIntervalRefresh` (timeout: 6s)
**Verification**: `xcodebuild test`
**Delivery Criteria**:
- [ ] 3 测试通过
- [ ] UI loading 反馈正常

---

## [TODO] T07: 多语言（中 / 英）
**Dependencies**: T06
**Goal**: UI 字符串本地化，跟随系统语言；提供中英两种翻译。
**Design**: 见 PLAN.md → T07。`Localizable.xcstrings` 含 6 个 key。
**Test Cases**:
- `testLocalizationKeysExist` (timeout: 5s)
- `testChineseTranslation` (timeout: 5s)
**Verification**: `xcodebuild test`；手动切系统语言验证。
**Delivery Criteria**:
- [ ] 6 key 翻译完整
- [ ] 2 测试通过
- [ ] 手动验证中文显示

---

## [TODO] T08: 开机自启动
**Dependencies**: T07
**Goal**: 菜单加 "Launch at Login" Toggle，使用 `SMAppService.mainApp` 注册 / 注销。
**Design**: 见 PLAN.md → T08。`RateBar/Services/LaunchAtLogin.swift` + 协议抽象便于测试。
**Test Cases**:
- `testToggleEnable` (timeout: 5s)
- `testToggleDisable` (timeout: 5s)
- `testStatusReflectsRegistration` (timeout: 5s)
**Verification**: `xcodebuild test`；手动重启 Mac 验证。
**Delivery Criteria**:
- [ ] 3 测试通过
- [ ] 手动验证生效

---

## [TODO] T09: 打包 + 验收
**Dependencies**: T08
**Goal**: Release 构建 .app，README 完整，打 v0.1.0 tag。
**Design**: 见 PLAN.md → T09。
**Test Cases**:
- `testFinalSmoke` (timeout: 10s) — 全套测试通过
**Verification**: `xcodebuild -configuration Release build` + `xcodebuild test`
**Delivery Criteria**:
- [ ] release .app 构建成功
- [ ] 全部测试通过
- [ ] README 含截图与安装说明
- [ ] `v0.1.0` tag

---

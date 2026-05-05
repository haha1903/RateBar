# PLAN.md — RateBar

## 背景与动机

Peter 住悉尼，常需要看 AUD 与 CNY/USD/JPY/EUR 的汇率（澳元跨境、日本旅游、欧美购物）。打开网页或 App 太重，菜单栏一眼瞄到最方便。MVP 只解决"瞄一眼"这件事。

## 技术栈

- Swift 6 + SwiftUI `MenuBarExtra`，macOS 26+ 独占
- 数据源：`https://api.exchangerate.host/latest?base=AUD&symbols=CNY,USD,JPY,EUR`（免 key）
- 持久化：UserDefaults
- 自启动：`SMAppService.mainApp`
- 多语言：`.xcstrings`（中 / 英），跟随系统
- 项目用 `xcodegen` 从 `project.yml` 生成 `.xcodeproj`
- 测试：XCTest

## 依赖图

```
T01
 └─ T02 ─ T03 ─ T04 ─ T05 ─ T06 ─ T07 ─ T08 ─ T09
```

## 任务清单

---

### T01. 项目骨架

**Dependencies**: -

#### Goal
建立可构建运行的最小 Swift 6 macOS App 骨架（空 MenuBarExtra），保证 `xcodebuild` 通过。

#### Design
- `project.yml`（xcodegen），target `RateBar`，platform macOS 26.0，Swift 6.0
- `RateBar` / `RateBarTests` 链接 `AppIntents.framework`，避免 Xcode 26 空 SwiftUI target 的 App Intents metadata warning
- `RateBar/RateBarApp.swift`：`@main struct RateBarApp: App` + `MenuBarExtra("RateBar", systemImage: "dollarsign.circle") { Text("Hello") }`
- `RateBar/Info.plist`（最小，由 xcodegen 生成）
- `Package.resolved` 不需要
- `RateBarTests/SmokeTests.swift`：`func testAppCompiles()` 仅断言 `1 == 1`
- 安装 xcodegen：`brew install xcodegen`（README 写明）

#### Test Cases
- `testAppCompiles` (timeout: 5s) — 断言 true（占位，证明测试 target 跑通）

#### Verification
```
brew list xcodegen >/dev/null || brew install xcodegen
xcodegen generate
xcodebuild -scheme RateBar -destination "platform=macOS,arch=$(uname -m)" build
xcodebuild -scheme RateBar -destination "platform=macOS,arch=$(uname -m)" test
```

#### Delivery Criteria
- [x] `project.yml` 存在并能 `xcodegen generate` 成功
- [x] `xcodebuild build` 0 warning 0 error
- [x] `xcodebuild test` 通过
- [x] `README.md` 写明开发环境要求与构建命令

---

### T02. 汇率数据模型

**Dependencies**: T01

#### Goal
定义汇率数据结构 + 解析 exchangerate.host 响应。

#### Design
- `RateBar/Models/Rate.swift`
  - `struct Rate: Codable, Equatable { let base: String; let quote: String; let value: Double }`
  - `struct RatesSnapshot: Codable, Equatable { let base: String; let fetchedAt: Date; let rates: [String: Double] }`
  - `extension RatesSnapshot { func rate(to quote: String) -> Rate? }`
- `RateBar/Models/ExchangeRateHostResponse.swift`
  - `struct ExchangeRateHostResponse: Decodable { let base: String; let date: String; let rates: [String: Double] }`
  - `func toSnapshot(fetchedAt: Date = Date()) -> RatesSnapshot`

#### Test Cases
- `testDecodeResponse` (timeout: 5s) — 用固定 JSON 串解码 → base="AUD"、rates 含 4 个 key
- `testRateLookup` (timeout: 5s) — `snapshot.rate(to: "CNY")?.value == 4.72`
- `testEquatable` (timeout: 5s) — 同内容两个 snapshot equal

#### Verification
```
xcodegen generate
xcodebuild -scheme RateBar -destination "platform=macOS,arch=$(uname -m)" clean test
```

#### Delivery Criteria
- [x] 3 个测试通过
- [x] 无 warning

---

### T03. ExchangeRateHost 客户端

**Dependencies**: T02

#### Goal
async/await HTTP 客户端，调用 exchangerate.host 拉取 AUD→{CNY,USD,JPY,EUR}。

#### Design
- `RateBar/Network/RateClient.swift`
  - `protocol RateFetching { func fetch(base: String, symbols: [String]) async throws -> RatesSnapshot }`
  - `struct ExchangeRateHostClient: RateFetching` 用 `URLSession.shared`
  - URL: `https://api.exchangerate.host/latest?base=\(base)&symbols=\(symbols.joined(separator:","))`
  - 错误：`enum RateClientError: Error { case badStatus(Int), decoding, transport(Error) }`
- 测试用 `URLProtocol` mock 注入

#### Test Cases
- `testFetchSuccess` (timeout: 5s) — mock 返回 200 + 固定 JSON → 得到含 4 个 rate 的 snapshot
- `testFetchHTTP500` (timeout: 5s) — mock 返回 500 → 抛 `badStatus(500)`
- `testFetchBadJSON` (timeout: 5s) — mock 返回非法 JSON → 抛 `decoding`

#### Verification
```
xcodebuild -scheme RateBar -destination 'platform=macOS' test
```

#### Delivery Criteria
- [x] 3 个测试通过
- [x] mock 用 `URLProtocol` 实现，不打真网络

---

### T04. RateService（缓存 + 状态）

**Dependencies**: T03

#### Goal
对外暴露 observable 汇率服务：负责调用客户端、缓存到 UserDefaults、提供"上次成功时间"和"是否陈旧"。

#### Design
- `RateBar/Services/RateService.swift`
  - `@MainActor @Observable final class RateService`
  - 字段：`var snapshot: RatesSnapshot?`、`var lastError: String?`、`var isLoading: Bool`
  - `init(client: RateFetching, defaults: UserDefaults = .standard)`
  - `func refresh() async`：调 `client.fetch`，成功写 snapshot + 持久化（key `rateSnapshot`，JSON），失败写 lastError 并保留旧 snapshot
  - 启动时从 UserDefaults 还原 snapshot
  - `var isStale: Bool { fetchedAt 超 1 小时 }`
- `RateBar/Storage/SnapshotStore.swift`：`save / load` 封装 JSON 编解码

#### Test Cases
- `testRefreshSuccess` (timeout: 5s) — 注入 mock client → snapshot 非空 + isLoading 归 false
- `testRefreshFailureKeepsCache` (timeout: 5s) — 先成功一次 → 再失败 → snapshot 仍是旧值，lastError 非空
- `testPersistAndReload` (timeout: 5s) — 用临时 UserDefaults，refresh 后新建 service → snapshot 还原
- `testStaleAfterOneHour` (timeout: 5s) — 注入 fetchedAt = 90 分钟前 → isStale == true

#### Verification
```
xcodebuild -scheme RateBar -destination 'platform=macOS' test
```

#### Delivery Criteria
- [ ] 4 测试通过
- [ ] 0 warning

---

### T05. MenuBarExtra UI

**Dependencies**: T04

#### Goal
菜单栏图标 + 文字（默认 `AUD→CNY: 4.72`），点开下拉显示 4 对汇率、最后刷新时间、刷新按钮、退出按钮。

#### Design
- `RateBar/UI/MenuBarLabel.swift`：`Text` 显示 AUD→CNY，陈旧时加 ⚠️
- `RateBar/UI/MenuContent.swift`：
  - 4 行汇率（Grid 排版，左货币对右数值）
  - 分隔线
  - "Last updated: 14:32"
  - "Refresh" 按钮（调 `service.refresh()`）
  - "Quit" 按钮
- 数值格式化：`Double.formatted(.number.precision(.fractionLength(2...4)))`
- App 入口注入 RateService

#### Test Cases
- `testMenuContentRendersFourRates` (timeout: 5s) — 用 ViewInspector 或快照断言：给定 4 rate 的 snapshot，渲染 4 行
- `testStaleBadgeAppears` (timeout: 5s) — service.isStale=true → 显示 ⚠️
- `testRefreshButtonInvokesService` (timeout: 5s) — 用 spy service，点 Refresh → refresh() 被调一次

#### Verification
```
xcodebuild -scheme RateBar -destination 'platform=macOS' test
xcodebuild -scheme RateBar -destination 'platform=macOS' build  # 手动跑 .app 看效果
```

#### Delivery Criteria
- [ ] 3 测试通过
- [ ] 手动启动 .app 能看到菜单栏图标和下拉
- [ ] README 加截图说明

---

### T06. 自动刷新 + 手动刷新

**Dependencies**: T05

#### Goal
App 启动时立即刷新一次；之后每 1 小时一次；菜单中的 Refresh 按钮可手动触发并显示 loading 状态。

#### Design
- `RateBar/Services/RefreshScheduler.swift`
  - `@MainActor final class RefreshScheduler`
  - `init(service: RateService, interval: TimeInterval = 3600)`
  - `func start()`：立即 refresh → 启动 `Timer.scheduledTimer(withTimeInterval: interval, repeats: true)`
  - `func stop()`
- App 启动时 `scheduler.start()`
- Refresh 按钮在 `service.isLoading` 时禁用，文案变 "Refreshing..."

#### Test Cases
- `testStartTriggersImmediateRefresh` (timeout: 5s) — 用 spy service → start() 后 refresh() 至少调 1 次
- `testStopCancelsTimer` (timeout: 5s) — start → stop → 等 0.2s（用短 interval 0.1）→ refresh 调用次数不再增长
- `testIntervalRefresh` (timeout: 6s) — interval=0.5s，0.6s 内 refresh 至少调 2 次

#### Verification
```
xcodebuild -scheme RateBar -destination 'platform=macOS' test
```

#### Delivery Criteria
- [ ] 3 测试通过
- [ ] 手动跑：UI 上 Refresh 按钮有 loading 反馈

---

### T07. 多语言（中 / 英，跟随系统）

**Dependencies**: T06

#### Goal
所有用户可见字符串本地化，提供中英两种翻译，跟随系统语言。

#### Design
- `RateBar/Localizable.xcstrings`（Xcode 15+ String Catalog）
- 字符串清单：
  - `"Refresh"` / `"Refreshing..."` / `"Quit"` / `"Last updated: %@"` / `"Stale data"` / `"Failed to refresh"`
- 代码中统一用 `String(localized: "Refresh")`
- 中文翻译：刷新 / 刷新中... / 退出 / 最后更新: %@ / 数据陈旧 / 刷新失败

#### Test Cases
- `testLocalizationKeysExist` (timeout: 5s) — 遍历 6 个 key，`String(localized:)` 不返回 key 本身（说明被翻译）
- `testChineseTranslation` (timeout: 5s) — 在 zh-Hans bundle 中 `"Refresh"` → `"刷新"`

#### Verification
```
xcodebuild -scheme RateBar -destination 'platform=macOS' test
# 手动：系统语言改中文 → 重启 App → 菜单中文
```

#### Delivery Criteria
- [ ] 6 个 key 全部翻译
- [ ] 2 个测试通过
- [ ] 手动验证中文显示正确

---

### T08. 开机自启动开关

**Dependencies**: T07

#### Goal
菜单中加 "Launch at Login" 勾选项，使用 `SMAppService.mainApp` 注册 / 注销。

#### Design
- `RateBar/Services/LaunchAtLogin.swift`
  - `@MainActor @Observable final class LaunchAtLogin`
  - `var isEnabled: Bool { get set }` — getter 读 `SMAppService.mainApp.status == .enabled`，setter 调 `register() / unregister()`
- 菜单中 Toggle 绑定该属性
- Info.plist / entitlements：标准 mainApp 注册无需特殊配置

#### Test Cases
- `testToggleEnable` (timeout: 5s) — 用协议抽象封装 SMAppService，spy 验证 register 被调
- `testToggleDisable` (timeout: 5s) — spy 验证 unregister 被调
- `testStatusReflectsRegistration` (timeout: 5s) — register 后 isEnabled == true

#### Verification
```
xcodebuild -scheme RateBar -destination 'platform=macOS' test
# 手动：勾上 → 重启 Mac → 自动出现菜单栏图标
```

#### Delivery Criteria
- [ ] 3 测试通过
- [ ] 手动验证勾选生效

---

### T09. 打包 + 最终验收

**Dependencies**: T08

#### Goal
本地 release 构建 .app，README 写完整使用说明，打 v0.1.0 tag。

#### Design
- `xcodebuild -scheme RateBar -configuration Release -derivedDataPath build` 产出 `RateBar.app`
- README 加：
  - 截图（菜单栏 + 下拉）
  - 安装：把 `RateBar.app` 拖到 `/Applications`
  - 已知限制：免 key 数据源，频率受 host 限制
- `git tag v0.1.0`

#### Test Cases
- `testFinalSmoke` (timeout: 10s) — 全部测试套件 `xcodebuild test` 通过

#### Verification
```
xcodebuild -scheme RateBar -configuration Release -derivedDataPath build build
ls build/Build/Products/Release/RateBar.app
xcodebuild -scheme RateBar -destination 'platform=macOS' test
```

#### Delivery Criteria
- [ ] release .app 构建成功
- [ ] 全部测试通过
- [ ] README 完整
- [ ] `v0.1.0` tag 已创建

---

## 实施顺序（拓扑）

阶段 1（骨架）：T01
阶段 2（数据层）：T02 → T03 → T04
阶段 3（UI 层）：T05 → T06
阶段 4（产品化）：T07 → T08
阶段 5（发布）：T09

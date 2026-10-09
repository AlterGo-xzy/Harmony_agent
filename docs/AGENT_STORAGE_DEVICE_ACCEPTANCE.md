# Agent Storage 设备验收

2026-10-02 历史材料已按所有者要求统一名称。下文历史设备 7/7 为结果转述，相关旧日志可能经过名称替换、旧 signed HAP 已退役；当前 RDB 表的验收须独立运行。处理清单见 `artifacts/complete-naming-cleanup/20261002/changes.json`。

本文只描述 `agent_storage` 的 test-only 验收流程，不交付产品页面、产品 Entry Ability 或产品 HAP。测试复用仓库现有无页面 `test_host`；Agent 的唯一外部业务控制入口仍是 `AgentRuntimeFacade`。

当前测试宿主包名为 `com.harmony.agent`；本页以“历史测试包名”指代更名前的设备身份。旧文本已规范化、旧签名 HAP 已退役，原文件 SHA-256 仅留作追溯。T07 历史成功记录属于旧包名及旧 RDB 表，今后复验命令使用当前包名。

## 历史验收结论

- `agent_storage` 0.4.0 当前合并主机 Hypium：39/39 已运行通过，其中本页对应的 M05-A 为 26 项；M05-B 设备门另见 [`AGENT_MEMORY_DEVICE_ACCEPTANCE.md`](AGENT_MEMORY_DEVICE_ACCEPTANCE.md)。T07 的设备 7/7 是旧 schema 证据，0.4.0/schema 1.2 必须重新运行本页套件后才能取得当前设备证据。
- API 26 签名主 HAP 与 ohosTest HAP：已构建并安装成功。
- `StorageDeviceRecovery`：7/7 已在 API 26 模拟器运行通过，`Failure: 0`、`Error: 0`。
- 验收后 `历史测试包名` 已卸载，并通过独立查询验证 bundle 不存在。
- 成功运行目录：`artifacts/t07-device-acceptance/20261001-211416/`。

## 用例

`StorageDeviceRecovery` 当前包含 8 项：

1. 加载 `@harmony_agent/agent-storage` HAR；
2. `PREPARED` intent 与 `RESERVED` budget 在 RDB close/reopen 后保留；
3. 调用中退出后，reopen 在返回恢复 session 前把 `IN_FLIGHT` 可靠固化为 `UNKNOWN_OUTCOME`；
4. 已观察到 provider 结果、但结果提交前退出时，不伪造成功，reopen 后仍为未知；
5. `COMMITTED` outcome、provider receipt 与实际预算在 close/reopen 后保留；
6. 两个 stale recovery session 竞争 lease/CAS 时只有一个成功；
7. 持久化摘要损坏时 fail-closed；
8. opaque Runtime checkpoint 与任务枚举在真实 RDB close/reopen 后保持一致。

第 8 项已编译进当前 unsigned ohosTest HAP，但尚未签名、安装或运行；下文 7/7 仍是 T07 旧 schema 的历史设备证据。

每项 RDB 测试使用独立数据库，并在开始前清理旧 fixture、在 `finally` 中关闭 RDB 后删除数据库。

## 工作区内构建

```powershell
$env:DEVECO_SDK_HOME='D:\DevEco\DevEco Studio\sdk'
& 'D:\DevEco\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=agent_storage@default -p product=default test --no-daemon
& 'D:\DevEco\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=test_host@default -p product=default assembleHap --no-daemon
& 'D:\DevEco\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=test_host@ohosTest -p product=default assembleHap --no-daemon
```

常规未签名构建产物位置：

```text
test_host/build/default/outputs/default/test_host-default-unsigned.hap
test_host/build/default/outputs/ohosTest/test_host-ohosTest-unsigned.hap
```

本次验收使用的签名交付物：

```text
artifacts/t07-device-acceptance/20261001-211416/deliverables/test_host-default-signed.hap
artifacts/t07-device-acceptance/20261001-211416/deliverables/test_host-ohosTest-signed.hap
```

- 主 HAP：47,057 bytes，SHA-256 `31188D7014260DAD33FD9F500CA4C70C20DB4E79D2BB76583F701C44F77DE66D`
- ohosTest HAP：2,048,764 bytes，SHA-256 `AE8B5A9933F59F14C5DB894E02E99EA78CEFD34568C02D23AEA2FB5044A62B74`
- 临时签名配置已删除，项目根 `build-profile.json5` 已恢复；私钥和口令未进入验收目录。

## 设备运行

使用已有 DevEco/组织签名流程生成可安装 HAP；不得把私钥、证书口令或账户凭据提交到仓库。确认目标设备和 bundle 后，执行：

```powershell
hdc install -r <signed-main-hap>
hdc install -r <signed-ohosTest-hap>
hdc shell aa test -b com.harmony.agent -m test_host_test -s unittest OpenHarmonyTestRunner -s class StorageDeviceRecovery -s timeout 60000
```

本次目标为 `127.0.0.1:5555`，系统版本 `emulator 7.0.0.106(SP1DEVC00E999R4P11)`，API 版本 26。Hypium 报告：

```text
Tests run: 7, Failure: 0, Error: 0, Pass: 7, Ignore: 0
```

安装、测试、设备信息和清理日志均位于成功运行目录的 `logs/` 下；`acceptance-summary.json` 是机器可读摘要。

验收后清理：

```powershell
hdc uninstall com.harmony.agent
```

同时确认测试 bundle 已不存在。测试自身会删除 fixture 数据库，但卸载验证仍然必须独立完成。


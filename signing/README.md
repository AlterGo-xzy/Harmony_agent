# 本机签名说明

本目录不保存实际签名材料。`.p12`、`.cer`、`.p7b` 和其他本机签名文件不得提交。

设备验收统一通过 `tools/test-mcp.ps1` 触发。操作者首次使用前手动执行：

```powershell
devecocli auth login
```

当设备测试条件满足时，脚本使用无签名 `build-profile.json5` 模板调用 `devecocli signature generate --product default`。带签名配置缓存在被忽略的 `.local/`，HAP 构建结束后恢复仓库模板。DevEco 管理的用户级证书材料可能被多个工程复用，脚本不会自动删除。

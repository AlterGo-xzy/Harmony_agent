# Shuvi 图片输入后端初步规划与交接

更新时间：2026-10-21

## 1. 目标与当前结论

目标是让用户从系统相册选择图片后，图片能够被 Shuvi Agent 安全接收、暂存、分析，并在取消、失败、过期或 Ability 关闭时释放资源。

本分支已经完成第一层“图片引用进入任务”的地基：

- `AgentFrontendTaskRequest` 可以携带最多 4 个图片引用；
- 接受 `image/jpeg`、`image/png`、`image/webp`；
- 要求完整 SHA-256、受约束的 `attachment://<refId>` 来源和唯一引用 ID；
- 图片引用进入 `TaskSubmission.inputRefs`，并随 Session normalization 进入 `TaskEnvelope`；
- `TaskAnalyzer` 会产生 `image-input` capability 和 `imageInputCount`；
- Contracts 要求每个 `TaskInputRef` 都具有 `mediaType` 和 `source`。

这不是完整图片输入。当前没有读取图片 URI、保存图片字节、解析真实格式，也没有视觉模型或 `image_analyze` 工具。现有 `AgentFrontendImageInput` 是过渡接口，后续应收回为后端内部数据，不能要求前端生成摘要或内部引用。

## 2. 冻结的产品边界

完整数据流：

```text
ArkUI 页面
  -> PhotoViewPicker 返回临时 URI
  -> AgentApplicationBackend.stageImage(uri)
  -> AttachmentStore 导入、校验、摘要和暂存
  -> 返回 attachmentId
  -> submitTask(intent, attachmentIds)
  -> 内部 TaskInputRef
  -> Runtime / Policy / Registry
  -> image_analyze
  -> Vision Provider
  -> 结构化结果和任务事件
```

前端只负责：

- 触发系统图片选择器；
- 展示本地预览、删除、排序和上传/处理状态；
- 把临时 URI 交给 `stageImage`；
- 保存后端返回的 `attachmentId`；
- 提交 `intent + attachmentIds`；
- 调用取消、释放接口并展示稳定错误。

后端负责：

- 在系统 URI 可读期间立即导入图片；
- 复制到应用私有目录，验证真实格式、大小、图片头和可解码性；
- 计算摘要、生成不可猜测的附件 ID、记录所有权和过期时间；
- 把附件 ID 转成内部 `TaskInputRef`；
- 控制远端图片上传授权、模型调用、取消、审计和资源释放；
- 确保 Base64、私有路径、图片正文和凭据不进入任务事件、日志、记忆或 checkpoint。

前端不得直接操作 `TaskInputRef`、MCP、Provider、Runtime、Storage、API Key、SHA-256 或 `attachment://` 内部协议。

## 3. 建议的稳定前端接口

```ts
export class AgentFrontendImageSource {
  uri: string = '';
}

export class AgentFrontendAttachment {
  attachmentId: string = '';
  mediaType: string = '';
  byteLength: number = 0;
  width: number = 0;
  height: number = 0;
  expiresAt: string = '';
}

export class AgentFrontendTaskRequest {
  requestId?: string;
  conversationId?: string;
  intent: string = '';
  attachmentIds: string[] = [];
}

stageImage(source: AgentFrontendImageSource): Promise<AgentFrontendAttachment>;
releaseAttachment(attachmentId: string): Promise<void>;
submitTask(request: AgentFrontendTaskRequest): Promise<AgentFrontendTaskHandle>;
```

`stageImage` 返回成功后，原始系统 URI 不再是 Runtime 的持久身份。Runtime、checkpoint、恢复和工具调用只保存 `attachmentId` 或由后端生成的 `TaskInputRef`。

## 4. 后端内部契约

建议新增独立端口，不让 Runtime 直接依赖 OHOS 文件 API：

```ts
export interface AgentAttachmentStorePort {
  open(): Promise<void>;
  importImage(userId: string, sourceUri: string): Promise<AttachmentRecord>;
  resolveForRead(userId: string, attachmentId: string): Promise<AttachmentReadHandle>;
  bindToTask(userId: string, attachmentId: string, taskId: string): Promise<void>;
  release(userId: string, attachmentId: string): Promise<void>;
  close(): Promise<void>;
}
```

`AttachmentRecord` 至少保存：

- `attachmentId`；
- 所属用户、会话和可选任务；
- 后端私有文件定位信息；
- 可信 `mediaType`、字节数、宽高和 SHA-256；
- 创建时间、过期时间和引用状态。

不要把私有绝对路径放入公共 DTO、事件、checkpoint 或 Provider trace。

## 5. 实施顺序

### P0：修正公共接口

1. 增加 `stageImage`、`releaseAttachment` 和稳定附件 DTO。
2. 把 `AgentFrontendTaskRequest.images` 改为 `attachmentIds`。
3. 保留当前 `TaskInputRef` 作为后端内部契约。
4. 为迁移期决定是否保留一个版本的旧 DTO；如果直接替换，则提升 `AGENT_APPLICATION_BACKEND_API_VERSION`。
5. 为图片相关失败增加稳定错误码，而不是向前端返回文件系统异常文本。

### P1：AttachmentStore

建议模块：`agent_storage`，OHOS URI 读取与 Ability 上下文适配放在产品宿主或专用 host adapter。

1. 读取 `PhotoViewPicker` 返回的 URI。
2. 流式复制到应用私有临时目录，避免一次性把整张图片读入内存。
3. 导入过程中计算 SHA-256 和字节数。
4. 通过图片解码器验证格式与尺寸，不信任扩展名和前端 MIME。
5. 使用随机不可猜测 ID；绑定 `userId`，防止跨用户读取。
6. 限制单图大小、每任务数量、总暂存配额和有效期。
7. 支持原子写入：失败时删除半成品和元数据。
8. 在取消、失败、显式释放、会话过期和 Ability 关闭时执行幂等清理。

建议首版继续保持最多 4 张、JPEG/PNG/WebP。具体单图字节和总配额应由产品配置冻结后写入测试，不要散落为多个硬编码值。

### P2：图片分析能力

建议实现本地 Tool Connector，而不是让远端 MCP 读取设备路径：

```json
{
  "tool": "image_analyze",
  "arguments": {
    "attachmentId": "att_...",
    "instruction": "描述图片并提取可见文字"
  }
}
```

1. 在 Registry 注册 `image_analyze`，接入 allowlist、授权、取消和审计链。
2. Tool 执行时通过 `AgentAttachmentStorePort` 获取只读句柄。
3. 新增独立 `VisionModelTransportPort` 或为 Provider message 增加类型化 content parts；不要在通用字符串 prompt 中拼接 Base64。
4. 仅在 Provider transport 的最后一跳构造供应商要求的图片载荷。
5. 远端上传图片前必须根据 privacy class 和 data boundary 触发明确授权。
6. 取消必须同时中止文件读取、编码和 HTTP 请求。

建议输出稳定结构：

```json
{
  "schemaVersion": "1.0",
  "description": "...",
  "extractedText": "...",
  "mediaType": "image/jpeg",
  "width": 1920,
  "height": 1080
}
```

不要把供应商原始响应直接暴露给前端。

### P3：Runtime 与恢复

1. 保留本分支已经加入的 `image-input` capability。
2. Planner 为带图片的任务生成 `image_analyze` Tool step。
3. Tool invocation 只携带附件 ID，不携带私有路径或图片正文。
4. checkpoint 只保存引用和可信元数据。
5. 恢复时检查附件仍存在、未过期且属于当前用户；否则以稳定失败或重新选择图片结束，不能静默调用空图片。
6. Tool outcome 回到现有 replan/结果链，由 Agent 结合用户文本生成最终回答。

### P4：Ability 和设备联调

1. 使用 `@kit.MediaLibraryKit` 的 `photoAccessHelper.PhotoViewPicker`，不要使用已经弃用的旧 picker。
2. 验证选取 1 张和多张图片、用户取消选择、URI 无法读取、应用退后台和进程恢复。
3. 验证 JPEG/PNG/WebP 正常路径，以及伪造扩展名、超限文件、损坏图片和重复图片。
4. 验证提交、授权、远端分析、用户取消、超时和资源释放。
5. 验证任务事件和日志中不存在 URI、私有路径、Base64、图片正文或 Provider 凭据。
6. 保存签名 HAP、设备型号/API、HDC 日志、任务事件和清理证据。

## 6. 稳定错误建议

- `IMAGE_URI_INVALID`
- `IMAGE_READ_DENIED`
- `IMAGE_TOO_LARGE`
- `IMAGE_MEDIA_TYPE_UNSUPPORTED`
- `IMAGE_DECODE_FAILED`
- `ATTACHMENT_NOT_FOUND`
- `ATTACHMENT_EXPIRED`
- `ATTACHMENT_OWNERSHIP_MISMATCH`
- `IMAGE_ANALYSIS_NOT_AUTHORIZED`
- `IMAGE_ANALYSIS_CANCELLED`
- `VISION_PROVIDER_UNAVAILABLE`

错误事件只包含稳定错误码和安全提示，不包含 URI、路径、图片正文或供应商原始异常。

## 7. 验收门

完成标准分为四层，不能互相替代：

1. **Contracts/HAR**：接口、校验和 Release HAR 构建通过。
2. **Host tests**：真实临时文件的导入、摘要、格式识别、所有权、过期和清理通过。
3. **Provider/tool tests**：视觉请求、授权、取消、超时、脱敏和结构化输出通过。
4. **设备验收**：真实 `PhotoViewPicker` URI 可导入，图片能被视觉 Provider 分析，任务完成或取消后资源被释放。

当前分支只满足第 1 层的一部分：图片引用 DTO、校验、任务映射、Planner capability、单元测试和 `agent_runtime` Release HAR 构建。它不证明真实图片读取、视觉分析或设备行为。

## 8. 当前相关文件

- `agent_runtime/src/main/ets/host/AgentApplicationBackend.ets`
- `agent_runtime/src/main/ets/orchestration/TaskAnalyzer.ets`
- `agent_runtime/src/main/ets/orchestration/SessionNormalization.ets`
- `agent_contracts/src/main/ets/contracts/TaskContracts.ets`
- `agent_contracts/src/main/ets/contracts/RuntimeContracts.ets`
- `agent_contracts/src/main/ets/contracts/ContractValidator.ets`
- `agent_runtime/src/test/ImageInput.test.ets`

建议下一位开发者从 P0 和 P1 开始，不要先改 ArkUI，也不要先把 Base64 塞进现有 `ModelMessage.content: string`。

# Định dạng tệp phiên

Các phiên được lưu trữ dưới dạng tệp JSONL (JSON Lines). Mỗi dòng là một đối tượng JSON có trường `type`. Các mục nhập phiên tạo thành cấu trúc cây thông qua các trường `id`/`parentId`, cho phép phân nhánh tại chỗ mà không cần tạo tệp mới.

## Vị trí tệp

```
~/.prime/agent/sessions/<session-id>.jsonl
```

Tiêu đề ghi lại thư mục làm việc. Các bản phát hành hiện tại giữ các phiên trong một thư mục phẳng; các thư mục cũ hơn cho mỗi dự án sẽ được di chuyển tự động.

## Xóa phiên

Có thể xóa phiên bằng cách xóa các tệp `.jsonl` của chúng trong `~/.prime/agent/sessions/`.

Prime Agent cũng hỗ trợ xóa các phiên tương tác khỏi `/resume` (chọn một phiên và nhấn `Ctrl+D`, sau đó xác nhận). Khi khả dụng, Prime Agent sử dụng `trash` CLI để tránh bị xóa vĩnh viễn.

## Phiên bản phiên

Phiên có trường phiên bản trong tiêu đề:

- **Phiên bản 1**: Trình tự nhập tuyến tính (cũ, tự động di chuyển khi tải)
- **Phiên bản 2**: Cấu trúc cây với liên kết `id`/`parentId`
- **Phiên bản 3**: Đổi tên vai trò `hookMessage` thành `custom` (hợp nhất tiện ích mở rộng)

Các phiên hiện tại sẽ tự động được di chuyển sang phiên bản hiện tại (v3) khi được tải.

## Tệp nguồn

- [`session-manager.ts`](../src/core/session-manager.ts) - Các loại mục nhập phiên và `SessionManager`
- [`messages.ts`](../src/core/messages.ts) - Các loại tin nhắn mở rộng (`BashExecutionMessage`, `CustomMessage` và các loại khác)
- [`packages/ai/src/types.ts`](../../ai/src/types.ts) - Các loại thông báo cơ bản (`UserMessage`, `AssistantMessage`, `ToolResultMessage`)
- [`packages/agent/src/types.ts`](../../agent/src/types.ts) - Loại kết hợp `AgentMessage`

Để biết các định nghĩa TypeScript trong dự án của bạn, hãy kiểm tra `node_modules/@earendil-works/pi-coding-agent/dist/` và `node_modules/@earendil-works/pi-ai/dist/`.

## Loại tin nhắn

Các mục phiên chứa các đối tượng `AgentMessage`. Hiểu các loại này là điều cần thiết cho các phiên phân tích cú pháp và viết phần mở rộng.

### Khối nội dung

Tin nhắn chứa mảng các khối nội dung được gõ:

```typescript
interface TextContent {
  type: "text";
  text: string;
}

interface ImageContent {
  type: "image";
  data: string;      // base64 encoded
  mimeType: string;  // e.g., "image/jpeg", "image/png"
}

interface ThinkingContent {
  type: "thinking";
  thinking: string;
}

interface ToolCall {
  type: "toolCall";
  id: string;
  name: string;
  arguments: Record<string, any>;
}
```

### Các loại thông báo cơ sở (từ Prime Agent AI)

```typescript
interface UserMessage {
  role: "user";
  content: string | (TextContent | ImageContent)[];
  timestamp: number;  // Unix ms
}

interface AssistantMessage {
  role: "assistant";
  content: (TextContent | ThinkingContent | ToolCall)[];
  api: string;
  provider: string;
  model: string;
  usage: Usage;
  stopReason: "stop" | "length" | "toolUse" | "error" | "aborted";
  errorMessage?: string;
  timestamp: number;
}

interface ToolResultMessage {
  role: "toolResult";
  toolCallId: string;
  toolName: string;
  content: (TextContent | ImageContent)[];
  details?: any;      // Tool-specific metadata
  isError: boolean;
  timestamp: number;
}

interface Usage {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  totalTokens: number;
  cost: {
    input: number;
    output: number;
    cacheRead: number;
    cacheWrite: number;
    total: number;
  };
}
```

### Các loại tin nhắn mở rộng (từ Tác nhân mã hóa Prime Agent)

```typescript
interface BashExecutionMessage {
  role: "bashExecution";
  command: string;
  output: string;
  exitCode: number | undefined;
  cancelled: boolean;
  truncated: boolean;
  fullOutputPath?: string;
  excludeFromContext?: boolean;  // true for !! prefix commands
  timestamp: number;
}

interface CustomMessage {
  role: "custom";
  customType: string;            // Extension identifier
  content: string | (TextContent | ImageContent)[];
  display: boolean;              // Show in TUI
  details?: any;                 // Extension-specific metadata
  timestamp: number;
}

interface BranchSummaryMessage {
  role: "branchSummary";
  summary: string;
  fromId: string;                // Entry we branched from
  timestamp: number;
}

interface CompactionSummaryMessage {
  role: "compactionSummary";
  summary: string;
  tokensBefore: number;
  timestamp: number;
}
```

### Liên minh AgentMessage

```typescript
type AgentMessage =
  | UserMessage
  | AssistantMessage
  | ToolResultMessage
  | BashExecutionMessage
  | CustomMessage
  | BranchSummaryMessage
  | CompactionSummaryMessage;
```

## Cơ sở nhập cảnh

Tất cả các mục (ngoại trừ `SessionHeader`) đều mở rộng `SessionEntryBase`:

```typescript
interface SessionEntryBase {
  type: string;
  id: string;           // 8-char hex ID
  parentId: string | null;  // Parent entry ID (null for first entry)
  timestamp: string;    // ISO timestamp
}
```

## Loại mục nhập

### SessionHeader

Dòng đầu tiên của tập tin. Chỉ siêu dữ liệu, không phải là một phần của cây (không có `id`/`parentId`).

```json
{"type":"session","version":3,"id":"uuid","timestamp":"2024-12-03T14:00:00.000Z","cwd":"/path/to/project"}
```

Đối với các phiên có cấp độ gốc (được tạo qua `/fork`, `/clone` hoặc `newSession({ parentSession })`):

```json
{"type":"session","version":3,"id":"uuid","timestamp":"2024-12-03T14:00:00.000Z","cwd":"/path/to/project","parentSession":"/path/to/original/session.jsonl"}
```

### SessionMessageEntry

Một tin nhắn trong cuộc trò chuyện. Trường `message` chứa `AgentMessage`.

```json
{"type":"message","id":"a1b2c3d4","parentId":"prev1234","timestamp":"2024-12-03T14:00:01.000Z","message":{"role":"user","content":"Hello"}}
{"type":"message","id":"b2c3d4e5","parentId":"a1b2c3d4","timestamp":"2024-12-03T14:00:02.000Z","message":{"role":"assistant","content":[{"type":"text","text":"Hi!"}],"provider":"anthropic","model":"claude-sonnet-4-5","usage":{...},"stopReason":"stop"}}
{"type":"message","id":"c3d4e5f6","parentId":"b2c3d4e5","timestamp":"2024-12-03T14:00:03.000Z","message":{"role":"toolResult","toolCallId":"call_123","toolName":"bash","content":[{"type":"text","text":"output"}],"isError":false}}
```

### ModelChangeEntry

Được phát ra khi người dùng chuyển đổi mô hình giữa phiên.

```json
{"type":"model_change","id":"d4e5f6g7","parentId":"c3d4e5f6","timestamp":"2024-12-03T14:05:00.000Z","provider":"openai","modelId":"gpt-4o"}
```

### ThinkingLevelChangeEntry

Phát ra khi người dùng thay đổi mức độ suy nghĩ/lý luận.

```json
{"type":"thinking_level_change","id":"e5f6g7h8","parentId":"d4e5f6g7","timestamp":"2024-12-03T14:06:00.000Z","thinkingLevel":"high"}
```

### ServiceTierChangeEntry

Được phát ra khi người dùng thay đổi cấp dịch vụ của nhà cung cấp.

```json
{"type":"service_tier_change","id":"e6f7g8h9","parentId":"e5f6g7h8","timestamp":"2024-12-03T14:07:00.000Z","serviceTier":"priority"}
```

### CompactionEntry

Được tạo khi bối cảnh được nén. Lưu trữ một bản tóm tắt các tin nhắn trước đó.

```json
{"type":"compaction","id":"f6g7h8i9","parentId":"e5f6g7h8","timestamp":"2024-12-03T14:10:00.000Z","summary":"User discussed X, Y, Z...","firstKeptEntryId":"c3d4e5f6","tokensBefore":50000}
```

Các trường tùy chọn:
- `details`: Dữ liệu dành riêng cho việc triển khai (ví dụ: `{ readFiles: string[], modifiedFiles: string[] }` cho mặc định hoặc dữ liệu tùy chỉnh cho tiện ích mở rộng)
- `fromHook`: `true` nếu được tạo bởi tiện ích mở rộng, `false`/`undefined` nếu được tạo bởi Prime Agent (tên trường kế thừa)

### BranchSummaryEntry

Được tạo khi chuyển nhánh thông qua `/tree` với bản tóm tắt được tạo bởi LLM của nhánh bên trái lên đến tổ tiên chung. Ghi lại bối cảnh từ con đường bị bỏ hoang.

```json
{"type":"branch_summary","id":"g7h8i9j0","parentId":"a1b2c3d4","timestamp":"2024-12-03T14:15:00.000Z","fromId":"f6g7h8i9","summary":"Branch explored approach A..."}
```

Các trường tùy chọn:
- `details`: Dữ liệu theo dõi tệp (`{ readFiles: string[], modifiedFiles: string[] }`) cho mặc định hoặc dữ liệu tùy chỉnh cho tiện ích mở rộng
- `fromHook`: `true` nếu được tạo bởi tiện ích mở rộng, `false`/`undefined` nếu được tạo bởi Prime Agent (tên trường kế thừa)

### CustomEntry

Sự kiên trì của trạng thái mở rộng. NOT có tham gia vào bối cảnh LLM không.

```json
{"type":"custom","id":"h8i9j0k1","parentId":"g7h8i9j0","timestamp":"2024-12-03T14:20:00.000Z","customType":"my-extension","data":{"count":42}}
```

Sử dụng `customType` để xác định các mục nhập tiện ích mở rộng của bạn khi tải lại.

### ChildUsageAttributionEntry

Ghi lại việc sử dụng RLM của trẻ được xếp thành tin nhắn trợ lý phụ huynh. Mục này là sổ sách kế toán daemon và không nhập ngữ cảnh mô hình.

```typescript
interface ChildUsageAttributionEntry extends SessionEntryBase {
  type: "child_usage_attributed";
  targetId: string;       // Parent assistant message entry
  childUsage: Usage;      // Usage added by one child
  aggregateUsage: Usage;  // Updated parent aggregate
}
```

Tải lại áp dụng `aggregateUsage` cho tin nhắn trợ lý đích. Sau đó, việc tính toán cây ngữ cảnh có thể trừ `childUsage` khi báo cáo mức sử dụng của chính nút cha.

### CustomMessageEntry

Các tin nhắn được đưa vào tiện ích mở rộng mà DO tham gia vào ngữ cảnh LLM.

```json
{"type":"custom_message","id":"i9j0k1l2","parentId":"h8i9j0k1","timestamp":"2024-12-03T14:25:00.000Z","customType":"my-extension","content":"Injected context...","display":true}
```

Lĩnh vực:
- `content`: Chuỗi hoặc `(TextContent | ImageContent)[]` (giống UserMessage)
- `display`: `true` = hiển thị trong TUI với kiểu dáng riêng biệt, `false` = ẩn
- `details`: Siêu dữ liệu dành riêng cho tiện ích mở rộng tùy chọn (không được gửi tới LLM)

### LabelEntry

Dấu trang/điểm đánh dấu do người dùng xác định trên một mục nhập.

```json
{"type":"label","id":"j0k1l2m3","parentId":"i9j0k1l2","timestamp":"2024-12-03T14:30:00.000Z","targetId":"a1b2c3d4","label":"checkpoint-1"}
```

Đặt `label` thành `undefined` để xóa nhãn.

### SessionInfoEntry

Siêu dữ liệu phiên (ví dụ: tên hiển thị do người dùng xác định). Đặt thông qua lệnh `/name` hoặc `pi.setSessionName()` trong phần mở rộng.

```json
{"type":"session_info","id":"k1l2m3n4","parentId":"j0k1l2m3","timestamp":"2024-12-03T14:35:00.000Z","name":"Refactor auth module"}
```

Tên phiên được hiển thị trong bộ chọn phiên (`/resume`) thay vì thông báo đầu tiên khi được đặt.

### SessionStateEntry

Lưu trữ trạng thái vòng đời do daemon quản lý. Các trạng thái tồn tại hiện tại là `active`, `archived` và `crash` cũ; các giá trị `sleep` cũ hơn sẽ chuẩn hóa thành `archived` khi đọc.

### AgentStatusEntry

Lưu trữ trạng thái tổng đài viên ngắn mới nhất được hiển thị trong chế độ xem tổng đài viên, bao gồm tóm tắt, trạng thái nhiệm vụ tùy chọn và số lượng tin nhắn nguồn. Nó không đi vào bối cảnh mô hình.

### GitStateEntry

Lưu trữ ảnh chụp nhanh trạng thái kho lưu trữ chỉ bổ sung cho trạng thái tác nhân và chế độ xem khôi phục. Nó không đi vào bối cảnh mô hình.

## Cấu trúc cây

Các mục tạo thành một cây:
- Mục đầu tiên có `parentId: null`
- Mỗi mục nhập tiếp theo trỏ tới mục gốc của nó thông qua `parentId`
- Phân nhánh tạo ra các mục con mới từ mục nhập trước đó
- “Chiếc lá” là vị trí hiện tại trong cây

```
[user msg] ─── [assistant] ─── [user msg] ─── [assistant] ─┬─ [user msg] ← current leaf
                                                            │
                                                            └─ [branch_summary] ─── [user msg] ← alternate branch
```

## Xây dựng bối cảnh

`buildSessionContext()` đi từ lá hiện tại đến gốc, tạo danh sách thông báo cho LLM:

1. Thu thập tất cả các mục trên đường dẫn
2. Trích xuất các cài đặt mô hình và cấp độ tư duy hiện tại
3. Nếu `CompactionEntry` nằm trên đường dẫn:
- Phát ra bản tóm tắt đầu tiên
- Sau đó nhắn từ `firstKeptEntryId` đến nén
- Sau đó nhắn tin sau khi nén
4. Chuyển đổi `BranchSummaryEntry` và `CustomMessageEntry` sang các định dạng tin nhắn phù hợp

Các mục ghi sổ kế toán như phân bổ mức sử dụng con, vòng đời phiên, trạng thái tổng đài viên và trạng thái git đều bị bỏ qua khi xây dựng bối cảnh mô hình.

## Ví dụ phân tích cú pháp

```typescript
import { readFileSync } from "fs";

const lines = readFileSync("session.jsonl", "utf8").trim().split("\n");

for (const line of lines) {
  const entry = JSON.parse(line);

  switch (entry.type) {
    case "session":
      console.log(`Session v${entry.version ?? 1}: ${entry.id}`);
      break;
    case "message":
      console.log(`[${entry.id}] ${entry.message.role}: ${JSON.stringify(entry.message.content)}`);
      break;
    case "compaction":
      console.log(`[${entry.id}] Compaction: ${entry.tokensBefore} tokens summarized`);
      break;
    case "branch_summary":
      console.log(`[${entry.id}] Branch from ${entry.fromId}`);
      break;
    case "custom":
      console.log(`[${entry.id}] Custom (${entry.customType}): ${JSON.stringify(entry.data)}`);
      break;
    case "custom_message":
      console.log(`[${entry.id}] Extension message (${entry.customType}): ${entry.content}`);
      break;
    case "label":
      console.log(`[${entry.id}] Label "${entry.label}" on ${entry.targetId}`);
      break;
    case "model_change":
      console.log(`[${entry.id}] Model: ${entry.provider}/${entry.modelId}`);
      break;
    case "thinking_level_change":
      console.log(`[${entry.id}] Thinking: ${entry.thinkingLevel}`);
      break;
  }
}
```

## SessionManager API

Các phương pháp chính để làm việc với phiên theo chương trình.

### Phương pháp tạo tĩnh
- `SessionManager.create(cwd, sessionDir?)` - Phiên mới
- `SessionManager.open(path, sessionDir?)` - Mở tệp phiên hiện có
- `SessionManager.continueRecent(cwd, sessionDir?)` - Tiếp tục gần đây nhất hoặc tạo mới
- `SessionManager.inMemory(cwd?)` - Không tồn tại tập tin
- `SessionManager.forkFrom(sourcePath, targetCwd, sessionDir?)` - Phiên phân nhánh từ một dự án khác

### Phương pháp liệt kê tĩnh
- `SessionManager.list(cwd, sessionDir?, callbacks?)` - Liệt kê các phiên cho một thư mục
- `SessionManager.listAll(callbacks?, sessionDir?)` - Liệt kê tất cả các phiên trên tất cả các dự án

`callbacks` có thể cung cấp trình xử lý `onProgress(loaded, total)` và `onSession(session)`.

### Phương thức phiên bản - Quản lý phiên
- `newSession(options?)` - Bắt đầu phiên mới (tùy chọn: `{ parentSession?: string }`)
- `setSessionFile(path)` - Chuyển sang tệp phiên khác
- `createBranchedSession(leafId)` - Trích xuất nhánh sang tệp phiên mới

### Phương thức phiên bản - Đang thêm (tất cả mục trả về ID)
- `appendMessage(message)` - Thêm tin nhắn
- `appendThinkingLevelChange(level)` - Ghi lại sự thay đổi tư duy
- `appendServiceTierChange(tier)` - Ghi lại thay đổi cấp dịch vụ của nhà cung cấp
- `appendModelChange(provider, modelId)` - Ghi lại sự thay đổi model
- `appendCompaction(summary, firstKeptEntryId, tokensBefore, details?, fromHook?, customInstructions?)` - Thêm độ nén
- `appendCustomEntry(customType, data?)` - Trạng thái mở rộng (không có trong ngữ cảnh)
- `appendChildUsageAttribution(targetId, childUsage, aggregateUsage)` - Duy trì việc sử dụng RLM của trẻ em được xếp thành tin nhắn trợ lý phụ huynh
- `appendSessionInfo(name)` - Đặt tên hiển thị phiên
- `appendSessionState(state)` - Ghi lại trạng thái vòng đời do daemon quản lý
- `appendAgentStatus(status)` - Ghi tóm tắt trạng thái xem tác nhân
- `appendGitState(git)` - Ghi lại trạng thái kho lưu trữ
- `appendCustomMessageEntry(customType, content, display, details?)` - Tin nhắn mở rộng (trong ngữ cảnh)
- `appendLabelChange(targetId, label)` - Đặt/xóa nhãn

### Phương thức phiên bản - Điều hướng dạng cây
- `getLeafId()` - Vị trí hiện tại
- `getLeafEntry()` - Nhận mục nhập lá hiện tại
- `getEntry(id)` - Nhận mục nhập của ID
- `getBranch(fromId?)` - Đi từ đầu vào đến gốc
- `getTree()` - Lấy cấu trúc cây đầy đủ
- `getChildren(parentId)` - Nhận con trực tiếp
- `getLabel(id)` - Nhận nhãn đầu vào
- `branch(entryId)` - Di chuyển lá về mục trước đó
- `resetLeaf()` - Đặt lại lá về null (trước bất kỳ mục nào)
- `branchWithSummary(entryId, summary, details?, fromHook?)` - Nhánh có tóm tắt ngữ cảnh

### Phương thức phiên bản - Ngữ cảnh & Thông tin
- `buildSessionContext()` - Nhận tin nhắn, thinkingLevel và model cho LLM
- `getEntries()` - Tất cả các mục (không bao gồm tiêu đề)
- `getHeader()` - Siêu dữ liệu tiêu đề phiên
- `getSessionName()` - Nhận tên hiển thị từ mục session_info mới nhất
- `getCwd()` - Thư mục làm việc
- `getSessionDir()` - Thư mục lưu trữ phiên
- `getSessionId()` - Phiên UUID
- `getSessionFile()` - Đường dẫn tệp phiên (không xác định cho trong bộ nhớ)
- `isPersisted()` - Phiên có được lưu vào đĩa hay không

# Chế độ RPC

Chế độ RPC cho phép tác nhân mã hóa hoạt động không đầu thông qua giao thức JSON qua stdin/stdout. Điều này hữu ích cho việc nhúng tác nhân vào các ứng dụng khác, IDEs hoặc UIs tùy chỉnh.

**Lưu ý dành cho người dùng Node.js/TypeScript**: Nếu bạn đang xây dựng ứng dụng Node.js, hãy cân nhắc sử dụng `AgentSession` trực tiếp từ `@earendil-works/pi-coding-agent` thay vì tạo ra một quy trình con. Xem [`src/core/agent-session.ts`](../src/core/agent-session.ts) để biết API. Đối với máy khách TypeScript dựa trên quy trình con, hãy xem [`src/modes/rpc/rpc-client.ts`](../src/modes/rpc/rpc-client.ts).

## Đang khởi động Chế độ RPC

```bash
prime-agent --mode rpc [options]
```

Các tùy chọn phổ biến:
- `--provider <name>`: Đặt nhà cung cấp LLM (anthropic, openai, google, v.v.)
- `--model <pattern>`: Mẫu mô hình hoặc ID (hỗ trợ `provider/id` và `:<thinking>` tùy chọn)
- `--no-session`: Tắt tính năng duy trì phiên
- `--session-dir <path>`: Thư mục lưu trữ phiên tùy chỉnh

## Tổng quan về giao thức

- **Lệnh**: Các đối tượng JSON được gửi tới stdin, mỗi dòng một đối tượng
- **Phản hồi**: Đối tượng JSON có `type: "response"` biểu thị lệnh thành công/thất bại
- **Sự kiện**: Các sự kiện của tác nhân được truyền tới thiết bị xuất chuẩn dưới dạng dòng JSON

Tất cả các lệnh đều hỗ trợ trường `id` tùy chọn để tương quan yêu cầu/phản hồi. Nếu được cung cấp, phản hồi tương ứng sẽ bao gồm cùng một `id`.

### Đóng khung

Chế độ RPC sử dụng ngữ nghĩa JSONL nghiêm ngặt với LF (`\n`) làm dấu phân cách bản ghi duy nhất.

Điều này quan trọng đối với máy khách:
- Chỉ chia bản ghi trên `\n`
- Chấp nhận đầu vào `\r\n` tùy chọn bằng cách loại bỏ `\r` ở cuối
- Không sử dụng các trình đọc dòng chung coi dấu phân cách Unicode là dòng mới

Đặc biệt, Node `readline` không tuân thủ giao thức cho chế độ RPC vì nó cũng phân tách trên `U+2028` và `U+2029`, hợp lệ bên trong các chuỗi JSON.

## Lệnh

### Nhắc nhở

#### prompt

Gửi lời nhắc của người dùng tới tác nhân. Phản hồi lệnh được phát ra sau khi lời nhắc được chấp nhận, xếp hàng hoặc xử lý. Các sự kiện tiếp tục phát trực tuyến không đồng bộ sau khi được chấp nhận.

```json
{"id": "req-1", "type": "prompt", "message": "Hello, world!"}
```

Với hình ảnh:
```json
{"type": "prompt", "message": "What's in this image?", "images": [{"type": "image", "data": "base64-encoded-data", "mimeType": "image/png"}]}
```

**Trong khi phát trực tuyến**: Nếu tác nhân đã phát trực tuyến, bạn phải chỉ định `streamingBehavior` để xếp hàng tin nhắn:

```json
{"type": "prompt", "message": "New instruction", "streamingBehavior": "steer"}
```

- `"steer"`: Xếp hàng tin nhắn trong khi tác nhân đang chạy. Nó được phân phối sau khi lượt trợ lý hiện tại hoàn tất việc thực hiện lệnh gọi công cụ của nó, trước lệnh gọi LLM tiếp theo.
- `"followUp"`: Đợi đến khi tác nhân kết thúc. Tin nhắn chỉ được gửi khi tác nhân dừng lại.

Nếu tác nhân đang phát trực tuyến và không có `streamingBehavior` nào được chỉ định, lệnh sẽ trả về lỗi.

**Lệnh mở rộng**: Nếu thông báo là lệnh mở rộng (ví dụ: `/mycommand`), thì nó sẽ thực thi ngay lập tức ngay cả khi đang phát trực tuyến. Các lệnh mở rộng quản lý tương tác LLM của riêng chúng thông qua `pi.sendMessage()`.

**Mở rộng đầu vào**: Lệnh kỹ năng (`/skill:name`) và mẫu lời nhắc (`/template`) được mở rộng trước khi gửi/xếp hàng.

Phản hồi:
```json
{"id": "req-1", "type": "response", "command": "prompt", "success": true}
```

`success: true` có nghĩa là lời nhắc đã được chấp nhận, xếp hàng hoặc xử lý ngay lập tức. `success: false` có nghĩa là lời nhắc đã bị từ chối trước khi được chấp nhận. Các lỗi sau khi chấp nhận được báo cáo thông qua luồng tin nhắn và sự kiện thông thường, không phải dưới dạng `response` thứ hai cho cùng một id yêu cầu.

Trường `images` là tùy chọn. Mỗi hình ảnh sử dụng định dạng `ImageContent`: `{"type": "image", "data": "base64-encoded-data", "mimeType": "image/png"}`.

#### steer

Xếp hàng tin nhắn chỉ đạo trong khi tác nhân đang chạy. Nó được phân phối sau khi lượt trợ lý hiện tại hoàn tất việc thực hiện lệnh gọi công cụ của nó, trước lệnh gọi LLM tiếp theo. Lệnh kỹ năng và mẫu nhắc nhở được mở rộng. Các lệnh mở rộng không được phép (thay vào đó hãy sử dụng `prompt`).

```json
{"type": "steer", "message": "Stop and do this instead"}
```

Với hình ảnh:
```json
{"type": "steer", "message": "Look at this instead", "images": [{"type": "image", "data": "base64-encoded-data", "mimeType": "image/png"}]}
```

Trường `images` là tùy chọn. Mỗi hình ảnh sử dụng định dạng `ImageContent` (giống như `prompt`).

Phản hồi:
```json
{"type": "response", "command": "steer", "success": true}
```

Xem [set_steering_mode](#set_steering_mode) để biết cách xử lý thông báo lái.

#### follow_up

Xếp hàng tin nhắn tiếp theo để xử lý sau khi tác nhân kết thúc. Chỉ được gửi khi tác nhân không còn cuộc gọi công cụ hoặc tin nhắn chỉ đạo nào nữa. Lệnh kỹ năng và mẫu nhắc nhở được mở rộng. Các lệnh mở rộng không được phép (thay vào đó hãy sử dụng `prompt`).

```json
{"type": "follow_up", "message": "After you're done, also do this"}
```

Với hình ảnh:
```json
{"type": "follow_up", "message": "Also check this image", "images": [{"type": "image", "data": "base64-encoded-data", "mimeType": "image/png"}]}
```

Trường `images` là tùy chọn. Mỗi hình ảnh sử dụng định dạng `ImageContent` (giống như `prompt`).

Phản hồi:
```json
{"type": "response", "command": "follow_up", "success": true}
```

Xem [set_follow_up_mode](#set_follow_up_mode) để biết cách xử lý các tin nhắn tiếp theo.

#### abort

Hủy bỏ hoạt động tác nhân hiện tại.

```json
{"type": "abort"}
```

Phản hồi:
```json
{"type": "response", "command": "abort", "success": true}
```

#### new_session

Bắt đầu một phiên mới. Có thể bị hủy bởi trình xử lý sự kiện mở rộng `session_before_switch`.

```json
{"type": "new_session"}
```

Với tính năng theo dõi phiên gốc tùy chọn:
```json
{"type": "new_session", "parentSession": "/path/to/parent-session.jsonl"}
```

Phản hồi:
```json
{"type": "response", "command": "new_session", "success": true, "data": {"cancelled": false}}
```

Nếu tiện ích mở rộng bị hủy:
```json
{"type": "response", "command": "new_session", "success": true, "data": {"cancelled": true}}
```

### Tình trạng

#### get_state

Nhận trạng thái phiên hiện tại.

```json
{"type": "get_state"}
```

Phản hồi:
```json
{
  "type": "response",
  "command": "get_state",
  "success": true,
  "data": {
    "model": {...},
    "thinkingLevel": "medium",
    "isStreaming": false,
    "isCompacting": false,
    "steeringMode": "all",
    "followUpMode": "one-at-a-time",
    "sessionFile": "/path/to/session.jsonl",
    "sessionId": "abc123",
    "sessionName": "my-feature-work",
    "autoCompactionEnabled": true,
    "messageCount": 5,
    "unfinishedActionCount": 0,
    "sessionActions": {
      "queuedCount": 0,
      "steering": [],
      "followUps": []
    }
  }
}
```

Trường `model` là một đối tượng [Model](#model) đầy đủ hoặc `null`. Trường `sessionName` là tên hiển thị được đặt qua `set_session_name` hoặc bị bỏ qua nếu không được đặt.

#### get_messages

Nhận tất cả tin nhắn trong cuộc trò chuyện.

```json
{"type": "get_messages"}
```

Phản hồi:
```json
{
  "type": "response",
  "command": "get_messages",
  "success": true,
  "data": {"messages": [...]}
}
```

Thông báo là các đối tượng `AgentMessage` (xem [Loại thông báo](#các-loại)).

### Phối hợp Daemon

Máy khách RPC có thể sử dụng các tính năng phối hợp do daemon sở hữu giống như máy khách tương tác. Những lệnh này mang tính bổ sung; các lệnh hiện có và hình dạng sự kiện không thay đổi.

| Lệnh | Lĩnh vực | Dữ liệu phản hồi thành công |
|---------|--------|--------------------------|
| `send_message` | `targetActiveSessionId`, `message`, `deliveryMode` tùy chọn (`auto`, `steer`, `follow_up`) | Biên nhận gửi tin nhắn tác nhân |
| `agent_messages_status` | không | Tình trạng an toàn khi nhắn tin |
| `agent_messages_pause` | không | Đã cập nhật trạng thái an toàn khi nhắn tin |
| `agent_messages_resume` | không | Đã cập nhật trạng thái an toàn khi nhắn tin |
| `agent_messages_clear` | không | `{ "cleared": number }` |
| `list_schedules` | tùy chọn `includeInactive` | `{ "jobs": [...] }` |
| `add_schedule` | `schedule`, `prompt` | `{ "job": {...} }` |
| `cancel_schedule` | `jobId` | `{ "job": {...} }` |
| `list_heartbeats` | không | `{ "heartbeats": [...] }` |
| `get_heartbeat` | không | `{ "heartbeat": {...} }` hoặc `null` |
| `set_heartbeat` | `schedule`, `prompt`, `deliveryMode` tùy chọn (`steer`, `follow_up`) | `{ "heartbeat": {...} }` |
| `update_heartbeat` | `action` (`pause`, `resume`, `clear`) | `{ "heartbeat": {...} }` hoặc `null` |
| `manage_heartbeat` | `activeSessionId`, `jobId`, `action` (`pause`, `resume`, `stop`) | `{ "heartbeat": {...} }` |

Việc thêm lịch trình hoặc nhịp tim sẽ thúc đẩy phiên RPC cục bộ được gọi vào phiên daemon thường trú để công việc đã lên lịch vẫn khả dụng sau khi stdin RPC đóng.

Sử dụng `observe` để đăng ký phiên root hoặc tác nhân phụ đang hoạt động khác:

```json
{"id":"watch-1","type":"observe","activeSessionId":"target-session-id"}
```

Phản hồi chứa các tin nhắn hiện tại của mục tiêu. Các sự kiện mục tiêu sau này được gói lại để không thể nhầm lẫn với các sự kiện từ phiên riêng của máy khách RPC:

```json
{"type":"observed_session_event","activeSessionId":"target-session-id","event":{"type":"agent_start"}}
```

Khi mục tiêu đóng lại, RPC phát ra `observed_session_closed`. Dừng xem một cách rõ ràng với:

```json
{"type":"unobserve","activeSessionId":"target-session-id"}
```

### Model

#### set_model

Chuyển sang một mô hình cụ thể.

```json
{"type": "set_model", "provider": "anthropic", "modelId": "claude-sonnet-4-20250514"}
```

Phản hồi chứa đối tượng [Model](#model) đầy đủ:
```json
{
  "type": "response",
  "command": "set_model",
  "success": true,
  "data": {...}
}
```

#### cycle_model

Chuyển sang mô hình có sẵn tiếp theo. Trả về dữ liệu `null` nếu chỉ có một kiểu máy.

```json
{"type": "cycle_model"}
```

Phản hồi:
```json
{
  "type": "response",
  "command": "cycle_model",
  "success": true,
  "data": {
    "model": {...},
    "thinkingLevel": "medium",
    "isScoped": false
  }
}
```

Trường `model` là một đối tượng [Model](#model) đầy đủ.

#### get_available_models

Liệt kê tất cả các mô hình được cấu hình.

```json
{"type": "get_available_models"}
```

Phản hồi chứa một mảng các đối tượng [Model](#model) đầy đủ:
```json
{
  "type": "response",
  "command": "get_available_models",
  "success": true,
  "data": {
    "models": [...]
  }
}
```

### Suy nghĩ

#### set_thinking_level

Đặt mức độ lý luận/tư duy cho các mô hình hỗ trợ nó.

```json
{"type": "set_thinking_level", "level": "high"}
```

Cấp độ: `"off"`, `"minimal"`, `"low"`, `"medium"`, `"high"`, `"xhigh"`

Lưu ý: `"xhigh"` chỉ được hỗ trợ bởi các mẫu codex-max OpenAI.

Phản hồi:
```json
{"type": "response", "command": "set_thinking_level", "success": true}
```

#### cycle_thinking_level

Xoay vòng qua các cấp độ tư duy sẵn có. Trả về dữ liệu `null` nếu mô hình không hỗ trợ suy nghĩ.

```json
{"type": "cycle_thinking_level"}
```

Phản hồi:
```json
{
  "type": "response",
  "command": "cycle_thinking_level",
  "success": true,
  "data": {"level": "high"}
}
```

### Chế độ xếp hàng

#### set_steering_mode

Kiểm soát cách gửi thông báo lái (từ `steer`).

```json
{"type": "set_steering_mode", "mode": "one-at-a-time"}
```

Chế độ:
- `"all"`: Gửi tất cả các thông báo điều khiển sau khi lượt trợ lý hiện tại kết thúc việc thực hiện lệnh gọi công cụ của mình
- `"one-at-a-time"`: Gửi một thông báo chỉ đạo cho mỗi lượt trợ lý đã hoàn thành (mặc định)

Phản hồi:
```json
{"type": "response", "command": "set_steering_mode", "success": true}
```

#### set_follow_up_mode

Kiểm soát cách gửi tin nhắn tiếp theo (từ `follow_up`).

```json
{"type": "set_follow_up_mode", "mode": "one-at-a-time"}
```

Chế độ:
- `"all"`: Gửi tất cả các tin nhắn tiếp theo khi tác nhân kết thúc
- `"one-at-a-time"`: Gửi một tin nhắn tiếp theo cho mỗi lần hoàn thành tác nhân (mặc định)

Phản hồi:
```json
{"type": "response", "command": "set_follow_up_mode", "success": true}
```

### Nén chặt

#### compact

Ngữ cảnh hội thoại được thu gọn theo cách thủ công để giảm mức sử dụng token.

```json
{"type": "compact"}
```

Với hướng dẫn tùy chỉnh:
```json
{"type": "compact", "customInstructions": "Focus on code changes"}
```

Phản hồi:
```json
{
  "type": "response",
  "command": "compact",
  "success": true,
  "data": {
    "summary": "Summary of conversation...",
    "firstKeptEntryId": "abc123",
    "tokensBefore": 150000,
    "details": {}
  }
}
```

#### set_auto_compaction

Bật hoặc tắt tính năng nén tự động khi ngữ cảnh gần đầy.

```json
{"type": "set_auto_compaction", "enabled": true}
```

Phản hồi:
```json
{"type": "response", "command": "set_auto_compaction", "success": true}
```

### Thử lại

#### set_auto_retry

Bật hoặc tắt tính năng tự động thử lại đối với các lỗi nhất thời (quá tải, giới hạn tốc độ, 5xx).

```json
{"type": "set_auto_retry", "enabled": true}
```

Phản hồi:
```json
{"type": "response", "command": "set_auto_retry", "success": true}
```

#### abort_retry

Hủy bỏ quá trình thử lại đang diễn ra (hủy bỏ thời gian trì hoãn và dừng thử lại).

```json
{"type": "abort_retry"}
```

Phản hồi:
```json
{"type": "response", "command": "abort_retry", "success": true}
```

### Bash

#### bash

Thực thi lệnh shell và thêm đầu ra vào ngữ cảnh hội thoại.

```json
{"type": "bash", "command": "ls -la"}
```

Phản hồi:
```json
{
  "type": "response",
  "command": "bash",
  "success": true,
  "data": {
    "output": "total 48\ndrwxr-xr-x ...",
    "exitCode": 0,
    "cancelled": false,
    "truncated": false
  }
}
```

Nếu đầu ra bị cắt bớt, bao gồm `fullOutputPath`:
```json
{
  "type": "response",
  "command": "bash",
  "success": true,
  "data": {
    "output": "truncated output...",
    "exitCode": 0,
    "cancelled": false,
    "truncated": true,
    "fullOutputPath": "/tmp/pi-bash-abc123.log"
  }
}
```

**Làm thế nào kết quả bash đạt đến LLM:**

Lệnh `bash` thực thi ngay lập tức và trả về `BashResult`. Trong nội bộ, `BashExecutionMessage` được tạo và lưu trữ ở trạng thái tin nhắn của tác nhân. Thông báo này NOT phát ra một sự kiện.

Khi lệnh `prompt` tiếp theo được gửi, tất cả các tin nhắn (bao gồm `BashExecutionMessage`) sẽ được chuyển đổi trước khi gửi đến LLM. `BashExecutionMessage` được chuyển đổi thành `UserMessage` với định dạng sau:

````
Ran `ls -la`
```
total 48
drwxr-xr-x ...
```
````

Điều này có nghĩa là:
1. Đầu ra Bash được bao gồm trong ngữ cảnh LLM trên **dấu nhắc tiếp theo**, không phải ngay lập tức
2. Nhiều lệnh bash có thể được thực thi trước dấu nhắc; tất cả đầu ra sẽ được bao gồm
3. Không có sự kiện nào được phát ra cho chính `BashExecutionMessage`

#### abort_bash

Hủy bỏ lệnh bash đang chạy.

```json
{"type": "abort_bash"}
```

Phản hồi:
```json
{"type": "response", "command": "abort_bash", "success": true}
```

### Phiên

#### get_session_stats

Nhận mức sử dụng token, thống kê chi phí và mức sử dụng cửa sổ ngữ cảnh hiện tại.

```json
{"type": "get_session_stats"}
```

Phản hồi:
```json
{
  "type": "response",
  "command": "get_session_stats",
  "success": true,
  "data": {
    "sessionFile": "/path/to/session.jsonl",
    "sessionId": "abc123",
    "userMessages": 5,
    "assistantMessages": 5,
    "toolCalls": 12,
    "toolResults": 12,
    "totalMessages": 22,
    "tokens": {
      "input": 50000,
      "output": 10000,
      "cacheRead": 40000,
      "cacheWrite": 5000,
      "total": 105000
    },
    "cost": 0.45,
    "contextUsage": {
      "tokens": 60000,
      "contextWindow": 200000,
      "percent": 30
    }
  }
}
```

`tokens` chứa tổng mức sử dụng trợ lý cho trạng thái phiên hiện tại. `contextUsage` chứa ước tính cửa sổ ngữ cảnh hiện tại thực tế được sử dụng để nén và hiển thị chân trang.

`contextUsage` bị bỏ qua khi không có sẵn mô hình hoặc cửa sổ ngữ cảnh. `contextUsage.tokens` và `contextUsage.percent` là `null` ngay sau khi nén cho đến khi có phản hồi hỗ trợ sau nén mới cung cấp dữ liệu sử dụng hợp lệ.

#### export_html

Xuất phiên sang tệp HTML.

```json
{"type": "export_html"}
```

Với đường dẫn tùy chỉnh:
```json
{"type": "export_html", "outputPath": "/tmp/session.html"}
```

Phản hồi:
```json
{
  "type": "response",
  "command": "export_html",
  "success": true,
  "data": {"path": "/tmp/session.html"}
}
```

#### switch_session

Tải một tập tin phiên khác. Có thể bị hủy bởi trình xử lý sự kiện mở rộng `session_before_switch`.

```json
{"type": "switch_session", "sessionPath": "/path/to/session.jsonl"}
```

Phản hồi:
```json
{"type": "response", "command": "switch_session", "success": true, "data": {"cancelled": false}}
```

Nếu tiện ích mở rộng đã hủy quá trình chuyển đổi:
```json
{"type": "response", "command": "switch_session", "success": true, "data": {"cancelled": true}}
```

#### fork

Tạo một nhánh mới từ tin nhắn của người dùng trước đó trên nhánh đang hoạt động. Có thể bị hủy bởi trình xử lý sự kiện mở rộng `session_before_fork`. Trả về nội dung của tin nhắn được phân nhánh từ đó.

```json
{"type": "fork", "entryId": "abc123"}
```

Phản hồi:
```json
{
  "type": "response",
  "command": "fork",
  "success": true,
  "data": {"text": "The original prompt text...", "cancelled": false}
}
```

Nếu tiện ích mở rộng đã hủy phân nhánh:
```json
{
  "type": "response",
  "command": "fork",
  "success": true,
  "data": {"text": "The original prompt text...", "cancelled": true}
}
```

#### clone

Sao chép nhánh hoạt động hiện tại vào một phiên mới ở vị trí hiện tại. Có thể bị hủy bởi trình xử lý sự kiện mở rộng `session_before_fork`.

```json
{"type": "clone"}
```

Phản hồi:
```json
{
  "type": "response",
  "command": "clone",
  "success": true,
  "data": {"cancelled": false}
}
```

Nếu tiện ích mở rộng đã hủy bản sao:
```json
{
  "type": "response",
  "command": "clone",
  "success": true,
  "data": {"cancelled": true}
}
```

#### get_fork_messages

Nhận tin nhắn của người dùng có sẵn để phân nhánh.

```json
{"type": "get_fork_messages"}
```

Phản hồi:
```json
{
  "type": "response",
  "command": "get_fork_messages",
  "success": true,
  "data": {
    "messages": [
      {"entryId": "abc123", "text": "First prompt..."},
      {"entryId": "def456", "text": "Second prompt..."}
    ]
  }
}
```

#### get_last_assistant_text

Lấy nội dung văn bản của tin nhắn trợ lý cuối cùng.

```json
{"type": "get_last_assistant_text"}
```

Phản hồi:
```json
{
  "type": "response",
  "command": "get_last_assistant_text",
  "success": true,
  "data": {"text": "The assistant's response..."}
}
```

Trả về `{"text": null}` nếu không có thông báo trợ lý nào tồn tại.

#### set_session_name

Đặt tên hiển thị cho phiên hiện tại. Tên xuất hiện trong danh sách phiên và giúp xác định phiên.

```json
{"type": "set_session_name", "name": "my-feature-work"}
```

Phản hồi:
```json
{
  "type": "response",
  "command": "set_session_name",
  "success": true
}
```

Tên phiên hiện tại có sẵn thông qua `get_state` trong trường `sessionName`.

### Lệnh

#### get_commands

Nhận các lệnh có sẵn (lệnh mở rộng, mẫu lời nhắc và kỹ năng). Chúng có thể được gọi thông qua lệnh `prompt` bằng cách thêm tiền tố `/`.

```json
{"type": "get_commands"}
```

Phản hồi:
```json
{
  "type": "response",
  "command": "get_commands",
  "success": true,
  "data": {
    "commands": [
      {"name": "session-name", "description": "Set or clear session name", "source": "extension", "path": "/home/user/.prime/agent/extensions/session.ts"},
      {"name": "fix-tests", "description": "Fix failing tests", "source": "prompt", "location": "project", "path": "/home/user/myproject/.prime/agent/prompts/fix-tests.md"},
      {"name": "skill:brave-search", "description": "Web search via Brave API", "source": "skill", "location": "user", "path": "/home/user/.prime/agent/skills/brave-search/SKILL.md"}
    ]
  }
}
```

Mỗi lệnh có:
- `name`: Tên lệnh (gọi bằng `/name`)
- `description`: Mô tả mà con người có thể đọc được (tùy chọn cho các lệnh mở rộng)
- `source`: Loại lệnh nào:
- `"extension"`: Đã đăng ký qua `pi.registerCommand()` trong tiện ích mở rộng
- `"prompt"`: Được tải từ tệp `.md` mẫu nhắc nhở
- `"skill"`: Được tải từ thư mục kỹ năng (tên có tiền tố `skill:`)
- `location`: Nó được tải từ đâu (tùy chọn, không có cho tiện ích mở rộng):
- `"user"`: Cấp độ người dùng (`~/.prime/agent/`)
- `"project"`: Cấp độ dự án (`./.prime/agent/`)
- `"path"`: Đường dẫn rõ ràng qua CLI hoặc cài đặt
- `path`: Đường dẫn file tuyệt đối tới nguồn lệnh (tùy chọn)

**Lưu ý**: Không bao gồm các lệnh TUI tích hợp (`/settings`, `/hotkeys`, v.v.). Chúng chỉ được xử lý ở chế độ tương tác và sẽ không thực thi nếu được gửi qua `prompt`.

## Sự kiện

Các sự kiện được truyền tới thiết bị xuất chuẩn dưới dạng dòng JSON trong quá trình vận hành tác nhân. Các sự kiện NOT bao gồm trường `id` (chỉ có phản hồi mới có).

### Loại sự kiện

| Sự kiện | Mô tả |
|-------|-------------|
| `agent_start` | Tác nhân bắt đầu xử lý |
| `agent_end` | Tác nhân hoàn thành (bao gồm tất cả các tin nhắn được tạo) |
| `turn_start` | Lượt mới bắt đầu |
| `turn_end` | Lượt hoàn thành (bao gồm thông báo trợ lý và kết quả công cụ) |
| `message_start` | Tin nhắn bắt đầu |
| `message_update` | Cập nhật trực tuyến (văn bản/suy nghĩ/đồng bằng cuộc gọi công cụ) |
| `message_end` | Tin nhắn hoàn tất |
| `tool_execution_start` | Công cụ bắt đầu thực hiện |
| `tool_execution_update` | Tiến trình thực hiện công cụ (đầu ra phát trực tuyến) |
| `tool_execution_end` | Công cụ hoàn thành |
| `session_action_update` | Đã thay đổi hàng đợi chỉ đạo/theo dõi đang chờ xử lý |
| `compaction_start` | Quá trình nén bắt đầu |
| `compaction_end` | Quá trình nén hoàn tất |
| `auto_retry_start` | Bắt đầu tự động thử lại (sau lỗi thoáng qua) |
| `auto_retry_end` | Tự động thử lại hoàn tất (thành công hoặc thất bại cuối cùng) |
| `extension_error` | Tiện ích mở rộng đã gây ra lỗi |

### agent_start

Được phát ra khi tác nhân bắt đầu xử lý lời nhắc.

```json
{"type": "agent_start"}
```

### agent_end

Được phát ra khi tác nhân hoàn thành. Chứa tất cả các tin nhắn được tạo trong quá trình chạy này.

```json
{
  "type": "agent_end",
  "messages": [...]
}
```

### turn_start / turn_end

Một lượt bao gồm một phản hồi trợ lý cộng với bất kỳ cuộc gọi và kết quả công cụ nào phát sinh.

```json
{"type": "turn_start"}
```

```json
{
  "type": "turn_end",
  "message": {...},
  "toolResults": [...]
}
```

### message_start / message_end

Được phát ra khi một tin nhắn bắt đầu và kết thúc. Trường `message` chứa `AgentMessage`.

```json
{"type": "message_start", "message": {...}}
{"type": "message_end", "message": {...}}
```

### message_update (Đang phát trực tuyến)

Được phát ra trong quá trình truyền phát tin nhắn trợ lý. Chứa cả thông báo một phần và sự kiện phát trực tuyến delta.

```json
{
  "type": "message_update",
  "message": {...},
  "assistantMessageEvent": {
    "type": "text_delta",
    "contentIndex": 0,
    "delta": "Hello ",
    "partial": {...}
  }
}
```

Trường `assistantMessageEvent` chứa một trong các loại delta sau:

| Loại | Mô tả |
|------|-------------|
| `start` | Đã bắt đầu tạo tin nhắn |
| `text_start` | Khối nội dung văn bản đã bắt đầu |
| `text_delta` | Đoạn nội dung văn bản |
| `text_end` | Khối nội dung văn bản đã kết thúc |
| `thinking_start` | Khối suy nghĩ bắt đầu |
| `thinking_delta` | Đoạn nội dung suy nghĩ |
| `thinking_end` | Khối suy nghĩ đã kết thúc |
| `toolcall_start` | Cuộc gọi công cụ đã bắt đầu |
| `toolcall_delta` | Đoạn đối số cuộc gọi công cụ |
| `toolcall_end` | Cuộc gọi công cụ đã kết thúc (bao gồm đối tượng `toolCall` đầy đủ) |
| `done` | Tin nhắn đã hoàn tất (lý do: `"stop"`, `"length"`, `"toolUse"`) |
| `error` | Đã xảy ra lỗi (lý do: `"aborted"`, `"error"`) |

Ví dụ truyền phát phản hồi văn bản:
```json
{"type":"message_update","message":{...},"assistantMessageEvent":{"type":"text_start","contentIndex":0,"partial":{...}}}
{"type":"message_update","message":{...},"assistantMessageEvent":{"type":"text_delta","contentIndex":0,"delta":"Hello","partial":{...}}}
{"type":"message_update","message":{...},"assistantMessageEvent":{"type":"text_delta","contentIndex":0,"delta":" world","partial":{...}}}
{"type":"message_update","message":{...},"assistantMessageEvent":{"type":"text_end","contentIndex":0,"content":"Hello world","partial":{...}}}
```

### tool_execution_start / tool_execution_update / tool_execution_end

Được phát ra khi một công cụ bắt đầu, truyền tiến trình và hoàn tất quá trình thực thi.

```json
{
  "type": "tool_execution_start",
  "toolCallId": "call_abc123",
  "toolName": "bash",
  "args": {"command": "ls -la"}
}
```

Trong quá trình thực thi, các sự kiện `tool_execution_update` truyền phát một phần kết quả (ví dụ: đầu ra bash khi nó đến):

```json
{
  "type": "tool_execution_update",
  "toolCallId": "call_abc123",
  "toolName": "bash",
  "args": {"command": "ls -la"},
  "partialResult": {
    "content": [{"type": "text", "text": "partial output so far..."}],
    "details": {"truncation": null, "fullOutputPath": null}
  }
}
```

Khi hoàn thành:

```json
{
  "type": "tool_execution_end",
  "toolCallId": "call_abc123",
  "toolName": "bash",
  "result": {
    "content": [{"type": "text", "text": "total 48\n..."}],
    "details": {...}
  },
  "isError": false
}
```

Sử dụng `toolCallId` để liên hệ các sự kiện. `partialResult` trong `tool_execution_update` chứa đầu ra tích lũy cho đến nay (không chỉ delta), cho phép máy khách chỉ cần thay thế màn hình của họ trên mỗi bản cập nhật.

### session_action_update

Được phát ra bất cứ khi nào các hành động được xếp hàng theo nghĩa đen hoặc hành động của bộ lập lịch hoạt động thay đổi.

```json
{
  "type": "session_action_update",
  "actions": {
    "queuedCount": 2,
    "steering": ["Focus on error handling"],
    "followUps": ["After that, summarize the result"],
    "active": { "kind": "session_command", "phase": "running", "label": "/compact" }
  }
}
```

### compaction_start / compaction_end

Phát ra khi quá trình nén diễn ra, dù là thủ công hay tự động.

```json
{"type": "compaction_start", "reason": "threshold"}
```

Trường `reason` là `"manual"`, `"threshold"` hoặc `"overflow"`.

```json
{
  "type": "compaction_end",
  "reason": "threshold",
  "result": {
    "summary": "Summary of conversation...",
    "firstKeptEntryId": "abc123",
    "tokensBefore": 150000,
    "details": {}
  },
  "aborted": false,
  "willRetry": false
}
```

Nếu `reason` là `"overflow"` và quá trình nén thành công thì `willRetry` là `true` và tác nhân sẽ tự động thử lại lời nhắc.

Nếu quá trình nén bị hủy bỏ, `result` là `null` và `aborted` là `true`.

Nếu quá trình nén không thành công (ví dụ: vượt quá hạn ngạch API), `result` là `null`, `aborted` là `false` và `errorMessage` chứa mô tả lỗi.

### auto_retry_start / auto_retry_end

Được phát ra khi kích hoạt tự động thử lại sau một lỗi nhất thời (quá tải, giới hạn tốc độ, 5xx).

```json
{
  "type": "auto_retry_start",
  "attempt": 1,
  "maxAttempts": 3,
  "delayMs": 2000,
  "errorMessage": "529 {\"type\":\"error\",\"error\":{\"type\":\"overloaded_error\",\"message\":\"Overloaded\"}}"
}
```

```json
{
  "type": "auto_retry_end",
  "success": true,
  "attempt": 2
}
```

Trong lần thất bại cuối cùng (vượt quá số lần thử lại tối đa):
```json
{
  "type": "auto_retry_end",
  "success": false,
  "attempt": 3,
  "finalError": "529 overloaded_error: Overloaded"
}
```

### extension_error

Được phát ra khi tiện ích mở rộng gặp lỗi.

```json
{
  "type": "extension_error",
  "extensionPath": "/path/to/extension.ts",
  "event": "tool_call",
  "error": "Error message..."
}
```

## Giao thức UI mở rộng

Các tiện ích mở rộng có thể yêu cầu tương tác của người dùng thông qua `ctx.ui.select()`, `ctx.ui.confirm()`, v.v. Ở chế độ RPC, các tiện ích mở rộng này được dịch thành giao thức phụ yêu cầu/phản hồi ở đầu luồng lệnh/sự kiện cơ sở.

Có hai loại phương pháp UI mở rộng:

- **Phương thức hộp thoại** (`select`, `confirm`, `input`, `editor`): phát ra `extension_ui_request` trên thiết bị xuất chuẩn và chặn cho đến khi máy khách gửi lại `extension_ui_response` trên stdin với `id` phù hợp.
- **Phương pháp bắn và quên** (`notify`, `setStatus`, `setWidget`, `setTitle`, `set_editor_text`): phát ra `extension_ui_request` trên thiết bị xuất chuẩn nhưng không mong đợi phản hồi. Máy khách có thể hiển thị thông tin hoặc bỏ qua nó.

Nếu phương thức hộp thoại bao gồm trường `timeout` thì phía tác nhân sẽ tự động giải quyết bằng giá trị mặc định khi hết thời gian chờ. Máy khách không cần phải theo dõi thời gian chờ.

Một số phương pháp `ExtensionUIContext` không được hỗ trợ hoặc xuống cấp ở chế độ RPC vì chúng yêu cầu truy cập TUI trực tiếp:
- `custom()` trả về `undefined`
- `setWorkingMessage()`, `setWorkingIndicator()`, `setFooter()`, `setHeader()`, `setEditorComponent()`, `setToolsExpanded()` không hoạt động
- `getEditorText()` trả về `""`
- `getToolsExpanded()` trả về `false`
- `pasteToEditor()` ủy quyền cho `setEditorText()` (không xử lý dán/thu gọn)
- `getAllThemes()` trả về `[]`
- `getTheme()` trả về `undefined`
- `setTheme()` trả về `{ success: false, error: "..." }`

Lưu ý: `ctx.hasUI` là `true` ở chế độ RPC vì hộp thoại và các phương thức kích hoạt và quên hoạt động thông qua giao thức con UI mở rộng.

### Yêu cầu mở rộng UI (thiết bị xuất chuẩn)

Tất cả các yêu cầu đều có `type: "extension_ui_request"`, `id` duy nhất và trường `method`.

#### select

Nhắc người dùng chọn từ danh sách. Các phương thức hộp thoại có trường `timeout` bao gồm thời gian chờ tính bằng mili giây; tác nhân tự động giải quyết bằng `undefined` nếu máy khách không phản hồi kịp thời.

```json
{
  "type": "extension_ui_request",
  "id": "uuid-1",
  "method": "select",
  "title": "Allow dangerous command?",
  "options": ["Allow", "Block"],
  "timeout": 10000
}
```

Phản hồi dự kiến: `extension_ui_response` với `value` (chuỗi tùy chọn đã chọn) hoặc `cancelled: true`.

#### confirm

Nhắc người dùng xác nhận có/không.

```json
{
  "type": "extension_ui_request",
  "id": "uuid-2",
  "method": "confirm",
  "title": "Clear session?",
  "message": "All messages will be lost.",
  "timeout": 5000
}
```

Phản hồi dự kiến: `extension_ui_response` với `confirmed: true/false` hoặc `cancelled: true`.

#### input

Nhắc người dùng về văn bản dạng tự do.

```json
{
  "type": "extension_ui_request",
  "id": "uuid-3",
  "method": "input",
  "title": "Enter a value",
  "placeholder": "type something..."
}
```

Phản hồi dự kiến: `extension_ui_response` với `value` (văn bản đã nhập) hoặc `cancelled: true`.

#### editor

Mở trình soạn thảo văn bản nhiều dòng với nội dung được điền sẵn tùy chọn.

```json
{
  "type": "extension_ui_request",
  "id": "uuid-4",
  "method": "editor",
  "title": "Edit some text",
  "prefill": "Line 1\nLine 2\nLine 3"
}
```

Phản hồi dự kiến: `extension_ui_response` với `value` (văn bản đã chỉnh sửa) hoặc `cancelled: true`.

#### notify

Hiển thị một thông báo. Bắn và quên, không có phản hồi mong đợi.

```json
{
  "type": "extension_ui_request",
  "id": "uuid-5",
  "method": "notify",
  "message": "Command blocked by user",
  "notifyType": "warning"
}
```

Trường `notifyType` là `"info"`, `"warning"` hoặc `"error"`. Mặc định là `"info"` nếu bị bỏ qua.

#### setStatus

Đặt hoặc xóa mục trạng thái trong thanh chân trang/trạng thái. Bắn và quên đi.

```json
{
  "type": "extension_ui_request",
  "id": "uuid-6",
  "method": "setStatus",
  "statusKey": "my-ext",
  "statusText": "Turn 3 running..."
}
```

Gửi `statusText: undefined` (hoặc bỏ qua) để xóa mục nhập trạng thái cho khóa đó.

#### setWidget

Đặt hoặc xóa tiện ích (khối dòng văn bản) hiển thị phía trên hoặc bên dưới trình chỉnh sửa. Bắn và quên đi.

```json
{
  "type": "extension_ui_request",
  "id": "uuid-7",
  "method": "setWidget",
  "widgetKey": "my-ext",
  "widgetLines": ["--- My Widget ---", "Line 1", "Line 2"],
  "widgetPlacement": "aboveEditor"
}
```

Gửi `widgetLines: undefined` (hoặc bỏ qua nó) để xóa tiện ích. Trường `widgetPlacement` là `"aboveEditor"` (mặc định) hoặc `"belowEditor"`. Chỉ mảng chuỗi được hỗ trợ ở chế độ RPC; các nhà máy sản xuất linh kiện được bỏ qua.

#### setTitle

Đặt tiêu đề cửa sổ/tab đầu cuối. Bắn và quên đi.

```json
{
  "type": "extension_ui_request",
  "id": "uuid-8",
  "method": "setTitle",
  "title": "Prime Agent - my project"
}
```

#### set_editor_text

Đặt văn bản trong trình chỉnh sửa đầu vào. Bắn và quên đi.

```json
{
  "type": "extension_ui_request",
  "id": "uuid-9",
  "method": "set_editor_text",
  "text": "prefilled text for the user"
}
```

### Phản hồi UI mở rộng (stdin)

Phản hồi chỉ được gửi cho các phương thức hộp thoại (`select`, `confirm`, `input`, `editor`). `id` phải phù hợp với yêu cầu.

#### Giá trị phản hồi (chọn, nhập, chỉnh sửa)

```json
{"type": "extension_ui_response", "id": "uuid-1", "value": "Allow"}
```

#### Phản hồi xác nhận (xác nhận)

```json
{"type": "extension_ui_response", "id": "uuid-2", "confirmed": true}
```

#### Phản hồi hủy (bất kỳ hộp thoại nào)

Loại bỏ bất kỳ phương thức hộp thoại nào. Tiện ích mở rộng nhận `undefined` (để chọn/đầu vào/trình chỉnh sửa) hoặc `false` (để xác nhận).

```json
{"type": "extension_ui_response", "id": "uuid-3", "cancelled": true}
```

## Xử lý lỗi

Các lệnh không thành công sẽ trả về phản hồi với `success: false`:

```json
{
  "type": "response",
  "command": "set_model",
  "success": false,
  "error": "Model not found: invalid/model"
}
```

Lỗi phân tích cú pháp:

```json
{
  "type": "response",
  "command": "parse",
  "success": false,
  "error": "Failed to parse command: Unexpected token..."
}
```

## Các loại

Các tập tin nguồn:
- [`packages/ai/src/types.ts`](../../ai/src/types.ts) - `Model`, `UserMessage`, `AssistantMessage`, `ToolResultMessage`
- [`packages/agent/src/types.ts`](../../agent/src/types.ts) - `AgentMessage`, `AgentEvent`
- [`src/core/messages.ts`](../src/core/messages.ts) - `BashExecutionMessage`
- [`src/modes/rpc/rpc-types.ts`](../src/modes/rpc/rpc-types.ts) - Các loại lệnh/phản hồi RPC, các loại yêu cầu/phản hồi UI mở rộng

### Model

```json
{
  "id": "claude-sonnet-4-20250514",
  "name": "Claude Sonnet 4",
  "api": "anthropic-messages",
  "provider": "anthropic",
  "baseUrl": "https://api.anthropic.com",
  "reasoning": true,
  "input": ["text", "image"],
  "contextWindow": 200000,
  "maxTokens": 16384,
  "cost": {
    "input": 3.0,
    "output": 15.0,
    "cacheRead": 0.3,
    "cacheWrite": 3.75
  }
}
```

### UserMessage

```json
{
  "role": "user",
  "content": "Hello!",
  "timestamp": 1733234567890,
  "attachments": []
}
```

Trường `content` có thể là một chuỗi hoặc một mảng các khối `TextContent`/`ImageContent`.

### AssistantMessage

```json
{
  "role": "assistant",
  "content": [
    {"type": "text", "text": "Hello! How can I help?"},
    {"type": "thinking", "thinking": "User is greeting me..."},
    {"type": "toolCall", "id": "call_123", "name": "bash", "arguments": {"command": "ls"}}
  ],
  "api": "anthropic-messages",
  "provider": "anthropic",
  "model": "claude-sonnet-4-20250514",
  "usage": {
    "input": 100,
    "output": 50,
    "cacheRead": 0,
    "cacheWrite": 0,
    "cost": {"input": 0.0003, "output": 0.00075, "cacheRead": 0, "cacheWrite": 0, "total": 0.00105}
  },
  "stopReason": "stop",
  "timestamp": 1733234567890
}
```

Lý do dừng: `"stop"`, `"length"`, `"toolUse"`, `"error"`, `"aborted"`

### ToolResultMessage

```json
{
  "role": "toolResult",
  "toolCallId": "call_123",
  "toolName": "bash",
  "content": [{"type": "text", "text": "total 48\ndrwxr-xr-x ..."}],
  "isError": false,
  "timestamp": 1733234567890
}
```

### BashExecutionMessage

Được tạo bởi lệnh `bash` RPC (không phải bởi lệnh gọi công cụ LLM):

```json
{
  "role": "bashExecution",
  "command": "ls -la",
  "output": "total 48\ndrwxr-xr-x ...",
  "exitCode": 0,
  "cancelled": false,
  "truncated": false,
  "fullOutputPath": null,
  "timestamp": 1733234567890
}
```

### Tệp đính kèm

```json
{
  "id": "img1",
  "type": "image",
  "fileName": "photo.jpg",
  "mimeType": "image/jpeg",
  "size": 102400,
  "content": "base64-encoded-data...",
  "extractedText": null,
  "preview": null
}
```

## Ví dụ: Máy khách cơ bản (Python)

```python
import subprocess
import json

proc = subprocess.Popen(
    ["prime-agent", "--mode", "rpc", "--no-session"],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    text=True
)

def send(cmd):
    proc.stdin.write(json.dumps(cmd) + "\n")
    proc.stdin.flush()

def read_events():
    for line in proc.stdout:
        yield json.loads(line)

# Send prompt
send({"type": "prompt", "message": "Hello!"})

# Process events
for event in read_events():
    if event.get("type") == "message_update":
        delta = event.get("assistantMessageEvent", {})
        if delta.get("type") == "text_delta":
            print(delta["delta"], end="", flush=True)
    
    if event.get("type") == "agent_end":
        print()
        break
```

## Ví dụ: Máy khách tương tác (Node.js)

Xem [`test/rpc-example.ts`](../test/rpc-example.ts) để biết ví dụ tương tác hoàn chỉnh hoặc [`src/modes/rpc/rpc-client.ts`](../src/modes/rpc/rpc-client.ts) để biết cách triển khai máy khách đã nhập.

Để biết ví dụ đầy đủ về cách xử lý giao thức UI tiện ích mở rộng, hãy xem [`examples/rpc-extension-ui.ts`](../examples/rpc-extension-ui.ts) ghép nối với tiện ích mở rộng [`examples/extensions/rpc-demo.ts`](../examples/extensions/rpc-demo.ts).

```javascript
const { spawn } = require("child_process");
const { StringDecoder } = require("string_decoder");

const agent = spawn("prime-agent", ["--mode", "rpc", "--no-session"]);

function attachJsonlReader(stream, onLine) {
    const decoder = new StringDecoder("utf8");
    let buffer = "";

    stream.on("data", (chunk) => {
        buffer += typeof chunk === "string" ? chunk : decoder.write(chunk);

        while (true) {
            const newlineIndex = buffer.indexOf("\n");
            if (newlineIndex === -1) break;

            let line = buffer.slice(0, newlineIndex);
            buffer = buffer.slice(newlineIndex + 1);
            if (line.endsWith("\r")) line = line.slice(0, -1);
            onLine(line);
        }
    });

    stream.on("end", () => {
        buffer += decoder.end();
        if (buffer.length > 0) {
            onLine(buffer.endsWith("\r") ? buffer.slice(0, -1) : buffer);
        }
    });
}

attachJsonlReader(agent.stdout, (line) => {
    const event = JSON.parse(line);

    if (event.type === "message_update") {
        const { assistantMessageEvent } = event;
        if (assistantMessageEvent.type === "text_delta") {
            process.stdout.write(assistantMessageEvent.delta);
        }
    }
});

// Send prompt
agent.stdin.write(JSON.stringify({ type: "prompt", message: "Hello" }) + "\n");

// Abort on Ctrl+C
process.on("SIGINT", () => {
    agent.stdin.write(JSON.stringify({ type: "abort" }) + "\n");
});
```

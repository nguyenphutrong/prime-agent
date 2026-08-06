# Chế độ phát trực tiếp sự kiện JSON

```bash
prime-agent --mode json "Your prompt"
```

Xuất tất cả các sự kiện phiên dưới dạng dòng JSON thành thiết bị xuất chuẩn. Hữu ích cho việc tích hợp Prime Agent vào các công cụ khác hoặc giao diện người dùng tùy chỉnh.

## Loại sự kiện

Các sự kiện được xác định trong [`AgentSessionEvent`](../src/core/agent-session.ts):

```typescript
type AgentSessionEvent =
  | AgentEvent
  | { type: "session_action_update"; actions: SessionActionSnapshot }
  | { type: "compaction_start"; reason: "manual" | "threshold" | "overflow" }
  | { type: "compaction_end"; reason: "manual" | "threshold" | "overflow"; result: CompactionResult | undefined; aborted: boolean; willRetry: boolean; errorMessage?: string }
  | { type: "auto_retry_start"; attempt: number; maxAttempts: number; delayMs: number; errorMessage: string }
  | { type: "auto_retry_end"; success: boolean; attempt: number; finalError?: string };
```

`session_action_update` phát ra các hành động được xếp hàng theo nghĩa đen tách biệt với công việc của bộ lập lịch hoạt động bất cứ khi nào phép chiếu thay đổi. `compaction_start` và `compaction_end` bao gồm cả việc nén thủ công và tự động.

Các sự kiện cơ bản từ [`AgentEvent`](../../agent/src/types.ts):

```typescript
type AgentEvent =
  // Agent lifecycle
  | { type: "agent_start" }
  | { type: "agent_end"; messages: AgentMessage[] }
  // Turn lifecycle
  | { type: "turn_start" }
  | { type: "turn_end"; message: AgentMessage; toolResults: ToolResultMessage[] }
  // Message lifecycle
  | { type: "message_start"; message: AgentMessage }
  | { type: "message_update"; message: AgentMessage; assistantMessageEvent: AssistantMessageEvent }
  | { type: "message_end"; message: AgentMessage }
  // Tool execution
  | { type: "tool_execution_start"; toolCallId: string; toolName: string; args: any }
  | { type: "tool_execution_update"; toolCallId: string; toolName: string; args: any; partialResult: any }
  | { type: "tool_execution_end"; toolCallId: string; toolName: string; result: any; isError: boolean };
```

## Loại tin nhắn

Tin nhắn cơ bản từ [`packages/ai/src/types.ts`](../../ai/src/types.ts):
- `UserMessage` (dòng 134)
- `AssistantMessage` (dòng 140)
- `ToolResultMessage` (dòng 152)

Tin nhắn mở rộng từ [`packages/coding-agent/src/core/messages.ts`](../src/core/messages.ts):
- `BashExecutionMessage` (dòng 29)
- `CustomMessage` (dòng 46)
- `BranchSummaryMessage` (dòng 55)
- `CompactionSummaryMessage` (dòng 62)

## Định dạng đầu ra

Mỗi dòng là một đối tượng JSON. Dòng đầu tiên là tiêu đề phiên:

```json
{"type":"session","version":3,"id":"uuid","timestamp":"...","cwd":"/path"}
```

Tiếp theo là các sự kiện khi chúng xảy ra:

```json
{"type":"agent_start"}
{"type":"turn_start"}
{"type":"message_start","message":{"role":"assistant","content":[],...}}
{"type":"message_update","message":{...},"assistantMessageEvent":{"type":"text_delta","delta":"Hello",...}}
{"type":"message_end","message":{...}}
{"type":"turn_end","message":{...},"toolResults":[]}
{"type":"agent_end","messages":[...]}
```

## Ví dụ

```bash
prime-agent --mode json "List files" 2>/dev/null | jq -c 'select(.type == "message_end")'
```

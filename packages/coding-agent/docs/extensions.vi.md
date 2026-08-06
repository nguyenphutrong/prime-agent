> Prime Agent có thể tạo extension. Hãy yêu cầu Prime Agent xây dựng một extension cho trường hợp sử dụng của bạn.

# Extension

Extension là các module TypeScript mở rộng hành vi của Prime Agent. Chúng có thể đăng ký lắng nghe sự kiện vòng đời, đăng ký công cụ tùy chỉnh mà LLM có thể gọi, thêm lệnh và nhiều khả năng khác.

> **Vị trí cho /reload:** Đặt extension vào `~/.prime/agent/extensions/` (toàn cục) hoặc `.prime/agent/extensions/` (riêng dự án) để tự động phát hiện. Chỉ dùng `prime-agent -e ./path.ts` cho các lần kiểm thử nhanh. Extension ở các vị trí được tự động phát hiện có thể được tải lại nóng bằng `/reload`.

**Khả năng chính:**
- **Công cụ tùy chỉnh** - Đăng ký các công cụ mà LLM có thể gọi qua `pi.registerTool()`
- **Chặn sự kiện** - Chặn hoặc sửa đổi lời gọi công cụ, chèn ngữ cảnh, tùy chỉnh việc nén ngữ cảnh
- **Tương tác với người dùng** - Hiển thị lời nhắc cho người dùng qua `ctx.ui` (select, confirm, input, notify)
- **Thành phần UI tùy chỉnh** - Các thành phần TUI đầy đủ có nhận đầu vào bàn phím qua `ctx.ui.custom()` cho những tương tác phức tạp
- **Lệnh tùy chỉnh** - Đăng ký các lệnh như `/mycommand` qua `pi.registerCommand()`
- **Lưu trạng thái phiên** - Lưu trạng thái vẫn tồn tại sau khi khởi động lại qua `pi.appendEntry()`
- **Kết xuất tùy chỉnh** - Kiểm soát cách lời gọi/kết quả công cụ và tin nhắn xuất hiện trong TUI

**Ví dụ về trường hợp sử dụng:**
- Cổng quyền hạn (xác nhận trước `rm -rf`, `sudo`, v.v.)
- Tạo checkpoint cho Git (stash ở mỗi lượt, khôi phục trên nhánh)
- Bảo vệ đường dẫn (chặn ghi vào `.env`, `node_modules/`)
- Nén ngữ cảnh tùy chỉnh (tóm tắt cuộc hội thoại theo cách của bạn)
- Tóm tắt cuộc hội thoại (xem ví dụ `summarize.ts`)
- Công cụ tương tác (câu hỏi, trình hướng dẫn, hộp thoại tùy chỉnh)
- Công cụ có trạng thái (danh sách việc cần làm, pool kết nối)
- Tích hợp bên ngoài (trình theo dõi tệp, webhook, trình kích hoạt CI)
- Trò chơi trong lúc chờ (xem ví dụ `snake.ts`)

Xem các triển khai hoạt động tại [examples/extensions/](../examples/extensions/).

## Mục lục

- [Bắt đầu nhanh](#bắt-đầu-nhanh)
- [Vị trí extension](#vị-trí-extension)
- [Các import khả dụng](#các-import-khả-dụng)
- [Viết extension](#viết-extension)
  - [Kiểu extension](#kiểu-extension)
- [Sự kiện](#sự-kiện)
  - [Tổng quan vòng đời](#tổng-quan-vòng-đời)
  - [Sự kiện tài nguyên](#sự-kiện-tài-nguyên)
  - [Sự kiện phiên](#sự-kiện-phiên)
  - [Sự kiện agent](#sự-kiện-agent)
  - [Sự kiện model](#sự-kiện-model)
  - [Sự kiện công cụ](#sự-kiện-công-cụ)
- [ExtensionContext](#extensioncontext)
- [ExtensionCommandContext](#extensioncommandcontext)
- [Các phương thức ExtensionAPI](#các-phương-thức-extensionapi)
- [Quản lý trạng thái](#quản-lý-trạng-thái)
- [Công cụ tùy chỉnh](#công-cụ-tùy-chỉnh)
- [UI tùy chỉnh](#ui-tùy-chỉnh)
- [Xử lý lỗi](#xử-lý-lỗi)
- [Hành vi theo chế độ](#hành-vi-theo-chế-độ)
- [Tham khảo ví dụ](#tham-khảo-ví-dụ)

## Bắt đầu nhanh

Tạo `~/.prime/agent/extensions/my-extension.ts`:

```typescript
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

export default function (pi: ExtensionAPI) {
  // React to events
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify("Extension loaded!", "info");
  });

  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName === "bash" && event.input.command?.includes("rm -rf")) {
      const ok = await ctx.ui.confirm("Dangerous!", "Allow rm -rf?");
      if (!ok) return { block: true, reason: "Blocked by user" };
    }
  });

  // Register a custom tool
  pi.registerTool({
    name: "greet",
    label: "Greet",
    description: "Greet someone by name",
    parameters: Type.Object({
      name: Type.String({ description: "Name to greet" }),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      return {
        content: [{ type: "text", text: `Hello, ${params.name}!` }],
        details: {},
      };
    },
  });

  // Register a command
  pi.registerCommand("hello", {
    description: "Say hello",
    handler: async (args, ctx) => {
      ctx.ui.notify(`Hello ${args || "world"}!`, "info");
    },
  });
}
```

Kiểm thử bằng cờ `--extension` (hoặc `-e`):

```bash
prime-agent -e ./my-extension.ts
```

## Vị trí extension

> **Bảo mật:** Extension chạy với toàn bộ quyền của hệ thống và có thể thực thi mã tùy ý. Chỉ cài đặt từ các nguồn mà bạn tin cậy.

Extension được tự động phát hiện từ các vị trí sau:

| Vị trí | Phạm vi |
|----------|-------|
| `~/.prime/agent/extensions/*.ts` | Toàn cục (mọi dự án) |
| `~/.prime/agent/extensions/*/index.ts` | Toàn cục (thư mục con) |
| `.prime/agent/extensions/*.ts` | Theo dự án |
| `.prime/agent/extensions/*/index.ts` | Theo dự án (thư mục con) |

Các đường dẫn bổ sung qua `settings.json`:

```json
{
  "packages": [
    "npm:@foo/bar@1.0.0",
    "git:github.com/user/repo@v1"
  ],
  "extensions": [
    "/path/to/local/extension.ts",
    "/path/to/local/extension/dir"
  ]
}
```

Để chia sẻ extension qua npm hoặc git dưới dạng package của Prime Agent, xem [packages.md](packages.vi.md).

## Các import khả dụng

| Package | Mục đích |
|---------|---------|
| `@earendil-works/pi-coding-agent` | Các kiểu extension (`ExtensionAPI`, `ExtensionContext`, sự kiện) |
| `typebox` | Định nghĩa schema cho tham số công cụ |
| `@earendil-works/pi-ai` | Tiện ích AI (`StringEnum` cho enum tương thích với Google) |
| `@earendil-works/pi-tui` | Các thành phần TUI để kết xuất tùy chỉnh |

Các dependency npm cũng hoạt động. Thêm `package.json` cạnh extension (hoặc trong một thư mục cha), chạy `npm install`, và các import từ `node_modules/` sẽ được tự động phân giải.

Với các package Prime Agent được phân phối và cài đặt bằng `prime-agent package install` (npm hoặc git), dependency thời gian chạy phải nằm trong `dependencies`. Việc cài đặt package mặc định dùng cài đặt production (`npm install --omit=dev`), nên `devDependencies` không khả dụng khi chạy; khi cấu hình `npmCommand`, package git dùng `install` thuần để tương thích với các wrapper.

Các module tích hợp sẵn của Node.js (`node:fs`, `node:path`, v.v.) cũng khả dụng.

## Viết extension

Một extension export một hàm factory mặc định nhận `ExtensionAPI`. Factory có thể đồng bộ hoặc bất đồng bộ:

```typescript
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  // Subscribe to events
  pi.on("event_name", async (event, ctx) => {
    // ctx.ui for user interaction
    const ok = await ctx.ui.confirm("Title", "Are you sure?");
    ctx.ui.notify("Done!", "success");
    ctx.ui.setStatus("my-ext", "Processing...");  // Footer status
    ctx.ui.setWidget("my-ext", ["Line 1", "Line 2"]);  // Widget above editor (default)
  });

  // Register tools, commands, shortcuts, flags
  pi.registerTool({ ... });
  pi.registerCommand("name", { ... });
  pi.registerShortcut("ctrl+x", { ... });
  pi.registerFlag("my-flag", { ... });
}
```

Extension được nạp bằng [jiti](https://github.com/unjs/jiti), nên TypeScript hoạt động mà không cần biên dịch.

Nếu factory trả về một `Promise`, Prime Agent sẽ chờ promise đó trước khi tiếp tục khởi động. Điều này nghĩa là việc khởi tạo bất đồng bộ hoàn tất trước `session_start`, trước `resources_discover` và trước khi các đăng ký provider được xếp hàng qua `pi.registerProvider()` được đẩy ra xử lý.

### Hàm factory bất đồng bộ

Dùng factory bất đồng bộ cho các công việc chỉ thực hiện một lần lúc khởi động, chẳng hạn lấy cấu hình từ xa hoặc tự động phát hiện các model khả dụng.

```typescript
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default async function (pi: ExtensionAPI) {
  const response = await fetch("http://localhost:1234/v1/models");
  const payload = (await response.json()) as {
    data: Array<{
      id: string;
      name?: string;
      context_window?: number;
      max_tokens?: number;
    }>;
  };

  pi.registerProvider("local-openai", {
    baseUrl: "http://localhost:1234/v1",
    apiKey: "LOCAL_OPENAI_API_KEY",
    api: "openai-completions",
    models: payload.data.map((model) => ({
      id: model.id,
      name: model.name ?? model.id,
      reasoning: false,
      input: ["text"],
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      contextWindow: model.context_window ?? 128000,
      maxTokens: model.max_tokens ?? 4096,
    })),
  });
}
```

Mẫu này giúp các model đã lấy được khả dụng trong quá trình khởi động thông thường và trong `prime-agent model list`.

### Kiểu extension

**Một file** - đơn giản nhất, dành cho extension nhỏ:

```
~/.prime/agent/extensions/
└── my-extension.ts
```

**Thư mục có index.ts** - dành cho extension nhiều file:

```
~/.prime/agent/extensions/
└── my-extension/
    ├── index.ts        # Entry point (exports default function)
    ├── tools.ts        # Helper module
    └── utils.ts        # Helper module
```

**Package có dependency** - dành cho extension cần package npm:

```
~/.prime/agent/extensions/
└── my-extension/
    ├── package.json    # Declares dependencies and entry points
    ├── package-lock.json
    ├── node_modules/   # After npm install
    └── src/
        └── index.ts
```

```json
// package.json
{
  "name": "my-extension",
  "dependencies": {
    "zod": "^3.0.0",
    "chalk": "^5.0.0"
  },
  "pi": {
    "extensions": ["./src/index.ts"]
  }
}
```

Chạy `npm install` trong thư mục extension; sau đó các import từ `node_modules/` sẽ tự động hoạt động.

## Sự kiện

### Tổng quan vòng đời

```
Prime Agent starts
  │
  ├─► session_start { reason: "startup" }
  └─► resources_discover { reason: "startup" }
      │
      ▼
user sends prompt ─────────────────────────────────────────┐
  │                                                        │
  ├─► (extension commands checked first, bypass if found)  │
  ├─► input (can intercept, transform, or handle)          │
  ├─► (skill/template expansion if not handled)            │
  ├─► before_agent_start (can inject message, modify system prompt)
  ├─► agent_start                                          │
  ├─► message_start / message_update / message_end         │
  │                                                        │
  │   ┌─── turn (repeats while LLM calls tools) ───┐       │
  │   │                                            │       │
  │   ├─► turn_start                               │       │
  │   ├─► context (can modify messages)            │       │
  │   ├─► before_provider_request (can inspect or replace payload)
  │   ├─► after_provider_response (status + headers, before stream consume)
  │   │                                            │       │
  │   │   LLM responds, may call tools:            │       │
  │   │     ├─► tool_execution_start               │       │
  │   │     ├─► tool_call (can block)              │       │
  │   │     ├─► tool_execution_update              │       │
  │   │     ├─► tool_result (can modify)           │       │
  │   │     └─► tool_execution_end                 │       │
  │   │                                            │       │
  │   └─► turn_end                                 │       │
  │                                                        │
  └─► agent_end                                            │
                                                           │
user sends another prompt ◄────────────────────────────────┘

/new (new session) or /resume (switch session)
  ├─► session_before_switch (can cancel)
  ├─► session_shutdown
  ├─► session_start { reason: "new" | "resume", previousSessionFile? }
  └─► resources_discover { reason: "startup" }

/fork or /clone
  ├─► session_before_fork (can cancel)
  ├─► session_shutdown
  ├─► session_start { reason: "fork", previousSessionFile }
  └─► resources_discover { reason: "startup" }

/compact or auto-compaction
  ├─► session_before_compact (can cancel or customize)
  └─► session_compact

/tree navigation
  ├─► session_before_tree (can cancel or customize)
  └─► session_tree

/model or Ctrl+P (model selection/cycling)
  ├─► thinking_level_select (if model change changes/clamps thinking level)
  └─► model_select

thinking level changes (settings, keybinding, pi.setThinkingLevel())
  └─► thinking_level_select

exit (Ctrl+C, Ctrl+D, SIGHUP, SIGTERM)
  └─► session_shutdown
```

### Sự kiện tài nguyên

#### resources_discover

Được phát ra sau `session_start` để extension có thể bổ sung các đường dẫn skill, prompt và theme.
Luồng khởi động dùng `reason: "startup"`. Reload dùng `reason: "reload"`.

```typescript
pi.on("resources_discover", async (event, _ctx) => {
  // event.cwd - current working directory
  // event.reason - "startup" | "reload"
  return {
    skillPaths: ["/path/to/skills"],
    promptPaths: ["/path/to/prompts"],
    themePaths: ["/path/to/themes"],
  };
});
```

### Sự kiện phiên

Xem [Định dạng phiên](session-format.vi.md) để biết nội bộ lưu trữ phiên và API SessionManager.

#### session_start

Được phát ra khi một phiên được bắt đầu, nạp hoặc nạp lại.

```typescript
pi.on("session_start", async (event, ctx) => {
  // event.reason - "startup" | "reload" | "new" | "resume" | "fork"
  // event.previousSessionFile - present for "new", "resume", and "fork"
  ctx.ui.notify(`Session: ${ctx.sessionManager.getSessionFile() ?? "ephemeral"}`, "info");
});
```

#### session_before_switch

Được phát ra trước khi bắt đầu phiên mới (`/new`) hoặc chuyển phiên (`/resume`).

```typescript
pi.on("session_before_switch", async (event, ctx) => {
  // event.reason - "new" or "resume"
  // event.targetSessionFile - session we're switching to (only for "resume")

  if (event.reason === "new") {
    const ok = await ctx.ui.confirm("Clear?", "Delete all messages?");
    if (!ok) return { cancel: true };
  }
});
```

Sau khi chuyển phiên hoặc tạo phiên mới thành công, Prime Agent phát ra `session_shutdown` cho instance extension cũ, nạp lại và liên kết lại các extension cho phiên mới, rồi phát ra `session_start` với `reason: "new" | "resume"` và `previousSessionFile`.
Thực hiện dọn dẹp trong `session_shutdown`, sau đó khôi phục trạng thái trong bộ nhớ tại `session_start`.

#### session_before_fork

Được phát ra khi fork qua `/fork` hoặc clone qua `/clone`.

```typescript
pi.on("session_before_fork", async (event, ctx) => {
  // event.entryId - ID of the selected entry
  // event.position - "before" for /fork, "at" for /clone
  return { cancel: true }; // Cancel fork/clone
  // OR
  return { skipConversationRestore: true }; // Reserved for future conversation restore control
});
```

Sau khi fork hoặc clone thành công, Prime Agent phát ra `session_shutdown` cho instance extension cũ, nạp lại và liên kết lại các extension cho phiên mới, rồi phát ra `session_start` với `reason: "fork"` và `previousSessionFile`.
Thực hiện dọn dẹp trong `session_shutdown`, sau đó khôi phục trạng thái trong bộ nhớ tại `session_start`.

#### session_before_compact / session_compact

Được phát ra khi nén ngữ cảnh. Xem [compaction.md](compaction.vi.md) để biết chi tiết.

```typescript
pi.on("session_before_compact", async (event, ctx) => {
  const { preparation, branchEntries, customInstructions, signal } = event;

  // Cancel:
  return { cancel: true };

  // Custom summary:
  return {
    compaction: {
      summary: "...",
      firstKeptEntryId: preparation.firstKeptEntryId,
      tokensBefore: preparation.tokensBefore,
    }
  };
});

pi.on("session_compact", async (event, ctx) => {
  // event.compactionEntry - the saved compaction
  // event.fromExtension - whether extension provided it
});
```

#### session_before_tree / session_tree

Được phát ra khi điều hướng `/tree`. Xem [Sessions](sessions.vi.md) để biết các khái niệm điều hướng cây.

```typescript
pi.on("session_before_tree", async (event, ctx) => {
  const { preparation, signal } = event;
  return { cancel: true };
  // OR provide custom summary:
  return { summary: { summary: "...", details: {} } };
});

pi.on("session_tree", async (event, ctx) => {
  // event.newLeafId, oldLeafId, summaryEntry, fromExtension
});
```

#### session_shutdown

Được phát ra trước khi runtime của extension bị dừng.

```typescript
pi.on("session_shutdown", async (event, ctx) => {
  // event.reason - "quit" | "reload" | "new" | "resume" | "fork"
  // event.targetSessionFile - destination session for session replacement flows
  // Cleanup, save state, etc.
});
```

### Sự kiện agent

#### before_agent_start

Được phát ra sau khi người dùng gửi prompt và trước vòng lặp agent. Có thể chèn tin nhắn và/hoặc sửa system prompt.

```typescript
pi.on("before_agent_start", async (event, ctx) => {
  // event.prompt - user's prompt text
  // event.images - attached images (if any)
  // event.systemPrompt - current chained system prompt for this handler
  //   (includes changes from earlier before_agent_start handlers)
  // event.systemPromptOptions - structured options used to build the system prompt
  //   .customPrompt - any custom system prompt (from --system-prompt, SYSTEM.md, or custom templates)
  //   .selectedTools - tools currently active in the prompt
  //   .toolSnippets - one-line descriptions for each tool
  //   .promptGuidelines - custom guideline bullets
  //   .appendSystemPrompt - text from --append-system-prompt flags
  //   .cwd - working directory
  //   .contextFiles - AGENTS.md files and other loaded context files
  //   .skills - loaded skills

  return {
    // Inject a persistent message (stored in session, sent to LLM)
    message: {
      customType: "my-extension",
      content: "Additional context for the LLM",
      display: true,
    },
    // Replace the system prompt for this turn (chained across extensions)
    systemPrompt: event.systemPrompt + "\n\nExtra instructions for this turn...",
  };
});
```

Trường `systemPromptOptions` cho extension truy cập cùng dữ liệu có cấu trúc mà Prime Agent dùng để xây dựng system prompt. Bạn có thể kiểm tra prompt tùy chỉnh, hướng dẫn, mô tả công cụ, tệp ngữ cảnh và skill đã được nạp mà không cần phát hiện lại tài nguyên hoặc phân tích lại cờ. Dùng trường này khi extension cần sửa system prompt một cách sâu và có cơ sở, đồng thời tôn trọng cấu hình của người dùng.

Trong `before_agent_start`, `event.systemPrompt` và `ctx.getSystemPrompt()` đều phản ánh system prompt đã nối cho đến handler hiện tại. Các handler `before_agent_start` chạy sau vẫn có thể sửa nó.

#### agent_start / agent_end

Được phát ra khice per user prompt.

```typescript
pi.on("agent_start", async (_event, ctx) => {});

pi.on("agent_end", async (event, ctx) => {
  // event.messages - messages from this prompt
});
```

#### turn_start / turn_end

Được phát ra cho mỗi lượt (một phản hồi của LLM và các lời gọi công cụ).

```typescript
pi.on("turn_start", async (event, ctx) => {
  // event.turnIndex, event.timestamp
});

pi.on("turn_end", async (event, ctx) => {
  // event.turnIndex, event.message, event.toolResults
});
```

#### message_start / message_update / message_end

Được phát ra khi vòng đời tin nhắn được cập nhật.

- `message_start` và `message_end` được phát ra cho tin nhắn user, assistant và toolResult.
- `message_update` được phát ra cho các cập nhật stream của assistant.
- Handler `message_end` có thể trả về `{ message }` để thay thế tin nhắn đã hoàn tất. Tin nhắn thay thế phải giữ nguyên `role`.

```typescript
pi.on("message_start", async (event, ctx) => {
  // event.message
});

pi.on("message_update", async (event, ctx) => {
  // event.message
  // event.assistantMessageEvent (token-by-token stream event)
});

pi.on("message_end", async (event, ctx) => {
  if (event.message.role !== "assistant") return;

  return {
    message: {
      ...event.message,
      usage: {
        ...event.message.usage,
        cost: {
          ...event.message.usage.cost,
          total: 0.123,
        },
      },
    },
  };
});
```

#### tool_execution_start / tool_execution_update / tool_execution_end

Được phát ra khi vòng đời thực thi công cụ được cập nhật.

Trong chế độ chạy công cụ song song:
- `tool_execution_start` được phát ra theo thứ tự trong nguồn assistant ở giai đoạn preflight
- Các sự kiện `tool_execution_update` có thể đan xen giữa các công cụ
- `tool_execution_end` được phát ra theo thứ tự công cụ hoàn tất sau khi mỗi công cụ được chốt
- các sự kiện tin nhắn `toolResult` cuối cùng vẫn được phát ra sau đó theo thứ tự trong nguồn assistant

```typescript
pi.on("tool_execution_start", async (event, ctx) => {
  // event.toolCallId, event.toolName, event.args
});

pi.on("tool_execution_update", async (event, ctx) => {
  // event.toolCallId, event.toolName, event.args, event.partialResult
});

pi.on("tool_execution_end", async (event, ctx) => {
  // event.toolCallId, event.toolName, event.result, event.isError
});
```

#### context

Được phát ra trước mỗi lần gọi LLM. Sửa tin nhắn theo cách không phá hủy. Xem [Định dạng phiên](session-format.vi.md) để biết các kiểu tin nhắn.

```typescript
pi.on("context", async (event, ctx) => {
  // event.messages - deep copy, safe to modify
  const filtered = event.messages.filter(m => !shouldPrune(m));
  return { messages: filtered };
});
```

#### before_provider_request

Được phát ra sau khi payload dành riêng cho provider được xây dựng, ngay trước khi gửi request. Handler chạy theo thứ tự nạp extension. Trả về `undefined` giữ nguyên payload. Giá trị khác thay thế payload cho các handler sau và request thực tế.

Hook này có thể viết lại system instruction ở cấp provider hoặc xóa hoàn toàn. Thay đổi ở cấp payload không được phản ánh bởi `ctx.getSystemPrompt()`, vì phương thức này báo cáo chuỗi system prompt của Prime Agent thay vì payload provider đã tuần tự hóa cuối cùng.

```typescript
pi.on("before_provider_request", (event, ctx) => {
  console.log(JSON.stringify(event.payload, null, 2));

  // Optional: replace payload
  // return { ...event.payload, temperature: 0 };
});
```

Điều này chủ yếu hữu ích để gỡ lỗi việc tuần tự hóa provider và hành vi cache.

#### after_provider_response

Được phát ra sau khi nhận response HTTP và trước khi đọc phần thân stream. Handler chạy theo thứ tự nạp extension.

```typescript
pi.on("after_provider_response", (event, ctx) => {
  // event.status - HTTP status code
  // event.headers - normalized response headers
  if (event.status === 429) {
    console.log("rate limited", event.headers["retry-after"]);
  }
});
```

Khả năng truy cập header phụ thuộc vào provider và transport. Provider trừu tượng hóa response HTTP có thể không cung cấp header.

### Sự kiện model

#### model_select

Được phát ra khi model thay đổi qua command `/model`, chuyển model (`Ctrl+P`) hoặc khôi phục phiên.

```typescript
pi.on("model_select", async (event, ctx) => {
  // event.model - newly selected model
  // event.previousModel - previous model (undefined if first selection)
  // event.source - "set" | "cycle" | "restore"

  const prev = event.previousModel
    ? `${event.previousModel.provider}/${event.previousModel.id}`
    : "none";
  const next = `${event.model.provider}/${event.model.id}`;

  ctx.ui.notify(`Model changed (${event.source}): ${prev} -> ${next}`, "info");
});
```

Dùng sự kiện này để cập nhật thành phần UI (thanh trạng thái, footer) hoặc khởi tạo theo model khi model đang hoạt động thay đổi.

#### thinking_level_select

Được phát ra khi mức suy luận thay đổi. Đây chỉ là thông báo; giá trị trả về của handler bị bỏ qua.

```typescript
pi.on("thinking_level_select", async (event, ctx) => {
  // event.level - newly selected thinking level
  // event.previousLevel - previous thinking level

  ctx.ui.setStatus("thinking", `thinking: ${event.level}`);
});
```

Dùng sự kiện này để cập nhật UI extension khi `pi.setThinkingLevel()`, model hoặc các điều khiển mức suy luận tích hợp sẵn thay đổi mức đang hoạt động.

### Sự kiện công cụ

#### tool_call

Được phát ra sau `tool_execution_start`, trước khi công cụ thực thi. **Có thể chặn.** Dùng `isToolCallEventType` để thu hẹp kiểu và nhận input đã định kiểu.

Trước khi `tool_call` chạy, Prime Agent chờ các sự kiện Agent đã phát ra xử lý xong qua `AgentSession`. Điều này nghĩa là `ctx.sessionManager` được cập nhật đến tin nhắn assistant hiện tại có lời gọi công cụ.

Trong chế độ thực thi công cụ song song mặc định, các lời gọi công cụ cùng cấp trong một tin nhắn assistant được preflight tuần tự rồi thực thi đồng thời. `tool_call` không được đảm bảo nhìn thấy kết quả công cụ cùng cấp của tin nhắn assistant đó trong `ctx.sessionManager`.

`event.input` có thể sửa đổi. Sửa trực tiếp tại chỗ để vá tham số công cụ trước khi thực thi.

Các bảo đảm về hành vi:
- Thay đổi `event.input` ảnh hưởng đến việc thực thi công cụ thực tế
- Handler `tool_call` chạy sau nhìn thấy thay đổi của handler chạy trước
- Không kiểm tra lại sau khi bạn thay đổi
- Giá trị trả về từ `tool_call` chỉ điều khiển việc chặn qua `{ block: true, reason?: string }`

```typescript
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";

pi.on("tool_call", async (event, ctx) => {
  // event.toolName - "ipython", "bash", "edit", etc.
  // event.toolCallId
  // event.input - tool parameters (mutable)

  // Built-in tools: no type params needed
  if (isToolCallEventType("bash", event)) {
    // event.input is { command: string; timeout?: number }
    event.input.command = `source ~/.profile\n${event.input.command}`;

    if (event.input.command.includes("rm -rf")) {
      return { block: true, reason: "Dangerous command" };
    }
  }

  if (isToolCallEventType("ipython", event)) {
    // event.input is { code: string }
    console.log(`Python code: ${event.input.code}`);
  }
});
```

#### Định kiểu input công cụ tùy chỉnh

Công cụ tùy chỉnh nên export kiểu input của chúng:

```typescript
// my-extension.ts
export type MyToolInput = Static<typeof myToolSchema>;
```

Dùng `isToolCallEventType` với tham số kiểu tường minh:

```typescript
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";
import type { MyToolInput } from "my-extension";

pi.on("tool_call", (event) => {
  if (isToolCallEventType<"my_tool", MyToolInput>("my_tool", event)) {
    event.input.action;  // typed
  }
});
```

#### tool_result

Được phát ra sau khi thực thi công cụ hoàn tất và trước `tool_execution_end` cùng các sự kiện tin nhắn kết quả công cụ cuối cùng. **Có thể sửa kết quả.**

Trong chế độ công cụ song song, `tool_result` và `tool_execution_end` có thể đan xen theo thứ tự công cụ hoàn tất, trong khi các sự kiện tin nhắn `toolResult` cuối cùng vẫn được phát ra sau đó theo thứ tự trong nguồn assistant.

Handler `tool_result` nối tiếp như middleware:
- Handler chạy theo thứ tự nạp extension
- Mỗi handler nhìn thấy kết quả mới nhất sau thay đổi của handler trước
- Handler có thể trả về bản vá một phần (`content`, `details` hoặc `isError`); trường bị bỏ qua giữ nguyên giá trị hiện tại

Dùng `ctx.signal` cho công việc bất đồng bộ lồng bên trong handler. Nhờ đó Esc có thể hủy lời gọi model, `fetch()` và các thao tác hỗ trợ abort khác do extension khởi chạy.

```typescript
import { isBashToolResult } from "@earendil-works/pi-coding-agent";

pi.on("tool_result", async (event, ctx) => {
  // event.toolName, event.toolCallId, event.input
  // event.content, event.details, event.isError

  if (isBashToolResult(event)) {
    // event.details is typed as BashToolDetails
  }

  const response = await fetch("https://example.com/summarize", {
    method: "POST",
    body: JSON.stringify({ content: event.content }),
    signal: ctx.signal,
  });

  // Modify result:
  return { content: [...], details: {...}, isError: false };
});
```

### Sự kiện Bash của user

#### user_bash

Được phát ra khi người dùng thực thi command `!` hoặc `!!`. **Có thể can thiệp.**

```typescript
import { createLocalBashOperations } from "@earendil-works/pi-coding-agent";

pi.on("user_bash", (event, ctx) => {
  // event.command - the bash command
  // event.excludeFromContext - true if !! prefix
  // event.cwd - working directory

  // Option 1: Provide custom operations (e.g., SSH)
  return { operations: remoteBashOps };

  // Option 2: Wrap Prime Agent's built-in local bash backend
  const local = createLocalBashOperations();
  return {
    operations: {
      exec(command, cwd, options) {
        return local.exec(`source ~/.profile\n${command}`, cwd, options);
      }
    }
  };

  // Option 3: Full replacement - return result directly
  return { result: { output: "...", exitCode: 0, cancelled: false, truncated: false } };
});
```

### Sự kiện input

#### input

Được phát ra khi nhận input của user, sau khi kiểm tra command extension nhưng trước khi mở rộng skill và template. Sự kiện nhìn thấy văn bản input thô, nên `/skill:foo` và `/template` chưa được mở rộng.

**Thứ tự xử lý:**
1. Kiểm tra command extension (`/cmd`) trước - nếu tìm thấy, handler chạy và bỏ qua sự kiện input
2. Phát ra sự kiện `input` - có thể can thiệp, biến đổi hoặc xử lý
3. Nếu chưa được xử lý: mở rộng command skill (`/skill:name`) thành nội dung skill
4. Nếu chưa được xử lý: mở rộng template prompt (`/template`) thành nội dung template
5. Bắt đầu xử lý agent (`before_agent_start`, v.v.)

```typescript
pi.on("input", async (event, ctx) => {
  // event.text - raw input (before skill/template expansion)
  // event.images - attached images, if any
  // event.source - "interactive" (typed), "rpc" (API), or "extension" (via sendUserMessage)

  // Transform: rewrite input before expansion
  if (event.text.startsWith("?quick "))
    return { action: "transform", text: `Respond briefly: ${event.text.slice(7)}` };

  // Handle: respond without LLM (extension shows its own feedback)
  if (event.text === "ping") {
    ctx.ui.notify("pong", "info");
    return { action: "handled" };
  }

  // Route by source: skip processing for extension-injected messages
  if (event.source === "extension") return { action: "continue" };

  // Intercept skill commands before expansion
  if (event.text.startsWith("/skill:")) {
    // Could transform, block, or let pass through
  }

  return { action: "continue" };  // Default: pass through to expansion
});
```

**Kết quả:**
- `continue` - truyền qua không thay đổi (mặc định nếu handler không trả về gì)
- `transform` - sửa văn bản/hình ảnh rồi tiếp tục mở rộng
- `handled` - bỏ qua hoàn toàn agent (handler đầu tiên trả về giá trị này sẽ thắng)

Các phép biến đổi được nối qua nhiều handler. Xem [input-transform.ts](../examples/extensions/input-transform.ts).

## ExtensionContext

Mọi handler đều nhận `ctx: ExtensionContext`.

### ctx.ui

Các phương thức UI để tương tác với người dùng. Xem [UI tùy chỉnh](#ui-tùy-chỉnh) để biết đầy đủ chi tiết.

### ctx.hasUI

`false` trong chế độ print (`-p`) và JSON. `true` trong chế độ tương tác và RPC. Trong chế độ RPC, các phương thức hộp thoại (`select`, `confirm`, `input`, `editor`) hoạt động qua sub-protocol UI của extension, còn các phương thức fire-and-forget (`notify`, `setStatus`, `setWidget`, `setTitle`, `setEditorText`) phát request tới client. Một số phương thức riêng của TUI không làm gì hoặc trả về mặc định (xem [rpc.md](rpc.vi.md#extension-ui-protocol)).

### ctx.cwd

Thư mục làm việc hiện tại.

### ctx.sessionManager

Truy cập chỉ đọc vào trạng thái phiên. Xem [Định dạng phiên](session-format.vi.md) để biết đầy đủ API SessionManager và các kiểu entry.

Với `tool_call`, trạng thái này được đồng bộ đến tin nhắn assistant hiện tại trước khi handler chạy. Trong chế độ thực thi công cụ song song, vẫn không đảm bảo trạng thái chứa kết quả công cụ cùng cấp từ cùng tin nhắn assistant.

```typescript
ctx.sessionManager.getEntries()       // All entries
ctx.sessionManager.getBranch()        // Current branch
ctx.sessionManager.getLeafId()        // Current leaf entry ID
```

### ctx.modelRegistry / ctx.model

Truy cập model và API key.

### ctx.signal

Tín hiệu abort hiện tại của agent, hoặc `undefined` khi không có lượt agent đang hoạt động.

Dùng tín hiệu này cho công việc lồng có hỗ trợ abort do handler extension khởi chạy, ví dụ:
- `fetch(..., { signal: ctx.signal })`
- lời gọi model nhận `signal`
- helper tệp hoặc process nhận `AbortSignal`

`ctx.signal` thường được định nghĩa trong các sự kiện của lượt đang hoạt động như `tool_call`, `tool_result`, `message_update` và `turn_end`.
Nó thường là `undefined` trong ngữ cảnh rảnh hoặc không thuộc lượt, chẳng hạn sự kiện phiên, command extension và shortcut được phát ra khi Prime Agent đang rảnh.

```typescript
pi.on("tool_result", async (event, ctx) => {
  const response = await fetch("https://example.com/api", {
    method: "POST",
    body: JSON.stringify(event),
    signal: ctx.signal,
  });

  const data = await response.json();
  return { details: data };
});
```

### ctx.isIdle() / ctx.abort() / ctx.hasPendingMessages()

Các hàm hỗ trợ điều khiển luồng.

### ctx.shutdown()

Yêu cầu Prime Agent tắt một cách an toàn.

- **Chế độ tương tác:** Được trì hoãn đến khi agent ở trạng thái rảnh (sau khi xử lý mọi tin nhắn điều hướng và follow-up đang xếp hàng).
- **Chế độ RPC:** Được trì hoãn đến trạng thái rảnh tiếp theo (sau khi hoàn tất phản hồi lệnh hiện tại và đang chờ lệnh tiếp theo).
- **Chế độ print:** Không làm gì. Tiến trình tự động thoát khi đã xử lý mọi prompt.

Phát ra sự kiện `session_shutdown` cho mọi extension trước khi thoát. Khả dụng trong mọi ngữ cảnh (handler sự kiện, công cụ, lệnh, shortcut).

```typescript
pi.on("tool_call", (event, ctx) => {
  if (isFatal(event.input)) {
    ctx.shutdown();
  }
});
```

### ctx.getContextUsage()

Trả về mức sử dụng ngữ cảnh hiện tại của model đang hoạt động. Dùng số liệu sử dụng gần nhất của assistant nếu có, sau đó ước tính token cho các tin nhắn còn lại.

```typescript
const usage = ctx.getContextUsage();
if (usage && usage.tokens > 100_000) {
  // ...
}
```

### ctx.compact()

Kích hoạt nén ngữ cảnh mà không chờ hoàn tất. Dùng `onComplete` và `onError` cho các hành động tiếp theo.

```typescript
ctx.compact({
  customInstructions: "Focus on recent changes",
  onComplete: (result) => {
    ctx.ui.notify("Compaction completed", "info");
  },
  onError: (error) => {
    ctx.ui.notify(`Compaction failed: ${error.message}`, "error");
  },
});
```

### ctx.getSystemPrompt()

Trả về chuỗi system prompt hiện tại của Prime Agent.

- Trong `before_agent_start`, giá trị này phản ánh các thay đổi system prompt đã được nối cho đến thời điểm hiện tại của lượt đang chạy.
- Giá trị này không bao gồm các thay đổi tin nhắn trong `context` diễn ra sau đó.
- Giá trị này không bao gồm việc viết lại payload trong `before_provider_request`.
- Nếu các extension được nạp sau extension của bạn chạy tiếp, chúng vẫn có thể thay đổi nội dung thực sự được gửi.

```typescript
pi.on("before_agent_start", (event, ctx) => {
  const prompt = ctx.getSystemPrompt();
  console.log(`System prompt length: ${prompt.length}`);
});
```

## ExtensionCommandContext

Handler lệnh nhận `ExtensionCommandContext`, mở rộng `ExtensionContext` bằng các phương thức điều khiển phiên. Các phương thức này chỉ khả dụng trong lệnh vì gọi chúng từ handler sự kiện có thể gây deadlock.

### ctx.waitForIdle()

Chờ agent hoàn tất việc stream:

```typescript
pi.registerCommand("my-cmd", {
  handler: async (args, ctx) => {
    await ctx.waitForIdle();
    // Agent is now idle, safe to modify session
  },
});
```

### ctx.newSession(options?)

Tạo một phiên mới:

```typescript
const parentSession = ctx.sessionManager.getSessionFile();
const kickoff = "Continue in the replacement session";

const result = await ctx.newSession({
  parentSession,
  setup: async (sm) => {
    sm.appendMessage({
      role: "user",
      content: [{ type: "text", text: "Context from previous session..." }],
      timestamp: Date.now(),
    });
  },
  withSession: async (ctx) => {
    // Use only the replacement-session ctx here.
    await ctx.sendUserMessage(kickoff);
  },
});

if (result.cancelled) {
  // An extension cancelled the new session
}
```

Tùy chọn:
- `parentSession`: tệp phiên cha cần ghi vào header của phiên mới
- `setup`: sửa `SessionManager` của phiên mới trước khi chạy `withSession`
- `withSession`: chạy công việc sau khi chuyển phiên trong ngữ cảnh phiên thay thế mới. Không dùng `pi` / `ctx` lệnh cũ đã capture; xem [Vòng đời thay thế phiên và các cạm bẫy](#vòng-đời-thay-thế-phiên-và-các-cạm-bẫy).

### ctx.fork(entryId, options?)

Fork từ một entry cụ thể để tạo tệp phiên mới:

```typescript
const result = await ctx.fork("entry-id-123", {
  withSession: async (ctx) => {
    // Use only the replacement-session ctx here.
    ctx.ui.notify("Now in the forked session", "info");
  },
});
if (result.cancelled) {
  // An extension cancelled the fork
}

const cloneResult = await ctx.fork("entry-id-456", { position: "at" });
if (cloneResult.cancelled) {
  // An extension cancelled the clone
}
```

Tùy chọn:
- `position`: `"before"` (mặc định) fork trước tin nhắn user được chọn và khôi phục prompt đó vào editor
- `position`: `"at"` nhân bản đường đi đang hoạt động qua entry được chọn mà không khôi phục văn bản editor
- `withSession`: chạy công việc sau khi chuyển phiên trong ngữ cảnh phiên thay thế mới. Không dùng `pi` / `ctx` lệnh cũ đã capture; xem [Vòng đời thay thế phiên và các cạm bẫy](#vòng-đời-thay-thế-phiên-và-các-cạm-bẫy).

### ctx.navigateTree(targetId, options?)

Điều hướng đến một điểm khác trong cây phiên:

```typescript
const result = await ctx.navigateTree("entry-id-456", {
  summarize: true,
  customInstructions: "Focus on error handling changes",
  replaceInstructions: false, // true = replace default prompt entirely
  label: "review-checkpoint",
});
```

Tùy chọn:
- `summarize`: Có tạo tóm tắt cho nhánh bị bỏ lại hay không
- `customInstructions`: Hướng dẫn tùy chỉnh cho bộ tóm tắt
- `replaceInstructions`: Nếu là true, `customInstructions` thay thế prompt mặc định thay vì được nối thêm
- `label`: Nhãn gắn vào entry tóm tắt nhánh (hoặc entry đích nếu không tóm tắt)

### ctx.switchSession(sessionPath, options?)

Chuyển sang một tệp phiên khác:

```typescript
const result = await ctx.switchSession("/path/to/session.jsonl", {
  withSession: async (ctx) => {
    await ctx.sendUserMessage("Resume work in the replacement session");
  },
});
if (result.cancelled) {
  // An extension cancelled the switch via session_before_switch
}
```

Tùy chọn:
- `withSession`: chạy công việc sau khi chuyển phiên trong ngữ cảnh phiên thay thế mới. Không dùng `pi` / `ctx` lệnh cũ đã capture; xem [Vòng đời thay thế phiên và các cạm bẫy](#vòng-đời-thay-thế-phiên-và-các-cạm-bẫy).

Để phát hiện các phiên khả dụng, dùng phương thức tĩnh `SessionManager.list()` hoặc `SessionManager.listAll()`:

```typescript
import { SessionManager } from "@earendil-works/pi-coding-agent";

pi.registerCommand("switch", {
  description: "Switch to another session",
  handler: async (args, ctx) => {
    const sessions = await SessionManager.list(ctx.cwd);
    if (sessions.length === 0) return;
    const choice = await ctx.ui.select(
      "Pick session:",
      sessions.map(s => s.file),
    );
    if (choice) {
      await ctx.switchSession(choice, {
        withSession: async (ctx) => {
          ctx.ui.notify("Switched session", "info");
        },
      });
    }
  },
});
```

### Vòng đời thay thế phiên và các cạm bẫy

`withSession` nhận một `ReplacedSessionContext` mới, mở rộng `ExtensionCommandContext` bằng các hàm hỗ trợ bất đồng bộ `sendMessage()` và `sendUserMessage()` gắn với phiên thay thế.

Vòng đời và các cạm bẫy:
- `withSession` chỉ chạy sau khi phiên cũ đã phát ra `session_shutdown`, runtime cũ đã bị dừng, phiên thay thế đã được liên kết lại và instance extension mới đã nhận `session_start`.
- Callback vẫn chạy trong closure ban đầu, không chạy bên trong instance extension mới. Vì vậy instance extension cũ có thể đã dọn dẹp khi tắt trước khi `withSession` bắt đầu.
- Các object `pi` cũ / `ctx` lệnh cũ đã capture và gắn với phiên sẽ lỗi thời sau khi thay thế và sẽ throw nếu được dùng. Chỉ dùng `ctx` được truyền vào `withSession` cho công việc gắn với phiên.
- Các object thô đã trích xuất trước đó vẫn thuộc trách nhiệm của bạn. Ví dụ, nếu capture `const sm = ctx.sessionManager` trước khi thay thế, `sm` vẫn là object `SessionManager` cũ. Không tái sử dụng nó sau khi thay thế.
- Code trong `withSession` phải giả định mọi trạng thái bị handler `session_shutdown` vô hiệu hóa đã biến mất. Chỉ capture dữ liệu thuần tồn tại an toàn sau khi tắt, chẳng hạn chuỗi, id và cấu hình đã tuần tự hóa.

Mẫu an toàn:

```typescript
pi.registerCommand("handoff", {
  handler: async (_args, ctx) => {
    const kickoff = "Continue from the replacement session";
    await ctx.newSession({
      withSession: async (ctx) => {
        await ctx.sendUserMessage(kickoff);
      },
    });
  },
});
```

Mẫu không an toàn:

```typescript
pi.registerCommand("handoff", {
  handler: async (_args, ctx) => {
    const oldSessionManager = ctx.sessionManager;
    await ctx.newSession({
      withSession: async (_ctx) => {
        // stale old objects: do not do this
        oldSessionManager.getSessionFile();
        pi.sendUserMessage("wrong");
      },
    });
  },
});
```

### ctx.reload()

Chạy cùng luồng reload như `/reload`.

```typescript
pi.registerCommand("reload-runtime", {
  description: "Reload extensions, skills, prompts, and themes",
  handler: async (_args, ctx) => {
    await ctx.reload();
    return;
  },
});
```

Hành vi quan trọng:
- `await ctx.reload()` phát ra `session_shutdown` cho runtime extension hiện tại
- Sau đó reload tài nguyên và phát ra `session_start` với `reason: "reload"`, cùng `resources_discover` với reason `"reload"`
- Handler lệnh đang chạy vẫn tiếp tục trong call frame cũ
- Code sau `await ctx.reload()` vẫn chạy từ phiên bản trước khi reload
- Code sau `await ctx.reload()` không được giả định trạng thái extension cũ trong bộ nhớ còn hợp lệ
- Sau khi handler trả về, các lệnh/sự kiện/lời gọi công cụ tiếp theo dùng phiên bản extension mới

Để hành vi dễ dự đoán, hãy coi reload là thao tác kết thúc handler đó (`await ctx.reload(); return;`).

Tool chạy với `ExtensionContext`, nên không thể gọi trực tiếp `ctx.reload()`. Dùng một command làm điểm vào reload, sau đó cung cấp một tool xếp command đó thành tin nhắn user follow-up.

Ví dụ công cụ mà LLM có thể gọi để kích hoạt reload:

```typescript
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("reload-runtime", {
    description: "Reload extensions, skills, prompts, and themes",
    handler: async (_args, ctx) => {
      await ctx.reload();
      return;
    },
  });

  pi.registerTool({
    name: "reload_runtime",
    label: "Reload Runtime",
    description: "Reload extensions, skills, prompts, and themes",
    parameters: Type.Object({}),
    async execute() {
      pi.sendUserMessage("/reload-runtime", { deliverAs: "followUp" });
      return {
        content: [{ type: "text", text: "Queued /reload-runtime as a follow-up command." }],
      };
    },
  });
}
```

## Các phương thức ExtensionAPI

### pi.on(event, handler)

Đăng ký lắng nghe sự kiện. Xem [Sự kiện](#sự-kiện) để biết các kiểu sự kiện và giá trị trả về.

### pi.registerTool(definition)

Đăng ký công cụ tùy chỉnh mà LLM có thể gọi. Xem [Công cụ tùy chỉnh](#công-cụ-tùy-chỉnh) để biết đầy đủ chi tiết.

`pi.registerTool()` hoạt động cả trong lúc nạp extension và sau khi khởi động. Bạn có thể gọi nó bên trong `session_start`, handler lệnh hoặc handler sự kiện khác. Công cụ mới được cập nhật ngay trong cùng phiên, nên xuất hiện trong `pi.getAllTools()` và LLM có thể gọi mà không cần `/reload`.

Dùng `pi.setActiveTools()` để bật hoặc tắt công cụ (bao gồm công cụ được thêm động) khi runtime đang chạy.

Dùng `promptGuidelines` để nối các bullet dành riêng cho công cụ vào system prompt mặc định khi công cụ đang hoạt động.
`promptSnippet` vẫn khả dụng dưới dạng metadata cho extension xây dựng prompt tùy chỉnh, nhưng prompt mặc định dựa vào schema công cụ của provider thay vì một danh sách công cụ riêng.

**Quan trọng:** Các bullet `promptGuidelines` được nối phẳng, không tự động thêm tiền tố tên công cụ. Mỗi hướng dẫn phải nêu tên công cụ mà nó đề cập — tránh viết "Use this tool when..." vì LLM không biết "this" là công cụ nào. Thay vào đó, hãy viết "Use my_tool when...".

Xem ví dụ đầy đủ tại [dynamic-tools.ts](../examples/extensions/dynamic-tools.ts).

```typescript
import { Type } from "typebox";
import { StringEnum } from "@earendil-works/pi-ai";

pi.registerTool({
  name: "my_tool",
  label: "My Tool",
  description: "What this tool does",
  promptSnippet: "Summarize or transform text according to action",
  promptGuidelines: ["Use my_tool when the user asks to summarize previously generated text."],
  parameters: Type.Object({
    action: StringEnum(["list", "add"] as const),
    text: Type.Optional(Type.String()),
  }),
  prepareArguments(args) {
    // Optional compatibility shim. Runs before schema validation.
    // Return the current schema shape, for example to fold legacy fields
    // into the modern parameter object.
    return args;
  },

  async execute(toolCallId, params, signal, onUpdate, ctx) {
    // Stream progress
    onUpdate?.({ content: [{ type: "text", text: "Working..." }] });

    return {
      content: [{ type: "text", text: "Done" }],
      details: { result: "..." },
    };
  },

  // Optional: Custom rendering
  renderCall(args, theme, context) { ... },
  renderResult(result, options, theme, context) { ... },
});
```

### pi.sendMessage(message, options?)

Chèn một tin nhắn tùy chỉnh vào phiên.

```typescript
pi.sendMessage({
  customType: "my-extension",
  content: "Message text",
  display: true,
  details: { ... },
}, {
  triggerTurn: true,
  deliverAs: "steer",
});
```

**Tùy chọn:**
- `deliverAs` - Chế độ phân phối:
  - `"steer"` (mặc định) - Xếp tin nhắn khi đang stream. Phân phối sau khi lượt assistant hiện tại hoàn tất việc thực thi các lời gọi công cụ và trước lần gọi LLM tiếp theo.
  - `"followUp"` - Chờ agent hoàn tất. Chỉ phân phối khi agent không còn lời gọi công cụ.
  - `"nextTurn"` - Xếp cho prompt user tiếp theo. Không ngắt hoặc kích hoạt gì.
- `triggerTurn: true` - Nếu agent đang rảnh, lập tức kích hoạt phản hồi LLM. Chỉ áp dụng cho chế độ `"steer"` và `"followUp"` (bị bỏ qua với `"nextTurn"`).

### pi.sendUserMessage(content, options?)

Gửi tin nhắn user cho agent. Khác với `sendMessage()` vốn gửi tin nhắn tùy chỉnh, phương thức này gửi tin nhắn user thực sự và hiển thị như thể người dùng đã nhập. Luôn kích hoạt một lượt.

```typescript
// Simple text message
pi.sendUserMessage("What is 2+2?");

// With content array (text + images)
pi.sendUserMessage([
  { type: "text", text: "Describe this image:" },
  { type: "image", source: { type: "base64", mediaType: "image/png", data: "..." } },
]);

// During streaming - must specify delivery mode
pi.sendUserMessage("Focus on error handling", { deliverAs: "steer" });
pi.sendUserMessage("And then summarize", { deliverAs: "followUp" });
```

**Tùy chọn:**
- `deliverAs` - Bắt buộc khi agent đang stream:
  - `"steer"` - Xếp tin nhắn để phân phối sau khi lượt assistant hiện tại hoàn tất thực thi các lời gọi công cụ
  - `"followUp"` - Chờ agent hoàn tất mọi công cụ

Khi không stream, tin nhắn được gửi ngay và kích hoạt lượt mới. Khi đang stream mà không có `deliverAs`, phương thức sẽ throw lỗi.

Xem ví dụ đầy đủ tại [send-user-message.ts](../examples/extensions/send-user-message.ts).

### pi.appendEntry(customType, data?)

Lưu bền trạng thái extension (KHÔNG tham gia vào ngữ cảnh LLM).

```typescript
pi.appendEntry("my-state", { count: 42 });

// Restore on reload
pi.on("session_start", async (_event, ctx) => {
  for (const entry of ctx.sessionManager.getEntries()) {
    if (entry.type === "custom" && entry.customType === "my-state") {
      // Reconstruct from entry.data
    }
  }
});
```

### pi.setSessionName(name)

Đặt tên hiển thị của phiên (hiển thị trong bộ chọn phiên thay cho tin nhắn đầu tiên).

```typescript
pi.setSessionName("Refactor auth module");
```

### pi.getSessionName()

Lấy tên phiên hiện tại nếu đã được đặt.

```typescript
const name = pi.getSessionName();
if (name) {
  console.log(`Session: ${name}`);
}
```

### pi.setLabel(entryId, label)

Đặt hoặc xóa nhãn trên một entry. Nhãn là các đánh dấu do người dùng định nghĩa để bookmark và điều hướng (hiển thị trong bộ chọn `/tree`).

```typescript
// Set a label
pi.setLabel(entryId, "checkpoint-before-refactor");

// Clear a label
pi.setLabel(entryId, undefined);

// Read labels via sessionManager
const label = ctx.sessionManager.getLabel(entryId);
```

Nhãn được lưu bền trong phiên và tồn tại qua các lần khởi động lại. Dùng chúng để đánh dấu các điểm quan trọng (lượt, checkpoint) trong cây hội thoại.

### pi.registerCommand(name, options)

Đăng ký một command.

Nếu nhiều extension đăng ký cùng tên command, Prime Agent giữ lại tất cả và gán hậu tố gọi bằng số theo thứ tự nạp, chẳng hạn `/review:1` và `/review:2`.

```typescript
pi.registerCommand("stats", {
  description: "Show session statistics",
  handler: async (args, ctx) => {
    const count = ctx.sessionManager.getEntries().length;
    ctx.ui.notify(`${count} entries`, "info");
  }
});
```

Tùy chọn: thêm tự động hoàn tất tham số cho `/command ...`:

```typescript
import type { AutocompleteItem } from "@earendil-works/pi-tui";

pi.registerCommand("deploy", {
  description: "Deploy to an environment",
  getArgumentCompletions: (prefix: string): AutocompleteItem[] | null => {
    const envs = ["dev", "staging", "prod"];
    const items = envs.map((e) => ({ value: e, label: e }));
    const filtered = items.filter((i) => i.value.startsWith(prefix));
    return filtered.length > 0 ? filtered : null;
  },
  handler: async (args, ctx) => {
    ctx.ui.notify(`Deploying: ${args}`, "info");
  },
});
```

### pi.getCommands()

Lấy các slash command có thể gọi qua `prompt` trong phiên hiện tại. Kết quả gồm command của extension, template prompt và command skill.
Danh sách này có cùng thứ tự với RPC `get_commands`: extension trước, rồi template, rồi skill.

```typescript
const commands = pi.getCommands();
const bySource = commands.filter((command) => command.source === "extension");
const userScoped = commands.filter((command) => command.sourceInfo.scope === "user");
```

Mỗi entry có dạng sau:

```typescript
{
  name: string; // Invokable command name without the leading slash. May be suffixed like "review:1"
  description?: string;
  source: "extension" | "prompt" | "skill";
  sourceInfo: {
    path: string;
    source: string;
    scope: "user" | "project" | "temporary";
    origin: "package" | "top-level";
    baseDir?: string;
  };
}
```

Dùng `sourceInfo` làm trường nguồn gốc chuẩn. Không suy đoán quyền sở hữu từ tên command hoặc tự phân tích đường dẫn tùy tiện.

Các command tương tác tích hợp sẵn (như `/model` và `/settings`) không được bao gồm ở đây. Chúng chỉ được xử lý trong
chế độ tương tác và sẽ không thực thi nếu được gửi qua `prompt`.

### pi.registerMessageRenderer(customType, renderer)

Đăng ký renderer TUI tùy chỉnh cho các tin nhắn có `customType` của bạn. Xem [UI tùy chỉnh](#ui-tùy-chỉnh).

### pi.registerShortcut(shortcut, options)

Đăng ký shortcut bàn phím. Xem [keybindings.md](keybindings.vi.md) để biết định dạng shortcut và các keybinding tích hợp sẵn.

```typescript
pi.registerShortcut("ctrl+shift+p", {
  description: "Toggle plan mode",
  handler: async (ctx) => {
    ctx.ui.notify("Toggled!");
  },
});
```

### pi.registerFlag(name, options)

Đăng ký một cờ CLI.

```typescript
pi.registerFlag("plan", {
  description: "Start in plan mode",
  type: "boolean",
  default: false,
});

// Check value
if (pi.getFlag("plan")) {
  // Plan mode enabled
}
```

### pi.exec(command, args, options?)

Thực thi một lệnh shell.

```typescript
const result = await pi.exec("git", ["status"], { signal, timeout: 5000 });
// result.stdout, result.stderr, result.code, result.killed
```

### pi.getActiveTools() / pi.getAllTools() / pi.setActiveTools(names)

Quản lý các công cụ đang hoạt động. Cách này áp dụng cho cả công cụ tích hợp sẵn và công cụ được đăng ký động.

```typescript
const active = pi.getActiveTools();
const all = pi.getAllTools();
// [{
//   name: "ipython",
//   description: "Execute Python code in a persistent IPython kernel...",
//   parameters: ..., 
//   sourceInfo: { path: "<builtin:ipython>", source: "builtin", scope: "temporary", origin: "top-level" }
// }, ...]
const names = all.map(t => t.name);
const builtinTools = all.filter((t) => t.sourceInfo.source === "builtin");
const extensionTools = all.filter((t) => t.sourceInfo.source !== "builtin" && t.sourceInfo.source !== "sdk");
pi.setActiveTools(["bash", "edit"]); // Switch to optional shell/edit tools
```

`pi.getAllTools()` trả về `name`, `description`, `parameters` và `sourceInfo`.

Các giá trị `sourceInfo.source` thường gặp:
- `builtin` cho công cụ tích hợp sẵn
- `sdk` cho công cụ truyền qua `createAgentSession({ customTools })`
- metadata nguồn extension cho công cụ do extension đăng ký

### pi.setModel(model)

Đặt model hiện tại. Trả về `false` nếu model không có API key khả dụng. Xem [models.md](models.vi.md) để biết cách cấu hình model tùy chỉnh.

```typescript
const model = ctx.modelRegistry.find("anthropic", "claude-sonnet-4-5");
if (model) {
  const success = await pi.setModel(model);
  if (!success) {
    ctx.ui.notify("No API key for this model", "error");
  }
}
```

### pi.getThinkingLevel() / pi.setThinkingLevel(level)

Lấy hoặc đặt mức suy luận. Mức được giới hạn theo khả năng của model (model không suy luận luôn dùng "off"). Thay đổi sẽ phát ra `thinking_level_select`.

```typescript
const current = pi.getThinkingLevel();  // "off" | "minimal" | "low" | "medium" | "high" | "xhigh"
pi.setThinkingLevel("high");
```

### pi.events

Event bus dùng chung để giao tiếp giữa các extension:

```typescript
pi.events.on("my:event", (data) => { ... });
pi.events.emit("my:event", { ... });
```

### pi.registerProvider(name, config)

Đăng ký hoặc ghi đè động một provider model. Hữu ích cho proxy, endpoint tùy chỉnh hoặc cấu hình model dùng chung trong nhóm.

Các lời gọi trong hàm factory của extension được xếp hàng và áp dụng khi runner khởi tạo xong. Các lời gọi sau đó — chẳng hạn từ handler command sau luồng thiết lập của người dùng — có hiệu lực ngay mà không cần `/reload`.

Nếu cần phát hiện model từ endpoint từ xa, nên dùng factory extension bất đồng bộ thay vì trì hoãn việc fetch đến `session_start`. Prime Agent chờ factory trước khi tiếp tục khởi động, nên các model đã đăng ký khả dụng ngay, bao gồm cả với `prime-agent model list`.

```typescript
// Register a new provider with custom models
pi.registerProvider("my-proxy", {
  name: "My Proxy",
  baseUrl: "https://proxy.example.com",
  apiKey: "PROXY_API_KEY",  // env var name or literal
  api: "anthropic-messages",
  models: [
    {
      id: "claude-sonnet-4-20250514",
      name: "Claude 4 Sonnet (proxy)",
      reasoning: false,
      input: ["text", "image"],
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      contextWindow: 200000,
      maxTokens: 16384
    }
  ]
});

// Override baseUrl for an existing provider (keeps all models)
pi.registerProvider("anthropic", {
  baseUrl: "https://proxy.example.com"
});

// Register provider with OAuth support for /login
pi.registerProvider("corporate-ai", {
  baseUrl: "https://ai.corp.com",
  api: "openai-responses",
  models: [...],
  oauth: {
    name: "Corporate AI (SSO)",
    async login(callbacks) {
      // Custom OAuth flow
      callbacks.onAuth({ url: "https://sso.corp.com/..." });
      const code = await callbacks.onPrompt({ message: "Enter code:" });
      return { refresh: code, access: code, expires: Date.now() + 3600000 };
    },
    async refreshToken(credentials) {
      // Refresh logic
      return credentials;
    },
    getApiKey(credentials) {
      return credentials.access;
    }
  }
});
```

**Tùy chọn cấu hình:**
- `name` - Tên hiển thị của provider trong UI như `/login`.
- `baseUrl` - URL endpoint API. Bắt buộc khi định nghĩa model.
- `apiKey` - API key hoặc tên biến môi trường. Bắt buộc khi định nghĩa model (trừ khi cung cấp `oauth`).
- `api` - Kiểu API: `"anthropic-messages"`, `"openai-completions"`, `"openai-responses"`, v.v.
- `headers` - Header tùy chỉnh đưa vào request.
- `authHeader` - Nếu là true, tự động thêm header `Authorization: Bearer`.
- `models` - Mảng định nghĩa model. Nếu cung cấp, thay thế mọi model hiện có của provider này. Định nghĩa model có thể đặt `baseUrl` để ghi đè endpoint provider cho model đó.
- `oauth` - Cấu hình provider OAuth để hỗ trợ `/login`. Khi cung cấp, provider xuất hiện trong menu đăng nhập.
- `streamSimple` - Triển khai stream tùy chỉnh cho API không theo chuẩn.

Xem [custom-provider.md](custom-provider.vi.md) để biết các chủ đề nâng cao: API stream tùy chỉnh, chi tiết OAuth và tham khảo định nghĩa model.

### pi.unregisterProvider(name)

Xóa provider và các model đã đăng ký trước đó. Các model tích hợp sẵn từng bị provider ghi đè sẽ được khôi phục. Không có tác dụng nếu provider chưa được đăng ký.

Giống `registerProvider`, phương thức này có hiệu lực ngay khi được gọi sau giai đoạn nạp ban đầu, nên không cần `/reload`.

```typescript
pi.registerCommand("my-setup-teardown", {
  description: "Remove the custom proxy provider",
  handler: async (_args, _ctx) => {
    pi.unregisterProvider("my-proxy");
  },
});
```

## Quản lý trạng thái

Extension có trạng thái nên lưu trạng thái đó trong `details` của kết quả công cụ để hỗ trợ phân nhánh chính xác:

```typescript
export default function (pi: ExtensionAPI) {
  let items: string[] = [];

  // Reconstruct state from session
  pi.on("session_start", async (_event, ctx) => {
    items = [];
    for (const entry of ctx.sessionManager.getBranch()) {
      if (entry.type === "message" && entry.message.role === "toolResult") {
        if (entry.message.toolName === "my_tool") {
          items = entry.message.details?.items ?? [];
        }
      }
    }
  });

  pi.registerTool({
    name: "my_tool",
    // ...
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      items.push("new item");
      return {
        content: [{ type: "text", text: "Added" }],
        details: { items: [...items] },  // Store for reconstruction
      };
    },
  });
}
```

## Công cụ tùy chỉnh

Đăng ký các công cụ mà LLM có thể gọi qua `pi.registerTool()`. Công cụ được cung cấp thông qua schema công cụ của provider và có thể có kết xuất tùy chỉnh.

Dùng `promptSnippet` làm metadata ngắn của công cụ cho extension xây dựng prompt tùy chỉnh. System prompt mặc định không kết xuất danh sách công cụ riêng.

Dùng `promptGuidelines` để thêm các bullet dành riêng cho công cụ vào system prompt mặc định. Các bullet này chỉ được đưa vào khi công cụ đang hoạt động (chẳng hạn sau `pi.setActiveTools([...])`).

**Quan trọng:** Các bullet `promptGuidelines` được nối phẳng, không có tiền tố tên công cụ hoặc nhóm tự động. Mỗi hướng dẫn phải nêu tên công cụ được đề cập — tránh "Use this tool when..." vì LLM không biết "this" là công cụ nào. Thay vào đó, hãy viết "Use my_tool when...".

Lưu ý: Một số model có thể đưa tiền tố @ vào tham số đường dẫn công cụ. Công cụ tích hợp sẵn loại bỏ @ ở đầu trước khi phân giải đường dẫn. Nếu công cụ tùy chỉnh nhận đường dẫn, cũng hãy chuẩn hóa @ ở đầu.

Nếu công cụ tùy chỉnh sửa tệp, hãy dùng `withFileMutationQueue()` để nó tham gia cùng hàng đợi theo từng tệp với `edit` tích hợp sẵn. Điều này quan trọng vì các lời gọi công cụ mặc định chạy song song. Không có hàng đợi, hai công cụ có thể đọc cùng nội dung tệp cũ, tính ra các cập nhật khác nhau, rồi lần ghi sau cùng sẽ ghi đè lần còn lại.

Ví dụ lỗi: công cụ tùy chỉnh sửa `foo.ts` trong khi `edit` tích hợp sẵn cũng sửa `foo.ts` trong cùng lượt assistant. Nếu công cụ của bạn không tham gia hàng đợi, cả hai có thể đọc `foo.ts` ban đầu, áp dụng các thay đổi riêng và một thay đổi sẽ bị mất.

Truyền đường dẫn tệp đích thực vào `withFileMutationQueue()`, không truyền trực tiếp tham số thô của user. Trước tiên hãy phân giải thành đường dẫn tuyệt đối, tương đối với `ctx.cwd` hoặc thư mục làm việc của công cụ. Với tệp đã tồn tại, helper chuẩn hóa qua `realpath()`, nên các alias symlink của cùng một tệp dùng chung một hàng đợi. Với tệp mới, helper dùng đường dẫn tuyệt đối đã phân giải vì chưa có gì để `realpath()`.

Xếp toàn bộ khoảng thời gian sửa đổi vào hàng đợi trên đường dẫn đích đó. Khoảng thời gian này bao gồm logic đọc-sửa-ghi, không chỉ lần ghi cuối.

```typescript
import { withFileMutationQueue } from "@earendil-works/pi-coding-agent";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";

async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
  const absolutePath = resolve(ctx.cwd, params.path);

  return withFileMutationQueue(absolutePath, async () => {
    await mkdir(dirname(absolutePath), { recursive: true });
    const current = await readFile(absolutePath, "utf8");
    const next = current.replace(params.oldText, params.newText);
    await writeFile(absolutePath, next, "utf8");

    return {
      content: [{ type: "text", text: `Updated ${params.path}` }],
      details: {},
    };
  });
}
```

### Định nghĩa công cụ

```typescript
import { Type } from "typebox";
import { StringEnum } from "@earendil-works/pi-ai";
import { Text } from "@earendil-works/pi-tui";

pi.registerTool({
  name: "my_tool",
  label: "My Tool",
  description: "What this tool does (shown to LLM)",
  promptSnippet: "List or add items in the project todo list",
  promptGuidelines: [
    "Use my_tool for todo planning instead of direct file edits when the user asks for a task list."
  ],
  parameters: Type.Object({
    action: StringEnum(["list", "add"] as const),  // Use StringEnum for Google compatibility
    text: Type.Optional(Type.String()),
  }),
  prepareArguments(args) {
    if (!args || typeof args !== "object") return args;
    const input = args as { action?: string; oldAction?: string };
    if (typeof input.oldAction === "string" && input.action === undefined) {
      return { ...input, action: input.oldAction };
    }
    return args;
  },

  async execute(toolCallId, params, signal, onUpdate, ctx) {
    // Check for cancellation
    if (signal?.aborted) {
      return { content: [{ type: "text", text: "Cancelled" }] };
    }

    // Stream progress updates
    onUpdate?.({
      content: [{ type: "text", text: "Working..." }],
      details: { progress: 50 },
    });

    // Run commands via pi.exec (captured from extension closure)
    const result = await pi.exec("some-command", [], { signal });

    // Return result
    return {
      content: [{ type: "text", text: "Done" }],  // Sent to LLM
      details: { data: result },                   // For rendering & state
      // Optional: stop after this tool batch when every finalized tool result
      // in the batch also returns terminate: true.
      terminate: true,
    };
  },

  // Optional: Custom rendering
  renderCall(args, theme, context) { ... },
  renderResult(result, options, theme, context) { ... },
});
```

**Báo hiệu lỗi:** Để đánh dấu việc thực thi công cụ thất bại (đặt `isError: true` trên kết quả và báo cho LLM), hãy throw lỗi từ `execute`. Việc trả về giá trị không bao giờ đặt cờ lỗi, bất kể object trả về có những thuộc tính nào.

**Kết thúc sớm:** Trả về `terminate: true` từ `execute()` để báo rằng có thể bỏ qua lần gọi LLM follow-up tự động sau batch công cụ hiện tại. Điều này chỉ có hiệu lực khi mọi kết quả công cụ đã chốt trong batch đều có tính kết thúc. Xem [examples/extensions/structured-output.ts](../examples/extensions/structured-output.ts) để biết ví dụ tối thiểu trong đó agent kết thúc bằng lời gọi công cụ output có cấu trúc cuối cùng.

```typescript
// Correct: throw to signal an error
async execute(toolCallId, params) {
  if (!isValid(params.input)) {
    throw new Error(`Invalid input: ${params.input}`);
  }
  return { content: [{ type: "text", text: "OK" }], details: {} };
}
```

**Quan trọng:** Dùng `StringEnum` từ `@earendil-works/pi-ai` cho enum chuỗi. `Type.Union`/`Type.Literal` không hoạt động với API của Google.

**Chuẩn bị tham số:** `prepareArguments(args)` là tùy chọn. Nếu được định nghĩa, nó chạy trước khi kiểm tra schema và trước `execute()`. Dùng nó để mô phỏng dạng input cũ từng được chấp nhận khi Prime Agent khôi phục phiên cũ có tham số lời gọi công cụ đã lưu không còn khớp schema hiện tại. Trả về object cần được kiểm tra với `parameters`. Giữ schema công khai nghiêm ngặt. Không thêm trường tương thích đã lỗi thời vào `parameters` chỉ để các phiên cũ được khôi phục tiếp tục hoạt động.

Ví dụ: một phiên cũ có thể chứa lời gọi công cụ `edit` với `oldText` và `newText` ở cấp cao nhất, trong khi schema hiện tại chỉ chấp nhận `edits: [{ oldText, newText }]`.

```typescript
pi.registerTool({
  name: "edit",
  label: "Edit",
  description: "Edit a single file using exact text replacement",
  parameters: Type.Object({
    path: Type.String(),
    edits: Type.Array(
      Type.Object({
        oldText: Type.String(),
        newText: Type.String(),
      }),
    ),
  }),
  prepareArguments(args) {
    if (!args || typeof args !== "object") return args;

    const input = args as {
      path?: string;
      edits?: Array<{ oldText: string; newText: string }>;
      oldText?: unknown;
      newText?: unknown;
    };

    if (typeof input.oldText !== "string" || typeof input.newText !== "string") {
      return args;
    }

    return {
      ...input,
      edits: [...(input.edits ?? []), { oldText: input.oldText, newText: input.newText }],
    };
  },
  async execute(toolCallId, params, signal, onUpdate, ctx) {
    // params now matches the current schema
    return {
      content: [{ type: "text", text: `Applying ${params.edits.length} edit block(s)` }],
      details: {},
    };
  },
});
```

### Ghi đè công cụ tích hợp sẵn

Extension có thể ghi đè công cụ tích hợp sẵn (`ipython`, `bash`, `edit`) bằng cách đăng ký công cụ cùng tên. Chế độ tương tác sẽ hiển thị cảnh báo khi việc này xảy ra.

```bash
# Extension's ipython tool replaces built-in ipython
prime-agent -e ./tool-override.ts
```

Ngoài ra, dùng `--no-builtin-tools` để khởi động mà không có công cụ tích hợp sẵn nào, đồng thời vẫn bật công cụ của extension:
```bash
# No built-in tools, only extension tools
prime-agent --no-builtin-tools -e ./my-extension.ts
```

Xem ví dụ ghi đè đầy đủ tại [examples/extensions/tool-override.ts](../examples/extensions/tool-override.ts).

**Kết xuất:** Việc kế thừa renderer tích hợp sẵn được phân giải theo từng slot. Ghi đè thực thi và ghi đè kết xuất độc lập với nhau. Nếu override không có `renderCall`, `renderCall` tích hợp sẵn được dùng. Nếu không có `renderResult`, `renderResult` tích hợp sẵn được dùng. Nếu thiếu cả hai, renderer tích hợp sẵn tự động được dùng (tô màu cú pháp, diff, v.v.). Nhờ vậy, bạn có thể bọc công cụ tích hợp sẵn để ghi log hoặc kiểm soát quyền truy cập mà không phải triển khai lại UI.

**Metadata prompt:** `promptSnippet` và `promptGuidelines` không được kế thừa từ công cụ tích hợp sẵn. Nếu override cần giữ các hướng dẫn prompt đó, hãy định nghĩa chúng rõ ràng trên override.

**Triển khai của bạn phải khớp chính xác dạng kết quả**, bao gồm cả kiểu `details`. UI và logic phiên phụ thuộc vào các dạng này để kết xuất và theo dõi trạng thái.

Triển khai công cụ tích hợp sẵn:
- [ipython.ts](https://github.com/PrimeIntellect-ai/prime-agent/blob/main/packages/coding-agent/src/core/tools/ipython.ts) - `IpythonToolDetails`
- [bash.ts](../src/core/tools/bash.ts) - `BashToolDetails`
- [edit.ts](../src/core/tools/edit.ts)

### Thực thi từ xa

Các công cụ `bash` và `edit` hỗ trợ operation có thể cắm để ủy quyền cho hệ thống từ xa (SSH, container, v.v.):

```typescript
import { createBashTool, type BashOperations } from "@earendil-works/pi-coding-agent";

// Create tool with custom operations
const remoteBash = createBashTool(cwd, {
  operations: createRemoteBashOps(ssh),
});

// Register, checking flag at execution time
pi.registerTool({
  ...remoteBash,
  async execute(id, params, signal, onUpdate, _ctx) {
    const ssh = getSshConfig();
    if (ssh) {
      const tool = createBashTool(cwd, { operations: createRemoteBashOps(ssh) });
      return tool.execute(id, params, signal, onUpdate);
    }
    return localBash.execute(id, params, signal, onUpdate);
  },
});
```

**Interface operation:** `EditOperations`, `BashOperations`

Với `user_bash`, extension có thể dùng lại backend shell cục bộ của Prime Agent qua `createLocalBashOperations()` thay vì tự triển khai việc tạo process cục bộ, phân giải shell và dừng cây process.

Công cụ bash cũng hỗ trợ spawn hook để điều chỉnh command, cwd hoặc env trước khi thực thi:

```typescript
import { createBashTool } from "@earendil-works/pi-coding-agent";

const bashTool = createBashTool(cwd, {
  spawnHook: ({ command, cwd, env }) => ({
    command: `source ~/.profile\n${command}`,
    cwd: `/mnt/sandbox${cwd}`,
    env: { ...env, CI: "1" },
  }),
});
```

Xem ví dụ SSH đầy đủ với cờ `--ssh` tại [examples/extensions/ssh.ts](../examples/extensions/ssh.ts).

### Cắt ngắn output

**Công cụ BẮT BUỘC phải cắt ngắn output** để tránh làm quá tải ngữ cảnh LLM. Output lớn có thể gây:
- Lỗi tràn ngữ cảnh (prompt quá dài)
- Nén ngữ cảnh thất bại
- Hiệu năng model suy giảm

Giới hạn tích hợp sẵn là **50KB** (~10k token) và **2000 dòng**, tùy điều kiện nào đạt trước. Dùng các tiện ích cắt ngắn đã export:

```typescript
import {
  truncateHead,      // Keep first N lines/bytes (good for file reads, search results)
  truncateTail,      // Keep last N lines/bytes (good for logs, command output)
  truncateLine,      // Truncate a single line to maxBytes with ellipsis
  formatSize,        // Human-readable size (e.g., "50KB", "1.5MB")
  DEFAULT_MAX_BYTES, // 50KB
  DEFAULT_MAX_LINES, // 2000
} from "@earendil-works/pi-coding-agent";

async execute(toolCallId, params, signal, onUpdate, ctx) {
  const output = await runCommand();

  // Apply truncation
  const truncation = truncateHead(output, {
    maxLines: DEFAULT_MAX_LINES,
    maxBytes: DEFAULT_MAX_BYTES,
  });

  let result = truncation.content;

  if (truncation.truncated) {
    // Write full output to temp file
    const tempFile = writeTempFile(output);

    // Inform the LLM where to find complete output
    result += `\n\n[Output truncated: ${truncation.outputLines} of ${truncation.totalLines} lines`;
    result += ` (${formatSize(truncation.outputBytes)} of ${formatSize(truncation.totalBytes)}).`;
    result += ` Full output saved to: ${tempFile}]`;
  }

  return { content: [{ type: "text", text: result }] };
}
```

**Điểm chính:**
- Dùng `truncateHead` cho nội dung mà phần đầu quan trọng (kết quả tìm kiếm, nội dung đọc từ tệp)
- Dùng `truncateTail` cho nội dung mà phần cuối quan trọng (log, output lệnh)
- Luôn báo cho LLM khi output bị cắt ngắn và chỉ nơi tìm phiên bản đầy đủ
- Ghi rõ giới hạn cắt ngắn trong mô tả công cụ

Xem ví dụ đầy đủ bọc `rg` (ripgrep) với việc cắt ngắn đúng cách tại [examples/extensions/truncated-tool.ts](../examples/extensions/truncated-tool.ts).

### Nhiều công cụ

Một extension có thể đăng ký nhiều công cụ dùng chung trạng thái:

```typescript
export default function (pi: ExtensionAPI) {
  let connection = null;

  pi.registerTool({ name: "db_connect", ... });
  pi.registerTool({ name: "db_query", ... });
  pi.registerTool({ name: "db_close", ... });

  pi.on("session_shutdown", async () => {
    connection?.close();
  });
}
```

### Kết xuất tùy chỉnh

Công cụ có thể cung cấp `renderCall` và `renderResult` để hiển thị TUI tùy chỉnh. Xem [tui.md](tui.vi.md) để biết đầy đủ API component và [tool-execution.ts](../src/modes/interactive/components/tool-execution.ts) để biết các hàng công cụ được ghép như thế nào.

Theo mặc định, output công cụ được bọc trong panel công cụ: một dòng header `label · status` (ví dụ `my_tool · running`) theo sau là các component slot; mọi dòng được thụt vào và vẽ trên nền `toolPanelBg` để cả khối được đọc như một đơn vị. `renderCall` hoặc `renderResult` được định nghĩa phải trả về một `Component`. Nếu renderer của slot chưa được định nghĩa, `tool-execution.ts` dùng kết xuất dự phòng cho slot đó.

Đặt `renderShell: "self"` khi công cụ cần tự kết xuất shell thay vì panel công cụ mặc định. Điều này hữu ích với công cụ cần kiểm soát hoàn toàn khung hoặc nền, chẳng hạn preview lớn phải ổn định về mặt hiển thị sau khi công cụ hoàn tất.

```typescript
pi.registerTool({
  name: "my_tool",
  label: "My Tool",
  description: "Custom shell example",
  parameters: Type.Object({}),
  renderShell: "self",
  async execute() {
    return { content: [{ type: "text", text: "ok" }], details: undefined };
  },
  renderCall(args, theme, context) {
    return new Text(theme.fg("accent", "my custom shell"), 0, 0);
  },
});
```

Mỗi `renderCall` và `renderResult` nhận một object `context` gồm:
- `args` - tham số lời gọi công cụ hiện tại
- `state` - trạng thái dùng chung trong hàng giữa `renderCall` và `renderResult`
- `lastComponent` - component trước đó được trả về cho slot này, nếu có
- `invalidate()` - yêu cầu kết xuất lại hàng công cụ này
- `toolCallId`, `cwd`, `executionStarted`, `argsComplete`, `isPartial`, `expanded`, `showImages`, `isError`

Dùng `context.state` cho trạng thái dùng chung giữa các slot. Giữ cache cục bộ của slot trên instance component được trả về khi muốn tái sử dụng và sửa cùng component qua nhiều lần kết xuất.

#### renderCall

Kết xuất lời gọi công cụ hoặc header:

```typescript
import { Text } from "@earendil-works/pi-tui";

renderCall(args, theme, context) {
  const text = (context.lastComponent as Text | undefined) ?? new Text("", 0, 0);
  let content = theme.fg("toolTitle", theme.bold("my_tool "));
  content += theme.fg("muted", args.action);
  if (args.text) {
    content += " " + theme.fg("dim", `"${args.text}"`);
  }
  text.setText(content);
  return text;
}
```

#### renderResult

Kết xuất kết quả hoặc output của công cụ:

```typescript
renderResult(result, { expanded, isPartial }, theme, context) {
  if (isPartial) {
    return new Text(theme.fg("warning", "Processing..."), 0, 0);
  }

  if (result.details?.error) {
    return new Text(theme.fg("error", `Error: ${result.details.error}`), 0, 0);
  }

  let text = theme.fg("success", "✓ Done");
  if (expanded && result.details?.items) {
    for (const item of result.details.items) {
      text += "\n  " + theme.fg("dim", item);
    }
  }
  return new Text(text, 0, 0);
}
```

Nếu một slot cố ý không có nội dung hiển thị, hãy trả về `Component` rỗng, chẳng hạn `Container` rỗng.

#### Gợi ý keybinding

Dùng `keyHint()` để hiển thị gợi ý keybinding tuân theo cấu hình keybinding đang hoạt động:

```typescript
import { keyHint } from "@earendil-works/pi-coding-agent";

renderResult(result, { expanded }, theme, context) {
  let text = theme.fg("success", "✓ Done");
  if (!expanded) {
    text += ` (${keyHint("app.tools.expand", "to expand")})`;
  }
  return new Text(text, 0, 0);
}
```

Các hàm khả dụng:
- `keyHint(keybinding, description)` - Định dạng id keybinding đã cấu hình như `"app.tools.expand"` hoặc `"tui.select.confirm"`
- `keyText(keybinding)` - Trả về văn bản phím thô đã cấu hình cho một id keybinding
- `rawKeyHint(key, description)` - Định dạng chuỗi phím thô

Dùng id keybinding có namespace:
- Các id TUI dùng chung dùng namespace `tui.*`, chẳng hạn `tui.select.confirm`, `tui.select.cancel`, `tui.input.tab`

Xem danh sách đầy đủ id keybinding và giá trị mặc định tại [keybindings.md](keybindings.vi.md). `keybindings.json` dùng chính các id có namespace đó.

Editor tùy chỉnh và component `ctx.ui.custom()` nhận `keybindings: KeybindingsManager` dưới dạng tham số được inject. Chúng nên dùng trực tiếp manager đã inject thay vì gọi `getKeybindings()` hoặc `setKeybindings()`.

#### Thực hành tốt

- Dùng `Text` với padding `(0, 0)`. Box mặc định đã xử lý padding.
- Dùng `\n` cho nội dung nhiều dòng.
- Xử lý `isPartial` cho tiến độ stream.
- Hỗ trợ `expanded` để hiển thị chi tiết theo yêu cầu.
- Giữ giao diện mặc định gọn.
- Đọc `context.args` trong `renderResult` thay vì sao chép args vào `context.state`.
- Chỉ dùng `context.state` cho dữ liệu cần chia sẻ giữa slot lời gọi và slot kết quả.
- Tái sử dụng `context.lastComponent` khi có thể cập nhật cùng instance component tại chỗ.
- Chỉ dùng `renderShell: "self"` khi shell panel công cụ mặc định gây cản trở. Ở chế độ self-shell, công cụ chịu trách nhiệm về khung, padding và nền của chính nó.

#### Dự phòng

Nếu renderer của slot chưa được định nghĩa hoặc throw:
- `renderCall`: Header panel đã nêu tên công cụ; công cụ self-shell hiển thị tên công cụ in đậm
- `renderResult`: Hiển thị văn bản thô từ `content`

## UI tùy chỉnh

Extension có thể tương tác với người dùng qua các phương thức `ctx.ui` và tùy chỉnh cách tin nhắn/công cụ được kết xuất.

**Với component tùy chỉnh, xem [tui.md](tui.vi.md)**, tài liệu này có các mẫu có thể sao chép cho:
- Hộp thoại chọn (SelectList)
- Thao tác bất đồng bộ có thể hủy (BorderedLoader)
- Công tắc cài đặt (SettingsList)
- Chỉ báo trạng thái (setStatus)
- Tin nhắn, khả năng hiển thị và chỉ báo đang xử lý khi stream (`setWorkingMessage`, `setWorkingVisible`, `setWorkingIndicator`)
- Widget phía trên/dưới editor (setWidget)
- Provider tự động hoàn tất xếp trên tính năng hoàn tất slash/path tích hợp sẵn (addAutocompleteProvider)
- Footer tùy chỉnh (setFooter)

### Hộp thoại

```typescript
// Select from options
const choice = await ctx.ui.select("Pick one:", ["A", "B", "C"]);

// Confirm dialog
const ok = await ctx.ui.confirm("Delete?", "This cannot be undone");

// Text input
const name = await ctx.ui.input("Name:", "placeholder");

// Multi-line editor
const text = await ctx.ui.editor("Edit:", "prefilled text");

// Notification (non-blocking)
ctx.ui.notify("Done!", "info");  // "info" | "warning" | "error"
```

#### Hộp thoại có thời hạn và đếm ngược

Hộp thoại hỗ trợ tùy chọn `timeout`, tự động đóng và hiển thị bộ đếm ngược trực tiếp:

```typescript
// Dialog shows "Title (5s)" → "Title (4s)" → ... → auto-dismisses at 0
const confirmed = await ctx.ui.confirm(
  "Timed Confirmation",
  "This dialog will auto-cancel in 5 seconds. Confirm?",
  { timeout: 5000 }
);

if (confirmed) {
  // User confirmed
} else {
  // User cancelled or timed out
}
```

**Giá trị trả về khi hết thời gian:**
- `select()` trả về `undefined`
- `confirm()` trả về `false`
- `input()` trả về `undefined`

#### Đóng thủ công bằng AbortSignal

Để kiểm soát nhiều hơn (ví dụ phân biệt hết thời gian với người dùng hủy), hãy dùng `AbortSignal`:

```typescript
const controller = new AbortController();
const timeoutId = setTimeout(() => controller.abort(), 5000);

const confirmed = await ctx.ui.confirm(
  "Timed Confirmation",
  "This dialog will auto-cancel in 5 seconds. Confirm?",
  { signal: controller.signal }
);

clearTimeout(timeoutId);

if (confirmed) {
  // User confirmed
} else if (controller.signal.aborted) {
  // Dialog timed out
} else {
  // User cancelled (pressed Escape or selected "No")
}
```

Xem các ví dụ đầy đủ tại [examples/extensions/timed-confirm.ts](../examples/extensions/timed-confirm.ts).

### Widget, trạng thái và footer

```typescript
// Status in footer (persistent until cleared)
ctx.ui.setStatus("my-ext", "Processing...");
ctx.ui.setStatus("my-ext", undefined);  // Clear

// Working loader (shown during streaming)
ctx.ui.setWorkingMessage("Thinking deeply...");
ctx.ui.setWorkingMessage();  // Restore default
ctx.ui.setWorkingVisible(false);  // Hide the built-in working loader row entirely
ctx.ui.setWorkingVisible(true);   // Show the built-in working loader row

// Working indicator (shown during streaming)
ctx.ui.setWorkingIndicator({ frames: [ctx.ui.theme.fg("accent", "●")] });  // Static dot
ctx.ui.setWorkingIndicator({
  frames: [
    ctx.ui.theme.fg("dim", "·"),
    ctx.ui.theme.fg("muted", "•"),
    ctx.ui.theme.fg("accent", "●"),
    ctx.ui.theme.fg("muted", "•"),
  ],
  intervalMs: 120,
});
ctx.ui.setWorkingIndicator({ frames: [] });  // Hide indicator
ctx.ui.setWorkingIndicator();  // Restore default spinner

// Widget above editor (default)
ctx.ui.setWidget("my-widget", ["Line 1", "Line 2"]);
// Widget below editor
ctx.ui.setWidget("my-widget", ["Line 1", "Line 2"], { placement: "belowEditor" });
ctx.ui.setWidget("my-widget", (tui, theme) => new Text(theme.fg("accent", "Custom"), 0, 0));
ctx.ui.setWidget("my-widget", undefined);  // Clear

// Custom footer (replaces built-in footer entirely)
ctx.ui.setFooter((tui, theme) => ({
  render(width) { return [theme.fg("dim", "Custom footer")]; },
  invalidate() {},
}));
ctx.ui.setFooter(undefined);  // Restore built-in footer

// Terminal title
ctx.ui.setTitle("Prime Agent - my-project");

// Editor text
ctx.ui.setEditorText("Prefill text");
const current = ctx.ui.getEditorText();

// Paste into editor (triggers paste handling, including collapse for large content)
ctx.ui.pasteToEditor("pasted content");

// Stack custom autocomplete behavior on top of the built-in provider
ctx.ui.addAutocompleteProvider((current) => ({
  async getSuggestions(lines, line, col, options) {
    const beforeCursor = (lines[line] ?? "").slice(0, col);
    const match = beforeCursor.match(/(?:^|[ \t])#([^\s#]*)$/);
    if (!match) {
      return current.getSuggestions(lines, line, col, options);
    }

    return {
      prefix: `#${match[1] ?? ""}`,
      items: [{ value: "#2983", label: "#2983", description: "Extension API for autocomplete" }],
    };
  },
  applyCompletion(lines, line, col, item, prefix) {
    return current.applyCompletion(lines, line, col, item, prefix);
  },
  shouldTriggerFileCompletion(lines, line, col) {
    return current.shouldTriggerFileCompletion?.(lines, line, col) ?? true;
  },
}));

// Tool output expansion
const wasExpanded = ctx.ui.getToolsExpanded();
ctx.ui.setToolsExpanded(true);
ctx.ui.setToolsExpanded(wasExpanded);

// Custom editor (vim mode, emacs mode, etc.)
ctx.ui.setEditorComponent((tui, theme, keybindings) => new VimEditor(tui, theme, keybindings));
const currentEditor = ctx.ui.getEditorComponent();
ctx.ui.setEditorComponent((tui, theme, keybindings) =>
  new WrappedEditor(tui, theme, keybindings, currentEditor?.(tui, theme, keybindings))
);
ctx.ui.setEditorComponent(undefined);  // Restore default editor

// Theme management (see themes.md for creating themes)
const themes = ctx.ui.getAllThemes();  // [{ name: "dark", path: "/..." | undefined }, ...]
const lightTheme = ctx.ui.getTheme("light");  // Load without switching
const result = ctx.ui.setTheme("light");  // Switch by name
if (!result.success) {
  ctx.ui.notify(`Failed: ${result.error}`, "error");
}
ctx.ui.setTheme(lightTheme!);  // Or switch by Theme object
ctx.ui.theme.fg("accent", "styled text");  // Access current theme
```

Các frame working-indicator tùy chỉnh được kết xuất nguyên văn. Nếu muốn có màu, hãy tự thêm màu vào chuỗi frame, chẳng hạn bằng `ctx.ui.theme.fg(...)`.

### Provider tự động hoàn tất

Dùng `ctx.ui.addAutocompleteProvider()` để xếp logic tự động hoàn tất tùy chỉnh lên trên provider slash-command và path tích hợp sẵn.

Mẫu thường dùng:

- kiểm tra văn bản trước con trỏ
- trả về gợi ý riêng khi cú pháp dành riêng cho extension khớp
- nếu không, ủy quyền cho `current.getSuggestions(...)`
- ủy quyền `applyCompletion(...)` trừ khi cần hành vi chèn tùy chỉnh

```typescript
pi.on("session_start", (_event, ctx) => {
  ctx.ui.addAutocompleteProvider((current) => ({
    async getSuggestions(lines, cursorLine, cursorCol, options) {
      const line = lines[cursorLine] ?? "";
      const beforeCursor = line.slice(0, cursorCol);
      const match = beforeCursor.match(/(?:^|[ \t])#([^\s#]*)$/);
      if (!match) {
        return current.getSuggestions(lines, cursorLine, cursorCol, options);
      }

      return {
        prefix: `#${match[1] ?? ""}`,
        items: [
          { value: "#2983", label: "#2983", description: "Extension API for registering custom @ autocomplete providers" },
          { value: "#2753", label: "#2753", description: "Reload stale resource settings" },
        ],
      };
    },

    applyCompletion(lines, cursorLine, cursorCol, item, prefix) {
      return current.applyCompletion(lines, cursorLine, cursorCol, item, prefix);
    },

    shouldTriggerFileCompletion(lines, cursorLine, cursorCol) {
      return current.shouldTriggerFileCompletion?.(lines, cursorLine, cursorCol) ?? true;
    },
  }));
});
```

Xem ví dụ đầy đủ tại [github-issue-autocomplete.ts](../examples/extensions/github-issue-autocomplete.ts). Ví dụ này nạp trước các issue GitHub đang mở mới nhất bằng `gh issue list` rồi lọc cục bộ để hoàn tất nhanh `#...`. Ví dụ yêu cầu GitHub CLI (`gh`) và một checkout của repository GitHub.

### Component tùy chỉnh

Với UI phức tạp, dùng `ctx.ui.custom()`. Phương thức này tạm thời thay editor bằng component của bạn cho đến khi gọi `done()`:

```typescript
import { Text, Component } from "@earendil-works/pi-tui";

const result = await ctx.ui.custom<boolean>((tui, theme, keybindings, done) => {
  const text = new Text("Press Enter to confirm, Escape to cancel", 1, 1);

  text.onKey = (key) => {
    if (key === "return") done(true);
    if (key === "escape") done(false);
    return true;
  };

  return text;
});

if (result) {
  // User pressed Enter
}
```

Callback nhận:
- `tui` - instance TUI (để lấy kích thước màn hình và quản lý focus)
- `theme` - theme hiện tại để tạo kiểu
- `keybindings` - manager keybinding của app (để kiểm tra shortcut)
- `done(value)` - Gọi để đóng component và trả về giá trị

Xem [tui.md](tui.vi.md) để biết đầy đủ API component.

#### Chế độ overlay (thử nghiệm)

Truyền `{ overlay: true }` để kết xuất component như modal nổi trên nội dung hiện có mà không xóa màn hình:

```typescript
const result = await ctx.ui.custom<string | null>(
  (tui, theme, keybindings, done) => new MyOverlayComponent({ onClose: done }),
  { overlay: true }
);
```

Để định vị nâng cao (anchor, margin, phần trăm, khả năng hiển thị responsive), truyền `overlayOptions`. Dùng `onHandle` để điều khiển khả năng hiển thị bằng code:

```typescript
const result = await ctx.ui.custom<string | null>(
  (tui, theme, keybindings, done) => new MyOverlayComponent({ onClose: done }),
  {
    overlay: true,
    overlayOptions: { anchor: "top-right", width: "50%", margin: 2 },
    onHandle: (handle) => { /* handle.setHidden(true/false) */ }
  }
);
```

Xem [tui.md](tui.vi.md) để biết đầy đủ API `OverlayOptions` và [overlay-qa-tests.ts](../examples/extensions/overlay-qa-tests.ts) để xem ví dụ.

### Editor tùy chỉnh

Thay editor nhập liệu chính bằng triển khai tùy chỉnh (chế độ vim, emacs, v.v.):

```typescript
import { CustomEditor, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { matchesKey } from "@earendil-works/pi-tui";

class VimEditor extends CustomEditor {
  private mode: "normal" | "insert" = "insert";

  handleInput(data: string): void {
    if (matchesKey(data, "escape") && this.mode === "insert") {
      this.mode = "normal";
      return;
    }
    if (this.mode === "normal" && data === "i") {
      this.mode = "insert";
      return;
    }
    super.handleInput(data);  // App keybindings + text editing
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    ctx.ui.setEditorComponent((_tui, theme, keybindings) =>
      new VimEditor(theme, keybindings)
    );
  });
}
```

**Điểm chính:**
- Mở rộng `CustomEditor` (không phải `Editor` cơ sở) để nhận keybinding của app (escape để hủy, ctrl+d, chuyển model)
- Gọi `super.handleInput(data)` cho các phím bạn không xử lý
- Factory nhận `theme` và `keybindings` từ app
- Dùng `ctx.ui.getEditorComponent()` trước `setEditorComponent()` để bọc editor tùy chỉnh đã cấu hình trước đó
- Truyền `undefined` để khôi phục mặc định: `ctx.ui.setEditorComponent(undefined)`

Để kết hợp với extension khác đã thay editor, hãy capture factory trước đó trước khi đặt factory của bạn:

```typescript
const previous = ctx.ui.getEditorComponent();
ctx.ui.setEditorComponent((tui, theme, keybindings) =>
  new MyEditor(tui, theme, keybindings, { base: previous?.(tui, theme, keybindings) })
);
```

Xem Pattern 7 trong [tui.md](tui.vi.md) để biết ví dụ đầy đủ có chỉ báo chế độ.

### Kết xuất tin nhắn

Đăng ký renderer tùy chỉnh cho các tin nhắn có `customType` của bạn:

```typescript
import { Text } from "@earendil-works/pi-tui";

pi.registerMessageRenderer("my-extension", (message, options, theme) => {
  const { expanded } = options;
  let text = theme.fg("accent", `[${message.customType}] `);
  text += message.content;

  if (expanded && message.details) {
    text += "\n" + theme.fg("dim", JSON.stringify(message.details, null, 2));
  }

  return new Text(text, 0, 0);
});
```

Tin nhắn được gửi qua `pi.sendMessage()`:

```typescript
pi.sendMessage({
  customType: "my-extension",  // Matches registerMessageRenderer
  content: "Status update",
  display: true,               // Show in TUI
  details: { ... },            // Available in renderer
});
```

### Màu theme

Mọi hàm render đều nhận object `theme`. Xem [themes.md](themes.vi.md) để biết cách tạo theme tùy chỉnh và toàn bộ bảng màu.

```typescript
// Foreground colors
theme.fg("toolTitle", text)   // Tool names
theme.fg("accent", text)      // Highlights
theme.fg("success", text)     // Success (green)
theme.fg("error", text)       // Errors (red)
theme.fg("warning", text)     // Warnings (yellow)
theme.fg("muted", text)       // Secondary text
theme.fg("dim", text)         // Tertiary text

// Text styles
theme.bold(text)
theme.italic(text)
theme.strikethrough(text)
```

Để tô màu cú pháp trong renderer công cụ tùy chỉnh:

```typescript
import { highlightCode, getLanguageFromPath } from "@earendil-works/pi-coding-agent";

// Highlight code with explicit language
const highlighted = highlightCode("const x = 1;", "typescript", theme);

// Auto-detect language from file path
const lang = getLanguageFromPath("/path/to/file.rs");  // "rust"
const highlighted = highlightCode(code, lang, theme);
```

## Xử lý lỗi

- Lỗi extension được ghi log, agent tiếp tục chạy
- Lỗi `tool_call` chặn công cụ (an toàn khi lỗi)
- Lỗi `execute` của công cụ phải được báo hiệu bằng cách throw; lỗi được throw sẽ bị bắt, báo cho LLM với `isError: true`, rồi việc thực thi tiếp tục

## Hành vi theo chế độ

| Chế độ | Phương thức UI | Ghi chú |
|------|-----------|-------|
| Tương tác | TUI đầy đủ | Hoạt động bình thường |
| RPC (`--mode rpc`) | Giao thức JSON | Host xử lý UI, xem [rpc.md](rpc.vi.md) |
| JSON (`--mode json`) | Không làm gì | Stream sự kiện tới stdout, xem [json.md](json.vi.md) |
| Print (`-p`) | Không làm gì | Extension vẫn chạy nhưng không thể hiển thị prompt |

Trong các chế độ không tương tác, hãy kiểm tra `ctx.hasUI` trước khi dùng phương thức UI.

## Tham khảo ví dụ

Tất cả ví dụ nằm trong [examples/extensions/](../examples/extensions/).

| Ví dụ | Mô tả | API chính |
|---------|-------------|----------|
| **Công cụ** |||
| `hello.ts` | Đăng ký công cụ tối thiểu | `registerTool` |
| `question.ts` | Công cụ có tương tác người dùng | `registerTool`, `ui.select` |
| `questionnaire.ts` | Công cụ dạng trình hướng dẫn nhiều bước | `registerTool`, `ui.custom` |
| `todo.ts` | Công cụ có trạng thái và lưu bền | `registerTool`, `appendEntry`, `renderResult`, sự kiện phiên |
| `dynamic-tools.ts` | Đăng ký công cụ sau khi khởi động và trong command | `registerTool`, `session_start`, `registerCommand` |
| `structured-output.ts` | Công cụ output có cấu trúc cuối cùng với `terminate: true` | `registerTool`, kết quả công cụ kết thúc |
| `truncated-tool.ts` | Ví dụ cắt ngắn output | `registerTool`, `truncateHead` |
| `tool-override.ts` | Ghi đè công cụ tích hợp sẵn | `registerTool` (cùng tên công cụ tích hợp sẵn) |
| **Command** |||
| `pirate.ts` | Sửa system prompt theo từng lượt | `registerCommand`, `before_agent_start` |
| `summarize.ts` | Command tóm tắt hội thoại | `registerCommand`, `ui.custom` |
| `handoff.ts` | Chuyển giao model giữa các provider | `registerCommand`, `ui.editor`, `ui.custom` |
| `qna.ts` | Hỏi đáp với UI tùy chỉnh | `registerCommand`, `ui.custom`, `setEditorText` |
| `send-user-message.ts` | Chèn tin nhắn user | `registerCommand`, `sendUserMessage` |
| `reload-runtime.ts` | Command reload và chuyển giao cho tool LLM | `registerCommand`, `ctx.reload()`, `sendUserMessage` |
| `shutdown-command.ts` | Command tắt an toàn | `registerCommand`, `shutdown()` |
| **Sự kiện và cổng** |||
| `permission-gate.ts` | Chặn command nguy hiểm | `on("tool_call")`, `ui.confirm` |
| `protected-paths.ts` | Chặn ghi vào đường dẫn cụ thể | `on("tool_call")` |
| `confirm-destructive.ts` | Xác nhận thay đổi phiên | `on("session_before_switch")`, `on("session_before_fork")` |
| `dirty-repo-guard.ts` | Cảnh báo repository Git có thay đổi chưa commit | `on("session_before_*")`, `exec` |
| `input-transform.ts` | Biến đổi input người dùng | `on("input")` |
| `model-status.ts` | Phản ứng với thay đổi model | `on("model_select")`, `setStatus` |
| `provider-payload.ts` | Kiểm tra payload và header response của provider | `on("before_provider_request")`, `on("after_provider_response")` |
| `system-prompt-header.ts` | Hiển thị thông tin system prompt | `on("agent_start")`, `getSystemPrompt` |
| `claude-rules.ts` | Nạp rule từ tệp | `on("session_start")`, `on("before_agent_start")` |
| `prompt-customizer.ts` | Thêm hướng dẫn công cụ theo ngữ cảnh bằng `systemPromptOptions` | `on("before_agent_start")`, `BuildSystemPromptOptions` |
| `file-trigger.ts` | Trình theo dõi tệp kích hoạt tin nhắn | `sendMessage` |
| **Nén ngữ cảnh và phiên** |||
| `custom-compaction.ts` | Tóm tắt nén ngữ cảnh tùy chỉnh | `on("session_before_compact")` |
| `trigger-compact.ts` | Kích hoạt nén ngữ cảnh thủ công | `compact()` |
| `git-checkpoint.ts` | Git stash ở mỗi lượt | `on("turn_start")`, `on("session_before_fork")`, `exec` |
| `auto-commit-on-exit.ts` | Commit khi tắt | `on("session_shutdown")`, `exec` |
| **Component UI** |||
| `status-line.ts` | Chỉ báo trạng thái ở footer | `setStatus`, sự kiện phiên |
| `working-indicator.ts` | Tùy chỉnh chỉ báo đang xử lý khi stream | `setWorkingIndicator`, `registerCommand` |
| `github-issue-autocomplete.ts` | Thêm gợi ý issue `#1234` trên tính năng tự động hoàn tất tích hợp sẵn bằng cách nạp trước issue đang mở gần đây từ `gh issue list` | `addAutocompleteProvider`, `on("session_start")`, `exec` |
| `custom-footer.ts` | Thay toàn bộ footer | `registerCommand`, `setFooter` |
| `custom-header.ts` | Thay header khởi động | `on("session_start")`, `setHeader` |
| `modal-editor.ts` | Editor modal kiểu Vim | `setEditorComponent`, `CustomEditor` |
| `rainbow-editor.ts` | Tạo kiểu editor tùy chỉnh | `setEditorComponent` |
| `widget-placement.ts` | Widget phía trên/dưới editor | `setWidget` |
| `overlay-test.ts` | Component overlay | `ui.custom` với tùy chọn overlay |
| `overlay-qa-tests.ts` | Kiểm thử overlay toàn diện | `ui.custom`, mọi tùy chọn overlay |
| `notify.ts` | Thông báo đơn giản | `ui.notify` |
| `timed-confirm.ts` | Hộp thoại có thời hạn | `ui.confirm` với timeout/signal |
| `mac-system-theme.ts` | Tự động chuyển theme | `setTheme`, `exec` |
| **Extension phức tạp** |||
| `plan-mode/` | Triển khai đầy đủ chế độ plan | Mọi kiểu sự kiện, `registerCommand`, `registerShortcut`, `registerFlag`, `setStatus`, `setWidget`, `sendMessage`, `setActiveTools` |
| `preset.ts` | Preset có thể lưu (model, công cụ, suy luận) | `registerCommand`, `registerShortcut`, `registerFlag`, `setModel`, `setActiveTools`, `setThinkingLevel`, `appendEntry` |
| `tools.ts` | UI bật/tắt công cụ | `registerCommand`, `setActiveTools`, `SettingsList`, sự kiện phiên |
| **Từ xa và sandbox** |||
| `ssh.ts` | Thực thi SSH từ xa | `registerFlag`, `on("user_bash")`, `on("before_agent_start")`, operation công cụ |
| `interactive-shell.ts` | Phiên shell bền vững | `on("user_bash")` |
| `sandbox/` | Thực thi công cụ trong sandbox | Operation công cụ |
| `subagent/` | Tạo sub-agent | `registerTool`, `exec` |
| **Trò chơi** |||
| `snake.ts` | Trò chơi Snake | `registerCommand`, `ui.custom`, xử lý bàn phím |
| `space-invaders.ts` | Trò chơi Space Invaders | `registerCommand`, `ui.custom` |
| `doom-overlay/` | Doom trong overlay | `ui.custom` với overlay |
| **Provider** |||
| `custom-provider-anthropic/` | Proxy Anthropic tùy chỉnh | `registerProvider` |
| `custom-provider-gitlab-duo/` | Tích hợp GitLab Duo | `registerProvider` với OAuth |
| **Tin nhắn và giao tiếp** |||
| `message-renderer.ts` | Kết xuất tin nhắn tùy chỉnh | `registerMessageRenderer`, `sendMessage` |
| `event-bus.ts` | Sự kiện giữa các extension | `pi.events` |
| **Metadata phiên** |||
| `session-name.ts` | Đặt tên phiên cho bộ chọn | `setSessionName`, `getSessionName` |
| `bookmark.ts` | Bookmark entry cho /tree | `setLabel` |
| **Khác** |||
| `inline-bash.ts` | Bash inline trong lời gọi công cụ | `on("tool_call")` |
| `bash-spawn-hook.ts` | Điều chỉnh command bash, cwd và env trước khi thực thi | `createBashTool`, `spawnHook` |
| `with-deps/` | Extension có dependency npm | Cấu trúc package với `package.json` |

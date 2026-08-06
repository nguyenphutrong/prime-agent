> Prime Agent có thể giúp bạn sử dụng SDK. Hãy yêu cầu nó xây dựng một tích hợp phù hợp với trường hợp sử dụng của bạn.

# SDK

SDK cung cấp quyền truy cập lập trình vào các khả năng của Prime Agent. Bạn có thể dùng SDK để nhúng Prime Agent vào ứng dụng khác, xây dựng giao diện tùy chỉnh hoặc tích hợp với quy trình tự động.

**Ví dụ về trường hợp sử dụng:**
- Xây dựng UI tùy chỉnh (web, desktop, di động)
- Tích hợp khả năng của agent vào ứng dụng hiện có
- Tạo pipeline tự động với khả năng suy luận của agent
- Xây dựng công cụ tùy chỉnh có thể khởi chạy sub-agent
- Kiểm thử hành vi của agent bằng lập trình

Xem [examples/sdk/](../examples/sdk/) để tham khảo các ví dụ hoạt động, từ tối giản đến toàn quyền kiểm soát.

## Bắt đầu nhanh

```typescript
import { AuthStorage, createAgentSession, ModelRegistry, SessionManager } from "@earendil-works/pi-coding-agent";

// Set up credential storage and model registry
const authStorage = AuthStorage.create();
const modelRegistry = ModelRegistry.create(authStorage);

const { session } = await createAgentSession({
  sessionManager: SessionManager.inMemory(),
  authStorage,
  modelRegistry,
});

session.subscribe((event) => {
  if (event.type === "message_update" && event.assistantMessageEvent.type === "text_delta") {
    process.stdout.write(event.assistantMessageEvent.delta);
  }
});

await session.prompt("What files are in the current directory?");
```

## Cài đặt

```bash
npm install @earendil-works/pi-coding-agent
```

SDK được tích hợp trong package chính. Không cần cài đặt riêng.

## Khái niệm cốt lõi

### createAgentSession()

Hàm khởi tạo chính để tạo một `AgentSession`.

`createAgentSession()` sử dụng `ResourceLoader` để cung cấp extension, skill, mẫu prompt, theme và file ngữ cảnh. Nếu bạn không cung cấp, hàm sẽ dùng `DefaultResourceLoader` với cơ chế phát hiện tiêu chuẩn.

```typescript
import { createAgentSession } from "@earendil-works/pi-coding-agent";

// Minimal: defaults with DefaultResourceLoader
const { session } = await createAgentSession();

// Custom: override specific options
const { session } = await createAgentSession({
  model: myModel,
  tools: ["ipython"],
  sessionManager: SessionManager.inMemory(),
});
```

### AgentSession

Session quản lý vòng đời agent, lịch sử tin nhắn, trạng thái model, việc thu gọn ngữ cảnh và truyền sự kiện.

```typescript
interface AgentSession {
  // Send a prompt and wait for completion
  prompt(text: string, options?: PromptOptions): Promise<void>;

  // Queue messages during streaming
  steer(text: string): Promise<void>;
  followUp(text: string): Promise<void>;

  // Subscribe to events (returns unsubscribe function)
  subscribe(listener: (event: AgentSessionEvent) => void): () => void;

  // Session info
  sessionFile: string | undefined;
  sessionId: string;

  // Model control
  setModel(model: Model): Promise<void>;
  setThinkingLevel(level: ThinkingLevel): void;
  cycleModel(): Promise<ModelCycleResult | undefined>;
  cycleThinkingLevel(): ThinkingLevel | undefined;

  // State access
  agent: Agent;
  model: Model | undefined;
  thinkingLevel: ThinkingLevel;
  messages: AgentMessage[];
  isStreaming: boolean;

  // In-place tree navigation within the current session file
  navigateTree(targetId: string, options?: { summarize?: boolean; customInstructions?: string; replaceInstructions?: boolean; label?: string }): Promise<{ editorText?: string; cancelled: boolean }>;

  // Compaction
  compact(customInstructions?: string): Promise<CompactionResult>;
  abortCompaction(): void;

  // Abort current operation
  abort(): Promise<void>;

  // Cleanup
  dispose(): void;
}
```

Các API thay thế session như new-session, resume, fork và import thuộc về `AgentSessionRuntime`, không phải `AgentSession`.

### createAgentSessionRuntime() và AgentSessionRuntime

Dùng API runtime khi cần thay thế session đang hoạt động và xây dựng lại trạng thái runtime gắn với cwd.
Đây cũng là lớp được các chế độ tương tác, in và RPC tích hợp sẵn sử dụng.

`createAgentSessionRuntime()` nhận một hàm khởi tạo runtime cùng cwd/đích session ban đầu. Hàm này giữ các đầu vào cố định cấp process, tạo lại các service gắn với cwd cho cwd hiệu lực, phân giải tùy chọn session dựa trên các service đó và trả về kết quả runtime đầy đủ.

```typescript
import {
  type CreateAgentSessionRuntimeFactory,
  createAgentSessionFromServices,
  createAgentSessionRuntime,
  createAgentSessionServices,
  getAgentDir,
  SessionManager,
} from "@earendil-works/pi-coding-agent";

const createRuntime: CreateAgentSessionRuntimeFactory = async ({ cwd, sessionManager, sessionStartEvent }) => {
  const services = await createAgentSessionServices({ cwd });
  return {
    ...(await createAgentSessionFromServices({
      services,
      sessionManager,
      sessionStartEvent,
    })),
    services,
    diagnostics: services.diagnostics,
  };
};

const runtime = await createAgentSessionRuntime(createRuntime, {
  cwd: process.cwd(),
  agentDir: getAgentDir(),
  sessionManager: SessionManager.create(process.cwd()),
});
```

`AgentSessionRuntime` chịu trách nhiệm thay thế runtime đang hoạt động qua:

- `newSession()`
- `switchSession()`
- `fork()`
- Luồng clone qua `fork(entryId, { position: "at" })`
- `importFromJsonl()`

Hành vi quan trọng:

- `runtime.session` thay đổi sau các thao tác đó
- đăng ký sự kiện gắn với một `AgentSession` cụ thể, vì vậy cần đăng ký lại sau khi thay thế
- nếu dùng extension, hãy gọi lại `runtime.session.bindExtensions(...)` cho session mới
- quá trình tạo trả về thông tin chẩn đoán trên `runtime.diagnostics`
- nếu tạo hoặc thay thế runtime thất bại, phương thức sẽ ném lỗi và bên gọi quyết định cách xử lý

```typescript
let session = runtime.session;
let unsubscribe = session.subscribe(() => {});

await runtime.newSession();

unsubscribe();
session = runtime.session;
unsubscribe = session.subscribe(() => {});
```

### Gửi prompt và xếp hàng tin nhắn

`PromptOptions` kiểm soát việc mở rộng prompt, hành vi xếp hàng khi đang streaming và thông báo preflight của prompt:

```typescript
interface PromptOptions {
  expandPromptTemplates?: boolean;
  images?: ImageContent[];
  streamingBehavior?: "steer" | "followUp";
  source?: InputSource;
  preflightResult?: (success: boolean) => void;
}
```

`preflightResult` được gọi một lần cho mỗi lần gọi `prompt()`:

- `true` khi prompt được chấp nhận, xếp hàng hoặc xử lý ngay lập tức
- `false` khi preflight của prompt từ chối trước lúc chấp nhận

Nó được gọi trước khi `prompt()` resolve. `prompt()` chỉ resolve sau khi toàn bộ lượt chạy đã được chấp nhận kết thúc, bao gồm cả các lần retry. Các lỗi sau khi chấp nhận được báo qua luồng sự kiện và tin nhắn thông thường, không qua `preflightResult(false)`.

Phương thức `prompt()` xử lý mẫu prompt, lệnh extension và việc gửi tin nhắn:

```typescript
// Basic prompt (when not streaming)
await session.prompt("What files are here?");

// With images
await session.prompt("What's in this image?", {
  images: [{ type: "image", source: { type: "base64", mediaType: "image/png", data: "..." } }]
});

// During streaming: must specify how to queue the message
await session.prompt("Stop and do this instead", { streamingBehavior: "steer" });
await session.prompt("After you're done, also check X", { streamingBehavior: "followUp" });
```

**Hành vi:**
- **Lệnh extension** (ví dụ `/mycommand`): Thực thi ngay cả khi đang streaming. Chúng tự quản lý tương tác LLM qua `pi.sendMessage()`.
- **Mẫu prompt dạng file** (từ các file `.md`): Được mở rộng thành nội dung trước khi gửi hoặc xếp hàng.
- **Khi đang streaming mà không có `streamingBehavior`**: Ném lỗi. Hãy dùng trực tiếp `steer()` hoặc `followUp()`, hoặc chỉ định tùy chọn.
- **`preflightResult(true)`**: Nghĩa là prompt được chấp nhận, xếp hàng hoặc xử lý ngay lập tức.
- **`preflightResult(false)`**: Nghĩa là preflight từ chối trước lúc chấp nhận.

Để xếp hàng tường minh khi đang streaming:

```typescript
// Queue a steering message for delivery after the current assistant turn finishes its tool calls
await session.steer("New instruction");

// Wait for agent to finish (delivered only when agent stops)
await session.followUp("After you're done, also do this");
```

Cả `steer()` và `followUp()` đều mở rộng mẫu prompt dạng file nhưng báo lỗi với lệnh extension (không thể xếp hàng lệnh extension).

### Agent và AgentState

Lớp `Agent` (từ `@earendil-works/pi-agent-core`) xử lý tương tác LLM cốt lõi. Truy cập qua `session.agent`.

```typescript
// Access current state
const state = session.agent.state;

// state.messages: AgentMessage[] - conversation history
// state.model: Model - current model
// state.thinkingLevel: ThinkingLevel - current thinking level
// state.systemPrompt: string - system prompt
// state.tools: AgentTool[] - available tools
// state.streamingMessage?: AgentMessage - current partial assistant message
// state.errorMessage?: string - latest assistant error

// Replace messages (useful for branching or restoration)
session.agent.state.messages = messages; // copies the top-level array

// Replace tools
session.agent.state.tools = tools; // copies the top-level array

// Wait for agent to finish processing
await session.agent.waitForIdle();
```

### Sự kiện

Đăng ký sự kiện để nhận output streaming và thông báo vòng đời.

```typescript
session.subscribe((event) => {
  switch (event.type) {
    // Streaming text from assistant
    case "message_update":
      if (event.assistantMessageEvent.type === "text_delta") {
        process.stdout.write(event.assistantMessageEvent.delta);
      }
      if (event.assistantMessageEvent.type === "thinking_delta") {
        // Thinking output (if thinking enabled)
      }
      break;
    
    // Tool execution
    case "tool_execution_start":
      console.log(`Tool: ${event.toolName}`);
      break;
    case "tool_execution_update":
      // Streaming tool output
      break;
    case "tool_execution_end":
      console.log(`Result: ${event.isError ? "error" : "success"}`);
      break;
    
    // Message lifecycle
    case "message_start":
      // New message starting
      break;
    case "message_end":
      // Message complete
      break;
    
    // Agent lifecycle
    case "agent_start":
      // Agent started processing prompt
      break;
    case "agent_end":
      // Agent finished (event.messages contains new messages)
      break;
    
    // Turn lifecycle (one LLM response + tool calls)
    case "turn_start":
      break;
    case "turn_end":
      // event.message: assistant response
      // event.toolResults: tool results from this turn
      break;
    
    // Session events (queue, compaction, retry)
    case "session_action_update":
      console.log(event.actions.steering, event.actions.followUps);
      break;
    case "compaction_start":
    case "compaction_end":
    case "auto_retry_start":
    case "auto_retry_end":
      break;
  }
});
```

## Tham chiếu tùy chọn

### Thư mục

```typescript
const { session } = await createAgentSession({
  // Working directory for DefaultResourceLoader discovery
  cwd: process.cwd(), // default
  
  // Global config directory
  agentDir: "~/.prime/agent", // default (expands ~)
});
```

`cwd` được `DefaultResourceLoader` dùng cho:
- Extension của dự án (`.prime/agent/extensions/`)
- Skill của dự án:
  - `.prime/agent/skills/`
  - `.agents/skills/` trong `cwd` và các thư mục tổ tiên (tối đa đến root của git repo, hoặc root filesystem nếu không nằm trong repo)
- Prompt của dự án (`.prime/agent/prompts/`)
- File ngữ cảnh (`AGENTS.md`, tìm ngược lên từ cwd)
- Phân giải nơi lưu session

`agentDir` được `DefaultResourceLoader` dùng cho:
- Extension toàn cục (`extensions/`)
- Skill toàn cục:
  - `skills/` bên dưới `agentDir` (ví dụ `~/.prime/agent/skills/`)
  - `~/.agents/skills/`
- Prompt toàn cục (`prompts/`)
- File ngữ cảnh toàn cục (`AGENTS.md`)
- Cài đặt (`settings.json`)
- Model tùy chỉnh (`models.json`)
- Credentials (`auth.json`)
- Sessions (`sessions/`)

Khi truyền `ResourceLoader` tùy chỉnh, `cwd` và `agentDir` không còn kiểm soát việc phát hiện resource. Chúng vẫn ảnh hưởng đến tên session và việc phân giải đường dẫn tool.

### Mô hình

```typescript
import { getModel } from "@earendil-works/pi-ai";
import { AuthStorage, ModelRegistry } from "@earendil-works/pi-coding-agent";

const authStorage = AuthStorage.create();
const modelRegistry = ModelRegistry.create(authStorage);

// Find specific built-in model (doesn't check if API key exists)
const opus = getModel("anthropic", "claude-opus-4-5");
if (!opus) throw new Error("Model not found");

// Find any model by provider/id, including custom models from models.json
// (doesn't check if API key exists)
const customModel = modelRegistry.find("my-provider", "my-model");

// Get only models that have valid API keys configured
const available = await modelRegistry.getAvailable();

const { session } = await createAgentSession({
  model: opus,
  thinkingLevel: "medium", // off, minimal, low, medium, high, xhigh
  
  // Models for cycling (Ctrl+P in interactive mode)
  scopedModels: [
    { model: opus, thinkingLevel: "high" },
    { model: haiku, thinkingLevel: "off" },
  ],
  
  authStorage,
  modelRegistry,
});
```

Nếu không cung cấp model:
1. Thử khôi phục từ session (nếu tiếp tục)
2. Dùng giá trị mặc định trong settings
3. Dùng model khả dụng đầu tiên làm dự phòng

> Xem [examples/sdk/02-custom-model.ts](../examples/sdk/02-custom-model.ts)

### API key và OAuth

Thứ tự ưu tiên phân giải API key (do AuthStorage xử lý):
1. Ghi đè runtime (qua `setRuntimeApiKey`, không được lưu bền vững)
2. Thông tin xác thực được lưu trong `auth.json` (API key hoặc token OAuth)
3. Biến môi trường (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, v.v.)
4. Resolver dự phòng (cho key provider tùy chỉnh từ `models.json`)

```typescript
import { AuthStorage, ModelRegistry } from "@earendil-works/pi-coding-agent";

// Default: uses ~/.prime/agent/auth.json and ~/.prime/agent/models.json
const authStorage = AuthStorage.create();
const modelRegistry = ModelRegistry.create(authStorage);

const { session } = await createAgentSession({
  sessionManager: SessionManager.inMemory(),
  authStorage,
  modelRegistry,
});

// Runtime API key override (not persisted to disk)
authStorage.setRuntimeApiKey("anthropic", "sk-my-temp-key");

// Custom auth storage location
const customAuth = AuthStorage.create("/my/app/auth.json");
const customRegistry = ModelRegistry.create(customAuth, "/my/app/models.json");

const { session } = await createAgentSession({
  sessionManager: SessionManager.inMemory(),
  authStorage: customAuth,
  modelRegistry: customRegistry,
});

// No custom models.json (built-in models only)
const simpleRegistry = ModelRegistry.inMemory(authStorage);
```

> Xem [examples/sdk/09-api-keys-and-oauth.ts](../examples/sdk/09-api-keys-and-oauth.ts)

### Lời nhắc hệ thống

Dùng `ResourceLoader` để ghi đè system prompt:

```typescript
import { createAgentSession, DefaultResourceLoader } from "@earendil-works/pi-coding-agent";

const loader = new DefaultResourceLoader({
  systemPromptOverride: () => "You are a helpful assistant.",
});
await loader.reload();

const { session } = await createAgentSession({ resourceLoader: loader });
```

> Xem [examples/sdk/03-custom-prompt.ts](../examples/sdk/03-custom-prompt.ts)

### Công cụ

```typescript
// Use the default built-in tool set: ipython
const { session } = await createAgentSession({
  tools: ["ipython"],
});

// Pick specific tools
const { session } = await createAgentSession({
  tools: ["ipython"],
});
```

#### Tool với cwd tùy chỉnh

**Quan trọng:** Chỉ dùng hàm khởi tạo của tool khi tự đăng ký định nghĩa tool tùy chỉnh. Tên tool tích hợp truyền qua `tools` được phân giải theo `cwd` của session.

```typescript
import {
  createIpythonToolDefinition,
  createBashToolDefinition,
  createEditToolDefinition,
} from "@earendil-works/pi-coding-agent";

const cwd = "/path/to/project";

const { session } = await createAgentSession({
  cwd,
  customTools: [
    createIpythonToolDefinition(cwd),
    createBashToolDefinition(cwd),
    createEditToolDefinition(cwd),
  ],
});
```

**Khi không cần hàm khởi tạo:**
- Nếu bỏ qua `tools`, Prime Agent tự động tạo chúng với `cwd` chính xác
- Nếu dùng `process.cwd()` làm `cwd`, các instance dựng sẵn hoạt động bình thường

**Khi bắt buộc dùng hàm khởi tạo:**
- Khi chỉ định đồng thời `cwd` (khác `process.cwd()`) VÀ `tools`

> Xem [examples/sdk/05-tools.ts](../examples/sdk/05-tools.ts)

### Tool tùy chỉnh

```typescript
import { Type } from "typebox";
import { createAgentSession, defineTool } from "@earendil-works/pi-coding-agent";

// Inline custom tool
const myTool = defineTool({
  name: "my_tool",
  label: "My Tool",
  description: "Does something useful",
  parameters: Type.Object({
    input: Type.String({ description: "Input value" }),
  }),
  execute: async (_toolCallId, params) => ({
    content: [{ type: "text", text: `Result: ${params.input}` }],
    details: {},
  }),
});

// Pass custom tools directly
const { session } = await createAgentSession({
  customTools: [myTool],
});
```

Dùng `defineTool()` cho các định nghĩa độc lập và các mảng như `customTools: [myTool]`. `pi.registerTool({ ... })` inline đã suy luận đúng kiểu tham số.

Các tool truyền qua `customTools` được kết hợp với tool do extension đăng ký. Extension được ResourceLoader tải cũng có thể đăng ký tool qua `pi.registerTool()`.

> Xem [examples/sdk/05-tools.ts](../examples/sdk/05-tools.ts)

### Extension

Extension được `ResourceLoader` tải. `DefaultResourceLoader` phát hiện extension từ `~/.prime/agent/extensions/`, `.prime/agent/extensions/` và các nguồn extension trong `settings.json`.

```typescript
import { createAgentSession, DefaultResourceLoader } from "@earendil-works/pi-coding-agent";

const loader = new DefaultResourceLoader({
  additionalExtensionPaths: ["/path/to/my-extension.ts"],
  extensionFactories: [
    (pi) => {
      pi.on("agent_start", () => {
        console.log("[Inline Extension] Agent starting");
      });
    },
  ],
});
await loader.reload();

const { session } = await createAgentSession({ resourceLoader: loader });
```

Extension có thể đăng ký tool, đăng ký nhận sự kiện, thêm lệnh và nhiều chức năng khác. Xem [extensions.vi.md](extensions.vi.md) để biết API đầy đủ.

**Bus sự kiện:** Extension có thể giao tiếp qua `pi.events`. Truyền một `eventBus` dùng chung vào `DefaultResourceLoader` nếu cần phát hoặc lắng nghe sự kiện từ bên ngoài:

```typescript
import { createEventBus, DefaultResourceLoader } from "@earendil-works/pi-coding-agent";

const eventBus = createEventBus();
const loader = new DefaultResourceLoader({
  eventBus,
});
await loader.reload();

eventBus.on("my-extension:status", (data) => console.log(data));
```

> Xem [examples/sdk/06-extensions.ts](../examples/sdk/06-extensions.ts) và [tài liệu extension](extensions.vi.md)

### Skill

```typescript
import {
  createAgentSession,
  DefaultResourceLoader,
  type Skill,
} from "@earendil-works/pi-coding-agent";

const customSkill: Skill = {
  name: "my-skill",
  description: "Custom instructions",
  filePath: "/path/to/SKILL.md",
  baseDir: "/path/to",
  source: "custom",
};

const loader = new DefaultResourceLoader({
  skillsOverride: (current) => ({
    skills: [...current.skills, customSkill],
    diagnostics: current.diagnostics,
  }),
});
await loader.reload();

const { session } = await createAgentSession({ resourceLoader: loader });
```

> Xem [examples/sdk/04-skills.ts](../examples/sdk/04-skills.ts)

### File ngữ cảnh

```typescript
import { createAgentSession, DefaultResourceLoader } from "@earendil-works/pi-coding-agent";

const loader = new DefaultResourceLoader({
  agentsFilesOverride: (current) => ({
    agentsFiles: [
      ...current.agentsFiles,
      { path: "/virtual/AGENTS.md", content: "# Guidelines\n\n- Be concise" },
    ],
  }),
});
await loader.reload();

const { session } = await createAgentSession({ resourceLoader: loader });
```

> Xem [examples/sdk/07-context-files.ts](../examples/sdk/07-context-files.ts)

### Lệnh slash

```typescript
import {
  createAgentSession,
  DefaultResourceLoader,
  type PromptTemplate,
} from "@earendil-works/pi-coding-agent";

const customCommand: PromptTemplate = {
  name: "deploy",
  description: "Deploy the application",
  source: "(custom)",
  content: "# Deploy\n\n1. Build\n2. Test\n3. Deploy",
};

const loader = new DefaultResourceLoader({
  promptsOverride: (current) => ({
    prompts: [...current.prompts, customCommand],
    diagnostics: current.diagnostics,
  }),
});
await loader.reload();

const { session } = await createAgentSession({ resourceLoader: loader });
```

> Xem [examples/sdk/08-prompt-templates.ts](../examples/sdk/08-prompt-templates.ts)

### Quản lý session

Session dùng cấu trúc cây liên kết bằng `id`/`parentId`, cho phép phân nhánh tại chỗ.

```typescript
import {
  type CreateAgentSessionRuntimeFactory,
  createAgentSession,
  createAgentSessionFromServices,
  createAgentSessionRuntime,
  createAgentSessionServices,
  getAgentDir,
  SessionManager,
} from "@earendil-works/pi-coding-agent";

// In-memory (no persistence)
const { session } = await createAgentSession({
  sessionManager: SessionManager.inMemory(),
});

// New persistent session
const { session: persisted } = await createAgentSession({
  sessionManager: SessionManager.create(process.cwd()),
});

// Continue most recent
const { session: continued, modelFallbackMessage } = await createAgentSession({
  sessionManager: SessionManager.continueRecent(process.cwd()),
});
if (modelFallbackMessage) {
  console.log("Note:", modelFallbackMessage);
}

// Open specific file
const { session: opened } = await createAgentSession({
  sessionManager: SessionManager.open("/path/to/session.jsonl"),
});

// List sessions
const currentProjectSessions = await SessionManager.list(process.cwd());
const allSessions = await SessionManager.listAll();

// Session replacement API for /new, /resume, /fork, /clone, and import flows.
const createRuntime: CreateAgentSessionRuntimeFactory = async ({ cwd, sessionManager, sessionStartEvent }) => {
  const services = await createAgentSessionServices({ cwd });
  return {
    ...(await createAgentSessionFromServices({
      services,
      sessionManager,
      sessionStartEvent,
    })),
    services,
    diagnostics: services.diagnostics,
  };
};

const runtime = await createAgentSessionRuntime(createRuntime, {
  cwd: process.cwd(),
  agentDir: getAgentDir(),
  sessionManager: SessionManager.create(process.cwd()),
});

// Replace the active session with a fresh one
await runtime.newSession();

// Replace the active session with another saved session
await runtime.switchSession("/path/to/session.jsonl");

// Replace the active session with a fork from a specific user entry
await runtime.fork("entry-id");

// Clone the active path through a specific entry
await runtime.fork("entry-id", { position: "at" });
```

**API cây của SessionManager:**

```typescript
const sm = SessionManager.open("/path/to/session.jsonl");

// Session listing
const currentProjectSessions = await SessionManager.list(process.cwd());
const allSessions = await SessionManager.listAll();

// Tree traversal
const entries = sm.getEntries();        // All entries (excludes header)
const tree = sm.getTree();              // Full tree structure
const path = sm.getPath();              // Path from root to current leaf
const leaf = sm.getLeafEntry();         // Current leaf entry
const entry = sm.getEntry(id);          // Get entry by ID
const children = sm.getChildren(id);    // Direct children of entry

// Labels
const label = sm.getLabel(id);          // Get label for entry
sm.appendLabelChange(id, "checkpoint"); // Set label

// Branching
sm.branch(entryId);                     // Move leaf to earlier entry
sm.branchWithSummary(id, "Summary...");  // Branch with context summary
sm.createBranchedSession(leafId);       // Extract path to new file
```

> Xem [examples/sdk/11-sessions.ts](../examples/sdk/11-sessions.ts) và [Định dạng Session](session-format.vi.md)

### Quản lý cài đặt

```typescript
import { createAgentSession, SettingsManager, SessionManager } from "@earendil-works/pi-coding-agent";

// Default: loads from files (global + project merged)
const { session } = await createAgentSession({
  settingsManager: SettingsManager.create(),
});

// With overrides
const settingsManager = SettingsManager.create();
settingsManager.applyOverrides({
  compaction: { enabled: false },
  retry: { enabled: true, maxRetries: 5 },
});
const { session } = await createAgentSession({ settingsManager });

// In-memory (no file I/O, for testing)
const { session } = await createAgentSession({
  settingsManager: SettingsManager.inMemory({ compaction: { enabled: false } }),
  sessionManager: SessionManager.inMemory(),
});

// Custom directories
const { session } = await createAgentSession({
  settingsManager: SettingsManager.create("/custom/cwd", "/custom/agent"),
});
```

**Hàm khởi tạo tĩnh:**
- `SettingsManager.create(cwd?, agentDir?)` - Tải từ file
- `SettingsManager.inMemory(settings?)` - Không I/O file

**Cài đặt theo dự án:**

Settings được tải từ hai vị trí và hợp nhất:
1. Toàn cục: `~/.prime/agent/settings.json`
2. Dự án: `<cwd>/.prime/agent/settings.json`

Dự án ghi đè toàn cục. Các object lồng nhau được hợp nhất theo key. Mặc định, setter sửa cài đặt toàn cục.

**Ngữ nghĩa lưu bền vững và xử lý lỗi:**

- Getter/setter của settings là đồng bộ đối với trạng thái trong bộ nhớ.
- Setter xếp hàng các lần ghi lưu bền vững theo cách bất đồng bộ.
- Gọi `await settingsManager.flush()` khi cần một ranh giới đảm bảo lưu bền vững (ví dụ trước khi process thoát hoặc trước khi kiểm tra nội dung file trong test).
- `SettingsManager` không in lỗi I/O của settings. Dùng `settingsManager.drainErrors()` và báo lỗi ở tầng ứng dụng.

> Xem [examples/sdk/10-settings.ts](../examples/sdk/10-settings.ts)

## ResourceLoader

Dùng `DefaultResourceLoader` để phát hiện extension, skill, prompt, theme và file ngữ cảnh.

```typescript
import {
  DefaultResourceLoader,
  getAgentDir,
} from "@earendil-works/pi-coding-agent";

const loader = new DefaultResourceLoader({
  cwd,
  agentDir: getAgentDir(),
});
await loader.reload();

const extensions = loader.getExtensions();
const skills = loader.getSkills();
const prompts = loader.getPrompts();
const themes = loader.getThemes();
const contextFiles = loader.getAgentsFiles().agentsFiles;
```

## Giá trị trả về

`createAgentSession()` trả về:

```typescript
interface CreateAgentSessionResult {
  // The session
  session: AgentSession;
  
  // Extensions result (for runner setup)
  extensionsResult: LoadExtensionsResult;
  
  // Warning if session model couldn't be restored
  modelFallbackMessage?: string;
}

interface LoadExtensionsResult {
  extensions: Extension[];
  errors: Array<{ path: string; error: string }>;
  runtime: ExtensionRuntime;
}
```

## Ví dụ đầy đủ

```typescript
import { getModel } from "@earendil-works/pi-ai";
import { Type } from "typebox";
import {
 AuthStorage,
  createAgentSession,
  DefaultResourceLoader,
  defineTool,
  ModelRegistry,
  SessionManager,
  SettingsManager,
} from "@earendil-works/pi-coding-agent";

// Set up auth storage (custom location)
const authStorage = AuthStorage.create("/custom/agent/auth.json");

// Runtime API key override (not persisted)
if (process.env.MY_KEY) {
  authStorage.setRuntimeApiKey("anthropic", process.env.MY_KEY);
}

// Model registry (no custom models.json)
const modelRegistry = ModelRegistry.create(authStorage);

// Inline tool
const statusTool = defineTool({
  name: "status",
  label: "Status",
  description: "Get system status",
  parameters: Type.Object({}),
  execute: async () => ({
    content: [{ type: "text", text: `Uptime: ${process.uptime()}s` }],
    details: {},
  }),
});

const model = getModel("anthropic", "claude-opus-4-5");
if (!model) throw new Error("Model not found");

// In-memory settings with overrides
const settingsManager = SettingsManager.inMemory({
  compaction: { enabled: false },
  retry: { enabled: true, maxRetries: 2 },
});

const loader = new DefaultResourceLoader({
  cwd: process.cwd(),
  agentDir: "/custom/agent",
  settingsManager,
  systemPromptOverride: () => "You are a minimal assistant. Be concise.",
});
await loader.reload();

const { session } = await createAgentSession({
  cwd: process.cwd(),
  agentDir: "/custom/agent",

  model,
  thinkingLevel: "off",
  authStorage,
  modelRegistry,

  tools: ["ipython"],
  customTools: [statusTool],
  resourceLoader: loader,

  sessionManager: SessionManager.inMemory(),
  settingsManager,
});

session.subscribe((event) => {
  if (event.type === "message_update" && event.assistantMessageEvent.type === "text_delta") {
    process.stdout.write(event.assistantMessageEvent.delta);
  }
});

await session.prompt("Get status and list files.");
```

## Các chế độ chạy

SDK export các tiện ích chế độ chạy để xây dựng giao diện tùy chỉnh dựa trên `createAgentSession()`:

### InteractiveMode

Chế độ TUI tương tác đầy đủ với trình soạn thảo, lịch sử chat và mọi lệnh tích hợp:

```typescript
import {
  type CreateAgentSessionRuntimeFactory,
  createAgentSessionFromServices,
  createAgentSessionRuntime,
  createAgentSessionServices,
  getAgentDir,
  InteractiveMode,
  SessionManager,
} from "@earendil-works/pi-coding-agent";

const createRuntime: CreateAgentSessionRuntimeFactory = async ({ cwd, sessionManager, sessionStartEvent }) => {
  const services = await createAgentSessionServices({ cwd });
  return {
    ...(await createAgentSessionFromServices({ services, sessionManager, sessionStartEvent })),
    services,
    diagnostics: services.diagnostics,
  };
};
const runtime = await createAgentSessionRuntime(createRuntime, {
  cwd: process.cwd(),
  agentDir: getAgentDir(),
  sessionManager: SessionManager.create(process.cwd()),
});

const mode = new InteractiveMode(runtime, {
  migratedProviders: [],
  modelFallbackMessage: undefined,
  initialMessage: "Hello",
  initialImages: [],
  initialMessages: [],
});

await mode.run();
```

### runPrintMode

Chế độ một lần: gửi prompt, xuất kết quả rồi thoát:

```typescript
import {
  type CreateAgentSessionRuntimeFactory,
  createAgentSessionFromServices,
  createAgentSessionRuntime,
  createAgentSessionServices,
  getAgentDir,
  runPrintMode,
  SessionManager,
} from "@earendil-works/pi-coding-agent";

const createRuntime: CreateAgentSessionRuntimeFactory = async ({ cwd, sessionManager, sessionStartEvent }) => {
  const services = await createAgentSessionServices({ cwd });
  return {
    ...(await createAgentSessionFromServices({ services, sessionManager, sessionStartEvent })),
    services,
    diagnostics: services.diagnostics,
  };
};
const runtime = await createAgentSessionRuntime(createRuntime, {
  cwd: process.cwd(),
  agentDir: getAgentDir(),
  sessionManager: SessionManager.create(process.cwd()),
});

await runPrintMode(runtime, {
  mode: "text",
  initialMessage: "Hello",
  initialImages: [],
  messages: ["Follow up"],
});
```

### runRpcMode

Chế độ JSON-RPC để tích hợp subprocess:

```typescript
import {
  type CreateAgentSessionRuntimeFactory,
  createAgentSessionFromServices,
  createAgentSessionRuntime,
  createAgentSessionServices,
  getAgentDir,
  runRpcMode,
  SessionManager,
} from "@earendil-works/pi-coding-agent";

const createRuntime: CreateAgentSessionRuntimeFactory = async ({ cwd, sessionManager, sessionStartEvent }) => {
  const services = await createAgentSessionServices({ cwd });
  return {
    ...(await createAgentSessionFromServices({ services, sessionManager, sessionStartEvent })),
    services,
    diagnostics: services.diagnostics,
  };
};
const runtime = await createAgentSessionRuntime(createRuntime, {
  cwd: process.cwd(),
  agentDir: getAgentDir(),
  sessionManager: SessionManager.create(process.cwd()),
});

await runRpcMode(runtime);
```

Xem [tài liệu RPC](rpc.vi.md) để biết giao thức JSON.

## Phương án chế độ RPC

Để tích hợp dựa trên subprocess mà không build bằng SDK, dùng trực tiếp CLI:

```bash
prime-agent --mode rpc --no-session
```

Xem [tài liệu RPC](rpc.vi.md) để biết giao thức JSON.

Nên dùng SDK khi:
- Bạn cần an toàn kiểu
- Bạn ở trong cùng process Node.js
- Bạn cần truy cập trực tiếp trạng thái agent
- Bạn muốn tùy chỉnh tool/extension bằng lập trình

Nên dùng chế độ RPC khi:
- Bạn tích hợp từ ngôn ngữ khác
- Bạn muốn cô lập process
- Bạn xây dựng client không phụ thuộc ngôn ngữ

## Các nội dung export

Entry point chính export:

```typescript
// Factory
createAgentSession
createAgentSessionRuntime
AgentSessionRuntime

// Auth and Models
AuthStorage
ModelRegistry

// Resource loading
DefaultResourceLoader
type ResourceLoader
createEventBus

// Helpers
defineTool

// Session management
SessionManager
SettingsManager

// Tool factories (for custom cwd)
createIpythonTool, createBashTool, createEditTool
createIpythonToolDefinition, createBashToolDefinition, createEditToolDefinition

// Types
type CreateAgentSessionOptions
type CreateAgentSessionResult
type ExtensionFactory
type ExtensionAPI
type ToolDefinition
type Skill
type PromptTemplate
type Tool
```

Với các kiểu dữ liệu của extension, xem [extensions.vi.md](extensions.vi.md) để biết API đầy đủ.

# Nhà cung cấp tùy chỉnh

Tiện ích có thể đăng ký nhà cung cấp mô hình tùy chỉnh qua `pi.registerProvider()`. Cơ chế này cho phép:

- **Proxy** - Định tuyến yêu cầu qua proxy doanh nghiệp hoặc cổng API
- **Điểm cuối tùy chỉnh** - Sử dụng bản triển khai mô hình tự lưu trữ hoặc riêng tư
- **OAuth/SSO** - Bổ sung luồng xác thực cho nhà cung cấp doanh nghiệp
- **API tùy chỉnh** - Triển khai truyền phát cho API LLM không theo chuẩn

## Tiện ích mẫu

Xem các ví dụ hoàn chỉnh về nhà cung cấp sau:

- [`examples/extensions/custom-provider-anthropic/`](../examples/extensions/custom-provider-anthropic/)
- [`examples/extensions/custom-provider-gitlab-duo/`](../examples/extensions/custom-provider-gitlab-duo/)

## Mục lục

- [Tiện ích mẫu](#tiện-ích-mẫu)
- [Tham khảo nhanh](#tham-khảo-nhanh)
- [Ghi đè nhà cung cấp hiện có](#ghi-đè-nhà-cung-cấp-hiện-có)
- [Đăng ký nhà cung cấp mới](#đăng-ký-nhà-cung-cấp-mới)
- [Hủy đăng ký nhà cung cấp](#hủy-đăng-ký-nhà-cung-cấp)
- [Hỗ trợ OAuth](#hỗ-trợ-oauth)
- [API truyền phát tùy chỉnh](#api-truyền-phát-tùy-chỉnh)
- [Kiểm thử phần triển khai](#kiểm-thử-phần-triển-khai)
- [Tham khảo cấu hình](#tham-khảo-cấu-hình)
- [Tham khảo định nghĩa mô hình](#tham-khảo-định-nghĩa-mô-hình)

## Tham khảo nhanh

```typescript
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  // Override baseUrl for existing provider
  pi.registerProvider("anthropic", {
    baseUrl: "https://proxy.example.com"
  });

  // Register new provider with models
  pi.registerProvider("my-provider", {
    name: "My Provider",
    baseUrl: "https://api.example.com",
    apiKey: "MY_API_KEY",
    api: "openai-completions",
    models: [
      {
        id: "my-model",
        name: "My Model",
        reasoning: false,
        input: ["text", "image"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 4096
      }
    ]
  });
}
```

Hàm khởi tạo tiện ích cũng có thể là `async`. Để khám phá mô hình động, hãy truy xuất và đăng ký mô hình trong hàm khởi tạo thay vì `session_start`. Prime Agent chờ hàm này hoàn tất trước khi tiếp tục khởi động, nhờ đó nhà cung cấp khả dụng trong quá trình khởi động tương tác và với `prime-agent model list`.

## Ghi đè nhà cung cấp hiện có

Trường hợp sử dụng đơn giản nhất là chuyển hướng một nhà cung cấp hiện có qua proxy.

```typescript
// All Anthropic requests now go through your proxy
pi.registerProvider("anthropic", {
  baseUrl: "https://proxy.example.com"
});

// Add custom headers to OpenAI requests
pi.registerProvider("openai", {
  headers: {
    "X-Custom-Header": "value"
  }
});

// Both baseUrl and headers
pi.registerProvider("google", {
  baseUrl: "https://ai-gateway.corp.com/google",
  headers: {
    "X-Corp-Auth": "CORP_AUTH_TOKEN"  // env var or literal
  }
});
```

Khi chỉ cung cấp `baseUrl` và/hoặc `headers` (không có `models`), toàn bộ mô hình hiện có của nhà cung cấp đó được giữ nguyên nhưng sử dụng điểm cuối mới.

## Đăng ký nhà cung cấp mới

Để thêm một nhà cung cấp hoàn toàn mới, hãy chỉ định `models` cùng cấu hình bắt buộc.

Nếu danh sách mô hình đến từ điểm cuối từ xa, hãy dùng hàm khởi tạo tiện ích bất đồng bộ:

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

Thao tác này đăng ký các mô hình đã truy xuất trước khi quá trình khởi động hoàn tất.

```typescript
pi.registerProvider("my-llm", {
  baseUrl: "https://api.my-llm.com/v1",
  apiKey: "MY_LLM_API_KEY",  // env var name or literal value
  api: "openai-completions",  // which streaming API to use
  models: [
    {
      id: "my-llm-large",
      name: "My LLM Large",
      reasoning: true,        // supports extended thinking
      input: ["text", "image"],
      cost: {
        input: 3.0,           // $/million tokens
        output: 15.0,
        cacheRead: 0.3,
        cacheWrite: 3.75
      },
      contextWindow: 200000,
      maxTokens: 16384
    }
  ]
});
```

Khi được cung cấp, `models` sẽ **thay thế** toàn bộ mô hình hiện có của nhà cung cấp đó.

## Hủy đăng ký nhà cung cấp

Dùng `pi.unregisterProvider(name)` để xóa nhà cung cấp đã được đăng ký trước đó qua `pi.registerProvider(name, ...)`:

```typescript
// Register
pi.registerProvider("my-llm", {
  baseUrl: "https://api.my-llm.com/v1",
  apiKey: "MY_LLM_API_KEY",
  api: "openai-completions",
  models: [
    {
      id: "my-llm-large",
      name: "My LLM Large",
      reasoning: true,
      input: ["text", "image"],
      cost: { input: 3.0, output: 15.0, cacheRead: 0.3, cacheWrite: 3.75 },
      contextWindow: 200000,
      maxTokens: 16384
    }
  ]
});

// Later, remove it
pi.unregisterProvider("my-llm");
```

Việc hủy đăng ký sẽ xóa các mô hình động, phương án dự phòng khóa API, đăng ký nhà cung cấp OAuth và đăng ký trình xử lý luồng tùy chỉnh của nhà cung cấp đó. Mọi mô hình tích hợp sẵn hoặc hành vi nhà cung cấp từng bị ghi đè sẽ được khôi phục.

Các lệnh gọi thực hiện sau giai đoạn tải tiện ích ban đầu được áp dụng ngay lập tức, vì vậy không cần `/reload`.

### Loại API

Trường `api` xác định phần triển khai truyền phát được sử dụng:

| API | Dùng cho |
|-----|---------|
| `anthropic-messages` | API Anthropic Claude và các API tương thích |
| `openai-completions` | API OpenAI Chat Completions và các API tương thích |
| `openai-responses` | OpenAI Responses API |
| `azure-openai-responses` | Azure OpenAI Responses API |
| `openai-codex-responses` | OpenAI Codex Responses API |
| `mistral-conversations` | Truyền phát Conversations/Chat của Mistral SDK |
| `google-generative-ai` | Google Generative AI API |
| `google-vertex` | Google Vertex AI API |
| `bedrock-converse-stream` | Amazon Bedrock Converse API |

Phần lớn nhà cung cấp tương thích OpenAI hoạt động với `openai-completions`. Dùng `thinkingLevelMap` ở cấp mô hình cho các mức suy luận riêng của mô hình và dùng `compat` cho các đặc thù của nhà cung cấp:

```typescript
models: [{
  id: "custom-model",
  // ...
  reasoning: true,
  thinkingLevelMap: {              // map Prime Agent levels to provider values; null hides unsupported levels
    minimal: null,
    low: null,
    medium: null,
    high: "default",
    xhigh: "max"
  },
  compat: {
    supportsDeveloperRole: false,   // use "system" instead of "developer"
    supportsReasoningEffort: true,
    maxTokensField: "max_tokens",   // instead of "max_completion_tokens"
    requiresToolResultName: true,   // tool results need name field
    thinkingFormat: "qwen",        // top-level enable_thinking: true
    cacheControlFormat: "anthropic" // Anthropic-style cache_control markers
  }
}]
```

Dùng `qwen-chat-template` thay thế cho các máy chủ cục bộ tương thích Qwen đọc `chat_template_kwargs.enable_thinking`.
Dùng `cacheControlFormat: "anthropic"` cho các nhà cung cấp tương thích OpenAI cung cấp bộ nhớ đệm lời nhắc kiểu Anthropic qua `cache_control` trên lời nhắc hệ thống, định nghĩa công cụ cuối cùng và nội dung văn bản cuối cùng của người dùng/trợ lý.

> Lưu ý khi chuyển đổi: Mistral đã chuyển từ `openai-completions` sang `mistral-conversations`.
> Dùng `mistral-conversations` cho các mô hình Mistral gốc.
> Nếu chủ động định tuyến điểm cuối tương thích Mistral hoặc điểm cuối tùy chỉnh qua `openai-completions`, hãy đặt rõ các cờ `compat` cần thiết.

### Tiêu đề xác thực

Nếu nhà cung cấp yêu cầu `Authorization: Bearer <key>` nhưng không dùng API chuẩn, hãy đặt `authHeader: true`:

```typescript
pi.registerProvider("custom-api", {
  baseUrl: "https://api.example.com",
  apiKey: "MY_API_KEY",
  authHeader: true,  // adds Authorization: Bearer header
  api: "openai-completions",
  models: [...]
});
```

## Hỗ trợ OAuth

Thêm xác thực OAuth/SSO tích hợp với `/login`:

```typescript
import type { OAuthCredentials, OAuthLoginCallbacks } from "@earendil-works/pi-ai";

pi.registerProvider("corporate-ai", {
  baseUrl: "https://ai.corp.com/v1",
  api: "openai-responses",
  models: [...],
  oauth: {
    name: "Corporate AI (SSO)",

    async login(callbacks: OAuthLoginCallbacks): Promise<OAuthCredentials> {
      // Option 1: Browser-based OAuth
      callbacks.onAuth({ url: "https://sso.corp.com/authorize?..." });

      // Option 2: Device code flow
      callbacks.onDeviceCode({
        userCode: "ABCD-1234",
        verificationUri: "https://sso.corp.com/device"
      });

      // Option 3: Prompt for token/code
      const code = await callbacks.onPrompt({ message: "Enter SSO code:" });

      // Exchange for tokens (your implementation)
      const tokens = await exchangeCodeForTokens(code);

      return {
        refresh: tokens.refreshToken,
        access: tokens.accessToken,
        expires: Date.now() + tokens.expiresIn * 1000
      };
    },

    async refreshToken(credentials: OAuthCredentials): Promise<OAuthCredentials> {
      const tokens = await refreshAccessToken(credentials.refresh);
      return {
        refresh: tokens.refreshToken ?? credentials.refresh,
        access: tokens.accessToken,
        expires: Date.now() + tokens.expiresIn * 1000
      };
    },

    getApiKey(credentials: OAuthCredentials): string {
      return credentials.access;
    },

    // Optional: modify models based on user's subscription
    modifyModels(models, credentials) {
      const region = decodeRegionFromToken(credentials.access);
      return models.map(m => ({
        ...m,
        baseUrl: `https://${region}.ai.corp.com/v1`
      }));
    }
  }
});
```

Sau khi đăng ký, người dùng có thể xác thực qua `/login corporate-ai`.

### OAuthLoginCallbacks

Đối tượng `callbacks` cung cấp ba cách xác thực:

```typescript
interface OAuthLoginCallbacks {
  // Open URL in browser (for OAuth redirects)
  onAuth(params: { url: string }): void;

  // Show device code (for device authorization flow)
  onDeviceCode(params: { userCode: string; verificationUri: string }): void;

  // Prompt user for input (for manual token entry)
  onPrompt(params: { message: string }): Promise<string>;
}
```

### OAuthCredentials

Thông tin xác thực được lưu bền vững trong `~/.prime/agent/auth.json`:

```typescript
interface OAuthCredentials {
  refresh: string;   // Refresh token (for refreshToken())
  access: string;    // Access token (returned by getApiKey())
  expires: number;   // Expiration timestamp in milliseconds
}
```

## API truyền phát tùy chỉnh

Với nhà cung cấp có API không theo chuẩn, hãy triển khai `streamSimple`. Nghiên cứu các phần triển khai nhà cung cấp hiện có trước khi tự viết:

**Các phần triển khai tham khảo:**
- [anthropic.ts](../../ai/src/providers/anthropic.ts) - API Anthropic Messages
- [mistral.ts](../../ai/src/providers/mistral.ts) - API Mistral Conversations
- [openai-completions.ts](../../ai/src/providers/openai-completions.ts) - API OpenAI Chat Completions
- [openai-responses.ts](../../ai/src/providers/openai-responses.ts) - API OpenAI Responses
- [google.ts](../../ai/src/providers/google.ts) - API Google Generative AI
- [amazon-bedrock.ts](../../ai/src/providers/amazon-bedrock.ts) - AWS Bedrock

### Mẫu luồng

Mọi nhà cung cấp đều tuân theo cùng một mẫu:

```typescript
import {
  type AssistantMessage,
  type AssistantMessageEventStream,
  type Context,
  type Model,
  type SimpleStreamOptions,
  calculateCost,
  createAssistantMessageEventStream,
} from "@earendil-works/pi-ai";

function streamMyProvider(
  model: Model<any>,
  context: Context,
  options?: SimpleStreamOptions
): AssistantMessageEventStream {
  const stream = createAssistantMessageEventStream();

  (async () => {
    // Initialize output message
    const output: AssistantMessage = {
      role: "assistant",
      content: [],
      api: model.api,
      provider: model.provider,
      model: model.id,
      usage: {
        input: 0,
        output: 0,
        cacheRead: 0,
        cacheWrite: 0,
        totalTokens: 0,
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
      },
      stopReason: "stop",
      timestamp: Date.now(),
    };

    try {
      // Push start event
      stream.push({ type: "start", partial: output });

      // Make API request and process response...
      // Push content events as they arrive...

      // Push done event
      stream.push({
        type: "done",
        reason: output.stopReason as "stop" | "length" | "toolUse",
        message: output
      });
      stream.end();
    } catch (error) {
      output.stopReason = options?.signal?.aborted ? "aborted" : "error";
      output.errorMessage = error instanceof Error ? error.message : String(error);
      stream.push({ type: "error", reason: output.stopReason, error: output });
      stream.end();
    }
  })();

  return stream;
}
```

### Loại sự kiện

Đẩy sự kiện qua `stream.push()` theo thứ tự sau:

1. `{ type: "start", partial: output }` - Luồng bắt đầu

2. Sự kiện nội dung (có thể lặp lại, theo dõi `contentIndex` cho từng khối):
   - `{ type: "text_start", contentIndex, partial }` - Khối văn bản bắt đầu
   - `{ type: "text_delta", contentIndex, delta, partial }` - Phần văn bản tăng thêm
   - `{ type: "text_end", contentIndex, content, partial }` - Khối văn bản kết thúc
   - `{ type: "thinking_start", contentIndex, partial }` - Quá trình suy luận bắt đầu
   - `{ type: "thinking_delta", contentIndex, delta, partial }` - Phần suy luận tăng thêm
   - `{ type: "thinking_end", contentIndex, content, partial }` - Quá trình suy luận kết thúc
   - `{ type: "toolcall_start", contentIndex, partial }` - Lệnh gọi công cụ bắt đầu
   - `{ type: "toolcall_delta", contentIndex, delta, partial }` - Phần JSON tăng thêm của lệnh gọi công cụ
   - `{ type: "toolcall_end", contentIndex, toolCall, partial }` - Lệnh gọi công cụ kết thúc

3. `{ type: "done", reason, message }` hoặc `{ type: "error", reason, error }` - Luồng kết thúc

Trường `partial` trong mỗi sự kiện chứa trạng thái `AssistantMessage` hiện tại. Cập nhật `output.content` khi nhận dữ liệu, sau đó đưa `output` vào làm `partial`.

### Khối nội dung

Thêm các khối nội dung vào `output.content` khi chúng đến:

```typescript
// Text block
output.content.push({ type: "text", text: "" });
stream.push({ type: "text_start", contentIndex: output.content.length - 1, partial: output });

// As text arrives
const block = output.content[contentIndex];
if (block.type === "text") {
  block.text += delta;
  stream.push({ type: "text_delta", contentIndex, delta, partial: output });
}

// When block completes
stream.push({ type: "text_end", contentIndex, content: block.text, partial: output });
```

### Lệnh gọi công cụ

Lệnh gọi công cụ yêu cầu tích lũy rồi phân tích cú pháp JSON:

```typescript
// Start tool call
output.content.push({
  type: "toolCall",
  id: toolCallId,
  name: toolName,
  arguments: {}
});
stream.push({ type: "toolcall_start", contentIndex: output.content.length - 1, partial: output });

// Accumulate JSON
let partialJson = "";
partialJson += jsonDelta;
try {
  block.arguments = JSON.parse(partialJson);
} catch {}
stream.push({ type: "toolcall_delta", contentIndex, delta: jsonDelta, partial: output });

// Complete
stream.push({
  type: "toolcall_end",
  contentIndex,
  toolCall: { type: "toolCall", id, name, arguments: block.arguments },
  partial: output
});
```

### Mức sử dụng và chi phí

Cập nhật mức sử dụng từ phản hồi API và tính chi phí:

```typescript
output.usage.input = response.usage.input_tokens;
output.usage.output = response.usage.output_tokens;
output.usage.cacheRead = response.usage.cache_read_tokens ?? 0;
output.usage.cacheWrite = response.usage.cache_write_tokens ?? 0;
output.usage.totalTokens = output.usage.input + output.usage.output +
                           output.usage.cacheRead + output.usage.cacheWrite;
calculateCost(model, output.usage);
```

### Đăng ký

Đăng ký hàm truyền phát của bạn:

```typescript
pi.registerProvider("my-provider", {
  baseUrl: "https://api.example.com",
  apiKey: "MY_API_KEY",
  api: "my-custom-api",
  models: [...],
  streamSimple: streamMyProvider
});
```

## Kiểm thử phần triển khai

Kiểm thử nhà cung cấp bằng chính các bộ kiểm thử dành cho nhà cung cấp tích hợp sẵn. Sao chép và điều chỉnh các tệp kiểm thử trong [`packages/ai/test/`](../../ai/test/):

| Kiểm thử | Mục đích |
|------|---------|
| `stream.test.ts` | Truyền phát cơ bản, đầu ra văn bản |
| `tokens.test.ts` | Đếm token và mức sử dụng |
| `abort.test.ts` | Xử lý AbortSignal |
| `empty.test.ts` | Phản hồi trống/tối thiểu |
| `context-overflow.test.ts` | Giới hạn cửa sổ ngữ cảnh |
| `image-limits.test.ts` | Xử lý đầu vào hình ảnh |
| `unicode-surrogate.test.ts` | Các trường hợp biên Unicode |
| `tool-call-without-result.test.ts` | Các trường hợp biên của lệnh gọi công cụ |
| `image-tool-result.test.ts` | Hình ảnh trong kết quả công cụ |
| `total-tokens.test.ts` | Tính tổng số token |
| `cross-provider-handoff.test.ts` | Chuyển giao ngữ cảnh giữa các nhà cung cấp |

Chạy kiểm thử với các cặp nhà cung cấp/mô hình để xác minh tính tương thích.

## Tham khảo cấu hình

```typescript
interface ProviderConfig {
  /** Display name for the provider in UI such as /login. */
  name?: string;

  /** API endpoint URL. Required when defining models. */
  baseUrl?: string;

  /** API key or environment variable name. Required when defining models (unless oauth). */
  apiKey?: string;

  /** API type for streaming. Required at provider or model level when defining models. */
  api?: Api;

  /** Custom streaming implementation for non-standard APIs. */
  streamSimple?: (
    model: Model<Api>,
    context: Context,
    options?: SimpleStreamOptions
  ) => AssistantMessageEventStream;

  /** Custom headers to include in requests. Values can be env var names. */
  headers?: Record<string, string>;

  /** If true, adds Authorization: Bearer header with the resolved API key. */
  authHeader?: boolean;

  /** Models to register. If provided, replaces all existing models for this provider. */
  models?: ProviderModelConfig[];

  /** OAuth provider for /login support. */
  oauth?: {
    name: string;
    login(callbacks: OAuthLoginCallbacks): Promise<OAuthCredentials>;
    refreshToken(credentials: OAuthCredentials): Promise<OAuthCredentials>;
    getApiKey(credentials: OAuthCredentials): string;
    modifyModels?(models: Model<Api>[], credentials: OAuthCredentials): Model<Api>[];
  };
}
```

## Tham khảo định nghĩa mô hình

```typescript
interface ProviderModelConfig {
  /** Model ID (e.g., "claude-sonnet-4-20250514"). */
  id: string;

  /** Display name (e.g., "Claude 4 Sonnet"). */
  name: string;

  /** API type override for this specific model. */
  api?: Api;

  /** API endpoint URL override for this specific model. */
  baseUrl?: string;

  /** Whether the model supports extended thinking. */
  reasoning: boolean;

  /** Maps Prime Agent thinking levels to provider/model-specific values; null marks a level unsupported. */
  thinkingLevelMap?: Partial<Record<"off" | "minimal" | "low" | "medium" | "high" | "xhigh", string | null>>;

  /** Supported input types. */
  input: ("text" | "image")[];

  /** Cost per million tokens (for usage tracking). */
  cost: {
    input: number;
    output: number;
    cacheRead: number;
    cacheWrite: number;
  };

  /** Maximum context window size in tokens. */
  contextWindow: number;

  /** Maximum output tokens. */
  maxTokens: number;

  /** Custom headers for this specific model. */
  headers?: Record<string, string>;

  /** OpenAI compatibility settings for openai-completions API. */
  compat?: {
    supportsStore?: boolean;
    supportsDeveloperRole?: boolean;
    supportsReasoningEffort?: boolean;
    supportsUsageInStreaming?: boolean;
    maxTokensField?: "max_completion_tokens" | "max_tokens";
    requiresToolResultName?: boolean;
    requiresAssistantAfterToolResult?: boolean;
    requiresThinkingAsText?: boolean;
    requiresReasoningContentOnAssistantMessages?: boolean;
    thinkingFormat?: "openai" | "deepseek" | "zai" | "qwen" | "qwen-chat-template";
    cacheControlFormat?: "anthropic";
  };
}
```

Khi được bật, `deepseek` gửi `thinking: { type: "enabled" | "disabled" }` và `reasoning_effort`. `qwen` dành cho `enable_thinking` cấp cao nhất theo kiểu DashScope. Dùng `qwen-chat-template` cho các máy chủ cục bộ tương thích Qwen đọc `chat_template_kwargs.enable_thinking`.
`cacheControlFormat: "anthropic"` áp dụng các dấu `cache_control` kiểu Anthropic cho lời nhắc hệ thống, định nghĩa công cụ cuối cùng và nội dung văn bản cuối cùng của người dùng/trợ lý.

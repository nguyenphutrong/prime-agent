# Mô hình tùy chỉnh

Thêm nhà cung cấp và mô hình tùy chỉnh (Ollama, vLLM, LM Studio, proxy) thông qua `~/.prime/agent/models.json`.

## Mục lục

- [Ví dụ tối thiểu](#ví-dụ-tối-thiểu)
- [Ví dụ đầy đủ](#ví-dụ-đầy-đủ)
- [Các API được hỗ trợ](#các-api-được-hỗ-trợ)
- [Cấu hình nhà cung cấp](#cấu-hình-nhà-cung-cấp)
- [Cấu hình mô hình](#cấu-hình-mô-hình)
- [Ghi đè nhà cung cấp tích hợp sẵn](#ghi-đè-nhà-cung-cấp-tích-hợp-sẵn)
- [Ghi đè theo từng mô hình](#ghi-đè-theo-từng-mô-hình)
- [Khả năng tương thích với Anthropic Messages](#khả-năng-tương-thích-với-anthropic-messages)
- [Khả năng tương thích với OpenAI](#khả-năng-tương-thích-với-openai)

## Ví dụ tối thiểu

Đối với mô hình cục bộ (Ollama, LM Studio, vLLM), mỗi mô hình chỉ bắt buộc có `id`:

```json
{
  "providers": {
    "ollama": {
      "baseUrl": "http://localhost:11434/v1",
      "api": "openai-completions",
      "apiKey": "ollama",
      "models": [
        { "id": "llama3.1:8b" },
        { "id": "qwen2.5-coder:7b" }
      ]
    }
  }
}
```

`apiKey` là bắt buộc nhưng Ollama bỏ qua trường này, vì vậy có thể dùng bất kỳ giá trị nào.

Một số máy chủ tương thích với OpenAI không hiểu vai trò `developer` dùng cho các mô hình có khả năng suy luận. Với những nhà cung cấp đó, hãy đặt `compat.supportsDeveloperRole` thành `false` để Prime Agent gửi prompt hệ thống dưới dạng thông điệp `system`. Nếu máy chủ cũng không hỗ trợ `reasoning_effort`, hãy đặt cả `compat.supportsReasoningEffort` thành `false`.

Bạn có thể đặt `compat` ở cấp nhà cung cấp để áp dụng cho mọi mô hình, hoặc ở cấp mô hình để ghi đè cho một mô hình cụ thể. Cấu hình này thường áp dụng cho Ollama, vLLM, SGLang và các máy chủ tương thích với OpenAI tương tự.

```json
{
  "providers": {
    "ollama": {
      "baseUrl": "http://localhost:11434/v1",
      "api": "openai-completions",
      "apiKey": "ollama",
      "compat": {
        "supportsDeveloperRole": false,
        "supportsReasoningEffort": false
      },
      "models": [
        {
          "id": "gpt-oss:20b",
          "reasoning": true
        }
      ]
    }
  }
}
```

## Ví dụ đầy đủ

Ghi đè các giá trị mặc định khi bạn cần giá trị cụ thể:

```json
{
  "providers": {
    "ollama": {
      "baseUrl": "http://localhost:11434/v1",
      "api": "openai-completions",
      "apiKey": "ollama",
      "models": [
        {
          "id": "llama3.1:8b",
          "name": "Llama 3.1 8B (Local)",
          "reasoning": false,
          "input": ["text"],
          "contextWindow": 128000,
          "maxTokens": 32000,
          "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 }
        }
      ]
    }
  }
}
```

Tệp được tải lại mỗi khi bạn mở `/model`. Bạn có thể chỉnh sửa ngay trong phiên mà không cần khởi động lại.

## Ví dụ Google AI Studio

Dùng `google-generative-ai` cùng `baseUrl` để thêm mô hình từ Google AI Studio, bao gồm các mục Gemma 4 tùy chỉnh:

```json
{
  "providers": {
    "my-google": {
      "baseUrl": "https://generativelanguage.googleapis.com/v1beta",
      "api": "google-generative-ai",
      "apiKey": "GEMINI_API_KEY",
      "models": [
        {
          "id": "gemma-4-31b-it",
          "name": "Gemma 4 31B",
          "input": ["text", "image"],
          "contextWindow": 262144,
          "reasoning": true
        }
      ]
    }
  }
}
```

`baseUrl` là bắt buộc khi thêm mô hình tùy chỉnh vào loại API `google-generative-ai`.

## Các API được hỗ trợ

| API | Mô tả |
|-----|-------------|
| `openai-completions` | OpenAI Chat Completions (tương thích rộng nhất) |
| `openai-responses` | OpenAI Responses API |
| `anthropic-messages` | Anthropic Messages API |
| `google-generative-ai` | Google Generative AI |

Đặt `api` ở cấp nhà cung cấp (mặc định cho mọi mô hình) hoặc cấp mô hình (ghi đè theo từng mô hình).

## Cấu hình nhà cung cấp

| Trường | Mô tả |
|-------|-------------|
| `baseUrl` | URL của endpoint API |
| `api` | Loại API (xem phía trên) |
| `apiKey` | Khóa API (xem phần phân giải giá trị bên dưới) |
| `headers` | Header tùy chỉnh (xem phần phân giải giá trị bên dưới) |
| `authHeader` | Đặt thành `true` để tự động thêm `Authorization: Bearer <apiKey>` |
| `models` | Mảng cấu hình mô hình |
| `modelOverrides` | Các giá trị ghi đè theo từng mô hình cho mô hình tích hợp sẵn của nhà cung cấp này |

### Phân giải giá trị

Các trường `apiKey` và `headers` hỗ trợ ba định dạng:

- **Lệnh shell:** `"!command"` được thực thi và sử dụng stdout
  ```json
  "apiKey": "!security find-generic-password -ws 'anthropic'"
  "apiKey": "!op read 'op://vault/item/credential'"
  ```
- **Biến môi trường:** Sử dụng giá trị của biến được chỉ định
  ```json
  "apiKey": "MY_API_KEY"
  ```
- **Giá trị trực tiếp:** Được sử dụng trực tiếp
  ```json
  "apiKey": "sk-..."
  ```

Đối với `models.json`, các lệnh shell được phân giải tại thời điểm gửi yêu cầu. Prime Agent chủ ý không áp dụng TTL tích hợp, tái sử dụng giá trị cũ hay logic khôi phục cho các lệnh tùy ý. Mỗi lệnh cần chiến lược lưu đệm và xử lý lỗi khác nhau, và Prime Agent không thể suy ra chiến lược phù hợp.

Nếu lệnh của bạn chạy chậm, tốn kém, bị giới hạn tốc độ hoặc cần tiếp tục dùng giá trị trước đó khi gặp lỗi tạm thời, hãy bọc lệnh trong script hoặc lệnh riêng có triển khai cơ chế lưu đệm hay TTL mong muốn.

Các bước kiểm tra tính khả dụng của `/model` dựa trên sự hiện diện của thông tin xác thực đã cấu hình và không thực thi lệnh shell.

### Header tùy chỉnh

```json
{
  "providers": {
    "custom-proxy": {
      "baseUrl": "https://proxy.example.com/v1",
      "apiKey": "MY_API_KEY",
      "api": "anthropic-messages",
      "headers": {
        "x-portkey-api-key": "PORTKEY_API_KEY",
        "x-secret": "!op read 'op://vault/item/secret'"
      },
      "models": [...]
    }
  }
}
```

## Cấu hình mô hình

| Trường | Bắt buộc | Mặc định | Mô tả |
|-------|----------|---------|-------------|
| `id` | Có | — | Mã định danh mô hình (được truyền tới API) |
| `name` | Không | `id` | Nhãn mô hình dễ đọc. Được dùng để khớp (mẫu `--model`) và hiển thị trong nội dung chi tiết/trạng thái mô hình. |
| `api` | Không | `api` của nhà cung cấp | Ghi đè API của nhà cung cấp cho mô hình này |
| `reasoning` | Không | `false` | Hỗ trợ suy luận mở rộng |
| `thinkingLevelMap` | Không | bỏ qua | Ánh xạ các mức suy luận của Prime Agent sang giá trị của nhà cung cấp và đánh dấu các mức không được hỗ trợ (xem bên dưới) |
| `input` | Không | `["text"]` | Loại đầu vào: `["text"]` hoặc `["text", "image"]` |
| `contextWindow` | Không | `128000` | Kích thước cửa sổ ngữ cảnh tính bằng token |
| `maxTokens` | Không | `16384` | Số token đầu ra tối đa |
| `cost` | Không | toàn số không | `{"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}` (trên mỗi triệu token) |
| `compat` | Không | `compat` của nhà cung cấp | Các giá trị ghi đè về khả năng tương thích của nhà cung cấp. Được hợp nhất với `compat` cấp nhà cung cấp khi cả hai cùng được đặt. |

Hành vi hiện tại:
- `/model` và `prime-agent model list` liệt kê các mục theo `id` mô hình.
- `name` đã cấu hình được dùng để khớp mô hình và hiển thị nội dung chi tiết/trạng thái.

### Ánh xạ mức suy luận

Dùng `thinkingLevelMap` trên một mô hình để mô tả các điều khiển suy luận riêng cho mô hình đó. Các khóa là mức suy luận của Prime Agent: `off`, `minimal`, `low`, `medium`, `high`, `xhigh`.

Giá trị có ba trạng thái:

| Giá trị | Ý nghĩa |
|-------|---------|
| bỏ qua | Mức được hỗ trợ và sử dụng ánh xạ mặc định của nhà cung cấp |
| chuỗi | Mức được hỗ trợ và giá trị này được gửi tới nhà cung cấp |
| `null` | Mức không được hỗ trợ và sẽ bị ẩn/bỏ qua/giới hạn sang mức khác |

Ví dụ về mô hình chỉ hỗ trợ tắt, mức suy luận cao và tối đa:

```json
{
  "id": "deepseek-v4-pro",
  "reasoning": true,
  "thinkingLevelMap": {
    "minimal": null,
    "low": null,
    "medium": null,
    "high": "high",
    "xhigh": "max"
  }
}
```

Ví dụ về mô hình không thể tắt suy luận:

```json
{
  "id": "always-thinking-model",
  "reasoning": true,
  "thinkingLevelMap": {
    "off": null
  }
}
```

Chuyển đổi: cấu hình cũ dùng `compat.reasoningEffortMap` nên chuyển ánh xạ đó sang `thinkingLevelMap` ở cấp mô hình. Dùng `null` cho những mức không nên xuất hiện trên giao diện người dùng.

## Ghi đè nhà cung cấp tích hợp sẵn

Định tuyến một nhà cung cấp tích hợp sẵn qua proxy mà không cần định nghĩa lại các mô hình:

```json
{
  "providers": {
    "anthropic": {
      "baseUrl": "https://my-proxy.example.com/v1"
    }
  }
}
```

Mọi mô hình Anthropic tích hợp sẵn vẫn khả dụng. Cơ chế xác thực OAuth hoặc khóa API hiện có tiếp tục hoạt động.

Để hợp nhất các mô hình tùy chỉnh vào một nhà cung cấp tích hợp sẵn, hãy thêm mảng `models`:

```json
{
  "providers": {
    "anthropic": {
      "baseUrl": "https://my-proxy.example.com/v1",
      "apiKey": "ANTHROPIC_API_KEY",
      "api": "anthropic-messages",
      "models": [...]
    }
  }
}
```

Quy tắc hợp nhất:
- Giữ lại các mô hình tích hợp sẵn.
- Các mô hình tùy chỉnh được thêm mới hoặc cập nhật theo `id` trong phạm vi nhà cung cấp.
- Nếu `id` của mô hình tùy chỉnh khớp với `id` của mô hình tích hợp sẵn, mô hình tùy chỉnh sẽ thay thế mô hình tích hợp sẵn đó.
- Nếu `id` của mô hình tùy chỉnh là mới, mô hình đó được thêm bên cạnh các mô hình tích hợp sẵn.

## Ghi đè theo từng mô hình

Dùng `modelOverrides` để tùy chỉnh các mô hình tích hợp sẵn cụ thể mà không thay thế toàn bộ danh sách mô hình của nhà cung cấp.

```json
{
  "providers": {
    "openrouter": {
      "modelOverrides": {
        "anthropic/claude-sonnet-4": {
          "name": "Claude Sonnet 4 (Bedrock Route)",
          "compat": {
            "openRouterRouting": {
              "only": ["amazon-bedrock"]
            }
          }
        }
      }
    }
  }
}
```

`modelOverrides` hỗ trợ các trường sau cho từng mô hình: `name`, `reasoning`, `input`, `cost` (một phần), `contextWindow`, `maxTokens`, `headers`, `compat`.

Lưu ý về hành vi:
- `modelOverrides` được áp dụng cho các mô hình tích hợp sẵn của nhà cung cấp.
- Các ID mô hình không xác định sẽ bị bỏ qua.
- Bạn có thể kết hợp `baseUrl`/`headers` cấp nhà cung cấp với `modelOverrides`.
- Nếu `models` cũng được định nghĩa cho một nhà cung cấp, các mô hình tùy chỉnh sẽ được hợp nhất sau khi áp dụng giá trị ghi đè tích hợp sẵn. Mô hình tùy chỉnh có cùng `id` sẽ thay thế mục mô hình tích hợp sẵn đã được ghi đè.

## Khả năng tương thích với Anthropic Messages

Với nhà cung cấp hoặc proxy dùng `api: "anthropic-messages"`, hãy dùng `compat.supportsEagerToolInputStreaming` để kiểm soát khả năng tương thích với cơ chế truyền phát công cụ chi tiết của Anthropic.

Theo mặc định, Prime Agent gửi `eager_input_streaming: true` cho từng công cụ. Nếu proxy hoặc backend tương thích với Anthropic từ chối trường đó, hãy đặt `supportsEagerToolInputStreaming` thành `false`. Khi đó Prime Agent sẽ bỏ qua `tools[].eager_input_streaming` và thay vào đó gửi header beta cũ `fine-grained-tool-streaming-2025-05-14` cho các yêu cầu có bật công cụ.

```json
{
  "providers": {
    "anthropic-proxy": {
      "baseUrl": "https://proxy.example.com",
      "api": "anthropic-messages",
      "apiKey": "ANTHROPIC_PROXY_KEY",
      "compat": {
        "supportsEagerToolInputStreaming": false,
        "supportsLongCacheRetention": true
      },
      "models": [
        {
          "id": "claude-opus-4-7",
          "reasoning": true,
          "input": ["text", "image"]
        }
      ]
    }
  }
}
```

| Trường | Mô tả |
|-------|-------------|
| `supportsEagerToolInputStreaming` | Nhà cung cấp có chấp nhận `eager_input_streaming` theo từng công cụ hay không. Mặc định: `true`. Đặt thành `false` để bỏ qua trường đó và dùng header beta truyền phát công cụ chi tiết kiểu cũ cho các yêu cầu có bật công cụ. |
| `supportsLongCacheRetention` | Nhà cung cấp có chấp nhận thời gian lưu bộ nhớ đệm dài của Anthropic (`cache_control.ttl: "1h"`) khi chế độ lưu bộ nhớ đệm là `long` hay không. Mặc định: `true`. |

## Khả năng tương thích với OpenAI

Với các nhà cung cấp chỉ tương thích một phần với OpenAI, hãy dùng trường `compat`.

- `compat` cấp nhà cung cấp áp dụng giá trị mặc định cho mọi mô hình thuộc nhà cung cấp đó.
- `compat` cấp mô hình ghi đè các giá trị cấp nhà cung cấp cho mô hình đó.

```json
{
  "providers": {
    "local-llm": {
      "baseUrl": "http://localhost:8080/v1",
      "api": "openai-completions",
      "compat": {
        "supportsUsageInStreaming": false,
        "maxTokensField": "max_tokens"
      },
      "models": [...]
    }
  }
}
```

| Trường | Mô tả |
|-------|-------------|
| `supportsStore` | Nhà cung cấp hỗ trợ trường `store` |
| `supportsDeveloperRole` | Dùng vai trò `developer` thay vì `system` |
| `supportsReasoningEffort` | Hỗ trợ tham số `reasoning_effort` |
| `supportsUsageInStreaming` | Hỗ trợ `stream_options: { include_usage: true }` (mặc định: `true`) |
| `maxTokensField` | Dùng `max_completion_tokens` hoặc `max_tokens` |
| `requiresToolResultName` | Thêm `name` vào thông điệp kết quả công cụ |
| `requiresAssistantAfterToolResult` | Chèn một thông điệp assistant trước thông điệp user đứng sau kết quả công cụ |
| `requiresThinkingAsText` | Chuyển các khối suy luận thành văn bản thuần túy |
| `requiresReasoningContentOnAssistantMessages` | Thêm `reasoning_content` rỗng vào mọi thông điệp assistant được phát lại khi bật suy luận |
| `thinkingFormat` | Dùng tham số suy luận `reasoning_effort`, `deepseek`, `zai`, `qwen` hoặc `qwen-chat-template` |
| `cacheControlFormat` | Dùng các dấu mốc `cache_control` kiểu Anthropic trên prompt hệ thống, định nghĩa công cụ cuối cùng và nội dung văn bản user/assistant cuối cùng. Hiện chỉ hỗ trợ `anthropic`. |
| `supportsStrictMode` | Thêm trường `strict` vào định nghĩa công cụ |
| `supportsLongCacheRetention` | Nhà cung cấp có chấp nhận thời gian lưu bộ nhớ đệm dài khi chế độ lưu bộ nhớ đệm là `long` hay không: `prompt_cache_retention: "24h"` cho bộ nhớ đệm prompt của OpenAI, hoặc `cache_control.ttl: "1h"` khi `cacheControlFormat` là `anthropic`. Mặc định: `true`. |
| `openRouterRouting` | Tùy chọn định tuyến nhà cung cấp OpenRouter. Đối tượng này được gửi nguyên trạng trong trường `provider` của [yêu cầu API OpenRouter](https://openrouter.ai/docs/guides/routing/provider-selection). |
| `vercelGatewayRouting` | Cấu hình định tuyến Vercel AI Gateway để chọn nhà cung cấp (`only`, `order`) |

`qwen` dùng `enable_thinking` ở cấp cao nhất. Dùng `qwen-chat-template` cho các máy chủ cục bộ tương thích với Qwen yêu cầu `chat_template_kwargs.enable_thinking`.

`cacheControlFormat: "anthropic"` dành cho các nhà cung cấp tương thích với OpenAI cung cấp cơ chế lưu bộ nhớ đệm prompt kiểu Anthropic thông qua dấu mốc `cache_control` trên nội dung văn bản và định nghĩa công cụ.

Ví dụ:

```json
{
  "providers": {
    "openrouter": {
      "baseUrl": "https://openrouter.ai/api/v1",
      "apiKey": "OPENROUTER_API_KEY",
      "api": "openai-completions",
      "models": [
        {
          "id": "openrouter/anthropic/claude-3.5-sonnet",
          "name": "OpenRouter Claude 3.5 Sonnet",
          "compat": {
            "openRouterRouting": {
              "allow_fallbacks": true,
              "require_parameters": false,
              "data_collection": "deny",
              "zdr": true,
              "enforce_distillable_text": false,
              "order": ["anthropic", "amazon-bedrock", "google-vertex"],
              "only": ["anthropic", "amazon-bedrock"],
              "ignore": ["gmicloud", "friendli"],
              "quantizations": ["fp16", "bf16"],
              "sort": {
                "by": "price",
                "partition": "model"
              },
              "max_price": {
                "prompt": 10,
                "completion": 20
              },
              "preferred_min_throughput": {
                "p50": 100,
                "p90": 50
              },
              "preferred_max_latency": {
                "p50": 1,
                "p90": 3,
                "p99": 5
              }
            }
          }
        }
      ]
    }
  }
}
```

Ví dụ về Vercel AI Gateway:

```json
{
  "providers": {
    "vercel-ai-gateway": {
      "baseUrl": "https://ai-gateway.vercel.sh/v1",
      "apiKey": "AI_GATEWAY_API_KEY",
      "api": "openai-completions",
      "models": [
        {
          "id": "moonshotai/kimi-k2.5",
          "name": "Kimi K2.5 (Fireworks via Vercel)",
          "reasoning": true,
          "input": ["text", "image"],
          "cost": { "input": 0.6, "output": 3, "cacheRead": 0, "cacheWrite": 0 },
          "contextWindow": 262144,
          "maxTokens": 262144,
          "compat": {
            "vercelGatewayRouting": {
              "only": ["fireworks", "novita"],
              "order": ["fireworks", "novita"]
            }
          }
        }
      ]
    }
  }
}
```

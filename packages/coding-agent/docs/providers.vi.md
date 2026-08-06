# Nhà cung cấp

Prime Agent hỗ trợ các nhà cung cấp theo gói đăng ký thông qua OAuth và các nhà cung cấp dùng khóa API thông qua biến môi trường hoặc tệp xác thực. Danh mục mô hình tích hợp sẵn được cập nhật theo mỗi bản phát hành Prime Agent.

## Mục lục

- [Gói đăng ký](#gói-đăng-ký)
- [Khóa API](#khóa-api)
- [Tệp xác thực](#tệp-xác-thực)
- [Nhà cung cấp đám mây](#nhà-cung-cấp-đám-mây)
- [Nhà cung cấp tùy chỉnh](#nhà-cung-cấp-tùy-chỉnh)
- [Thứ tự phân giải](#thứ-tự-phân-giải)

## Gói đăng ký

Trong chế độ tương tác, dùng `/login`, sau đó chọn một nhà cung cấp:

- ChatGPT Plus/Pro (Codex)
- Claude Pro/Max
- GitHub Copilot

Dùng `/logout` để xóa thông tin xác thực. Token được lưu trong `~/.prime/agent/auth.json` và tự động làm mới khi hết hạn.

### OpenAI Codex

- Yêu cầu gói đăng ký ChatGPT Plus hoặc Pro
- Được OpenAI chính thức hỗ trợ: [Codex dành cho OSS](https://developers.openai.com/community/codex-for-oss)

### Claude Pro/Max

Tính năng xác thực bằng gói đăng ký Anthropic đang hoạt động cho các tài khoản Claude Pro/Max. Việc sử dụng qua công cụ điều phối của bên thứ ba được tính vào [mức sử dụng bổ sung](https://claude.ai/settings/usage) và tính phí theo token, không trừ vào hạn mức của gói Claude.

### GitHub Copilot

- Nhấn Enter để dùng github.com hoặc nhập miền GitHub Enterprise Server của bạn
- Nếu gặp thông báo "model not supported", hãy bật mô hình trong VS Code: Copilot Chat → trình chọn mô hình → chọn mô hình → "Enable"

## Khóa API

### Biến môi trường hoặc tệp xác thực

Trong chế độ tương tác, dùng `/login` rồi chọn một nhà cung cấp để lưu khóa API vào `auth.json`, hoặc thiết lập thông tin xác thực qua biến môi trường:

```bash
export ANTHROPIC_API_KEY=sk-ant-...
prime-agent
```

| Nhà cung cấp | Biến môi trường | Khóa `auth.json` |
|----------|----------------------|------------------|
| Anthropic | `ANTHROPIC_API_KEY` | `anthropic` |
| Azure OpenAI Responses | `AZURE_OPENAI_API_KEY` | `azure-openai-responses` |
| OpenAI | `OPENAI_API_KEY` | `openai` |
| Prime Inference | `PRIME_API_KEY` | `prime-inference` |
| DeepSeek | `DEEPSEEK_API_KEY` | `deepseek` |
| Google Gemini | `GEMINI_API_KEY` | `google` |
| Mistral | `MISTRAL_API_KEY` | `mistral` |
| Groq | `GROQ_API_KEY` | `groq` |
| Cerebras | `CEREBRAS_API_KEY` | `cerebras` |
| Cloudflare AI Gateway | `CLOUDFLARE_API_KEY` (+ `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_GATEWAY_ID`) | `cloudflare-ai-gateway` |
| Cloudflare Workers AI | `CLOUDFLARE_API_KEY` (+ `CLOUDFLARE_ACCOUNT_ID`) | `cloudflare-workers-ai` |
| xAI | `XAI_API_KEY` | `xai` |
| OpenRouter | `OPENROUTER_API_KEY` | `openrouter` |
| Vercel AI Gateway | `AI_GATEWAY_API_KEY` | `vercel-ai-gateway` |
| ZAI | `ZAI_API_KEY` | `zai` |
| OpenCode Zen | `OPENCODE_API_KEY` | `opencode` |
| OpenCode Go | `OPENCODE_API_KEY` | `opencode-go` |
| Hugging Face | `HF_TOKEN` | `huggingface` |
| Fireworks | `FIREWORKS_API_KEY` | `fireworks` |
| Kimi For Coding | `KIMI_API_KEY` | `kimi-coding` |
| MiniMax | `MINIMAX_API_KEY` | `minimax` |
| MiniMax (Trung Quốc) | `MINIMAX_CN_API_KEY` | `minimax-cn` |
| Xiaomi MiMo | `XIAOMI_API_KEY` | `xiaomi` |
| Xiaomi MiMo Token Plan (Trung Quốc) | `XIAOMI_TOKEN_PLAN_CN_API_KEY` | `xiaomi-token-plan-cn` |
| Xiaomi MiMo Token Plan (Amsterdam) | `XIAOMI_TOKEN_PLAN_AMS_API_KEY` | `xiaomi-token-plan-ams` |
| Xiaomi MiMo Token Plan (Singapore) | `XIAOMI_TOKEN_PLAN_SGP_API_KEY` | `xiaomi-token-plan-sgp` |

Tham khảo các biến môi trường và khóa `auth.json` tại: [`env-api-keys.ts`](../../ai/src/env-api-keys.ts).

#### Tệp xác thực

Lưu thông tin xác thực trong `~/.prime/agent/auth.json`:

```json
{
  "anthropic": { "type": "api_key", "key": "sk-ant-..." },
  "openai": { "type": "api_key", "key": "sk-..." },
  "prime-inference": { "type": "api_key", "key": "..." },
  "deepseek": { "type": "api_key", "key": "sk-..." },
  "google": { "type": "api_key", "key": "..." },
  "opencode": { "type": "api_key", "key": "..." },
  "opencode-go": { "type": "api_key", "key": "..." },
  "xiaomi": { "type": "api_key", "key": "..." },
  "xiaomi-token-plan-cn":  { "type": "api_key", "key": "..." },
  "xiaomi-token-plan-ams": { "type": "api_key", "key": "..." },
  "xiaomi-token-plan-sgp": { "type": "api_key", "key": "..." }
}
```

Tệp được tạo với quyền `0600` (chỉ người dùng được đọc/ghi). Thông tin xác thực trong tệp xác thực được ưu tiên hơn biến môi trường.

### Phân giải khóa

Trường `key` hỗ trợ ba định dạng:

- **Lệnh shell:** Thực thi `"!command"` và sử dụng stdout (được lưu vào bộ nhớ đệm trong suốt vòng đời tiến trình)
  ```json
  { "type": "api_key", "key": "!security find-generic-password -ws 'anthropic'" }
  { "type": "api_key", "key": "!op read 'op://vault/item/credential'" }
  ```
- **Biến môi trường:** Sử dụng giá trị của biến có tên tương ứng
  ```json
  { "type": "api_key", "key": "MY_ANTHROPIC_KEY" }
  ```
- **Giá trị trực tiếp:** Được sử dụng trực tiếp
  ```json
  { "type": "api_key", "key": "sk-ant-..." }
  ```

Thông tin xác thực OAuth cũng được lưu tại đây sau khi chạy `/login` và được quản lý tự động.

### Prime Inference

Prime Inference sử dụng điểm cuối tương thích với OpenAI tại `https://api.pinference.ai/api/v1`. Thiết lập `PRIME_API_KEY` hoặc lưu khóa API cho `prime-inference` qua `/login`.

## Nhà cung cấp đám mây

### Azure OpenAI

```bash
export AZURE_OPENAI_API_KEY=...
export AZURE_OPENAI_BASE_URL=https://your-resource.openai.azure.com
# also supported: https://your-resource.cognitiveservices.azure.com
# root endpoints are auto-normalized to /openai/v1
# or use resource name instead of base URL
export AZURE_OPENAI_RESOURCE_NAME=your-resource

# Optional
export AZURE_OPENAI_API_VERSION=2024-02-01
export AZURE_OPENAI_DEPLOYMENT_NAME_MAP=gpt-4=my-gpt4,gpt-4o=my-gpt4o
```

### Amazon Bedrock

```bash
# Option 1: AWS Profile
export AWS_PROFILE=your-profile

# Option 2: IAM Keys
export AWS_ACCESS_KEY_ID=AKIA...
export AWS_SECRET_ACCESS_KEY=...

# Option 3: Bearer Token
export AWS_BEARER_TOKEN_BEDROCK=...

# Optional region (defaults to us-east-1)
export AWS_REGION=us-west-2
```

Đồng thời hỗ trợ vai trò tác vụ ECS (`AWS_CONTAINER_CREDENTIALS_*`) và IRSA (`AWS_WEB_IDENTITY_TOKEN_FILE`).

```bash
prime-agent --provider amazon-bedrock --model us.anthropic.claude-sonnet-4-20250514-v1:0
```

Bộ nhớ đệm lời nhắc được tự động bật cho các mô hình Claude có ID chứa tên mô hình nhận diện được (mô hình cơ sở và hồ sơ suy luận do hệ thống định nghĩa). Với hồ sơ suy luận ứng dụng (có ARN không chứa tên mô hình), hãy thiết lập `AWS_BEDROCK_FORCE_CACHE=1` để bật các điểm lưu bộ nhớ đệm:

```bash
export AWS_BEDROCK_FORCE_CACHE=1
prime-agent --provider amazon-bedrock --model arn:aws:bedrock:us-east-1:123456789012:application-inference-profile/abc123
```

Nếu kết nối đến proxy API Bedrock, bạn có thể dùng các biến môi trường sau:

```bash
# Set the URL for the Bedrock proxy (standard AWS SDK env var)
export AWS_ENDPOINT_URL_BEDROCK_RUNTIME=https://my.corp.proxy/bedrock

# Set if your proxy does not require authentication
export AWS_BEDROCK_SKIP_AUTH=1

# Set if your proxy only supports HTTP/1.1
export AWS_BEDROCK_FORCE_HTTP1=1
```

### Cloudflare AI Gateway

Có thể thiết lập `CLOUDFLARE_API_KEY` qua `/login`. ID tài khoản và slug của gateway phải được thiết lập dưới dạng biến môi trường.

```bash
export CLOUDFLARE_API_KEY=...           # or use /login
export CLOUDFLARE_ACCOUNT_ID=...
export CLOUDFLARE_GATEWAY_ID=...        # create at dash.cloudflare.com → AI → AI Gateway
prime-agent --provider cloudflare-ai-gateway --model "claude-sonnet-4-5"
```

Định tuyến đến OpenAI, Anthropic và Workers AI thông qua Cloudflare AI Gateway. Workers AI sử dụng Unified API (`/compat`) và ID mô hình có tiền tố (`workers-ai/@cf/...`). OpenAI sử dụng tuyến chuyển tiếp OpenAI (`/openai`) với ID mô hình OpenAI gốc như `gpt-5.1`. Anthropic sử dụng tuyến chuyển tiếp Anthropic (`/anthropic`) với ID mô hình Anthropic gốc như `claude-sonnet-4-5`.

Xác thực AI Gateway sử dụng `CLOUDFLARE_API_KEY` làm `cf-aig-authorization`. Xác thực dịch vụ thượng nguồn có thể theo một trong các chế độ sau:

| Chế độ | Xác thực yêu cầu | Xác thực dịch vụ thượng nguồn |
|------|--------------|---------------|
| Workers AI | Chỉ token Cloudflare | Cơ chế gốc của Cloudflare |
| Thanh toán hợp nhất | Chỉ token Cloudflare | Cloudflare xử lý xác thực dịch vụ thượng nguồn và khấu trừ tín dụng |
| BYOK được lưu trữ | Chỉ token Cloudflare | Cloudflare chèn các khóa nhà cung cấp được lưu trong bảng điều khiển AI Gateway |
| BYOK nội tuyến | Token Cloudflare cùng tiêu đề `Authorization` của dịch vụ thượng nguồn | Yêu cầu cung cấp khóa của nhà cung cấp thượng nguồn |

Khi sử dụng Prime Agent thông thường, nên ưu tiên thanh toán hợp nhất hoặc BYOK được lưu trữ. BYOK nội tuyến yêu cầu cấu hình thêm tiêu đề `Authorization` của dịch vụ thượng nguồn cho nhà cung cấp Cloudflare AI Gateway, chẳng hạn thông qua cấu hình ghi đè nhà cung cấp/mô hình trong `models.json`.

### Cloudflare Workers AI

Có thể thiết lập `CLOUDFLARE_API_KEY` qua `/login`. `CLOUDFLARE_ACCOUNT_ID` phải được thiết lập dưới dạng biến môi trường.

```bash
export CLOUDFLARE_API_KEY=...           # or use /login
export CLOUDFLARE_ACCOUNT_ID=...
prime-agent --provider cloudflare-workers-ai --model "@cf/moonshotai/kimi-k2.6"
```

Prime Agent tự động thiết lập `x-session-affinity` để hưởng ưu đãi của tính năng [lưu tiền tố vào bộ nhớ đệm](https://developers.cloudflare.com/workers-ai/features/prompt-caching/).

### Google Vertex AI

Sử dụng thông tin xác thực mặc định của ứng dụng:

```bash
gcloud auth application-default login
export GOOGLE_CLOUD_PROJECT=your-project
export GOOGLE_CLOUD_LOCATION=us-central1
```

Hoặc thiết lập `GOOGLE_APPLICATION_CREDENTIALS` trỏ đến tệp khóa của tài khoản dịch vụ.

## Nhà cung cấp tùy chỉnh

**Thông qua models.json:** Thêm Ollama, LM Studio, vLLM hoặc bất kỳ nhà cung cấp nào triển khai API được hỗ trợ (OpenAI Completions, OpenAI Responses, Anthropic Messages, Google Generative AI). Xem [models.md](models.vi.md).

**Thông qua phần mở rộng:** Với các nhà cung cấp cần phần triển khai API hoặc luồng OAuth tùy chỉnh, hãy tạo một phần mở rộng. Xem [custom-provider.md](custom-provider.vi.md) và [examples/extensions/custom-provider-gitlab-duo](../examples/extensions/custom-provider-gitlab-duo/).

## Thứ tự phân giải

Khi phân giải thông tin xác thực cho một nhà cung cấp:

1. Cờ CLI `--api-key`
2. Mục trong `auth.json` (khóa API hoặc token OAuth)
3. Biến môi trường
4. Khóa nhà cung cấp tùy chỉnh từ `models.json`

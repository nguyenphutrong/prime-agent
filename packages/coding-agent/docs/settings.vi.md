# Cài đặt

Prime Agent sử dụng file cài đặt JSON; cài đặt dự án ghi đè cài đặt toàn cục.

| Vị trí | Phạm vi |
|----------|-------|
| `~/.prime/agent/settings.json` | Toàn cục (mọi dự án) |
| `.prime/agent/settings.json` | Dự án (thư mục hiện tại) |

Chỉnh sửa trực tiếp hoặc dùng `/settings` cho các tùy chọn phổ biến.

## Tất cả cài đặt

### Model và suy luận

| Cài đặt | Kiểu | Mặc định | Mô tả |
|---------|------|---------|-------------|
| `defaultProvider` | string | - | Nhà cung cấp mặc định (ví dụ: `"anthropic"`, `"openai"`) |
| `defaultModel` | string | - | ID model mặc định |
| `defaultThinkingLevel` | string | `"xhigh"` | `"off"`, `"minimal"`, `"low"`, `"medium"`, `"high"`, `"xhigh"` |
| `hideThinkingBlock` | boolean | `false` | Ẩn khối suy luận trong đầu ra |
| `thinkingBudgets` | object | - | Ngân sách token tùy chỉnh cho từng cấp độ suy luận |

#### thinkingBudgets

```json
{
  "thinkingBudgets": {
    "minimal": 1024,
    "low": 4096,
    "medium": 10240,
    "high": 32768
  }
}
```

### Giao diện và hiển thị

| Cài đặt | Kiểu | Mặc định | Mô tả |
|---------|------|---------|-------------|
| `theme` | string | `"dark"` | Tên theme (`"dark"`, `"light"` hoặc tùy chỉnh) |
| `quietStartup` | boolean | `false` | Ẩn header khởi động |
| `collapseChangelog` | boolean | `false` | Hiện changelog rút gọn sau khi cập nhật |
| `treeFilterMode` | string | `"user-only"` | Bộ lọc mặc định cho `/tree`: `"default"`, `"no-tools"`, `"user-only"`, `"labeled-only"`, `"all"` |
| `editorPaddingX` | number | `0` | Khoảng đệm ngang của trình soạn thảo nhập liệu (0-3) |
| `autocompleteMaxVisible` | number | `5` | Số mục hiển thị tối đa trong danh sách tự động hoàn thành (3-20) |
| `showHardwareCursor` | boolean | `false` | Hiện con trỏ terminal |

### Kiểm tra cập nhật

Bản dựng ổn định tải manifest phát hành từ `https://pub-728493de92a943e2a9b2d17b4719f318.r2.dev/latest.json`. Bản dựng beta tải `beta.json` và tiếp tục theo dõi các bản cập nhật beta. Ghi đè URL cơ sở bằng `PRIME_AGENT_DOWNLOAD_BASE_URL`.

Đặt `PI_SKIP_VERSION_CHECK=1` để tắt kiểm tra cập nhật phiên bản Prime Agent. Dùng `--offline` hoặc `PI_OFFLINE=1` để tắt các thao tác mạng khi khởi động, gồm kiểm tra cập nhật và kiểm tra cập nhật package.

Manifest ổn định `latest.json` và beta `beta.json` dùng cùng cấu trúc JSON:

```json
{
  "version": "0.73.1",
  "package": "prime-agent",
  "tarball": "releases/v0.73.1/prime-agent-0.73.1.tgz"
}
```

`version` là bắt buộc. `package` là tùy chọn và cũng có thể mang tên `packageName`; giá trị mặc định là tên package hiện tại. `tarball` là tùy chọn; khi có, Prime Agent cài tarball đó thay vì tên package. Đường dẫn tarball tương đối được phân giải theo `PRIME_AGENT_DOWNLOAD_BASE_URL`.

### Cảnh báo

| Cài đặt | Kiểu | Mặc định | Mô tả |
|---------|------|---------|-------------|
| `warnings.anthropicExtraUsage` | boolean | `true` | Hiện cảnh báo khi xác thực bằng gói đăng ký Anthropic có thể phát sinh mức sử dụng trả phí bổ sung |

```json
{
  "warnings": {
    "anthropicExtraUsage": false
  }
}
```

### Nén ngữ cảnh

| Cài đặt | Kiểu | Mặc định | Mô tả |
|---------|------|---------|-------------|
| `compaction.enabled` | boolean | `true` | Bật tự động nén ngữ cảnh |
| `compaction.reserveTokens` | number | `16384` | Số token dành riêng cho phản hồi LLM |
| `compaction.keepRecentTokens` | number | `20000` | Số token gần đây cần giữ lại (không tóm tắt) |

```json
{
  "compaction": {
    "enabled": true,
    "reserveTokens": 16384,
    "keepRecentTokens": 20000
  }
}
```

### Tóm tắt nhánh

| Cài đặt | Kiểu | Mặc định | Mô tả |
|---------|------|---------|-------------|
| `branchSummary.reserveTokens` | number | `16384` | Số token dành riêng để tóm tắt nhánh |
| `branchSummary.skipPrompt` | boolean | `false` | Bỏ qua lời nhắc "Summarize branch?" khi điều hướng `/tree` (mặc định không tóm tắt) |

### Thử lại

| Cài đặt | Kiểu | Mặc định | Mô tả |
|---------|------|---------|-------------|
| `retry.enabled` | boolean | `true` | Bật tự động thử lại ở cấp agent khi gặp lỗi tạm thời |
| `retry.maxRetries` | number | `3` | Số lần thử lại tối đa ở cấp agent |
| `retry.baseDelayMs` | number | `2000` | Độ trễ cơ sở cho exponential backoff ở cấp agent (2s, 4s, 8s) |
| `retry.provider.timeoutMs` | number | Mặc định của SDK | Thời gian chờ request của nhà cung cấp/SDK, tính bằng mili giây |
| `retry.provider.maxRetries` | number | Mặc định của SDK | Số lần thử lại của nhà cung cấp/SDK |
| `retry.provider.maxRetryDelayMs` | number | `60000` | Độ trễ tối đa do server yêu cầu trước khi báo lỗi (60s) |

Khi nhà cung cấp yêu cầu độ trễ thử lại dài hơn `retry.provider.maxRetryDelayMs` (ví dụ: "quota will reset after 5h" của Google), request thất bại ngay với lỗi cung cấp đầy đủ thông tin thay vì âm thầm chờ. Đặt thành `0` để bỏ giới hạn.

```json
{
  "retry": {
    "enabled": true,
    "maxRetries": 3,
    "baseDelayMs": 2000,
    "provider": {
      "timeoutMs": 3600000,
      "maxRetries": 0,
      "maxRetryDelayMs": 60000
    }
  }
}
```

### Phân phối tin nhắn

| Cài đặt | Kiểu | Mặc định | Mô tả |
|---------|------|---------|-------------|
| `steeringMode` | string | `"one-at-a-time"` | Cách gửi tin nhắn điều hướng: `"all"` hoặc `"one-at-a-time"` |
| `followUpMode` | string | `"one-at-a-time"` | Cách gửi tin nhắn tiếp nối: `"all"` hoặc `"one-at-a-time"` |
| `transport` | string | `"sse"` | Transport ưu tiên cho nhà cung cấp hỗ trợ nhiều transport: `"sse"`, `"websocket"` hoặc `"auto"` |

### Terminal và hình ảnh

| Cài đặt | Kiểu | Mặc định | Mô tả |
|---------|------|---------|-------------|
| `terminal.showImages` | boolean | `true` | Hiện kiểu và kích thước ảnh trong terminal |
| `terminal.clearOnShrink` | boolean | `false` | Xóa các hàng trống khi nội dung co lại (có thể gây nhấp nháy) |
| `images.autoResize` | boolean | `true` | Thay đổi kích thước ảnh xuống tối đa 2000x2000 |
| `images.blockImages` | boolean | `false` | Chặn gửi mọi hình ảnh đến LLM |

### Shell

| Cài đặt | Kiểu | Mặc định | Mô tả |
|---------|------|---------|-------------|
| `shellPath` | string | - | Đường dẫn shell tùy chỉnh (ví dụ: cho Cygwin trên Windows) |
| `shellCommandPrefix` | string | - | Tiền tố cho mọi lệnh bash (ví dụ: `"shopt -s expand_aliases"`) |
| `npmCommand` | string[] | - | argv của lệnh dùng cho thao tác tra cứu/cài đặt package npm (ví dụ: `["mise", "exec", "node@20", "--", "npm"]`) |

```json
{
  "npmCommand": ["mise", "exec", "node@20", "--", "npm"]
}
```

`npmCommand` được dùng cho mọi thao tác của trình quản lý package npm, gồm cài đặt, gỡ cài đặt và cài dependency bên trong package git. Dùng các mục theo kiểu argv đúng như cách process cần được khởi chạy. Khi cấu hình `npmCommand`, việc cài dependency của package git dùng `install` thuần để tránh cờ riêng của npm trong wrapper hoặc trình quản lý package thay thế.

Thông thường, vị trí module toàn cục của trình quản lý package được truy vấn bằng `root -g`. Trong trường hợp đặc biệt, nếu phần tử đầu tiên của `npmCommand` là `"bun"`, vị trí module sẽ được truy vấn bằng `pm bin -g`.

### Daemon

| Cài đặt | Kiểu | Mặc định | Mô tả |
|---------|------|---------|-------------|
| `idleEvictionMinutes` | number hoặc `"off"` | `90` | Ngưỡng nhàn rỗi tính bằng phút để loại bỏ worker của toàn cây và passivate từng child nhàn rỗi; `"off"` tắt cả hai. |

`idleEvictionMinutes` là chính sách daemon toàn cục và chỉ được đọc từ `~/.prime/agent/settings.json`. Đặt thành số dương để cấu hình ngưỡng nhàn rỗi.

### Session

| Cài đặt | Kiểu | Mặc định | Mô tả |
|---------|------|---------|-------------|
| `sessionDir` | string | - | Thư mục lưu file session. Chấp nhận đường dẫn tuyệt đối hoặc tương đối, cùng với `~`. |

```json
{ "sessionDir": ".prime/agent/sessions" }
```

Khi nhiều nguồn chỉ định thư mục session, thứ tự ưu tiên là `--session-dir`, `PRIME_AGENT_SESSION_DIR`, biến cũ `PRIME_AGENT_CODING_AGENT_SESSION_DIR`, rồi đến `sessionDir` trong `settings.json`.

### Luân phiên model

| Cài đặt | Kiểu | Mặc định | Mô tả |
|---------|------|---------|-------------|
| `enabledModels` | string[] | - | Mẫu model cho thao tác luân phiên bằng Ctrl+P (cùng định dạng với cờ CLI `--models`) |

```json
{
  "enabledModels": ["claude-*", "gpt-4o", "gemini-2*"]
}
```

### Markdown

| Cài đặt | Kiểu | Mặc định | Mô tả |
|---------|------|---------|-------------|
| `markdown.codeBlockIndent` | string | `"  "` | Khoảng thụt đầu dòng cho khối code |

### Tài nguyên

Các cài đặt này xác định nơi tải extension, skill, prompt và theme.

Đường dẫn trong `~/.prime/agent/settings.json` được phân giải tương đối theo `~/.prime/agent`. Đường dẫn trong `.prime/agent/settings.json` được phân giải tương đối theo `.prime/agent`. Hỗ trợ đường dẫn tuyệt đối và `~`.

| Cài đặt | Kiểu | Mặc định | Mô tả |
|---------|------|---------|-------------|
| `packages` | array | `[]` | Package npm/git để tải tài nguyên |
| `extensions` | string[] | `[]` | Đường dẫn file hoặc thư mục extension cục bộ |
| `skills` | string[] | `[]` | Đường dẫn file hoặc thư mục skill cục bộ |
| `prompts` | string[] | `[]` | Đường dẫn hoặc thư mục template prompt cục bộ |
| `themes` | string[] | `[]` | Đường dẫn file hoặc thư mục theme cục bộ |
| `enableSkillCommands` | boolean | `true` | Đăng ký skill dưới dạng lệnh `/skill:name` |
| `enableBuiltinSkills` | boolean | `true` | Tải skill tích hợp sẵn đi kèm prime-agent |
| `bundledSkills.websearch` | boolean | `true` | Tải skill `websearch` tích hợp sẵn |

Các mảng hỗ trợ mẫu glob và quy tắc loại trừ. Dùng `!pattern` để loại trừ. Dùng `+path` để buộc bao gồm một đường dẫn chính xác và `-path` để buộc loại trừ một đường dẫn chính xác.

Tắt skill `websearch` tích hợp sẵn trong khi vẫn bật khám phá skill thông thường:

```json
{
  "bundledSkills": {
    "websearch": false
  }
}
```

#### packages

Dạng chuỗi tải mọi tài nguyên từ một package:

```json
{
  "packages": ["pi-skills", "@org/my-extension"]
}
```

Dạng object lọc những tài nguyên cần tải:

```json
{
  "packages": [
    {
      "source": "pi-skills",
      "skills": ["brave-search", "transcribe"],
      "extensions": []
    }
  ]
}
```

Xem [packages.vi.md](packages.vi.md) để biết chi tiết về quản lý package.

## Ví dụ

```json
{
  "defaultProvider": "anthropic",
  "defaultModel": "claude-sonnet-4-20250514",
  "defaultThinkingLevel": "xhigh",
  "theme": "dark",
  "compaction": {
    "enabled": true,
    "reserveTokens": 16384,
    "keepRecentTokens": 20000
  },
  "retry": {
    "enabled": true,
    "maxRetries": 3
  },
  "enabledModels": ["claude-*", "gpt-4o"],
  "warnings": {
    "anthropicExtraUsage": true
  },
  "packages": ["pi-skills"]
}
```

## Ghi đè theo dự án

Cài đặt dự án (`.prime/agent/settings.json`) ghi đè cài đặt toàn cục. Các object lồng nhau được hợp nhất:

```json
// ~/.prime/agent/settings.json (global)
{
  "theme": "dark",
  "compaction": { "enabled": true, "reserveTokens": 16384 }
}

// .prime/agent/settings.json (project)
{
  "compaction": { "reserveTokens": 8192 }
}

// Result
{
  "theme": "dark",
  "compaction": { "enabled": true, "reserveTokens": 8192 }
}
```

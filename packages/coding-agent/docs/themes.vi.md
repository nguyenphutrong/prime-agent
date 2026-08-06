> Prime Agent có thể tạo theme. Hãy yêu cầu nó xây dựng một theme phù hợp với thiết lập của bạn.

# Theme

Theme là các file JSON định nghĩa màu sắc cho TUI.

## Mục lục

- [Vị trí](#vị-trí)
- [Chọn theme](#chọn-theme)
- [Tạo theme tùy chỉnh](#tạo-theme-tùy-chỉnh)
- [Định dạng theme](#định-dạng-theme)
- [Token màu](#token-màu)
- [Giá trị màu](#giá-trị-màu)
- [Mẹo](#mẹo)

## Vị trí

Prime Agent tải theme từ:

- Tích hợp sẵn: `dark`, `light`
- Toàn cục: `~/.prime/agent/themes/*.json`
- Dự án: `.prime/agent/themes/*.json`
- Package: thư mục `themes/` hoặc mục `pi.themes` trong `package.json`
- Cài đặt: mảng `themes` chứa file hoặc thư mục
- CLI: `--theme <path>` (có thể lặp lại)

Tắt tính năng khám phá bằng `--no-themes`.

## Chọn theme

Chọn theme qua `/settings` hoặc trong `settings.json`:

```json
{
  "theme": "my-theme"
}
```

Trong lần chạy đầu tiên, Prime Agent phát hiện nền terminal và mặc định dùng `dark` hoặc `light`.

## Tạo theme tùy chỉnh

1. Tạo file theme:

```bash
mkdir -p ~/.prime/agent/themes
vim ~/.prime/agent/themes/my-theme.json
```

2. Định nghĩa theme với tất cả màu bắt buộc (xem [Token màu](#token-màu)):

```json
{
  "$schema": "https://raw.githubusercontent.com/PrimeIntellect-ai/prime-agent/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json",
  "name": "my-theme",
  "vars": {
    "primary": "#00aaff",
    "secondary": 242
  },
  "colors": {
    "accent": "primary",
    "border": "primary",
    "borderAccent": "#00ffff",
    "borderMuted": "secondary",
    "success": "#00ff00",
    "error": "#ff0000",
    "warning": "#ffff00",
    "muted": "secondary",
    "dim": 240,
    "text": "",
    "thinkingText": "secondary",
    "selectedBg": "#2d2d30",
    "userMessageBg": "#2d2d30",
    "userMessageText": "",
    "customMessageBg": "#2d2d30",
    "customMessageText": "",
    "customMessageLabel": "primary",
    "toolPendingBg": "#1e1e2e",
    "toolSuccessBg": "#1e2e1e",
    "toolErrorBg": "#2e1e1e",
    "toolPanelBg": "#2d2d38",
    "toolTitle": "primary",
    "toolOutput": "",
    "mdHeading": "#ffaa00",
    "mdLink": "primary",
    "mdLinkUrl": "secondary",
    "mdCode": "#00ffff",
    "mdCodeBlock": "",
    "mdCodeBlockBorder": "secondary",
    "mdQuote": "secondary",
    "mdQuoteBorder": "secondary",
    "mdHr": "secondary",
    "mdListBullet": "#00ffff",
    "toolDiffAdded": "#00ff00",
    "toolDiffRemoved": "#ff0000",
    "toolDiffContext": "secondary",
    "syntaxComment": "secondary",
    "syntaxKeyword": "primary",
    "syntaxFunction": "#00aaff",
    "syntaxVariable": "#ffaa00",
    "syntaxString": "#00ff00",
    "syntaxNumber": "#ff00ff",
    "syntaxType": "#00aaff",
    "syntaxOperator": "primary",
    "syntaxPunctuation": "secondary",
    "thinkingOff": "secondary",
    "thinkingMinimal": "primary",
    "thinkingLow": "#00aaff",
    "thinkingMedium": "#00ffff",
    "thinkingHigh": "#ff00ff",
    "thinkingXhigh": "#ff0000",
    "bashMode": "#ffaa00"
  }
}
```

3. Chọn theme qua `/settings`.

**Tải lại nóng:** Khi bạn chỉnh sửa file theme tùy chỉnh đang hoạt động, Prime Agent tự động tải lại để phản hồi trực quan ngay lập tức.

## Định dạng theme

```json
{
  "$schema": "https://raw.githubusercontent.com/PrimeIntellect-ai/prime-agent/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json",
  "name": "my-theme",
  "vars": {
    "blue": "#0066cc",
    "gray": 242
  },
  "colors": {
    "accent": "blue",
    "muted": "gray",
    "text": "",
    ...
  }
}
```

- `name` là bắt buộc và phải là duy nhất.
- `vars` là tùy chọn. Định nghĩa màu có thể tái sử dụng tại đây, sau đó tham chiếu chúng trong `colors`.
- `colors` phải định nghĩa đủ 51 token bắt buộc.

Trường `$schema` hỗ trợ tự động hoàn thành và xác thực trong trình soạn thảo.

## Token màu

Mỗi theme phải định nghĩa đủ 51 token màu. Không có màu tùy chọn.

### Giao diện cốt lõi (11 màu)

| Token | Mục đích |
|-------|---------|
| `accent` | Màu nhấn chính (logo, mục đã chọn, con trỏ) |
| `border` | Đường viền thông thường |
| `borderAccent` | Đường viền được làm nổi bật |
| `borderMuted` | Đường viền tinh tế (trình soạn thảo) |
| `success` | Trạng thái thành công |
| `error` | Trạng thái lỗi |
| `warning` | Trạng thái cảnh báo |
| `muted` | Văn bản phụ |
| `dim` | Văn bản cấp ba |
| `text` | Văn bản mặc định (thường là `""`) |
| `thinkingText` | Văn bản khối suy luận |

### Nền và nội dung (12 màu)

| Token | Mục đích |
|-------|---------|
| `selectedBg` | Nền dòng đã chọn |
| `userMessageBg` | Nền tin nhắn người dùng |
| `userMessageText` | Văn bản tin nhắn người dùng |
| `customMessageBg` | Nền tin nhắn extension |
| `customMessageText` | Văn bản tin nhắn extension |
| `customMessageLabel` | Nhãn tin nhắn extension |
| `toolPendingBg` | Hộp công cụ (đang chờ) |
| `toolSuccessBg` | Hộp công cụ (thành công) |
| `toolErrorBg` | Hộp công cụ (lỗi) |
| `toolPanelBg` | Nền bảng công cụ |
| `toolTitle` | Tiêu đề công cụ |
| `toolOutput` | Văn bản đầu ra công cụ |

### Markdown (10 màu)

| Token | Mục đích |
|-------|---------|
| `mdHeading` | Heading |
| `mdLink` | Văn bản liên kết |
| `mdLinkUrl` | URL liên kết |
| `mdCode` | Code nội dòng |
| `mdCodeBlock` | Nội dung khối code |
| `mdCodeBlockBorder` | Hàng rào khối code |
| `mdQuote` | Văn bản trích dẫn khối |
| `mdQuoteBorder` | Đường viền trích dẫn khối |
| `mdHr` | Đường kẻ ngang |
| `mdListBullet` | Dấu đầu dòng |

### Diff công cụ (3 màu)

| Token | Mục đích |
|-------|---------|
| `toolDiffAdded` | Dòng được thêm |
| `toolDiffRemoved` | Dòng bị xóa |
| `toolDiffContext` | Dòng ngữ cảnh |

### Tô sáng cú pháp (9 màu)

| Token | Mục đích |
|-------|---------|
| `syntaxComment` | Chú thích |
| `syntaxKeyword` | Từ khóa |
| `syntaxFunction` | Tên hàm |
| `syntaxVariable` | Biến |
| `syntaxString` | Chuỗi |
| `syntaxNumber` | Số |
| `syntaxType` | Kiểu |
| `syntaxOperator` | Toán tử |
| `syntaxPunctuation` | Dấu câu |

### Viền cấp độ suy luận (6 màu)

Màu viền trình soạn thảo biểu thị cấp độ suy luận (phân cấp trực quan từ nhẹ đến nổi bật):

| Token | Mục đích |
|-------|---------|
| `thinkingOff` | Tắt suy luận |
| `thinkingMinimal` | Suy luận tối thiểu |
| `thinkingLow` | Suy luận thấp |
| `thinkingMedium` | Suy luận trung bình |
| `thinkingHigh` | Suy luận cao |
| `thinkingXhigh` | Suy luận cực cao |

### Chế độ Bash (1 màu)

| Token | Mục đích |
|-------|---------|
| `bashMode` | Viền trình soạn thảo trong chế độ bash (tiền tố `!`) |

### Xuất HTML (tùy chọn)

Phần `export` điều khiển màu cho đầu ra HTML của `/export`. Nếu bỏ qua, màu được suy ra từ `userMessageBg`.

```json
{
  "export": {
    "pageBg": "#18181e",
    "cardBg": "#1e1e24",
    "infoBg": "#3c3728"
  }
}
```

## Giá trị màu

Hỗ trợ bốn định dạng:

| Định dạng | Ví dụ | Mô tả |
|--------|---------|-------------|
| Hex | `"#ff0000"` | RGB hex 6 chữ số |
| 256 màu | `39` | Chỉ mục bảng màu xterm 256 màu (0-255) |
| Biến | `"primary"` | Tham chiếu đến một mục trong `vars` |
| Mặc định | `""` | Màu mặc định của terminal |

### Bảng màu 256 màu

- `0-15`: Màu ANSI cơ bản (phụ thuộc terminal)
- `16-231`: Khối RGB 6×6×6 (`16 + 36×R + 6×G + B`, trong đó R,G,B nằm trong khoảng 0-5)
- `232-255`: Dải thang xám

### Khả năng tương thích terminal

Prime Agent sử dụng màu RGB 24-bit. Hầu hết terminal hiện đại đều hỗ trợ (iTerm2, Kitty, WezTerm, Windows Terminal, VS Code). Với terminal cũ chỉ hỗ trợ 256 màu, Prime Agent dùng màu xấp xỉ gần nhất.

Kiểm tra hỗ trợ truecolor:

```bash
echo $COLORTERM  # Should output "truecolor" or "24bit"
```

## Mẹo

**Terminal tối:** Dùng màu sáng, bão hòa với độ tương phản cao hơn.

**Terminal sáng:** Dùng màu tối, dịu với độ tương phản thấp hơn.

**Hài hòa màu sắc:** Bắt đầu với bảng màu cơ sở (Nord, Gruvbox, Tokyo Night), định nghĩa trong `vars` và tham chiếu nhất quán.

**Kiểm thử:** Kiểm tra theme với nhiều loại tin nhắn, trạng thái công cụ, nội dung markdown và văn bản dài được ngắt dòng.

**VS Code:** Đặt `terminal.integrated.minimumContrastRatio` thành `1` để màu hiển thị chính xác.

## Ví dụ

Xem các theme tích hợp sẵn:
- [dark.json](../src/modes/interactive/theme/dark.json)
- [light.json](../src/modes/interactive/theme/light.json)

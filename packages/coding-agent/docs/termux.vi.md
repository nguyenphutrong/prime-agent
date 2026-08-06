# Thiết lập Termux (Android)

Prime Agent chạy trên Android thông qua [Termux](https://termux.dev/), một trình mô phỏng terminal và môi trường Linux cho Android.

## Điều kiện tiên quyết

1. Cài [Termux](https://github.com/termux/termux-app#installation) từ GitHub hoặc F-Droid (không cài từ Google Play vì phiên bản đó đã lỗi thời)
2. Cài [Termux:API](https://github.com/termux/termux-api#installation) từ GitHub hoặc F-Droid để dùng clipboard và các tích hợp thiết bị khác

## Cài đặt

```bash
# Update packages
pkg update && pkg upgrade

# Install dependencies
pkg install nodejs termux-api git ripgrep

# Clone and install Prime Agent from source
git clone https://github.com/PrimeIntellect-ai/prime-agent.git
cd prime-agent
npm ci

# Run Prime Agent
./prime-agent.sh
```

## Hỗ trợ clipboard

Khi chạy trong Termux, các thao tác clipboard sử dụng `termux-clipboard-set` và `termux-clipboard-get`. Phải cài ứng dụng Termux:API thì các thao tác này mới hoạt động.

Clipboard hình ảnh không được hỗ trợ trên Termux (tính năng dán ảnh bằng `ctrl+v` sẽ không hoạt động).

## Ví dụ AGENTS.md cho Termux

Tạo `~/.prime/agent/AGENTS.md` để giúp agent hiểu môi trường Termux:

```markdown
# Agent Environment: Termux on Android

## Location
- **OS**: Android (Termux terminal emulator)
- **Home**: `/data/data/com.termux/files/home`
- **Prefix**: `/data/data/com.termux/files/usr`
- **Shared storage**: `/storage/emulated/0` (Downloads, Documents, etc.)

## Opening URLs
```bash
termux-open-url "https://example.com"
```

## Opening Files
```bash
termux-open file.pdf          # Opens with default app
termux-open -c image.jpg      # Choose app
```

## Clipboard
```bash
termux-clipboard-set "text"   # Copy
termux-clipboard-get          # Paste
```

## Notifications
```bash
termux-notification -t "Title" -c "Content"
```

## Device Info
```bash
termux-battery-status         # Battery info
termux-wifi-connectioninfo    # WiFi info
termux-telephony-deviceinfo   # Device info
```

## Sharing
```bash
termux-share -a send file.txt # Share file
```

## Other Useful Commands
```bash
termux-toast "message"        # Quick toast popup
termux-vibrate                # Vibrate device
termux-tts-speak "hello"      # Text to speech
termux-camera-photo out.jpg   # Take photo
```

## Notes
- Termux:API app must be installed for `termux-*` commands
- Use `pkg install termux-api` for the command-line tools
- Storage permission needed for `/storage/emulated/0` access
```

## Limitations

- **No image clipboard**: Termux clipboard API only supports text
- **No native binaries**: Some optional native dependencies (like the clipboard module) are unavailable on Android ARM64 and are skipped during installation
- **Storage access**: To access files in `/storage/emulated/0` (Downloads, etc.), run `termux-setup-storage` once to grant permissions

## Troubleshooting

### Clipboard not working

Ensure both apps are installed:
1. Termux (from GitHub or F-Droid)
2. Termux:API (from GitHub or F-Droid)

Then install the CLI tools:
```bash
pkg install termux-api
```

### Bị từ chối quyền truy cập bộ nhớ dùng chung

Chạy một lần để cấp quyền truy cập bộ nhớ:
```bash
termux-setup-storage
```

### Sự cố cài Node.js

Nếu npm bị lỗi, hãy thử xóa cache:
```bash
npm cache clean --force
```

# Thiết lập terminal

Prime Agent sử dụng [giao thức bàn phím Kitty](https://sw.kovidgoyal.net/kitty/keyboard-protocol/) để nhận diện phím bổ trợ một cách ổn định. Hầu hết terminal hiện đại đều hỗ trợ giao thức này, nhưng một số terminal cần được cấu hình.

## Kitty, iTerm2

Hoạt động ngay sau khi cài đặt.

## Ghostty

Thêm vào cấu hình Ghostty của bạn (`~/Library/Application Support/com.mitchellh.ghostty/config` trên macOS, `~/.config/ghostty/config` trên Linux):

```
keybind = alt+backspace=text:\x1b\x7f
```

Các phiên bản Claude Code cũ hơn có thể đã thêm ánh xạ Ghostty sau:

```
keybind = shift+enter=text:\n
```

Ánh xạ này gửi một byte linefeed thô. Trong Prime Agent, byte đó không thể phân biệt với `Ctrl+J`, vì vậy tmux và Prime Agent không còn nhận được sự kiện phím `shift+enter` thực sự.

Nếu lý do duy nhất bạn thêm ánh xạ đó là Claude Code 2.x trở lên, bạn có thể xóa nó, trừ khi muốn dùng Claude Code trong tmux; khi đó ánh xạ Ghostty vẫn cần thiết.

Nếu muốn `Shift+Enter` tiếp tục hoạt động trong tmux qua ánh xạ lại đó, hãy thêm `ctrl+j` vào keybinding `newLine` của Prime Agent trong `~/.prime/agent/keybindings.json`:

```json
{
  "newLine": ["shift+enter", "ctrl+j"]
}
```

## WezTerm

Tạo `~/.wezterm.lua`:

```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()
config.enable_kitty_keyboard = true
return config
```

## VS Code (Terminal tích hợp)

Vị trí của `keybindings.json`:
- macOS: `~/Library/Application Support/Code/User/keybindings.json`
- Linux: `~/.config/Code/User/keybindings.json`
- Windows: `%APPDATA%\\Code\\User\\keybindings.json`

Thêm vào `keybindings.json` để bật `Shift+Enter` cho nhập nhiều dòng:

```json
{
  "key": "shift+enter",
  "command": "workbench.action.terminal.sendSequence",
  "args": { "text": "\u001b[13;2u" },
  "when": "terminalFocus"
}
```

## Windows Terminal

Thêm vào `settings.json` (Ctrl+Shift+, hoặc Settings → Open JSON file) để chuyển tiếp các phím Enter bổ trợ mà Prime Agent sử dụng:

```json
{
  "actions": [
    {
      "command": { "action": "sendInput", "input": "\u001b[13;2u" },
      "keys": "shift+enter"
    },
    {
      "command": { "action": "sendInput", "input": "\u001b[13;3u" },
      "keys": "alt+enter"
    }
  ]
}
```

- `Shift+Enter` chèn một dòng mới.
- Windows Terminal mặc định gán `Alt+Enter` cho chế độ toàn màn hình. Điều đó khiến Prime Agent không nhận được `Alt+Enter` để xếp hàng lời nhắc tiếp theo.
- Ánh xạ lại `Alt+Enter` sang `sendInput` sẽ chuyển tiếp đúng tổ hợp phím đến Prime Agent.

Nếu đã có mảng `actions`, hãy thêm các đối tượng trên vào mảng đó. Nếu hành vi toàn màn hình cũ vẫn còn, hãy đóng hoàn toàn rồi mở lại Windows Terminal.

## xfce4-terminal, terminator

Các terminal này hỗ trợ chuỗi thoát hạn chế. Không thể phân biệt các phím Enter bổ trợ như `Ctrl+Enter` và `Shift+Enter` với `Enter` thông thường, nên các keybinding tùy chỉnh như `submit: ["ctrl+enter"]` sẽ không hoạt động.

Để có trải nghiệm tốt nhất, hãy dùng terminal hỗ trợ giao thức bàn phím Kitty:
- [Kitty](https://sw.kovidgoyal.net/kitty/)
- [Ghostty](https://ghostty.org/)
- [WezTerm](https://wezfurlong.org/wezterm/)
- [iTerm2](https://iterm2.com/)
- [Alacritty](https://github.com/alacritty/alacritty) (cần biên dịch với hỗ trợ giao thức Kitty)

## IntelliJ IDEA (Terminal tích hợp)

Terminal tích hợp có hỗ trợ chuỗi thoát hạn chế. Không thể phân biệt `Shift+Enter` với `Enter` trong terminal của IntelliJ.

Nếu muốn con trỏ phần cứng hiển thị, hãy đặt `PI_HARDWARE_CURSOR=1` trước khi chạy `prime-agent` (mặc định tắt để tương thích).

Hãy cân nhắc dùng trình mô phỏng terminal chuyên dụng để có trải nghiệm tốt nhất.

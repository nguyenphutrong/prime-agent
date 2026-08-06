# Thiết lập tmux

Prime Agent hoạt động bên trong tmux, nhưng theo mặc định tmux loại bỏ thông tin phím bổ trợ khỏi một số phím. Nếu không cấu hình, `Shift+Enter` và `Ctrl+Enter` thường không thể phân biệt với `Enter` thông thường.

## Cấu hình khuyến nghị

Thêm vào `~/.tmux.conf`:

```tmux
set -g extended-keys on
set -g extended-keys-format csi-u
```

Sau đó khởi động lại hoàn toàn tmux:

```bash
tmux kill-server
tmux
```

Prime Agent tự động yêu cầu báo cáo phím mở rộng khi giao thức bàn phím Kitty không khả dụng. Với `extended-keys-format csi-u`, tmux chuyển tiếp các phím bổ trợ theo định dạng CSI-u, đây là cấu hình đáng tin cậy nhất.

## Vì sao khuyến nghị `csi-u`

Chỉ với:

```tmux
set -g extended-keys on
```

tmux mặc định dùng `extended-keys-format xterm`. Khi một ứng dụng yêu cầu báo cáo phím mở rộng, các phím bổ trợ được chuyển tiếp theo định dạng `modifyOtherKeys` của xterm, chẳng hạn như:

- `Ctrl+C` → `\x1b[27;5;99~`
- `Ctrl+D` → `\x1b[27;5;100~`
- `Ctrl+Enter` → `\x1b[27;5;13~`

Với `extended-keys-format csi-u`, các phím tương tự được chuyển tiếp như sau:

- `Ctrl+C` → `\x1b[99;5u`
- `Ctrl+D` → `\x1b[100;5u`
- `Ctrl+Enter` → `\x1b[13;5u`

Prime Agent hỗ trợ cả hai định dạng, nhưng `csi-u` là cấu hình tmux được khuyến nghị.

## Vấn đề được khắc phục

Nếu không có phím mở rộng của tmux, các phím Enter bổ trợ sẽ bị gộp thành các chuỗi cũ:

| Phím | Không có extkeys | Với `csi-u` |
|-----|-----------------|--------------|
| Enter | `\r` | `\r` |
| Shift+Enter | `\r` | `\x1b[13;2u` |
| Ctrl+Enter | `\r` | `\x1b[13;5u` |
| Alt/Option+Enter | `\x1b\r` | `\x1b[13;3u` |

Điều này ảnh hưởng đến các phím tắt mặc định (`Enter` để gửi, `Shift+Enter` để xuống dòng) và mọi phím tắt tùy chỉnh sử dụng Enter bổ trợ.

## Yêu cầu

- tmux 3.2 trở lên (chạy `tmux -V` để kiểm tra)
- Trình mô phỏng thiết bị đầu cuối hỗ trợ phím mở rộng (Ghostty, Kitty, iTerm2, WezTerm, Windows Terminal)

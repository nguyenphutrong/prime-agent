# Phiên

Prime Agent lưu các cuộc hội thoại dưới dạng phiên để bạn có thể tiếp tục làm việc, phân nhánh từ các lượt trước đó và truy cập lại các đường dẫn trước đó.

## Lưu trữ phiên

Phiên tự động lưu vào `~/.prime/agent/sessions/`. Mỗi phiên là một tệp JSONL có cấu trúc cây.

```bash
prime-agent --continue          # Continue the most recent session
prime-agent --resume [path|id]  # Browse past sessions or resume one directly
prime-agent --no-session        # Ephemeral mode; do not save
prime-agent --fork <path|id>    # Fork a session file or partial session ID into a new session
```

Sử dụng `/session` ở chế độ tương tác để xem tệp phiên hiện tại, ID phiên và số lượng tin nhắn. Sử dụng `/usage` để sử dụng token, chi phí và ngữ cảnh.

Để biết định dạng tệp JSONL và SessionManager API, hãy xem [Định dạng phiên](session-format.vi.md).

## Lệnh phiên

| Lệnh | Mô tả |
|---------|-------------|
| `/resume` | Duyệt và chọn các phiên trước |
| `/new` | Bắt đầu một phiên mới |
| `/name <name>` | Đặt tên hiển thị phiên hiện tại |
| `/session` | Hiển thị thông tin phiên |
| `/usage` | Hiển thị token, chi phí và cách sử dụng ngữ cảnh |
| `/tree` | Điều hướng cây phiên hiện tại |
| `/fork` | Tạo phiên mới từ tin nhắn của người dùng trước đó |
| `/clone` | Sao chép nhánh đang hoạt động hiện tại vào một phiên mới |
| `/compact [prompt]` | Tóm tắt bối cảnh cũ hơn; xem [Nén](compaction.vi.md) |
| `/export [file]` | Xuất phiên sang HTML |
| `/share` | Tải lên dưới dạng GitHub gist riêng tư với liên kết HTML có thể chia sẻ |

## Tiếp tục và xóa phiên

`/resume` mở bộ chọn phiên tương tác cho dự án hiện tại. `prime-agent --resume` mở cùng một bộ chọn khi khởi động và `prime-agent --resume <path|id>` tiếp tục một phiên cụ thể.

ID không hợp lệ thoát ra với ID phiên rõ ràng gần nhất khi có sẵn. Để mở bộ chọn và gửi lời nhắc ban đầu sau khi chọn một phiên, hãy tách lời nhắc bằng `--`: `prime-agent --resume -- "continue this work"`.

Trong bộ chọn bạn có thể:

- tìm kiếm bằng cách gõ
- chuyển đổi hiển thị đường dẫn bằng Ctrl+P
- chuyển đổi chế độ sắp xếp bằng Ctrl+S
- lọc các phiên được đặt tên bằng Ctrl+N
- đổi tên bằng Ctrl+R
- xóa bằng Ctrl+D, sau đó xác nhận

Khi khả dụng, Prime Agent sử dụng `trash` CLI để xóa thay vì xóa vĩnh viễn các tệp.

## Phiên đặt tên

Sử dụng `/name <name>` để đặt tên phiên mà con người có thể đọc được:

```text
/name Refactor auth module
```

Các phiên được đặt tên dễ tìm thấy hơn trong `/resume` và `prime-agent --resume`.

## Phân nhánh với `/tree`

Phiên được lưu trữ dưới dạng cây. Mỗi mục có `id` và `parentId` và vị trí hiện tại là lá đang hoạt động. `/tree` cho phép bạn chuyển đến bất kỳ điểm nào trước đó và tiếp tục từ đó mà không cần tạo tệp mới.

<p align="center"><img src="images/tree-view.png" alt="Chế độ xem cây" width="600"></p>

Hình dạng ví dụ:

```text
├─ user: "Hello, can you help..."
│  └─ assistant: "Of course! I can..."
│     ├─ user: "Let's try approach A..."
│     │  └─ assistant: "For approach A..."
│     │     └─ user: "That worked..."  ← active
│     └─ user: "Actually, approach B..."
│        └─ assistant: "For approach B..."
```

### Kiểm soát cây

| Phím | Hành động |
|-----|--------|
| ↑/↓ | Điều hướng các mục hiển thị |
| ←/→ | Trang lên/xuống |
| Ctrl+←/Ctrl+→ hoặc Alt+←/Alt+→ | Gấp/mở hoặc nhảy giữa các đoạn nhánh |
| Shift+L | Đặt hoặc xóa nhãn trên mục đã chọn |
| Shift+T | Chuyển đổi dấu thời gian của nhãn |
| Enter | Chọn mục |
| Escape/Ctrl+C | Hủy bỏ |
| Ctrl+O | Chuyển qua các chế độ lọc |

Các chế độ lọc là: mặc định, không có công cụ, chỉ dành cho người dùng, chỉ được gắn nhãn và tất cả. Định cấu hình mặc định với `treeFilterMode` trong [Cài đặt](settings.vi.md).

### Hành vi lựa chọn

Chọn người dùng hoặc tin nhắn tùy chỉnh:

1. Di chuyển nút lá đến nút cha của thông điệp đã chọn.
2. Đặt nội dung tin nhắn đã chọn vào trình chỉnh sửa.
3. Cho phép bạn chỉnh sửa và gửi lại, tạo một nhánh mới.

Chọn một trợ lý, công cụ, nén hoặc mục nhập không phải của người dùng khác:

1. Di chuyển lá tới mục đó.
2. Để trống trình soạn thảo.
3. Cho phép bạn tiếp tục từ thời điểm đó.

Việc chọn thông báo của người dùng gốc sẽ đặt lại lá về cuộc trò chuyện trống và đặt lời nhắc ban đầu vào trình chỉnh sửa.

## `/tree`, `/fork` và `/clone`

| Tính năng | `/tree` | `/fork` | `/clone` |
|---------|---------|---------|----------|
| Đầu ra | Cùng một tệp phiên | Tệp phiên mới | Tệp phiên mới |
| Xem | Toàn cây | Bộ chọn tin nhắn của người dùng | Nhánh đang hoạt động hiện tại |
| Sử dụng điển hình | Khám phá các lựa chọn thay thế tại chỗ | Bắt đầu phiên mới từ lời nhắc trước đó | Sao chép công việc hiện tại trước khi tiếp tục |
| Tóm tắt | Tóm tắt nhánh tùy chọn | Không có | Không có |

Sử dụng `/tree` khi bạn muốn giữ các lựa chọn thay thế cùng nhau. Sử dụng `/fork` hoặc `/clone` khi bạn muốn có một tệp phiên riêng biệt.

## Tóm tắt nhánh

Khi `/tree` chuyển từ nhánh này sang nhánh khác, Prime Agent có thể tóm tắt nhánh bị bỏ rơi và đính kèm bản tóm tắt đó vào vị trí mới. Điều này bảo tồn bối cảnh quan trọng từ đường dẫn bạn đã rời đi mà không phát lại toàn bộ nhánh.

Khi được nhắc, hãy chọn một trong:

1. không có tóm tắt
2. tóm tắt bằng lời nhắc mặc định
3. tóm tắt với hướng dẫn tập trung tùy chỉnh

Xem [Nén](compaction.vi.md) để biết cơ chế tóm tắt nhánh và các hook mở rộng.

## Định dạng phiên

Các tệp phiên là JSONL và chứa các mục nhập thông báo, thay đổi mô hình, thay đổi ở cấp độ tư duy, nhãn, rút ​​gọn, tóm tắt nhánh và mục mở rộng.

Để biết trình phân tích cú pháp, tiện ích mở rộng, cách sử dụng SDK và SessionManager API đầy đủ, hãy xem [Định dạng phiên](session-format.vi.md).

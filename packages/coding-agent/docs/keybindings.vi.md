# Phím tắt

Bạn có thể tùy chỉnh mọi phím tắt qua `~/.prime/agent/keybindings.json`. Mỗi hành động có thể được gán cho một hoặc nhiều phím.

File cấu hình sử dụng cùng các id phím tắt có namespace mà Prime Agent dùng nội bộ và tác giả extension dùng trong `keyHint()` cũng như các trình quản lý `keybindings` được inject.

Các cấu hình cũ dùng id chưa có namespace như `cursorUp` hoặc `expandTools` sẽ tự động được chuyển sang id có namespace khi khởi động.

Sau khi chỉnh sửa `keybindings.json`, chạy `/reload` trong Prime Agent để áp dụng thay đổi mà không cần khởi động lại session.

## Định dạng phím

`modifier+key`, trong đó modifier là `ctrl`, `shift`, `alt` (có thể kết hợp), còn phím gồm:

- **Chữ cái:** `a-z`
- **Chữ số:** `0-9`
- **Phím đặc biệt:** `escape`, `esc`, `enter`, `return`, `tab`, `space`, `backspace`, `delete`, `insert`, `clear`, `home`, `end`, `pageUp`, `pageDown`, `up`, `down`, `left`, `right`
- **Phím chức năng:** `f1`-`f12`
- **Ký hiệu:** `` ` ``, `-`, `=`, `[`, `]`, `\`, `;`, `'`, `,`, `.`, `/`, `!`, `@`, `#`, `$`, `%`, `^`, `&`, `*`, `(`, `)`, `_`, `+`, `|`, `~`, `{`, `}`, `:`, `<`, `>`, `?`

Các tổ hợp modifier: `ctrl+shift+x`, `alt+ctrl+x`, `ctrl+shift+alt+x`, `ctrl+1`, v.v.

## Tất cả hành động

### Di chuyển con trỏ trong trình soạn thảo TUI

| Id phím tắt | Mặc định | Mô tả |
|--------|---------|-------------|
| `tui.editor.cursorUp` | `up` | Di chuyển con trỏ lên |
| `tui.editor.cursorDown` | `down` | Di chuyển con trỏ xuống |
| `tui.editor.cursorLeft` | `left`, `ctrl+b` | Di chuyển con trỏ sang trái |
| `tui.editor.cursorRight` | `right`, `ctrl+f` | Di chuyển con trỏ sang phải |
| `tui.editor.cursorWordLeft` | `alt+left`, `ctrl+left`, `alt+b` | Di chuyển con trỏ sang từ bên trái |
| `tui.editor.cursorWordRight` | `alt+right`, `ctrl+right`, `alt+f` | Di chuyển con trỏ sang từ bên phải |
| `tui.editor.cursorLineStart` | `home`, `ctrl+a` | Di chuyển đến đầu dòng |
| `tui.editor.cursorLineEnd` | `end`, `ctrl+e` | Di chuyển đến cuối dòng |
| `tui.editor.jumpForward` | `ctrl+]` | Nhảy tới ký tự về phía trước |
| `tui.editor.jumpBackward` | `ctrl+alt+]` | Nhảy tới ký tự về phía sau |
| `tui.editor.pageUp` | `pageUp` | Cuộn lên một trang |
| `tui.editor.pageDown` | `pageDown` | Cuộn xuống một trang |

### Xóa trong trình soạn thảo TUI

| Id phím tắt | Mặc định | Mô tả |
|--------|---------|-------------|
| `tui.editor.deleteCharBackward` | `backspace` | Xóa ký tự phía trước con trỏ |
| `tui.editor.deleteCharForward` | `delete`, `ctrl+d` | Xóa ký tự phía sau con trỏ |
| `tui.editor.deleteWordBackward` | `ctrl+w`, `alt+backspace` | Xóa từ phía trước con trỏ |
| `tui.editor.deleteWordForward` | `alt+d`, `alt+delete` | Xóa từ phía sau con trỏ |
| `tui.editor.deleteToLineStart` | `ctrl+u` | Xóa đến đầu dòng |
| `tui.editor.deleteToLineEnd` | `ctrl+k` | Xóa đến cuối dòng |

### Nhập liệu TUI

| Id phím tắt | Mặc định | Mô tả |
|--------|---------|-------------|
| `tui.input.newLine` | `shift+enter` | Chèn dòng mới |
| `tui.input.submit` | `enter` | Gửi nội dung nhập |
| `tui.input.tab` | `tab` | Tab / tự động hoàn thành |

### Kill ring của TUI

| Id phím tắt | Mặc định | Mô tả |
|--------|---------|-------------|
| `tui.editor.yank` | `ctrl+y` | Dán văn bản vừa xóa gần nhất |
| `tui.editor.yankPop` | `alt+y` | Duyệt vòng qua văn bản đã xóa sau khi yank |
| `tui.editor.undo` | `ctrl+-` | Hoàn tác lần chỉnh sửa gần nhất |

### Clipboard và vùng chọn của TUI

| Id phím tắt | Mặc định | Mô tả |
|--------|---------|-------------|
| `tui.input.copy` | `ctrl+c` | Sao chép vùng chọn |
| `tui.select.up` | `up` | Di chuyển vùng chọn lên |
| `tui.select.down` | `down` | Di chuyển vùng chọn xuống |
| `tui.select.pageUp` | `pageUp` | Lên một trang trong danh sách |
| `tui.select.pageDown` | `pageDown` | Xuống một trang trong danh sách |
| `tui.select.confirm` | `enter` | Xác nhận lựa chọn |
| `tui.select.cancel` | `escape`, `ctrl+c` | Hủy lựa chọn |

### Bản ghi toàn màn hình của TUI

| Id phím tắt | Mặc định | Mô tả |
|--------|---------|-------------|
| `tui.viewport.pageUp` | `pageUp` | Cuộn bản ghi lên một trang |
| `tui.viewport.pageDown` | `pageDown` | Cuộn bản ghi xuống một trang |
| `tui.viewport.top` | `shift+alt+up` | Cuộn bản ghi lên đầu |
| `tui.viewport.follow` | `ctrl+shift+down` | Cuộn xuống cuối và theo dõi đầu ra |

### Ứng dụng

| Id phím tắt | Mặc định | Mô tả |
|--------|---------|-------------|
| `app.interrupt` | *(không có)* | Ngắt thao tác hiện tại |
| `app.clear` | `ctrl+c` | Ngắt thao tác hiện tại, sau đó thoát |
| `app.input.clear` | `escape` | Xóa nội dung nhập |
| `app.exit` | `ctrl+d` | Thoát (khi trình soạn thảo trống) |
| `app.suspend` | `ctrl+z` (không có trên Windows) | Tạm dừng xuống nền |
| `app.editor.external` | `ctrl+g` | Mở trong trình soạn thảo ngoài (`$VISUAL` hoặc `$EDITOR`) |
| `app.clipboard.pasteImage` | `ctrl+v` (`alt+v` trên Windows) | Dán ảnh từ clipboard |

### Session

| Id phím tắt | Mặc định | Mô tả |
|--------|---------|-------------|
| `app.session.new` | *(không có)* | Bắt đầu session mới (`/new`) |
| `app.session.tree` | *(không có)* | Mở trình điều hướng cây session (`/tree`) |
| `app.session.fork` | *(không có)* | Fork session hiện tại (`/fork`) |
| `app.session.resume` | *(không có)* | Mở trình chọn tiếp tục session (`/resume`) |

### Model và suy luận

| Id phím tắt | Mặc định | Mô tả |
|--------|---------|-------------|
| `app.model.select` | `ctrl+l` | Mở trình chọn model |
| `app.model.toggleScope` | `alt+s` | Chuyển đổi giữa tất cả model và model trong phạm vi |
| `app.thinking.toggle` | `ctrl+t` | Thu gọn hoặc mở rộng khối suy luận |

### Menu cấu hình

Dùng `tab` để chuyển tiếp và `shift+tab` để chuyển lùi qua Nhà cung cấp, Model và Kết nối MCP. Dùng `escape` để đóng menu. Phím trái và phải di chuyển con trỏ trong trường tìm kiếm đang hoạt động.

| Id phím tắt | Mặc định | Mô tả |
|--------|---------|-------------|
| `app.configuration.previousTab` | `shift+tab` | Chọn tab cấu hình trước đó |

### Hiển thị và hàng đợi tin nhắn

| Id phím tắt | Mặc định | Mô tả |
|--------|---------|-------------|
| `app.tools.expand` | `ctrl+o` | Thu gọn hoặc mở rộng đầu ra của công cụ |
| `app.message.followUp` | `alt+enter` | Đưa tin nhắn tiếp nối vào hàng đợi |
| `app.message.dequeue` | `alt+up` | Khôi phục tin nhắn trong hàng đợi vào trình soạn thảo |

### Điều hướng cây

| Id phím tắt | Mặc định | Mô tả |
|--------|---------|-------------|
| `app.tree.foldOrUp` | `ctrl+left`, `alt+left` | Thu gọn đoạn nhánh hiện tại hoặc nhảy đến đầu đoạn trước |
| `app.tree.unfoldOrDown` | `ctrl+right`, `alt+right` | Mở đoạn nhánh hiện tại hoặc nhảy đến đầu đoạn tiếp theo hay cuối nhánh |
| `app.tree.editLabel` | `shift+l` | Sửa nhãn trên node cây đã chọn |
| `app.tree.toggleLabelTimestamp` | `shift+t` | Bật/tắt timestamp của nhãn trong cây |
| `app.tree.filter.default` | `ctrl+d` | Đặt bộ lọc cây về chế độ xem mặc định |
| `app.tree.filter.noTools` | `ctrl+t` | Bật/tắt bộ lọc ẩn kết quả công cụ |
| `app.tree.filter.userOnly` | `ctrl+u` | Bật/tắt bộ lọc chỉ hiện tin nhắn người dùng |
| `app.tree.filter.labeledOnly` | `ctrl+l` | Bật/tắt bộ lọc chỉ hiện mục có nhãn |
| `app.tree.filter.all` | `ctrl+a` | Bật/tắt bộ lọc hiện tất cả mục |
| `app.tree.filter.cycleForward` | `ctrl+o` | Duyệt bộ lọc cây theo chiều tiến |
| `app.tree.filter.cycleBackward` | `shift+ctrl+o` | Duyệt bộ lọc cây theo chiều lùi |

### Trình chọn model trong phạm vi

Được dùng trong trình chọn model trong phạm vi (mở bằng `/scoped-models`).

| Id phím tắt | Mặc định | Mô tả |
|--------|---------|-------------|
| `app.models.save` | `ctrl+s` | Lưu lựa chọn model hiện tại vào cài đặt |
| `app.models.enableAll` | `ctrl+a` | Bật tất cả model (hoặc tất cả model khớp tìm kiếm hiện tại) |
| `app.models.clearAll` | `ctrl+x` | Xóa tất cả model (hoặc tất cả model khớp tìm kiếm hiện tại) |
| `app.models.toggleProvider` | `ctrl+p` | Bật/tắt tất cả model của nhà cung cấp hiện tại |
| `app.models.reorderUp` | `alt+up` | Di chuyển model đã chọn lên trong thứ tự luân phiên |
| `app.models.reorderDown` | `alt+down` | Di chuyển model đã chọn xuống trong thứ tự luân phiên |

## Cấu hình tùy chỉnh

Tạo `~/.prime/agent/keybindings.json`:

```json
{
  "tui.editor.cursorUp": ["up", "ctrl+p"],
  "tui.editor.cursorDown": ["down", "ctrl+n"],
  "tui.editor.deleteWordBackward": ["ctrl+w", "alt+backspace"]
}
```

Mỗi hành động có thể nhận một phím hoặc một mảng phím. Cấu hình người dùng ghi đè giá trị mặc định.

Trên Windows native, `app.suspend` không có phím mặc định vì terminal Windows không hỗ trợ điều khiển job của Unix. Nếu gán thủ công, Prime Agent sẽ hiện thông báo trạng thái thay vì tạm dừng. Trong WSL, hành vi `ctrl+z`/`fg` thông thường của Linux vẫn được áp dụng.

### Ví dụ Emacs

```json
{
  "tui.editor.cursorUp": ["up", "ctrl+p"],
  "tui.editor.cursorDown": ["down", "ctrl+n"],
  "tui.editor.cursorLeft": ["left", "ctrl+b"],
  "tui.editor.cursorRight": ["right", "ctrl+f"],
  "tui.editor.cursorWordLeft": ["alt+left", "alt+b"],
  "tui.editor.cursorWordRight": ["alt+right", "alt+f"],
  "tui.editor.deleteCharForward": ["delete", "ctrl+d"],
  "tui.editor.deleteCharBackward": ["backspace", "ctrl+h"],
  "tui.input.newLine": ["shift+enter", "ctrl+j"]
}
```

### Ví dụ Vim

```json
{
  "tui.editor.cursorUp": ["up", "alt+k"],
  "tui.editor.cursorDown": ["down", "alt+j"],
  "tui.editor.cursorLeft": ["left", "alt+h"],
  "tui.editor.cursorRight": ["right", "alt+l"],
  "tui.editor.cursorWordLeft": ["alt+left", "alt+b"],
  "tui.editor.cursorWordRight": ["alt+right", "alt+w"]
}
```

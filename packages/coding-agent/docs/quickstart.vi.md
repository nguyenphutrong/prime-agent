# Bắt đầu nhanh

Trang này hướng dẫn bạn đi từ bước cài đặt đến phiên Prime Agent đầu tiên hữu ích.

## Cài đặt

Cài đặt bản phát hành ổn định mới nhất trên Linux hoặc macOS:

```bash
curl -fsSL https://app.primeintellect.ai/prime-agent/install.sh | sh
```

Để thử bản beta mới nhất được build từ `main`:

```bash
curl -fsSL https://app.primeintellect.ai/prime-agent/install.sh | sh -s -- beta
```

Cả hai lệnh đều tải các artifact phát hành Prime Agent có phiên bản và cài đặt lệnh `prime-agent`. Các mã định danh workspace npm kế thừa trong cây mã nguồn không phải là đường dẫn cài đặt công khai.

Sau đó khởi động Prime Agent trong thư mục dự án mà bạn muốn nó làm việc:

```bash
cd /path/to/project
prime-agent
```

Để chạy bản checkout mã nguồn, hãy dùng Node.js 22.8.0 trở lên:

```bash
git clone https://github.com/PrimeIntellect-ai/prime-agent
cd prime-agent
npm ci
./prime-agent.sh
```

Trình chạy mã nguồn giữ nguyên thư mục nơi nó được gọi, vì vậy bạn cũng có thể gọi `/path/to/prime-agent/prime-agent.sh` từ một dự án khác.

## Xác thực

Prime Agent có thể dùng các nhà cung cấp qua gói thuê bao bằng `/login`, hoặc các nhà cung cấp dùng API key qua biến môi trường hay tệp auth.

### Tùy chọn 1: Đăng nhập bằng gói thuê bao

Khởi động Prime Agent và chạy:

```text
/login
```

Sau đó chọn một nhà cung cấp. Các đăng nhập gói thuê bao tích hợp gồm Claude Pro/Max, ChatGPT Plus/Pro (Codex) và GitHub Copilot.

### Tùy chọn 2: API key

Đặt API key trước khi khởi động Prime Agent:

```bash
export ANTHROPIC_API_KEY=sk-ant-...
prime-agent
```

Bạn cũng có thể chạy `/login` và chọn nhà cung cấp dùng API key để lưu key vào `~/.prime/agent/auth.json`.

Xem [Các nhà cung cấp](providers.vi.md) để biết tất cả nhà cung cấp được hỗ trợ, biến môi trường và cách thiết lập nhà cung cấp đám mây.

## Phiên đầu tiên

Khi Prime Agent khởi động, hãy nhập yêu cầu rồi nhấn Enter:

```text
Summarize this repository and tell me how to run its checks.
```

Prime Agent cung cấp cho model một công cụ tích hợp là `ipython`. Kernel tồn tại lâu dài này là môi trường điều khiển để đọc và chỉnh sửa tệp, chạy lệnh dự án, kiểm tra dữ liệu, duy trì trạng thái Python và gọi các skill đã cài đặt. Runtime kernel được tự động bootstrap khi dùng lần đầu; đặt `PRIME_AGENT_KERNEL_PYTHON` để dùng một môi trường Python có sẵn với `ipykernel`.

Prime Agent chạy trong thư mục làm việc hiện tại và có thể sửa các tệp ở đó. Hãy dùng git hoặc một quy trình tạo checkpoint khác nếu bạn muốn dễ dàng hoàn tác.

## Subagent đệ quy

Subagent đệ quy là khả năng tích hợp của Prime Agent. Model tạo công việc độc lập từ IPython bằng `await rlm("subtask")`; mỗi lần gọi trả về khi tác vụ được tiếp nhận, kèm một child handle, và không bao giờ trả về câu trả lời. Các child gửi kết quả được yêu cầu dưới dạng reply `agent_message` rõ ràng cho parent hoặc ghi chúng vào tệp. Child agent dùng cùng TypeScript agent runtime, provider, tool, skill và cơ chế session như parent.

Bạn có thể yêu cầu model dùng trực tiếp khả năng này:

```text
Review authentication and test coverage as independent subtasks. Run them in parallel, then synthesize the findings.
```

Xem [Kiến trúc RLM Runtime](rlm-runtime.vi.md) để biết API và mô hình thực thi.

## Cung cấp hướng dẫn dự án cho Prime Agent

Prime Agent tải các tệp ngữ cảnh khi khởi động. Thêm tệp `AGENTS.md` để hướng dẫn nó làm việc trong một dự án:

```markdown
# Project Instructions

- Run `npm run check` after code changes.
- Do not run production migrations locally.
- Keep responses concise.
```

Prime Agent tải:

- `~/.prime/agent/AGENTS.md` cho hướng dẫn toàn cục
- `AGENTS.md` hoặc `CLAUDE.md` từ các thư mục cha và thư mục hiện tại

Khởi động lại Prime Agent hoặc chạy `/reload` sau khi thay đổi các tệp ngữ cảnh.

## Một số việc thường thử

### Tham chiếu tệp

Nhập `@` trong trình soạn thảo để tìm kiếm tệp mờ, hoặc truyền tệp trên dòng lệnh:

```bash
prime-agent @README.md "Summarize this"
prime-agent @src/app.ts @src/app.test.ts "Review these together"
```

Có thể dán ảnh bằng Ctrl+V (Alt+V trên Windows) hoặc kéo ảnh vào các terminal được hỗ trợ.

### Chạy lệnh shell

Trong chế độ tương tác:

```text
!npm run lint
```

Kết quả lệnh được gửi cho model. Dùng `!!command` để chạy lệnh mà không thêm kết quả vào ngữ cảnh model. Trong lúc agent làm việc, model thường chạy lệnh dự án từ môi trường điều khiển IPython bằng một ô `%%bash`.

### Chuyển model

Dùng `/model` hoặc Ctrl+L để chọn model. Dùng `/effort` để đặt mức suy luận. Dùng Ctrl+P / Shift+Ctrl+P để chuyển qua các model theo phạm vi.

### Tiếp tục sau

Session được tự động lưu dưới `~/.prime/agent/sessions/`:

```bash
prime-agent -c                  # Continue the most recent session
prime-agent -r [path|id]        # Browse sessions or open a specific session
```

Bên trong Prime Agent, dùng `/resume`, `/new`, `/tree`, `/fork` và `/clone` để quản lý session. Session bền vững chạy trong worker process, vì vậy đóng TUI sẽ tách khỏi agent chứ không nhất thiết dừng agent. Dùng `prime-agent agents` để kiểm tra hoặc kết nối lại các agent đang hoạt động.

### Chế độ không tương tác

Đối với prompt một lần:

```bash
prime-agent -p "Summarize this codebase"
cat README.md | prime-agent -p "Summarize this text"
prime-agent -p @screenshot.png "What's in this image?"
```

Dùng `--mode json` để xuất sự kiện JSON hoặc `--mode rpc` để tích hợp tiến trình.

## Bước tiếp theo

- [Sử dụng Prime Agent](usage.vi.md) - chế độ tương tác, lệnh slash, session, tệp ngữ cảnh và tham chiếu CLI.
- [Các nhà cung cấp](providers.vi.md) - xác thực và thiết lập model.
- [Cài đặt](settings.vi.md) - cấu hình toàn cục và dự án.
- [Phím tắt](keybindings.vi.md) - phím tắt và tùy chỉnh.
- [Các package của Prime Agent](packages.vi.md) - cài đặt extension, skill, prompt và theme dùng chung.

Ghi chú theo nền tảng: [Windows](windows.vi.md), [Termux](termux.vi.md), [tmux](tmux.vi.md), [Thiết lập terminal](terminal-setup.vi.md), [Bí danh shell](shell-aliases.vi.md).

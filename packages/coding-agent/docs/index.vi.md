# Tài liệu Prime Agent

Prime Agent là một harness nghiên cứu và lập trình dựa trên RLM, được xây dựng dựa trên hạt nhân IPython bền vững, các tác nhân phụ đệ quy, các phiên bền bỉ và thời gian chạy cục bộ nhiều quy trình. Nó bắt đầu như một phân nhánh cứng của pi-mono, nhưng Prime Agent hiện là sản phẩm, CLI, nguồn cài đặt và kho lưu trữ phát triển.

## Bắt đầu nhanh

Cài đặt bản phát hành ổn định mới nhất trên Linux hoặc macOS:

```bash
curl -fsSL https://app.primeintellect.ai/prime-agent/install.sh | sh
```

Sau đó chạy nó trong một thư mục dự án:

```bash
cd /path/to/project
prime-agent
```

Xác thực bằng `/login` để đăng ký hoặc nhà cung cấp khóa API được lưu trữ hoặc đặt một biến môi trường như `ANTHROPIC_API_KEY` trước khi khởi chạy. Xem [Quickstart](quickstart.vi.md) để biết quy trình chạy đầu tiên hoàn chỉnh.

Các bản phát hành công khai hiện được cài đặt từ các tạo phẩm phát hành được phiên bản. Tên không gian làm việc npm được kế thừa trong cây nguồn là chi tiết triển khai, không phải đường dẫn cài đặt công khai.

## Bắt đầu tại đây

- [Quickstart](quickstart.vi.md) - cài đặt, xác thực và chạy phiên đầu tiên.
- [Sử dụng Prime Agent](usage.vi.md) - chế độ tương tác, tác nhân phụ RLM, lệnh gạch chéo, tệp ngữ cảnh và tham chiếu CLI.
- [Tổng quan về kiến ​​trúc](architecture.vi.md) - ranh giới máy khách, daemon, worker, phiên, kernel, nhà cung cấp và lưu trữ.
- [Mô hình lập trình RLM](rlm.vi.md) - thực thi theo chương trình, các tác nhân phụ gốc, kỹ năng Python và trạng thái bền vững.
- [Tác nhân chạy dài và nền](long-running-agents.vi.md) - worker daemon, nhắn tin, nhịp tim, mục tiêu, lịch trình và chế độ tự trị.
- [Providers](providers.vi.md) - đăng ký và thiết lập khóa API cho các nhà cung cấp tích hợp.
- [Settings](settings.vi.md) - cài đặt chung và dự án.
- [Keybounds](keybindings.vi.md) - phím tắt mặc định và tổ hợp phím tùy chỉnh.
- [Sessions](sessions.vi.md) - quản lý phiên, phân nhánh và điều hướng cây.
- [Compaction](compaction.vi.md) - nén ngữ cảnh và tóm tắt nhánh.

## Tùy chỉnh

- [Extensions](extensions.vi.md) - Mô-đun TypeScript cho các công cụ, lệnh, sự kiện và giao diện người dùng tùy chỉnh.
- [Skills](skills.vi.md) - kỹ năng đánh dấu và hỗ trợ bởi Python, bao gồm cả cách yêu cầu Prime Agent tạo chúng.
- [MCP tích hợp](mcp-integrations.vi.md) - sử dụng máy chủ MCP thông qua các kỹ năng Python mà không cần mở rộng bề mặt công cụ của mô hình.
- [Mẫu lời nhắc](prompt-templates.vi.md) - lời nhắc có thể tái sử dụng mở rộng từ các lệnh gạch chéo.
- [Themes](themes.vi.md) - chủ đề thiết bị đầu cuối tùy chỉnh và tích hợp sẵn.
- [Gói Prime Agent](packages.vi.md) - gói và chia sẻ các tiện ích mở rộng, kỹ năng, lời nhắc và chủ đề.
- [Mô hình tùy chỉnh](models.vi.md) - thêm mục nhập mô hình cho API nhà cung cấp được hỗ trợ.
- [Nhà cung cấp tùy chỉnh](custom-provider.vi.md) - triển khai các luồng API và OAuth tùy chỉnh.

## Cách sử dụng có lập trình

- [SDK](sdk.vi.md) - nhúng Prime Agent vào các ứng dụng Node.js.
- [Chế độ ACP](acp.vi.md) - điều khiển Prime Agent từ bất kỳ client Giao thức Client Tác nhân nào.
- [Chế độ RPC](rpc.vi.md) - tích hợp trên stdin/stdout JSONL.
- [Chế độ luồng sự kiện JSON](json.vi.md) - chế độ in với các sự kiện có cấu trúc.
- [Thành phần TUI](tui.vi.md) - xây dựng giao diện người dùng thiết bị đầu cuối tùy chỉnh cho tiện ích mở rộng.

## Thẩm quyền giải quyết

- [Định dạng phiên](session-format.vi.md) - Định dạng tệp phiên JSONL, loại mục nhập và Trình quản lý phiên API.
- [Tham khảo gói CLI](../../../README.vi.md) - người dùng hoàn chỉnh và tham chiếu CLI.

## Thiết lập nền tảng

- [Windows](windows.vi.md)
- [Termux trên Android](termux.vi.md)
- [tmux](tmux.vi.md)
- [Thiết lập thiết bị đầu cuối](terminal-setup.vi.md)
- [Bí danh Shell](shell-aliases.vi.md)

## Phát triển

- [Development](development.vi.md) - thiết lập, cấu hình, gỡ lỗi và xác thực cục bộ.
- [Tổng quan về kiến ​​trúc](architecture.vi.md) - cấu trúc liên kết hệ thống và luồng nhắc nhở từ đầu đến cuối.
- [Daemon Architecture](daemon.vi.md) - chi tiết về người giám sát, danh mục, worker, vòng đời và quá trình khôi phục.
- [Kiến trúc kết nối tác nhân](agent-connection.vi.md) - ranh giới kết nối máy khách/thời gian chạy.
- [RLM Runtime Architecture](rlm-runtime.vi.md) - Vận chuyển hạt nhân ZeroMQ và thực thi tác nhân phụ đệ quy.

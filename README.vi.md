<p align="center">
  <a href="https://primeintellect.ai">
    <picture>
      <source media="(prefers-color-scheme: light)" srcset="https://github.com/user-attachments/assets/40c36e38-c5bd-4c5a-9b34-f7b902cd155d">
      <source media="(prefers-color-scheme: dark)" srcset="https://github.com/user-attachments/assets/6414bc9b-126b-41ca-9307-9e982430cde8">
      <img alt="Prime Intellect" src="https://github.com/user-attachments/assets/6414bc9b-126b-41ca-9307-9e982430cde8" width="312" style="max-width: 100%;">
    </picture>
  </a>
</p>

<h3 align="center">
Prime Agent: tác nhân RLM tự cải thiện
</h3>

<p align="center">
  <a href="packages/coding-agent/docs/index.vi.md">Tài liệu</a> &bull;
  <a href="https://github.com/PrimeIntellect-ai/verifiers">Verifier</a> &bull;
  <a href="https://github.com/PrimeIntellect-ai/prime-rl">PRIME-RL</a> &bull;
  <a href="https://github.com/badlogic/pi-mono">pi-mono</a>
</p>

<p align="center">
  <a href="https://github.com/PrimeIntellect-ai/prime-agent/actions/workflows/ci.yml">
    <img src="https://github.com/PrimeIntellect-ai/prime-agent/actions/workflows/ci.yml/badge.svg" alt="CI" />
  </a>
  <a href="https://github.com/PrimeIntellect-ai/prime-agent/actions/workflows/build-binaries.yml">
    <img src="https://github.com/PrimeIntellect-ai/prime-agent/actions/workflows/build-binaries.yml/badge.svg" alt="Build Binaries" />
  </a>
</p>

Prime Agent là một tác nhân nghiên cứu và mã hóa nguồn mở dành cho công việc chung và lâu dài. Nó được thiết kế xung quanh hai khái niệm trừu tượng cốt lõi:

- **[Mô hình ngôn ngữ đệ quy (RLM)](https://www.primeintellect.ai/blog/rlm)** xử lý ngữ cảnh dưới dạng các biến (*prompt-as-a-variable*) và các công cụ như tác nhân phụ đệ quy dưới dạng lệnh gọi hàm (*công cụ lập trình/gọi tác nhân phụ*) bên trong REPL liên tục.
- **[Harness liên tục](https://arxiv.org/abs/2605.09998)** lưu trữ các lời nhắc bổ sung, ký ức, mô tả kỹ năng và thông số kỹ thuật của tác nhân phụ có thể tái sử dụng dưới dạng trạng thái bền vững mà Prime Agent có thể tinh chỉnh thông qua các bản cập nhật nhỏ, có bằng chứng, cục bộ cho phiên theo mặc định.

Prime Agent kết hợp môi trường điều khiển Python liên tục với trạng thái harness bền bỉ, do đó bối cảnh làm việc hữu ích và các mẫu hoạt động có thể tái sử dụng có thể tồn tại lâu hơn một cửa sổ trò chuyện.

- **Mọi thứ đều được lập trình:** IPython liên tục là công cụ mô hình tích hợp sẵn; thao tác tệp, lệnh shell, sử dụng công cụ, tác nhân phụ và quản lý ngữ cảnh diễn ra thông qua mã.
- **Các tác nhân phụ được tích hợp sẵn:** `rlm(...)` tạo ra các tác nhân phụ thực sự cho công việc song song hoặc chạy nền và trả về kết quả theo chương trình.
- **Harness có thể cải thiện:** `/refine` xem xét quỹ đạo hiện tại và có thể áp dụng các bản cập nhật nhỏ, được chứng minh bằng bằng chứng cho trạng thái harness bổ sung. Nó không bao giờ viết lại lời nhắc hệ thống cơ sở bất biến và các ảnh chụp nhanh được ghi lại hỗ trợ khôi phục.
- **Các kỹ năng có thể thực thi được:** các kỹ năng là các gói Python có thể nhập được và trình tạo kỹ năng tích hợp sẵn có thể biến các quy trình làm việc định kỳ thành các kỹ năng dự án hoặc cá nhân.
- **Phiên chạy ở chế độ nền:** các tác nhân được hỗ trợ bằng daemon tiếp tục chạy khi thiết bị đầu cuối ngắt kết nối và có thể được gắn lại sau.
- **Các tác nhân giao tiếp trực tiếp:** các tác nhân đang chạy có thể trao đổi tin nhắn và điều phối lẫn nhau mà không cần định tuyến mọi thứ thông qua người dùng.
- **Các nhiệm vụ dài tiếp tục di chuyển:** nén tự động, mục tiêu liên tục, nhịp tim, lịch trình, chế độ tự trị và các tác nhân phụ được giữ lại duy trì tiến độ qua các lượt và phiên cuối.

## Bắt đầu

Cài đặt bản phát hành ổn định mới nhất trên macOS hoặc Linux:

```bash
curl -fsSL https://app.primeintellect.ai/prime-agent/install.sh | sh
```

Trình cài đặt tải xuống bản phát hành đã được phiên bản, xác minh tổng kiểm tra SHA-256 của nó, cài đặt lệnh `prime-agent` và có thể chuẩn bị thời gian chạy IPython được tác nhân sử dụng.

Khởi động Prime Agent từ kho lưu trữ hoặc thư mục mà bạn muốn nó hoạt động:

```bash
cd /path/to/project
prime-agent
```

Trong lần khởi chạy đầu tiên, hãy chạy `/login` để chọn gói đăng ký hoặc nhà cung cấp khóa API. Prime Agent hoạt động trong thư mục hiện tại và có thể chạy lệnh cũng như sửa đổi các tệp ở đó. Sử dụng bản sao dùng một lần, cây làm việc sạch hoặc điểm kiểm tra khác mà bạn có thể kiểm tra và khôi phục.

> [!WARNING]
> Prime Agent thực thi các lệnh Python và dự án do mô hình tạo với quyền người dùng của bạn. Các quy trình kernel và kernel của nó cải thiện khả năng cách ly và phục hồi vòng đời; chúng **không phải** là hộp cát bảo mật. Xem lại các thay đổi và chỉ sử dụng các kho lưu trữ, hướng dẫn, kỹ năng và tiện ích mở rộng đáng tin cậy. Chạy mã hoặc hướng dẫn không đáng tin cậy trong hộp cát bên ngoài hoặc môi trường bị hạn chế.

Các lệnh hữu ích:

```bash
prime-agent agents                   # Browse running, idle, and saved sessions
prime-agent attach <agent>           # Reattach to a running session
prime-agent --resume <path|id>       # Resume a saved session
prime-agent status                   # Inspect background service state
prime-agent doctor [--fix]           # Inspect or repair background services
prime-agent update [--force]         # Update Prime Agent
prime-agent shutdown [--force]       # Stop every agent, worker, and background service
```

## Được xây dựng cho công việc lâu dài
Prime Agent được xây dựng cho công việc lâu dài, đặc biệt là để đánh giá trong nghiên cứu. Các tính năng này có sẵn trong TUI và khi chạy tự động.

- **Harness liên tục:** `/refine` có thể duy trì các bài học tập trung, có thể xem lại dưới dạng lời nhắc bổ sung, ký ức, mô tả kỹ năng có thể sử dụng lại hoặc thông số kỹ thuật của tác nhân phụ, với lịch sử sàng lọc được ghi lại. Nó không thay thế việc đóng gói và xem xét các kỹ năng thực thi mới.
- **Giao tiếp trực tiếp giữa các tác nhân:** các tác nhân đang chạy và các tác nhân phụ được giữ lại có thể khám phá lẫn nhau, trao đổi tin nhắn và chỉ đạo công việc đang hoạt động.
- **Tính liên tục được hỗ trợ bởi Daemon:** các phiên hoạt động, trạng thái IPython, lịch trình và tác nhân phụ tiếp tục chạy khi thiết bị đầu cuối tách ra và có thể được gắn lại sau.
- **Nhịp tim và lịch trình:** `/heartbeat`, `rlm_heartbeat` và `prime-agent schedule` có thể vào lại phiên theo định kỳ hoặc tại một thời điểm cụ thể.
- **Mục tiêu liên tục:** `/goal` giữ mục tiêu và tiến trình của nó hoạt động qua các lượt cho đến khi hoàn thành, tạm dừng hoặc xóa.
- **Chế độ tự trị bị giới hạn:** `/autonomous` tiếp tục trong phạm vi ngân sách lượt, mã thông báo và thời gian đã định cấu hình và có thể chạy các cổng chất lượng do người dùng xác định. Cổng đã vượt qua chỉ kiểm tra những gì cổng đó xác minh; đạt đến một giới hạn không có nghĩa là nhiệm vụ thành công.

## Tài liệu

- [Quickstart](packages/coding-agent/docs/quickstart.vi.md) — cài đặt, xác thực và chạy phiên đầu tiên
- [Cách sử dụng và tham chiếu CLI](packages/coding-agent/docs/usage.vi.md) - lệnh, phiên, giới hạn tự trị và chế độ đầu ra
- [Tác nhân nền và chạy dài](packages/coding-agent/docs/long-running-agents.vi.md) — tách và gắn lại, mục tiêu, nhịp tim và lịch trình
- [Mô hình lập trình RLM](packages/coding-agent/docs/rlm.vi.md) - IPython, tác nhân phụ, kỹ năng và mô hình tin cậy liên tục
- [Chế độ JSON](packages/coding-agent/docs/json.vi.md) và [Chế độ RPC](packages/coding-agent/docs/rpc.vi.md) — tích hợp và tự động hóa không đầu
- [Skills](packages/coding-agent/docs/skills.vi.md) — cài đặt và tạo các khả năng có thể tái sử dụng
- [Nhà cung cấp setup](packages/coding-agent/docs/providers.vi.md) — nhà cung cấp đăng ký và khóa API
- [Tổng quan về kiến ​​trúc](packages/coding-agent/docs/architecture.vi.md) — ranh giới daemon, worker, kernel và Persistent
- [Development](packages/coding-agent/docs/development.vi.md) - xây dựng và chạy từ nguồn

## Lời cảm ơn

Tác nhân của chúng tôi và TUI được xây dựng dựa trên [`pi`](https://github.com/earendil-works/pi). Chúng tôi cảm ơn các tác giả của `pi` vì công việc có giá trị của họ.

## Giấy phép

Prime Agent là nguồn mở hoàn toàn và được phát hành theo [MIT License](LICENSE).

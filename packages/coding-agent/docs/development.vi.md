# Phát triển

Xem kho lưu trữ [AGENTS.md](../../../AGENTS.md) để biết các quy tắc đóng góp hiện tại và xác thực bắt buộc.

## Cài đặt

Prime Agent yêu cầu Node.js 22.8.0 trở lên.

```bash
git clone https://github.com/PrimeIntellect-ai/prime-agent
cd prime-agent
npm ci
```

Chạy từ nguồn:

```bash
/path/to/prime-agent/prime-agent.sh
```

Tập lệnh có thể được gọi từ bất kỳ thư mục nào và giữ nguyên thư mục làm việc của người gọi. Sử dụng hành vi đó để chạy kiểm tra nguồn đối với một dự án thử nghiệm riêng biệt.

## Tên sản phẩm và nguồn

Prime Agent là sản phẩm, CLI công khai, tạo phẩm phát hành và tên kho lưu trữ. Monorepo vẫn giữ lại các tên không gian làm việc npm `@earendil-works/pi-*` kế thừa, mục nhập bin `pi` của gói nguồn, khóa kê khai gói `pi` và một số biến môi trường tương thích `PI_*`. Những tên này là thông tin chi tiết về nguồn và khả năng tương thích, không phải là tín hiệu cho thấy những người đóng góp nên cài đặt hoặc phát triển dựa trên pi-mono.

Các bản phát hành công khai hiện là các tạo phẩm tarball được phiên bản được cài đặt bởi các tập lệnh cài đặt beta và ổn định. `scripts/pack-prime-agent-release.mjs` ghi lại tên gói tác nhân mã hóa, tệp thực thi, siêu dữ liệu cấu hình và URL phụ thuộc nội bộ cho bản phân phối đó. Không ghi lại gói không gian làm việc npm được kế thừa dưới dạng đường dẫn cài đặt Prime Agent công khai.

## Cấu hình cục bộ

Cấu hình người dùng nằm trong `~/.prime/agent/`. Cài đặt dự án cục bộ, lời nhắc, chủ đề, tiện ích mở rộng, kỹ năng và tệp lời nhắc hệ thống nằm trong `.prime/agent/` trong thư mục gốc của dự án. Ghi đè thư mục cấu hình người dùng bằng `PRIME_AGENT_CODING_AGENT_DIR` và thư mục phiên bằng `PRIME_AGENT_SESSION_DIR`.

Sử dụng thư mục cấu hình biệt lập khi thực hiện hành vi daemon theo cách thủ công để các phiên phát triển không xung đột với các phiên thông thường:

```bash
PRIME_AGENT_CODING_AGENT_DIR=/tmp/prime-agent-dev /path/to/prime-agent/prime-agent.sh
```

## Thay đổi giao thức Daemon

Phân loại mọi thay đổi về lệnh, sự kiện hoặc hình dạng phản hồi của daemon là tương thích ngược, hạn chế khả năng hoặc không tương thích. Hành vi tùy chọn phải được thương lượng và làm suy giảm cục bộ. Thực hiện theo các yêu cầu kiểm tra phiên bản giao thức, sửa đổi lược đồ, bản đồ tương thích và phiên bản chéo trong `AGENTS.md` gốc trước khi thay đổi hợp đồng dây.

## Giải quyết tài sản trọn gói

Prime Agent chạy từ nguồn, đầu ra gói Node.js và các tạo phẩm phát hành độc lập. Luôn sử dụng trình trợ giúp `src/config.ts` cho nội dung gói:

```typescript
import { getPackageDir, getThemeDir } from "./config.js";
```

Không giải quyết nội dung được đóng gói trực tiếp từ `__dirname`.

## Gỡ lỗi

Lệnh `/debug` ẩn ghi `~/.prime/agent/prime-agent-debug.log` với các dòng TUI được hiển thị, độ rộng hiển thị của chúng và thông báo tác nhân hiện tại. Nhật ký chẩn đoán Daemon, worker, client và nhà cung cấp nằm trong `~/.prime/agent/logs/`.

Các lệnh dịch vụ hữu ích:

```bash
prime-agent status
prime-agent doctor
prime-agent doctor --fix
prime-agent shutdown
```

## Xác thực

Sau khi thay đổi mã, hãy chạy kiểm tra kho lưu trữ từ thư mục gốc:

```bash
npm run check
```

Điều này thực hiện việc định dạng, tìm lỗi mã nguồn, kiểm tra kiểu, kiểm tra kết xuất trình cài đặt và kiểm tra khói của trình duyệt. Nó không chạy bộ thử nghiệm.

Chạy thử nghiệm tập trung từ thư mục gốc của gói. Ví dụ:

```bash
cd packages/coding-agent
npx tsx ../../node_modules/vitest/dist/cli.js --run test/specific.test.ts
```

Nếu bạn tạo hoặc sửa đổi tệp thử nghiệm, hãy chạy tệp đó và lặp lại cho đến khi vượt qua. Hồi quy bộ tác nhân mã hóa thuộc về `test/suite/regressions/` và sử dụng test harness và nhà cung cấp giả thay vì thông tin xác thực của nhà cung cấp trực tiếp.

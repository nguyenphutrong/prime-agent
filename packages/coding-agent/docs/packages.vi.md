> Prime Agent có thể giúp bạn tạo các gói tài nguyên. Hãy yêu cầu nó đóng gói các extension, skill, mẫu prompt hoặc theme của bạn.

# Gói Prime Agent

Các gói Prime Agent đóng gói extension, skill, mẫu prompt và theme để bạn có thể chia sẻ chúng qua npm hoặc git. Để tương thích với hệ sinh thái extension kế thừa, một gói khai báo tài nguyên trong `package.json` dưới khóa `pi`, hoặc sử dụng các thư mục theo quy ước.

## Mục lục

- [Cài đặt và quản lý](#cài-đặt-và-quản-lý)
- [Nguồn gói](#nguồn-gói)
- [Tạo gói Prime Agent](#tạo-gói-prime-agent)
- [Cấu trúc gói](#cấu-trúc-gói)
- [Dependencies](#dependencies)
- [Lọc gói](#lọc-gói)
- [Bật và tắt tài nguyên](#bật-và-tắt-tài-nguyên)
- [Phạm vi và loại bỏ trùng lặp](#phạm-vi-và-loại-bỏ-trùng-lặp)

## Cài đặt và quản lý

> **Bảo mật:** Các gói Prime Agent chạy với toàn quyền truy cập hệ thống. Extension thực thi mã tùy ý, còn skill có thể hướng dẫn model thực hiện bất kỳ hành động nào, bao gồm chạy executable. Hãy xem xét mã nguồn trước khi cài đặt các gói bên thứ ba.

```bash
prime-agent package install npm:@foo/bar@1.0.0
prime-agent package install git:github.com/user/repo@v1
prime-agent package install https://github.com/user/repo  # raw URLs work too
prime-agent package install /absolute/path/to/package
prime-agent package install ./relative/path/to/package

prime-agent package remove npm:@foo/bar
prime-agent package list                  # show installed packages from settings
prime-agent package update                # update all non-pinned packages
prime-agent package update npm:@foo/bar   # update one package
prime-agent update                        # update Prime Agent
prime-agent update --force                # reinstall Prime Agent even if current
```

Theo mặc định, `package install` và `package remove` ghi vào settings toàn cục (`~/.prime/agent/settings.json`). Dùng `--local` để ghi vào settings dự án (`.prime/agent/settings.json`) thay thế. Settings dự án có thể được chia sẻ với nhóm của bạn, và Prime Agent sẽ tự động cài đặt mọi gói còn thiếu khi khởi động.

Để thử một gói mà không cài đặt, hãy dùng `--extension` hoặc `-e`. Gói được cài vào một thư mục tạm thời chỉ dành cho lần chạy hiện tại:

```bash
prime-agent -e npm:@foo/bar
prime-agent -e git:github.com/user/repo
```

## Nguồn gói

Prime Agent chấp nhận ba loại nguồn trong settings và `prime-agent package install`.

### npm

```
npm:@scope/pkg@1.2.3
npm:pkg
```

- Spec có phiên bản được ghim và bị bỏ qua bởi `prime-agent package update`.
- Cài đặt toàn cục sử dụng `npm install -g`.
- Cài đặt dự án nằm trong `.prime/agent/npm/`.
- Đặt `npmCommand` trong `settings.json` để ghim thao tác tra cứu và cài đặt gói npm vào một lệnh wrapper cụ thể như `mise` hoặc `asdf`.

Ví dụ:

```json
{
  "npmCommand": ["mise", "exec", "node@20", "--", "npm"]
}
```

### git

```
git:github.com/user/repo@v1
git:git@github.com:user/repo@v1
https://github.com/user/repo@v1
ssh://git@github.com/user/repo@v1
```

- Không có tiền tố `git:`, chỉ chấp nhận URL giao thức (`https://`, `http://`, `ssh://`, `git://`).
- Có tiền tố `git:`, chấp nhận các định dạng viết tắt, bao gồm `github.com/user/repo` và `git@github.com:user/repo`.
- Hỗ trợ cả URL HTTPS và SSH.
- URL SSH tự động sử dụng các SSH key đã cấu hình của bạn (tôn trọng `~/.ssh/config`).
- Với các lần chạy không tương tác (ví dụ CI), bạn có thể đặt `GIT_TERMINAL_PROMPT=0` để tắt lời nhắc thông tin xác thực và đặt `GIT_SSH_COMMAND` (ví dụ `ssh -o BatchMode=yes -o ConnectTimeout=5`) để thoát nhanh khi lỗi.
- Ref ghim gói và bị bỏ qua bởi `prime-agent package update`.
- Được clone vào `~/.prime/agent/git/<host>/<path>` (toàn cục) hoặc `.prime/agent/git/<host>/<path>` (dự án).
- Chạy `npm install` sau khi clone hoặc pull nếu có `package.json`.

**Ví dụ SSH:**
```bash
# git@host:path shorthand (requires git: prefix)
prime-agent package install git:git@github.com:user/repo

# ssh:// protocol format
prime-agent package install ssh://git@github.com/user/repo

# With version ref
prime-agent package install git:git@github.com:user/repo@v1.0.0
```

### Đường dẫn cục bộ

```
/absolute/path/to/package
./relative/path/to/package
```

Đường dẫn cục bộ trỏ đến các file hoặc thư mục trên ổ đĩa và được thêm vào settings mà không sao chép. Đường dẫn tương đối được phân giải dựa trên file settings nơi chúng xuất hiện. Nếu đường dẫn là một file, nó được tải như một extension đơn lẻ. Nếu là một thư mục, Prime Agent tải tài nguyên theo quy tắc gói.

## Tạo gói Prime Agent

Thêm manifest `pi` vào `package.json` hoặc sử dụng các thư mục theo quy ước. Bao gồm từ khóa `pi-package` để dễ được tìm thấy.

```json
{
  "name": "my-package",
  "keywords": ["pi-package"],
  "pi": {
    "extensions": ["./extensions"],
    "skills": ["./skills"],
    "prompts": ["./prompts"],
    "themes": ["./themes"]
  }
}
```

Đường dẫn tính từ thư mục gốc của gói. Các mảng hỗ trợ mẫu glob và `!exclusions`.

### Metadata thư viện

Từ khóa `pi-package` kế thừa cùng các trường `video` hoặc `image` tùy chọn vẫn có thể được dùng làm metadata gói:

```json
{
  "name": "my-package",
  "keywords": ["pi-package"],
  "pi": {
    "extensions": ["./extensions"],
    "video": "https://example.com/demo.mp4",
    "image": "https://example.com/screenshot.png"
  }
}
```

- **video**: URL đến bản xem trước MP4.
- **image**: URL đến bản xem trước PNG, JPEG, GIF hoặc WebP.

Nếu cả hai được thiết lập, video được ưu tiên.

## Cấu trúc gói

### Thư mục theo quy ước

Nếu không có manifest `pi`, Prime Agent tự động phát hiện tài nguyên từ các thư mục sau:

- `extensions/` tải các file `.ts` và `.js`
- `skills/` đệ quy tìm các thư mục `SKILL.md` và tải các file `.md` cấp cao nhất làm skill
- `prompts/` tải các file `.md`
- `themes/` tải các file `.json`

## Dependencies

Dependencies runtime bên thứ ba thuộc về `dependencies` trong `package.json`. Dependencies không đăng ký extension, skill, mẫu prompt hoặc theme cũng thuộc về `dependencies`. Khi Prime Agent cài đặt một gói từ npm hoặc git, nó chạy `npm install`, vì vậy các dependencies đó được cài tự động.

Prime Agent đóng gói các gói lõi cho extension và skill. Workspace vẫn phát hành các tên gói kế thừa này; nếu bạn import bất kỳ gói nào, hãy liệt kê chúng trong `peerDependencies` với khoảng phiên bản `"*"` và không đóng gói chúng: `@earendil-works/pi-ai`, `@earendil-works/pi-agent-core`, `@earendil-works/pi-coding-agent`, `@earendil-works/pi-tui`, `typebox`.

Các gói tài nguyên khác phải được đóng gói trong tarball của bạn. Thêm chúng vào `dependencies` và `bundledDependencies`, sau đó tham chiếu tài nguyên của chúng qua các đường dẫn `node_modules/`. Prime Agent tải các gói với các module root riêng biệt, vì vậy các lần cài đặt riêng biệt không xung đột hoặc chia sẻ module.

Ví dụ:

```json
{
  "dependencies": {
    "shitty-extensions": "^1.0.1"
  },
  "bundledDependencies": ["shitty-extensions"],
  "pi": {
    "extensions": ["extensions", "node_modules/shitty-extensions/extensions"],
    "skills": ["skills", "node_modules/shitty-extensions/skills"]
  }
}
```

## Lọc gói

Lọc nội dung một gói được tải bằng dạng object trong settings:

```json
{
  "packages": [
    "npm:simple-pkg",
    {
      "source": "npm:my-package",
      "extensions": ["extensions/*.ts", "!extensions/legacy.ts"],
      "skills": [],
      "prompts": ["prompts/review.md"],
      "themes": ["+themes/legacy.json"]
    }
  ]
}
```

`+path` và `-path` là các đường dẫn chính xác tính từ thư mục gốc của gói.

- Bỏ qua một khóa để tải toàn bộ loại tài nguyên đó.
- Dùng `[]` để không tải loại tài nguyên đó.
- `!pattern` loại trừ các kết quả khớp.
- `+path` buộc bao gồm một đường dẫn chính xác.
- `-path` buộc loại trừ một đường dẫn chính xác.
- Bộ lọc được áp dụng trên manifest. Chúng thu hẹp nội dung đã được cho phép.

## Bật và tắt tài nguyên

Dùng `prime-agent config` để bật hoặc tắt extension, skill, mẫu prompt và theme từ các gói đã cài đặt cùng các thư mục cục bộ. Tính năng này hoạt động cho cả phạm vi toàn cục (`~/.prime/agent`) và phạm vi dự án (`.prime/agent/`).

## Phạm vi và loại bỏ trùng lặp

Gói có thể xuất hiện trong cả settings toàn cục và settings dự án. Nếu cùng một gói xuất hiện ở cả hai, mục nhập dự án được ưu tiên. Danh tính được xác định bởi:

- npm: tên gói
- git: URL repository không có ref
- local: đường dẫn tuyệt đối đã phân giải

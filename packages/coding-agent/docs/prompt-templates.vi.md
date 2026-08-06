> Prime Agent có thể tạo các prompt template. Hãy yêu cầu nó xây dựng một template cho quy trình của bạn.

# Prompt template

Prompt template là các đoạn Markdown được mở rộng thành prompt đầy đủ. Gõ `/name` trong editor để gọi một template, trong đó `name` là tên tệp không có `.md`.

## Vị trí

Prime Agent tải prompt template từ:

- Global: `~/.prime/agent/prompts/*.md`
- Project: `.prime/agent/prompts/*.md`
- Package: các thư mục `prompts/` hoặc các entry `pi.prompts` trong `package.json`
- Settings: mảng `prompts` chứa tệp hoặc thư mục
- CLI: `--prompt-template <path>` (có thể lặp lại)

Tắt việc tìm kiếm bằng `--no-prompt-templates`.

## Định dạng

```markdown
---
description: Review staged git changes
---
Review the staged changes (`git diff --cached`). Focus on:
- Bugs and logic errors
- Security issues
- Error handling gaps
```

- Tên tệp trở thành tên lệnh. `review.md` trở thành `/review`.
- `description` là tùy chọn. Nếu thiếu, dòng không rỗng đầu tiên sẽ được dùng.
- `argument-hint` là tùy chọn. Khi được đặt, hint hiển thị trước description trong menu autocomplete.

### Gợi ý tham số

Dùng `argument-hint` trong frontmatter để hiển thị tham số dự kiến trong autocomplete. Dùng `<dấu ngoặc nhọn>` cho tham số bắt buộc và `[dấu ngoặc vuông]` cho tham số tùy chọn:

```markdown
---
description: Review PRs from URLs with structured issue and code analysis
argument-hint: "<PR-URL>"
---
```

Trong menu autocomplete, nội dung này hiển thị như sau:

```
→ pr   <PR-URL>       — Review PRs from URLs with structured issue and code analysis
  is   <issue>        — Analyze GitHub issues (bugs or feature requests)
  wr   [instructions] — Finish the current task end-to-end
  cl   — Audit changelog entries before release
```

## Cách dùng

Gõ `/` rồi tên template trong editor. Autocomplete hiển thị các template có sẵn cùng description.

```
/review                           # Expands review.md
/component Button                 # Expands with argument
/component Button "click handler" # Multiple arguments
```

## Tham số

Template hỗ trợ tham số vị trí và phép cắt đơn giản:

- `$1`, `$2`, ... tham số vị trí
- `$@` hoặc `$ARGUMENTS` cho toàn bộ tham số được nối lại
- `${@:N}` cho các tham số từ vị trí N (đánh số từ 1)
- `${@:N:L}` cho L tham số bắt đầu từ N

Ví dụ:

```markdown
---
description: Create a component
---
Create a React component named $1 with features: $@
```

Cách dùng: `/component Button "onClick handler" "disabled support"`

## Quy tắc tải

- Việc tìm template trong `prompts/` không đệ quy.
- Nếu muốn template trong thư mục con, hãy thêm chúng một cách tường minh qua settings `prompts` hoặc package manifest.

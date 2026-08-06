# Sử dụng Prime Agent

Trang này tập hợp các thông tin sử dụng hằng ngày không phù hợp với trang bắt đầu nhanh.

Prime Agent được xây dựng xoay quanh một công cụ dành cho model: kernel IPython duy trì lâu dài. Kernel giữ lại trạng thái Python giữa các lượt và đóng vai trò môi trường điều khiển cho thao tác tệp, lệnh dự án, các skill Python đã cài đặt, skill dựa trên MCP và subagent đệ quy. Host TypeScript vẫn chịu trách nhiệm gọi provider, quản lý trạng thái phiên, thực thi công cụ, lập lịch và vòng đời của các agent con.

## Chế độ tương tác

<p align="center"><img src="images/interactive-mode.png" alt="Chế độ tương tác" width="600"></p>

Giao diện có bốn khu vực chính:

- **Header khởi động** - tóm tắt ngắn gọn thương hiệu và runtime; `--verbose` cũng liệt kê các tệp context, template prompt, skill và extension đã tải
- **Tin nhắn** - tin nhắn người dùng, câu trả lời của assistant, lần gọi công cụ, kết quả công cụ, thông báo, lỗi và UI của extension
- **Trình soạn thảo** - nơi bạn nhập nội dung
- **Chân trang** - mặc định để trống; dùng `/usage` để xem thông tin token, chi phí và context

Trình soạn thảo có thể tạm thời được thay thế bằng UI tích hợp như `/settings` hoặc UI tùy chỉnh của extension.

### Tính năng trình soạn thảo

| Tính năng | Cách dùng |
|---------|-----|
| Tham chiếu tệp | Nhập `@` để tìm kiếm gần đúng các tệp dự án |
| Hoàn tất đường dẫn | Nhấn Tab để hoàn tất đường dẫn |
| Nhập nhiều dòng | Shift+Enter, hoặc Ctrl+Enter trên Windows Terminal |
| Hình ảnh | Dán bằng Ctrl+V, Alt+V trên Windows hoặc kéo vào terminal |
| Lệnh shell | `!command` chạy lệnh và gửi đầu ra cho model |
| Lệnh shell ẩn | `!!command` chạy lệnh mà không gửi đầu ra cho model |
| Trình soạn thảo bên ngoài | Ctrl+G mở `$VISUAL` hoặc `$EDITOR` |

Xem [Phím tắt](keybindings.vi.md) để biết tất cả phím tắt và cách tùy chỉnh.

## Lệnh slash

Nhập `/` trong trình soạn thảo để mở tính năng hoàn tất lệnh. Extension có thể đăng ký lệnh tùy chỉnh, skill có sẵn dưới dạng `/skill:name`, còn template prompt được mở rộng qua `/templatename`.

| Lệnh | Mô tả |
|---------|-------------|
| `/login`, `/logout` | Quản lý thông tin xác thực OAuth hoặc API key |
| `/model` | Chuyển model |
| `/effort` | Đặt mức suy luận/tư duy |
| `/scoped-models` | Bật/tắt các model dùng khi chuyển bằng Ctrl+P |
| `/settings` | Mức tư duy, giao diện, phân phối tin nhắn, transport |
| `/resume` | Chọn từ các phiên trước |
| `/new` | Bắt đầu phiên mới |
| `/name <name>` | Đặt tên hiển thị cho phiên |
| `/session` | Hiển thị tệp phiên, ID và số lượng tin nhắn |
| `/traces [status\|on\|off\|preview\|upload-current\|upload-all\|login]` | Xem trước, tải lên hoặc quản lý việc chia sẻ trace theo lựa chọn |
| `/usage`, `/context` | Hiển thị context của agent cha và subagent, cùng phân tích token và chi phí |
| `/tree` | Chuyển đến bất kỳ điểm nào trong phiên và tiếp tục từ đó |
| `/fork` | Tạo phiên mới từ một tin nhắn trước đó của người dùng |
| `/clone` | Nhân bản nhánh đang hoạt động thành một phiên mới |
| `/compact [prompt]` | Tự nén context, có thể kèm chỉ dẫn tùy chỉnh |
| `/refine [instructions]` | Tinh chỉnh hoặc khôi phục trạng thái harness dựa trên phiên |
| `/copy` | Sao chép tin nhắn cuối của assistant vào clipboard |
| `/btw <question>`, `/side <question>` | Đặt câu hỏi bên trong dòng mà không thêm vào phiên; câu trả lời tiếp tục cuộc trò chuyện bên, nhấn esc để quay lại |
| `/export [file]` | Xuất phiên thành HTML |
| `/share` | Tải lên dưới dạng GitHub gist riêng tư kèm liên kết HTML có thể chia sẻ |
| `/reload` | Tải lại phím tắt, extension, skill, prompt và tệp context |
| `/hotkeys` | Hiển thị tất cả phím tắt |
| `/changelog` | Hiển thị lịch sử phiên bản |
| `/quit` | Thoát Prime Agent |

## Hàng đợi tin nhắn

Bạn có thể gửi tin nhắn trong khi agent vẫn đang làm việc:

- **Enter** xếp một tin nhắn điều hướng vào hàng đợi, được gửi sau khi lượt hiện tại của assistant thực thi xong các lần gọi công cụ.
- **Alt+Enter** xếp một tin nhắn tiếp nối vào hàng đợi, được gửi sau khi agent hoàn tất mọi việc.
- **Ctrl+C** ngắt thao tác hiện tại và hiển thị nhanh gợi ý thoát; nhấn lại khi gợi ý còn hiển thị để thoát.
- **Escape** xóa thanh nhập liệu mà không ngắt agent.
- **Alt+Up** đưa các tin nhắn đang chờ từ hàng đợi trở lại trình soạn thảo.

Trên Windows Terminal, Alt+Enter mặc định là phím tắt toàn màn hình. Hãy ánh xạ lại như mô tả trong [Thiết lập terminal](terminal-setup.vi.md) nếu muốn Prime Agent nhận phím tắt này.

Cấu hình việc phân phối trong [Cài đặt](settings.vi.md) bằng `steeringMode` và `followUpMode`.

## Phiên

Các phiên được tự động lưu dưới dạng tệp JSONL phẳng trong `~/.prime/agent/sessions/`. Header của mỗi phiên ghi lại thư mục làm việc, được trình chọn phiên sử dụng để hiển thị theo phạm vi dự án.

```bash
prime-agent -c                  # Continue most recent session
prime-agent -r [path|id]        # Browse sessions or resume one directly
prime-agent --no-session        # Ephemeral mode; do not save
prime-agent --fork <path|id>    # Fork a session into a new session file
```

Các lệnh phiên hữu ích:

- `/session` hiển thị tệp và ID của phiên hiện tại.
- `/usage` hiển thị mức sử dụng token, chi phí và context.
- `/tree` điều hướng cây phiên trong tệp và có thể tóm tắt các nhánh đã bỏ.
- `/fork` tạo phiên mới từ một tin nhắn trước đó của người dùng.
- `/clone` nhân bản nhánh đang hoạt động thành tệp phiên mới.
- `/compact` tóm tắt các tin nhắn cũ để giải phóng context.

See [Phiên](sessions.vi.md) and [Compact](compaction.vi.md) for details.

## Agent và subagent đệ quy

Các phiên tương tác thông thường là những agent lâu dài được hỗ trợ bởi các tiến trình worker biệt lập. Đóng TUI sẽ tách client; dùng `prime-agent agents`, `prime-agent list` hoặc `prime-agent attach <agent>` để tìm và kết nối lại với công việc đang chạy. `prime-agent stop <agent>` dừng một agent gốc, còn `prime-agent shutdown` dừng mọi worker và supervisor cục bộ.

Trong một phiên, model có thể ủy quyền qua callable `rlm` đã có sẵn trong IPython:

```python
# Spawn independent children. Each call returns at admission with a child handle,
# never the child's answer.
review = await rlm(
    "Review authentication and reply to the parent with findings.",
    name="auth-reviewer",
)
tests = await rlm("Find missing regression tests and reply to the parent.", name="test-reviewer")
docs = await rlm("Find stale public documentation and reply to the parent.", name="docs-reviewer")

# Children reply from their own sessions with:
# await agent_message.send(message, receiver_role="parent")
# Their replies arrive here as ordinary agent messages.

# Recover handles and follow up with a retained child.
children = await rlm.list_subagents()
await agent_message.send(
    "Also check authorization boundaries.",
    receiver_role="child",
    receiver_name=review.name,
)
```

Các agent con kế thừa model của agent cha trừ khi người dùng yêu cầu model khác. Chúng chạy dưới dạng các instance `AgentSession` của TypeScript trong cùng worker gốc và có thể dùng cùng provider, công cụ, skill, bộ lưu trữ phiên và hệ thống lập lịch. Xem [Kiến trúc runtime RLM](rlm-runtime.vi.md).

## Tệp context

Khi khởi động, Prime Agent tải `AGENTS.md` hoặc `CLAUDE.md` từ:

- `~/.prime/agent/AGENTS.md` cho chỉ dẫn toàn cục
- các thư mục cha, lần lượt đi lên từ thư mục làm việc hiện tại
- thư mục hiện tại

Dùng tệp context cho quy ước dự án, lệnh, quy tắc an toàn và tùy chọn. Tắt việc tải bằng `--no-context-files` hoặc `-nc`.

### Tệp system prompt

Thay system prompt mặc định bằng:

- `.prime/agent/SYSTEM.md` cho một dự án
- `~/.prime/agent/SYSTEM.md` trên toàn cục

Nối thêm vào prompt mặc định mà không thay thế nó bằng `APPEND_SYSTEM.md` ở một trong hai vị trí.

## Xuất và chia sẻ phiên

Dùng `/export [file]` để ghi một phiên thành HTML.

Dùng `/share` để tải một GitHub gist riêng tư kèm liên kết HTML có thể chia sẻ.

## Tham chiếu CLI

```bash
prime-agent [options] [@files...] [messages...]
```

### Lệnh shell

```bash
prime-agent agents
prime-agent list [--all]
prime-agent attach <agent>
prime-agent stop <agent>
prime-agent rename <agent> <name>
prime-agent send <agent> <message>
prime-agent schedule <list|add|cancel>
prime-agent status
prime-agent doctor [--fix]
prime-agent shutdown [--force]

prime-agent package install <source> [--local]
prime-agent package remove <source> [--local]
prime-agent package list
prime-agent package update [source]
prime-agent update [--force]
prime-agent config
```

Xem [Gói Prime Agent](packages.vi.md) để biết nguồn package và lưu ý bảo mật.

### Chế độ

| Cờ | Mô tả |
|------|-------------|
| default | Chế độ tương tác |
| `-p`, `--print` | In câu trả lời rồi thoát |
| `--mode json` | Xuất mọi event thành các dòng JSON; xem [Chế độ JSON](json.vi.md) |
| `--mode rpc` | Chế độ RPC qua stdin/stdout; xem [Chế độ RPC](rpc.vi.md) |

Ở chế độ in, Prime Agent cũng đọc stdin được pipe và gộp vào prompt ban đầu:

```bash
cat README.md | prime-agent -p "Summarize this text"
```

### Tùy chọn model

| Tùy chọn | Mô tả |
|--------|-------------|
| `--provider <name>` | Provider, chẳng hạn `anthropic`, `openai` hoặc `google` |
| `--model <pattern>` | Pattern hoặc ID của model; hỗ trợ `provider/id` và `:<thinking>` tùy chọn |
| `--api-key <key>` | API key, ghi đè các biến môi trường |
| `--thinking <level>` | `off`, `minimal`, `low`, `medium`, `high`, `xhigh` hoặc `max` |
| `--models <patterns>` | Các pattern phân tách bằng dấu phẩy để chuyển bằng Ctrl+P |

Dùng `prime-agent model list [search]` để liệt kê các model khả dụng.

### Tùy chọn phiên

| Tùy chọn | Mô tả |
|--------|-------------|
| `-c`, `--continue` | Tiếp tục phiên gần nhất |
| `-r`, `--resume [path\|id]` | Duyệt và chọn một phiên, hoặc tiếp tục tệp phiên cụ thể hay UUID một phần |
| `--fork <path\|id>` | Tách tệp phiên hoặc UUID một phần thành phiên mới |
| `--session-dir <dir>` | Thư mục lưu trữ phiên tùy chỉnh |
| `--no-session` | Chế độ tạm thời; không lưu |

Dùng `prime-agent session export <file> [output]` để xuất một phiên thành HTML.

### Tùy chọn công cụ

| Tùy chọn | Mô tả |
|--------|-------------|
| `--tools <list>`, `-t <list>` | Cho phép các công cụ tích hợp, extension và tùy chỉnh cụ thể |
| `--no-builtin-tools`, `-nbt` | Tắt công cụ tích hợp nhưng vẫn bật công cụ extension/tùy chỉnh |
| `--no-tools`, `-nt` | Tắt mọi công cụ |

Công cụ tích hợp: `ipython`.

### Tùy chọn tài nguyên

| Tùy chọn | Mô tả |
|--------|-------------|
| `-e`, `--extension <source>` | Tải extension từ path, npm hoặc git; có thể lặp lại |
| `--no-extensions`, `-ne` | Tắt việc tìm extension |
| `--skill <path>` | Tải skill; có thể lặp lại |
| `--no-skills`, `-ns` | Tắt việc tìm skill |
| `--prompt-template <path>` | Tải template prompt; có thể lặp lại |
| `--no-prompt-templates`, `-np` | Tắt việc tìm template prompt |
| `--theme <path>` | Tải theme; có thể lặp lại |
| `--no-themes` | Tắt việc tìm theme |
| `--no-context-files`, `-nc` | Tắt việc tìm `AGENTS.md` và `CLAUDE.md` |

Kết hợp `--no-*` với các cờ tường minh để chỉ tải đúng những gì bạn cần và bỏ qua settings. Ví dụ:

```bash
prime-agent --no-extensions -e ./my-extension.ts
```

### Tùy chọn chế độ tự động

Chế độ tự động là chính sách của host dành cho công việc không cần giám sát. Chế độ này bắt đầu ở trạng thái tắt. `--autonomous` bật chế độ, và việc cung cấp bất kỳ tùy chọn con `--autonomous-*` nào cũng bật chế độ. Host bắt đầu mỗi lần chạy đã bật với các bộ đếm continuation, lượt, token và thời gian đã trôi qua được đặt lại.

| Tùy chọn | Hành vi, đơn vị và mặc định |
|--------|------------------------------|
| `--autonomous` | Bật continuation tự động. Nếu không có gate, host tiếp tục yêu cầu công việc cho đến khi một giới hạn ngăn continuation tiếp theo. |
| `--autonomous-gate <command>` | Thêm lệnh shell phải chạy thành công trước khi lần chạy có thể kết thúc. Các lệnh lặp lại chạy theo thứ tự CLI; mặc định không có gate. |
| `--autonomous-gate-retries <n>` | Đặt giới hạn thử lại cho mỗi gate. Mặc định: `3`. Gate lỗi có thể tiếp tục khi số lần thử đã ghi nhận không vượt quá giá trị này; lần thử lỗi tiếp theo sẽ làm gate hết lượt. |
| `--autonomous-gate-timeout-ms <n>` | Đặt thời gian chờ cho mỗi tiến trình gate theo mili giây. Mặc định: `300000` (5 phút). Gate hết thời gian chờ bị đánh dấu lỗi và cây tiến trình bị dừng. |
| `--autonomous-max-continuations <n>` | Đặt số tin nhắn tiếp nối tối đa do host chèn vào. Mặc định: `3`. |
| `--autonomous-max-turns <n>` | Đặt số câu trả lời tối đa của assistant được tính khi bật chế độ tự động. Mặc định: `12`. |
| `--autonomous-max-tokens <n>` | Đặt tổng số token tích lũy tối đa. Mặc định: `80000`; việc tính gồm token đầu vào, đầu ra và ghi cache, nhưng không gồm token đọc cache. |
| `--autonomous-timeout-ms <n>` | Đặt thời gian tự động đã trôi qua tối đa theo mili giây. Mặc định: `1800000` (30 phút). |

Mọi giá trị `<n>` phải là số nguyên dương: giá trị bằng không, âm, phân số và không phải số đều bị từ chối. Các cờ tự động nhận giá trị yêu cầu một đối số riêng, không dùng dạng `--flag=value`. Giá trị bị thiếu sẽ bị từ chối, và tùy chọn dài đứng sau không bị dùng làm giá trị. Cờ số lặp lại sẽ dùng giá trị cuối; lặp `--autonomous-gate` sẽ thêm một gate khác.

Sau mỗi câu trả lời của assistant, các gate đã cấu hình chạy trước khi đánh giá giới hạn continuation thông thường. Mọi gate phải đạt thì lần chạy mới kết thúc. Gate lỗi cung cấp đầu ra lệnh có giới hạn cho continuation tiếp theo để agent sửa lỗi; Prime Agent tránh chạy lại gate lỗi không thay đổi và thay vào đó tăng số lần thử. Gate đạt cho phép hoàn tất ngay cả khi đã chạm một giới hạn về continuation, lượt, token hoặc thời gian. Nếu gate không đạt, hoặc không có gate, host chỉ có thể chèn continuation khác khi cả bốn giới hạn vẫn thấp hơn giá trị đã cấu hình. Các giới hạn được kiểm tra theo thứ tự: continuation, lượt, token rồi thời gian đã trôi qua. Chạm một giới hạn sẽ ngăn continuation tự động tiếp theo; điều đó không đồng nghĩa tác vụ đã thành công.

Ví dụ, lần chạy không tương tác này dùng cấu hình model có sẵn cục bộ, bỏ qua các thao tác mạng khi khởi động và giới hạn mọi ngân sách tự động, đồng thời yêu cầu kiểm tra dự án phải đạt:

```bash
prime-agent -p \
  --autonomous \
  --autonomous-gate "npm run check" \
  --autonomous-gate-retries 2 \
  --autonomous-gate-timeout-ms 300000 \
  --autonomous-max-continuations 3 \
  --autonomous-max-turns 12 \
  --autonomous-max-tokens 80000 \
  --autonomous-timeout-ms 1800000 \
  --model openai/gpt-5.1-codex \
  --offline \
  --thinking high \
  "Fix the failing check and report the verified result."
```

`--offline` tắt các thao tác mạng khi khởi động; tùy chọn này không cung cấp thông tin xác thực cho model và cũng không làm cho việc suy luận của provider trở thành offline. Hãy chọn model đã được cấu hình cho môi trường cục bộ.

Goal tách biệt với chế độ tự động: `--goal <objective>` chỉ bắt đầu một goal lâu dài cho phiên gốc mới chưa có trạng thái goal, còn chế độ tự động quyết định host có nên chèn continuation khác hay không. `--goal-token-budget <n>` là ngân sách token số nguyên dương cho goal ban đầu và yêu cầu có `--goal`.

### Tùy chọn khác

| Tùy chọn | Mô tả |
|--------|-------------|
| `--cwd <dir>` | Dùng thư mục làm việc cụ thể cho phiên |
| `--system-prompt <text>` | Thay prompt mặc định; tệp context và skill vẫn được nối thêm |
| `--append-system-prompt <text>` | Nối thêm vào system prompt |
| `--verbose` | Bắt buộc khởi động ở chế độ chi tiết |
| `--offline` | Tắt các thao tác mạng khi khởi động |
| `-h`, `--help` | Hiển thị trợ giúp |
| `-v`, `--version` | Hiển thị phiên bản |
| `--` | Kết thúc phân tích tùy chọn và coi mọi đối số sau đó là tin nhắn |

### Đối số tệp

Thêm tiền tố `@` trước tệp để đưa tệp vào tin nhắn:

```bash
prime-agent @prompt.md "Answer this"
prime-agent -p @screenshot.png "What's in this image?"
prime-agent @code.ts @test.ts "Review these files"
```

### Ví dụ

```bash
# Interactive with initial prompt
prime-agent "List all .ts files in src/"

# Non-interactive
prime-agent -p "Summarize this codebase"

# Non-interactive with piped stdin
cat README.md | prime-agent -p "Summarize this text"

# Different model
prime-agent --provider openai --model gpt-4o "Help me refactor"

# Model with provider prefix
prime-agent --model openai/gpt-4o "Help me refactor"

# Model with thinking level shorthand
prime-agent --model sonnet:high "Solve this complex problem"

# Limit model cycling
prime-agent --models "claude-*,gpt-4o"

# Restrict to the built-in IPython tool
prime-agent --tools ipython -p "Review the code"
```

### Biến môi trường

| Biến | Mô tả |
|----------|-------------|
| `PRIME_AGENT_CODING_AGENT_DIR` | Ghi đè thư mục cấu hình; mặc định là `~/.prime/agent` |
| `PRIME_AGENT_SESSION_DIR` | Ghi đè thư mục lưu trữ phiên; bị ghi đè bởi `--session-dir` |
| `PRIME_AGENT_CODING_AGENT_SESSION_DIR` | Bí danh cũ của `PRIME_AGENT_SESSION_DIR` |
| `PI_PACKAGE_DIR` | Ghi đè thư mục package, hữu ích cho path của kho Nix/Guix |
| `PI_OFFLINE` | Tắt các thao tác mạng khi khởi động, gồm kiểm tra cập nhật và kiểm tra cập nhật package |
| `PI_SKIP_VERSION_CHECK` | Bỏ qua kiểm tra cập nhật phiên bản Prime Agent khi khởi động. Việc này ngăn yêu cầu manifest phát hành |
| `PRIME_AGENT_DOWNLOAD_BASE_URL` | Ghi đè URL cơ sở của manifest phát hành và tarball Prime Agent |
| `PI_CACHE_RETENTION` | Đặt thành `long` để dùng cache prompt mở rộng khi được hỗ trợ |
| `PRIME_API_KEY` | API key Prime Inference; cũng dùng để chia sẻ trace khi có scope `agent_traces` |
| `PRIME_AGENT_TRACES_API_KEY` | API key Prime chỉ dùng cho việc chia sẻ trace theo lựa chọn |
| `PRIME_AGENT_TRACES_BASE_URL` | Ghi đè URL cơ sở của API tải trace Prime Agent |
| `PRIME_AGENT_KERNEL_PYTHON` | Dùng môi trường Python hiện có với `ipykernel` thay vì khởi tạo `~/.prime/agent/kernel-venv` |
| `VISUAL`, `EDITOR` | Trình soạn thảo bên ngoài cho Ctrl+G |

Các biến `PI_*` còn lại là những tên tương thích vẫn được runtime hiện tại đọc. Chúng không thay đổi tên ứng dụng, lệnh hoặc đường dẫn cấu hình mặc định `~/.prime/agent`.

## Nguyên tắc thiết kế

Prime Agent giữ bề mặt công cụ dành cho model ở mức nhỏ, đồng thời làm cho runtime IPython mạnh mẽ và có thể kết hợp. Công cụ `ipython` tích hợp cung cấp trạng thái lâu dài, thực thi lệnh dự án, skill Python, tích hợp dựa trên MCP và API ủy quyền `rlm` gốc mà không trình bày từng khả năng như một công cụ model riêng.

Subagent đệ quy là khả năng cốt lõi, không phải extension tùy chọn. Host TypeScript sở hữu mọi vòng lặp agent cha và con, để việc đệ quy dùng cùng hạ tầng provider, phiên, công cụ, skill, lập lịch, tính mức sử dụng và khôi phục. Package Python `rlm` là cầu nối mỏng tới host thay vì một bản triển khai agent riêng.

Extension, skill, template prompt, theme và package Prime Agent tiếp tục là các bề mặt tùy chỉnh chính. Chúng có thể thêm workflow theo dự án, công cụ và UI tùy chỉnh, chính sách quyền, tích hợp provider và các mẫu điều phối xoay quanh runtime tích hợp.

Prime Agent vẫn ghi nhận pi-mono theo giấy phép MIT trong nguồn gốc upstream, nhưng các tuyên bố và giới hạn của sản phẩm Pi upstream không mô tả kiến trúc Prime Agent hiện tại.

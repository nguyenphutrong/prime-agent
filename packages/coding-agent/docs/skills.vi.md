> Prime Agent có thể tạo skill. Hãy yêu cầu nó xây dựng một skill cho trường hợp sử dụng của bạn.

# Các skill

Skill là các gói khả năng độc lập mà Prime Agent tải theo yêu cầu. Mỗi skill cung cấp quy trình chuyên biệt, hướng dẫn thiết lập, script trợ giúp và tài liệu tham khảo cho các tác vụ cụ thể.

Prime Agent triển khai [tiêu chuẩn Agent Skills](https://agentskills.io/specification), cảnh báo về các vi phạm nhưng vẫn linh hoạt. Prime Agent cũng hỗ trợ skill chạy bằng Python: một siêu tập của skill Markdown, cài các package Python vào kernel IPython bền vững.

## Mục lục

- [Vị trí](#vị-trí)
- [Skill tích hợp](#skill-tích-hợp)
- [Cách skill hoạt động](#cách-skill-hoạt-động)
- [Skill chạy bằng Python](#skill-chạy-bằng-python)
- [Tạo skill với Prime Agent](#tạo-skill-với-prime-agent)
- [Các lệnh skill](#các-lệnh-skill)
- [Cấu trúc skill](#cấu-trúc-skill)
- [Frontmatter](#frontmatter)
- [Xác thực](#xác-thực)
- [Ví dụ](#ví-dụ)
- [Kho skill](#kho-skill)

## Vị trí

> **Bảo mật:** Skill có thể hướng dẫn model thực hiện bất kỳ hành động nào và có thể chứa mã thực thi mà model gọi. Hãy xem nội dung skill trước khi sử dụng.

Prime Agent tải skill từ:

- Toàn cục:
  - `~/.prime/agent/skills/`
  - `~/.agents/skills/`
- Project:
  - `.prime/agent/skills/`
  - `.agents/skills/` trong `cwd` và các thư mục tổ tiên (tối đa đến gốc git, hoặc gốc filesystem khi không ở trong repo)
- Package: các thư mục `skills/` hoặc mục `pi.skills` trong `package.json`
- Settings: mảng `skills` chứa file hoặc thư mục
- CLI: `--skill <path>` (có thể lặp lại, cộng dồn ngay cả với `--no-skills`)
- Tích hợp sẵn: `skills/` đi kèm package prime-agent (độ ưu tiên thấp nhất)

Quy tắc phát hiện:
- Trong `~/.prime/agent/skills/` và `.prime/agent/skills/`, các file `.md` trực tiếp ở thư mục gốc được phát hiện như các skill riêng lẻ
- Ở mọi vị trí skill, các thư mục chứa `SKILL.md` được phát hiện đệ quy
- Trong `~/.agents/skills/` và `.agents/skills/` của project, các file `.md` ở thư mục gốc bị bỏ qua

Tắt việc phát hiện bằng `--no-skills` (các đường dẫn `--skill` rõ ràng vẫn được tải).

## Skill tích hợp

Prime Agent cung cấp các skill tích hợp được tải mặc định:

- `prime-intellect` - các sản phẩm và quy trình Prime Intellect qua prime CLI: môi trường verifier và Environments Hub, đánh giá (cục bộ và hosted), Hosted Training và prime-rl, sandbox, tunnel, Prime Inference, tính toán GPU và lưu trữ. Tài liệu tham khảo cho từng lĩnh vực được tải theo yêu cầu từ thư mục `references/` của skill.
- `skill-creator` - hướng dẫn agent tạo skill: bố cục skill Markdown, quy tắc frontmatter, vị trí và độ ưu tiên, cùng hợp đồng đầy đủ của skill chạy bằng Python (bố cục package, quy ước `run()`, CLI tùy chọn, hành vi venv của kernel), với template hoạt động trong `references/python-skills.md`.
- `websearch` - skill tìm kiếm Google chạy bằng Python qua API [Serper](https://serper.dev).

Skill tích hợp hoạt động như mọi skill khác nhưng có độ ưu tiên thấp nhất: skill của người dùng, project, package hoặc skill được chỉ định bằng `--skill` cùng tên sẽ ghi đè skill tích hợp.

### websearch

Thiết lập: lấy API key miễn phí tại [serper.dev](https://serper.dev), rồi chạy `/login`, chuyển sang **MCP Connections** bằng các phím tắt tab được hiển thị và chọn **Serper (web search)** để dán key. Key được lưu cùng các thông tin xác thực khác (trong `auth.json`) và skill đọc key ở mỗi lần gọi — không cần biến môi trường, đồng thời vẫn hoạt động nếu bạn thêm key giữa phiên.

Ghi đè tùy chọn (biến môi trường):

```bash
export PRIME_AGENT_WEBSEARCH_TIMEOUT=45
export PRIME_AGENT_WEBSEARCH_NUM_RESULTS=5
```



`SERPER_API_KEY` trong môi trường, nếu có, được ưu tiên hơn key đã lưu.

Sau khi được tải, model có thể gọi skill trực tiếp trong kernel IPython bằng tên import:

```python
print(await websearch("latest Prime Agent release"))
```



Cho đến khi cấu hình key, tìm kiếm web trả về thông báo rõ ràng yêu cầu agent hướng dẫn bạn qua `/login`.

Tắt riêng skill `websearch` tích hợp trong settings:

```json
{
  "bundledSkills": {
    "websearch": false
  }
}
```



Để tắt toàn bộ skill tích hợp, đặt `enableBuiltinSkills` thành `false` trong `settings.json` (hoặc bật/tắt “Built-in skills” trong `/settings`):

```json
{
  "enableBuiltinSkills": false
}
```



`--no-skills` cũng loại trừ các skill tích hợp. Để tắt một skill tích hợp riêng lẻ mà không cần setting chuyên dụng, buộc loại trừ nó trong mảng `skills` toàn cục (các pattern được phân giải tương đối với thư mục skill tích hợp):

```json
{
  "skills": ["-prime-intellect/SKILL.md"]
}
```



### Dùng skill từ các harness khác

Để dùng skill từ Claude Code hoặc OpenAI Codex, thêm thư mục của chúng vào settings:

```json
{
  "skills": [
    "~/.claude/skills",
    "~/.codex/skills"
  ]
}
```



Đối với skill cấp project của Claude Code, thêm vào `.prime/agent/settings.json`:

```json
{
  "skills": ["../.claude/skills"]
}
```



## Cách skill hoạt động

1. Khi khởi động, Prime Agent quét các vị trí skill và trích xuất tên, mô tả, loại và vị trí file
2. System prompt chứa các skill hiển thị dưới dạng XML theo [đặc tả](https://agentskills.io/integrate-skills)
3. Khi một tác vụ phù hợp, agent dùng `ipython` để tải toàn bộ `SKILL.md` (model không phải lúc nào cũng làm vậy; dùng prompt hoặc `/skill:name` để buộc tải)
4. Agent làm theo hướng dẫn, dùng đường dẫn tương đối để tham chiếu script và asset

Đây là cơ chế tiết lộ dần: chỉ mô tả luôn có trong ngữ cảnh; hướng dẫn đầy đủ được tải theo yêu cầu.

Skill có `disable-model-invocation: true` bị ẩn khỏi danh sách skill lúc khởi động. Tuy vậy, chúng vẫn có thể được gọi rõ ràng bằng `/skill:name`.

## Skill chạy bằng Python

Skill chạy bằng Python dùng metadata và cơ chế gọi `SKILL.md` như skill Markdown, đồng thời cung cấp một package Python cho kernel IPython.

```
web-search/
├── SKILL.md
├── pyproject.toml
└── src/
    └── web_search/
        └── __init__.py
```



Quy tắc phát hiện:
- Vẫn bắt buộc có `SKILL.md`
- `pyproject.toml` đánh dấu skill là skill chạy bằng Python
- tên import là tên skill sau khi đổi dấu gạch nối thành dấu gạch dưới
- phải có `src/<import_name>/__init__.py`

Với `web-search`, Prime Agent cung cấp `web_search` trong IPython. Nếu module định nghĩa `run()`, module được bọc thành một hàm async có thể gọi:

```python
await web_search("prime agent skills")
await web_search.run("prime agent skills")
help(web_search)
```



Skill Python được cài ở chế độ editable vào venv của kernel trong quá trình thiết lập kernel. Mặc định đây là `~/.prime/agent/kernel-venv`; đặt `PRIME_AGENT_KERNEL_VENV` để ghi đè. Nếu `pyproject.toml` thay đổi, Prime Agent xây dựng lại venv kernel để tiếp nhận thay đổi dependency.

Nếu đặt `PRIME_AGENT_KERNEL_PYTHON`, Prime Agent không cài package vào môi trường đó. Python phải có sẵn `ipykernel`, `prime-agent-runtime` và các package runtime mặc định. Import skill Python bị thiếu sẽ bị tắt kèm cảnh báo và việc gọi skill sẽ ném `RuntimeError`.

### Lệnh CLI tùy chọn

Skill Python có thể cung cấp lệnh shell bằng cách khai báo console script trong `pyproject.toml`. Tên script phải khớp chính xác với tên import Python, bao gồm cả dấu gạch dưới:

```toml
[project]
name = "web-search"
version = "0.1.0"
dependencies = ["requests"]

[project.scripts]
web_search = "rlm.skill:cli"
```



Helper `rlm.skill:cli` import `web_search.run`, phân tích đối số CLI bằng `tyro`, chờ kết quả bất đồng bộ và in các giá trị trả về khác `None`.

```python
async def run(query: str, limit: int = 5) -> str:
    """Search the web and return a concise summary."""
    ...
```



Model có thể gọi skill từ Python thông thường hoặc từ chế độ shell:

```python
await web_search("prime agent")
!web_search "prime agent" --limit 3
```



## Tạo skill với Prime Agent

Prime Agent đi kèm skill tích hợp `skill-creator`, hướng dẫn agent cả định dạng Agent Skills lẫn hợp đồng package chạy bằng Python. Bạn có thể yêu cầu tạo skill bằng ngôn ngữ tự nhiên:

```text
Create a project Python-backed skill named release-audit in
.prime/agent/skills/release-audit. It should expose
await release_audit(repository, target_version), include concise SKILL.md
instructions, declare its dependencies, and verify the callable in a fresh
Prime Agent session.
```



Để buộc gọi trực tiếp quy trình tạo, hãy gọi lệnh skill tích hợp:

```text
/skill:skill-creator Create a personal markdown skill for reviewing database migrations.
```



Hãy nêu ba điều với agent:

1. **Phạm vi:** dùng `.prime/agent/skills/<name>/` cho skill project được commit cùng repository, hoặc `~/.prime/agent/skills/<name>/` cho skill cá nhân.
2. **Loại:** yêu cầu skill Markdown khi khả năng chủ yếu là hướng dẫn; yêu cầu skill chạy bằng Python khi agent cần gọi chức năng có thể tái sử dụng từ IPython.
3. **Hợp đồng:** mô tả lời gọi Python dự kiến, input, output, dependency, credential và hành vi xác minh.

Agent nên tạo `SKILL.md` trong cả hai trường hợp. Với skill chạy bằng Python, agent cũng nên tạo `pyproject.toml` và `src/<import_name>/__init__.py`, cung cấp callable có tài liệu và xác minh package import được trong kernel.

Dùng `/reload` để phát hiện lại metadata skill mới hoặc đã sửa. Hãy bắt đầu phiên Prime Agent mới sau khi thêm skill chạy bằng Python để kernel có thể cài và import package.

### Skill đã cài và skill harness liên tục

Skill chạy bằng Python đã cài là một package thực trên ổ đĩa, bổ sung chức năng thực thi cho kernel. Mục skill harness liên tục là mô tả đã lưu về một lời gọi Python có thể tái sử dụng, gồm tham chiếu và hợp đồng đối số. `/refine` có thể tạo hoặc cập nhật mục sau khi một quy trình lặp lại hình thành, nhưng không thay thế việc đóng gói chức năng mới bằng `skill-creator`.

## Các lệnh skill

Skill đăng ký thành các lệnh `/skill:name`:

```bash
/skill:brave-search           # Load and execute the skill
/skill:pdf-tools extract      # Load skill with arguments
```



Các đối số sau lệnh được nối vào nội dung skill dưới dạng `User: <args>`.

Bật/tắt lệnh skill qua `/settings` trong chế độ tương tác hoặc trong `settings.json`:

```json
{
  "enableSkillCommands": true
}
```



## Cấu trúc skill

Skill là một thư mục có file `SKILL.md`. Mọi thứ khác đều tùy ý.

```
my-skill/
├── SKILL.md              # Required: frontmatter + instructions
├── scripts/              # Helper scripts
│   └── process.sh
├── references/           # Detailed docs loaded on-demand
│   └── api-reference.md
└── assets/
    └── template.json
```

### Định dạng SKILL.md

````markdown
---
name: my-skill
description: What this skill does and when to use it. Be specific.
---

# My Skill

## Setup

Run once before first use:
```bash
cd /path/to/skill && npm install
```

## Usage

```bash
./scripts/process.sh <input>
```
````

Dùng đường dẫn tương đối từ thư mục skill:

```markdown
See [the reference guide](references/REFERENCE.md) for details.
```

## Frontmatter

Theo [đặc tả Agent Skills](https://agentskills.io/specification#frontmatter-required):

| Trường | Bắt buộc | Mô tả |
|-------|----------|-------------|
| `name` | Có | Tối đa 64 ký tự. Chỉ chữ thường a-z, số 0-9 và dấu gạch nối. Phải khớp thư mục cha. |
| `description` | Có | Tối đa 1024 ký tự. Skill làm gì và dùng khi nào. |
| `license` | Không | Tên license hoặc tham chiếu đến file đi kèm. |
| `compatibility` | Không | Tối đa 500 ký tự. Các yêu cầu môi trường. |
| `metadata` | Không | Ánh xạ key-value tùy ý. |
| `allowed-tools` | Không | Danh sách tool được phê duyệt trước, phân tách bằng dấu cách (thử nghiệm). |
| `disable-model-invocation` | Không | Khi là `true`, skill bị ẩn khỏi system prompt. Người dùng phải dùng `/skill:name`. |

### Quy tắc tên

- 1-64 ký tự
- Chỉ chữ thường, số và dấu gạch nối
- Không có dấu gạch nối ở đầu/cuối
- Không có hai dấu gạch nối liên tiếp
- Phải khớp tên thư mục cha

Hợp lệ: `pdf-processing`, `data-analysis`, `code-review`
Không hợp lệ: `PDF-Processing`, `-pdf`, `pdf--processing`

### Thực hành tốt cho description

Description quyết định thời điểm agent tải skill. Hãy viết cụ thể.

Tốt:
```yaml
description: Extracts text and tables from PDF files, fills PDF forms, and merges multiple PDFs. Use when working with PDF documents.
```

Kém:
```yaml
description: Helps with PDFs.
```

## Xác thực

Prime Agent xác thực skill theo tiêu chuẩn Agent Skills. Hầu hết vấn đề tạo cảnh báo nhưng skill vẫn được tải:

- Tên không khớp thư mục cha
- Tên dài hơn 64 ký tự hoặc chứa ký tự không hợp lệ
- Tên bắt đầu/kết thúc bằng dấu gạch nối hoặc có hai dấu gạch nối liên tiếp
- Description dài hơn 1024 ký tự

Các trường frontmatter không xác định bị bỏ qua.

**Ngoại lệ:** Skill thiếu description sẽ không được tải.

Trùng tên (cùng tên ở các vị trí khác nhau) sẽ tạo cảnh báo và giữ skill đầu tiên được tìm thấy.

## Ví dụ

```
brave-search/
├── SKILL.md
├── search.js
└── content.js
```

**SKILL.md:**
````markdown
---
name: brave-search
description: Web search and content extraction via Brave Search API. Use for searching documentation, facts, or any web content.
---

# Brave Search

## Setup

```bash
cd /path/to/brave-search && npm install
```

## Search

```bash
./search.js "query"              # Basic search
./search.js "query" --content    # Include page content
```

## Extract Page Content

```bash
./content.js https://example.com
```
````

## Kho skill

- [Anthropic Skills](https://github.com/anthropics/skills) - Xử lý tài liệu (docx, pdf, pptx, xlsx), phát triển web
- [Pi Skills](https://github.com/badlogic/pi-skills) - Tìm kiếm web, tự động hóa trình duyệt, Google APIs, chuyển lời nói thành văn bản

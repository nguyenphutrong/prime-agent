# Tích hợp MCP

Kết nối các dịch vụ bên ngoài (Linear, Notion, …) với Prime Agent qua
[Model Context Protocol](https://modelcontextprotocol.io).

Phù hợp với thiết kế một-tool của Prime Agent, các tích hợp MCP **không**
được expose thành tool agent mới. Mỗi tích hợp là một [skill Python](skills.vi.md)
mà model import và gọi từ kernel IPython:

```python
import linear
issues = await linear.list_issues(team="Engineering")
```

Kết nối MCP chạy bên trong kernel qua Python SDK chính thức `mcp`. Host chỉ phụ
trách đăng nhập tương tác (browser OAuth) và tạo/làm mới thông tin xác thực trong
`auth.json`.

## Mục lục

- [Dùng tích hợp có sẵn](#dùng-tích-hợp-có-sẵn)
- [Một lần gọi hoạt động như thế nào](#một-lần-gọi-hoạt-động-như-thế-nào)
- [Tự viết tích hợp](#tự-viết-tích-hợp)
  - [1. Khai báo server](#1-khai-báo-server)
  - [2. Đóng gói skill](#2-đóng-gói-skill)
  - [Xác thực](#xác-thực)
- [API `McpIntegration`](#api-mcpintegration)
- [Vòng đời bật khi đăng nhập](#vòng-đời-bật-khi-đăng-nhập)
- [Lưu ý](#lưu-ý)

## Dùng tích hợp có sẵn

Các tích hợp có sẵn (Linear, Notion) được cung cấp ở trạng thái **disabled**. Đăng nhập sẽ bật chúng:

- Mở `/login`, chuyển sang **MCP Connections**, chọn tích hợp và hoàn tất OAuth trong browser. `/mcp login <name>` thực hiện tương tự từ CLI.
- Sau khi kết nối, skill của tích hợp hiển thị với model và được tự động import vào kernel.
- `/mcp` liệt kê các tích hợp và trạng thái kết nối; `/mcp logout <name>` ngắt kết nối.

Thông tin xác thực được lưu một lần trong `~/.prime/agent/auth.json` dưới khóa
`mcp:<name>`. Việc bật được suy ra từ sự tồn tại của thông tin xác thực hợp lệ — không có công tắc bật/tắt riêng.

## Một lần gọi hoạt động như thế nào

Bộ tool do **server**, không phải skill, định nghĩa, vì vậy hãy khám phá trước khi
gọi — đừng giả định tên hoặc tham số của tool:

```python
import linear

# 1. Discover available tools
for tool in await linear.list_tools():
    print(tool["name"], "-", tool["description"])

# 2. Inspect a tool's argument schema
help(linear.list_issues)        # populated once list_tools() has run

# 3. Call it; keyword args match the tool's JSON Schema
result = await linear.list_issues(team="Engineering")
```

- Mọi tool đều là method `async` — luôn dùng `await`.
- Kết quả đã được phân tích sẵn thành Python: `dict` cho output có cấu trúc, string cho text hoặc danh sách content block nếu không thuộc hai dạng trên. Không cần `json.loads`.
- Tool có tên không phải Python identifier hợp lệ (ví dụ `notion-search`) được gọi qua escape hatch: `await notion.call_tool("notion-search", {...})`.
- Gọi một tích hợp chưa có thông tin xác thực sẽ phát sinh `NotEnabled` (hướng dẫn người dùng chạy `/mcp login`); tool trả lỗi sẽ phát sinh `McpToolError`.

## Tự viết tích hợp

Một tích hợp là [gói skill Python](skills.vi.md#python-backed-skills) có module
subclass `McpIntegration`. Các gói `linear` / `notion` có sẵn là implementation
tham khảo.

### 1. Khai báo server

Thêm server dưới `mcpServers` trong `~/.prime/agent/settings.json` (hoặc
`.prime/agent/settings.json` của project):

```jsonc
// ~/.prime/agent/settings.json
{
  "mcpServers": {
    "acme": {
      "type": "http",
      "url": "https://mcp.acme.com/mcp",
      "oauth": true
    }
  }
}
```

Hiện tại `McpIntegration` chỉ hỗ trợ server remote kiểu `"http"`. Các trường
server HTTP:

| Trường | Ý nghĩa |
|-------|---------|
| `type` | Phải là `"http"` |
| `url` | Endpoint MCP |
| `oauth` | `true` để dùng luồng OAuth trong browser (server phải hỗ trợ dynamic client registration) |
| `bearerTokenEnvVar` | Tên env var chứa static bearer token, thay cho OAuth |
| `headers` | Các HTTP header tĩnh bổ sung được gửi trong mọi request |
| `enabled` | Đặt `false` để buộc tắt ngay cả khi có thông tin xác thực |

> `stdio` (server local chạy bằng subprocess) chưa được nối tới kernel — host bỏ qua các entry không phải HTTP — nên một tích hợp phải nhắm đến endpoint HTTP.

### 2. Đóng gói skill

Tạo một thư mục skill (bất kỳ [vị trí skill nào](skills.vi.md#locations), ví dụ
`~/.prime/agent/skills/acme/`) với layout Python-skill chuẩn:

```
acme/
  SKILL.md
  pyproject.toml
  src/acme/__init__.py
```

`pyproject.toml` (phụ thuộc vào `mcp`, `httpx` và `prime-agent-runtime`):

```toml
[project]
name = "prime-agent-skill-acme"
version = "0.1.0"
requires-python = ">=3.10"
dependencies = ["mcp", "httpx", "prime-agent-runtime"]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/acme"]
```

`src/acme/__init__.py`:

```python
from rlm import McpIntegration

class Acme(McpIntegration):
    server = "acme"                      # matches the mcpServers key / auth.json `mcp:acme`
    url = "https://mcp.acme.com/mcp"

acme = Acme()

# Forward bare module access (`import acme; await acme.<tool>(...)`) to the
# instance, but NOT the names the kernel bootstrap probes — forwarding `run`
# would make it treat the module as a callable skill and break tool dispatch.
_RESERVED = {"run", "__wrapped__", "__call__"}

def __getattr__(name):
    if name.startswith("_") or name in _RESERVED:
        raise AttributeError(name)
    return getattr(acme, name)
```

Base class kết nối bằng SDK `mcp`, phân giải URL/header từ host (tuân theo cấu hình
`mcpServers`), đưa bearer token từ `auth.json` vào (làm mới khi hết hạn) và bind
tool của server thành các method async. Viết tích hợp chỉ cần vài dòng — toàn bộ
tích hợp chính là package trên.

### Xác thực

- **OAuth** (`"oauth": true`): người dùng chạy `/login` → MCP Connections → server của bạn (hoặc `/mcp login acme`). Hoạt động khi server hỗ trợ dynamic client registration OAuth 2.1 (RFC 7591); thao tác đăng nhập sẽ tìm auth server, đăng ký client và chạy PKCE. Server yêu cầu client id đăng ký trước hiện chưa được hỗ trợ qua `mcpServers`.
- **Static bearer token** (`"bearerTokenEnvVar": "ACME_TOKEN"`): không cần đăng nhập; tích hợp được coi là “connected” khi env var đó được thiết lập. Đặt `bearer_token_env = "ACME_TOKEN"` tương ứng trên subclass.

## API `McpIntegration`

Import từ `rlm` (`from rlm import McpIntegration`).

Các class attribute cần đặt trên subclass:

- `server: str` — bắt buộc; key `mcpServers` và credential id trong `auth.json`.
- `url: str | None` — endpoint remote (bắt buộc trừ khi override `_open_session` cho transport không phải HTTP).
- `bearer_token_env: str | None` — env var tùy chọn chứa static bearer token.

Các method:

- `await list_tools() -> list[dict]` — các tool của server dưới dạng `[{name, description, inputSchema}]`. Đồng thời tạo docstring hiển thị bởi `help(integration.<tool>)`.
- `await call_tool(name, arguments={}) -> Any` — gọi tường minh; escape hatch cho tên tool không phải identifier.
- `integration.<tool>(**kwargs)` — method async tự bind cho mọi tool đã khám phá.

Exception (đều import được từ `rlm`):

- `NotEnabled` — phát sinh khi không có thông tin xác thực dùng được (chưa đăng nhập).
- `McpToolError` — phát sinh khi lần gọi tool trả về kết quả được đánh dấu là lỗi.

## Vòng đời bật khi đăng nhập

Cơ chế kiểm soát xác thực này áp dụng cho các tích hợp **có sẵn** (Linear, Notion):

1. Skill có sẵn được cài nhưng **disabled** — bị loại khỏi prompt và không được import vào kernel — vì chưa có thông tin xác thực.
2. Người dùng đăng nhập; thông tin xác thực được ghi vào `auth.json` dưới `mcp:<server>`.
3. Reload resource (tự động sau `/login`/`/mcp login`, hoặc `/reload`) phát hiện thông tin xác thực, bật skill, rồi kernel cài và import package.
4. Logout (hoặc mất thông tin xác thực) sẽ tắt skill một lần nữa.

Nếu đăng nhập giữa turn, reload được trì hoãn — chạy `/reload` sau turn để kích hoạt tích hợp.

**Tích hợp do người dùng tự viết không bị kiểm soát xác thực theo cách này.** Skill bạn đặt vào thư mục skills được load như mọi skill khác — hiển thị với model và được import vào kernel ngay lập tức, bất kể `auth.json`. Skill chỉ thất bại lúc gọi với `NotEnabled` cho đến khi có thông tin xác thực. Vì vậy `SKILL.md` của skill cần hướng dẫn model cách kết nối khi lần gọi phát sinh `NotEnabled`, phù hợp với chế độ xác thực đã cấu hình:

- **OAuth** (`"oauth": true`): hướng dẫn người dùng chạy `/mcp login <server>` (hoặc `/login` → MCP Connections). `/mcp login` chỉ hoạt động với server OAuth.
- **Bearer token** (`bearerTokenEnvVar`): hướng dẫn người dùng đặt env var đó — *không* hướng họ đến `/mcp login`, vì lệnh này không có provider cho server chỉ dùng bearer và sẽ báo “Unknown MCP integration”.

## Lưu ý

- **Khám phá trước khi giả định.** Tên tool và schema tham số đến từ server và có thể thay đổi; gọi `list_tools()` / `help()` thay vì hardcode.
- **Kernel tùy chỉnh + trùng tên.** Tên import kernel là giá trị `server`. Với `PRIME_AGENT_KERNEL_PYTHON` tùy chỉnh đã có package PyPI không liên quan cùng tên (ví dụ `notion`), `import <name>` có thể resolve đến package đó. Dùng venv kernel mặc định do hệ thống quản lý để tránh việc này.
- **Ghi đè tên có sẵn.** Khai báo entry `mcpServers` có key trùng với một tích hợp có sẵn (ví dụ `linear`) và `url` tùy chỉnh sẽ trỏ tích hợp đến URL của bạn. Credential chính thức đã lưu trước đó *không* được dùng lại cho override, nhằm tránh gửi token chính thức đến endpoint của bạn. Chỉ xác thực override đó qua `bearerTokenEnvVar` — credential OAuth không được áp dụng cho override dùng tên trong catalog. (Dùng tên không phải tích hợp có sẵn để có OAuth.)
- **Daemon nhiều phiên.** Việc đăng ký OAuth provider là cấp process; server do người dùng khai báo chỉ dành cho một phiên daemon sẽ được đăng ký lại khi phiên đó reload lần tiếp theo.

Xem thêm: [Skills](skills.vi.md), [Settings](settings.vi.md).

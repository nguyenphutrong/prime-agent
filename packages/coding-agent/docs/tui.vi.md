> Prime Agent có thể tạo các thành phần TUI. Hãy yêu cầu nó xây dựng thành phần phù hợp với trường hợp sử dụng của bạn.

# Thành phần TUI

Các extension và công cụ tùy chỉnh có thể hiển thị thành phần TUI tùy chỉnh cho giao diện người dùng tương tác. Trang này trình bày hệ thống thành phần và các khối dựng sẵn.

**Mã nguồn:** [`packages/tui`](../../tui/)

## Giao diện thành phần

Mọi thành phần đều triển khai:

```typescript
interface Component {
  render(width: number): string[];
  handleInput?(data: string): void;
  wantsKeyRelease?: boolean;
  invalidate(): void;
}
```

| Phương thức | Mô tả |
|--------|-------------|
| `render(width)` | Trả về mảng chuỗi, mỗi chuỗi tương ứng một dòng. Mỗi dòng **không được dài quá `width`**. |
| `handleInput?(data)` | Nhận dữ liệu bàn phím khi thành phần được đặt focus. |
| `wantsKeyRelease?` | Nếu là `true`, thành phần nhận sự kiện nhả phím (giao thức Kitty). Mặc định: `false`. |
| `invalidate()` | Xóa trạng thái hiển thị đã lưu đệm. Được gọi khi theme thay đổi. |

TUI thêm mã đặt lại SGR đầy đủ và mã đặt lại OSC 8 ở cuối mỗi dòng được hiển thị. Kiểu không được giữ sang dòng tiếp theo. Khi xuất văn bản nhiều dòng có kiểu, hãy áp dụng lại kiểu trên từng dòng hoặc dùng `wrapTextWithAnsi()` để giữ kiểu cho mỗi dòng được ngắt.

## Giao diện Focusable (hỗ trợ IME)

Các thành phần hiển thị con trỏ văn bản và cần hỗ trợ IME (Trình soạn thảo phương thức nhập) nên triển khai giao diện `Focusable`:

```typescript
import { CURSOR_MARKER, type Component, type Focusable } from "@earendil-works/pi-tui";

class MyInput implements Component, Focusable {
  focused: boolean = false;  // Set by TUI when focus changes
  
  render(width: number): string[] {
    const marker = this.focused ? CURSOR_MARKER : "";
    // Emit marker right before the fake cursor
    return [`> ${beforeCursor}${marker}\x1b[7m${atCursor}\x1b[27m${afterCursor}`];
  }
}
```

Khi thành phần `Focusable` được đặt focus, TUI sẽ:
1. Đặt `focused = true` trên thành phần
2. Quét đầu ra đã hiển thị để tìm `CURSOR_MARKER` (một chuỗi thoát APC có độ rộng bằng không)
3. Đặt con trỏ phần cứng của terminal vào vị trí đó
4. Hiển thị con trỏ phần cứng

Điều này giúp cửa sổ ứng viên IME xuất hiện đúng vị trí đối với phương thức nhập CJK. Các thành phần dựng sẵn `Editor` và `Input` đã triển khai giao diện này.

### Thành phần Container chứa Input được nhúng

Khi một thành phần chứa (hộp thoại, bộ chọn, v.v.) có thành phần con là `Input` hoặc `Editor`, thành phần chứa phải triển khai `Focusable` và truyền trạng thái focus cho thành phần con. Nếu không, con trỏ phần cứng sẽ không được đặt đúng vị trí khi nhập bằng IME.

```typescript
import { Container, type Focusable, Input } from "@earendil-works/pi-tui";

class SearchDialog extends Container implements Focusable {
  private searchInput: Input;

  // Focusable implementation - propagate to child input for IME cursor positioning
  private _focused = false;
  get focused(): boolean {
    return this._focused;
  }
  set focused(value: boolean) {
    this._focused = value;
    this.searchInput.focused = value;
  }

  constructor() {
    super();
    this.searchInput = new Input();
    this.addChild(this.searchInput);
  }
}
```

Nếu không truyền trạng thái này, việc nhập bằng IME (tiếng Trung, tiếng Nhật, tiếng Hàn, v.v.) sẽ hiển thị cửa sổ ứng viên sai vị trí trên màn hình.

## Sử dụng thành phần

**Trong extension** qua `ctx.ui.custom()`:

```typescript
pi.on("session_start", async (_event, ctx) => {
  const handle = ctx.ui.custom(myComponent);
  // handle.requestRender() - trigger re-render
  // handle.close() - restore normal UI
});
```

**Trong công cụ tùy chỉnh** qua `pi.ui.custom()`:

```typescript
async execute(toolCallId, params, onUpdate, ctx, signal) {
  const handle = pi.ui.custom(myComponent);
  // ...
  handle.close();
}
```

## Lớp phủ

Lớp phủ hiển thị thành phần trên nội dung hiện có mà không xóa màn hình. Truyền `{ overlay: true }` vào `ctx.ui.custom()`:

```typescript
const result = await ctx.ui.custom<string | null>(
  (tui, theme, keybindings, done) => new MyDialog({ onClose: done }),
  { overlay: true }
);
```

Để định vị và đặt kích thước, hãy dùng `overlayOptions`:

```typescript
const result = await ctx.ui.custom<string | null>(
  (tui, theme, keybindings, done) => new SidePanel({ onClose: done }),
  {
    overlay: true,
    overlayOptions: {
      // Size: number or percentage string
      width: "50%",          // 50% of terminal width
      minWidth: 40,          // minimum 40 columns
      maxHeight: "80%",      // max 80% of terminal height

      // Position: anchor-based (default: "center")
      anchor: "right-center", // 9 positions: center, top-left, top-center, etc.
      offsetX: -2,            // offset from anchor
      offsetY: 0,

      // Or percentage/absolute positioning
      row: "25%",            // 25% from top
      col: 10,               // column 10

      // Margins
      margin: 2,             // all sides, or { top, right, bottom, left }

      // Responsive: hide on narrow terminals
      visible: (termWidth, termHeight) => termWidth >= 80,
    },
    // Get handle for programmatic visibility control
    onHandle: (handle) => {
      // handle.setHidden(true/false) - toggle visibility
      // handle.hide() - permanently remove
    },
  }
);
```

### Vòng đời lớp phủ

Các thành phần lớp phủ được giải phóng khi đóng. Không dùng lại các tham chiếu; hãy tạo đối tượng mới:

```typescript
// Wrong - stale reference
let menu: MenuComponent;
await ctx.ui.custom((_, __, ___, done) => {
  menu = new MenuComponent(done);
  return menu;
}, { overlay: true });
setActiveComponent(menu);  // Disposed

// Correct - re-call to re-show
const showMenu = () => ctx.ui.custom((_, __, ___, done) => 
  new MenuComponent(done), { overlay: true });

await showMenu();  // First show
await showMenu();  // "Back" = just call again
```

Xem [overlay-qa-tests.ts](../examples/extensions/overlay-qa-tests.ts) để tham khảo các ví dụ đầy đủ về neo, lề, xếp chồng, khả năng hiển thị đáp ứng và hoạt ảnh.

## Thành phần dựng sẵn

Nhập từ `@earendil-works/pi-tui`:

```typescript
import { Text, Box, Container, Spacer, Markdown } from "@earendil-works/pi-tui";
```

### Text

Văn bản nhiều dòng có tự động ngắt dòng.

```typescript
const text = new Text(
  "Hello World",    // content
  1,                // paddingX (default: 1)
  1,                // paddingY (default: 1)
  (s) => bgGray(s)  // optional background function
);
text.setText("Updated");
```

### Box

Bộ chứa có khoảng đệm và màu nền.

```typescript
const box = new Box(
  1,                // paddingX
  1,                // paddingY
  (s) => bgGray(s)  // background function
);
box.addChild(new Text("Content", 0, 0));
box.setBgFn((s) => bgBlue(s));
```

### Container

Nhóm các thành phần con theo chiều dọc.

```typescript
const container = new Container();
container.addChild(component1);
container.addChild(component2);
container.removeChild(component1);
```

### Spacer

Khoảng trống theo chiều dọc.

```typescript
const spacer = new Spacer(2);  // 2 empty lines
```

### Markdown

Hiển thị Markdown kèm tô sáng cú pháp.

```typescript
const md = new Markdown(
  "# Title\n\nSome **bold** text",
  1,        // paddingX
  1,        // paddingY
  theme     // MarkdownTheme (see below)
);
md.setText("Updated markdown");
```

### Image

Prime Agent hiển thị siêu dữ liệu hình ảnh dạng gọn và không xuất đồ họa terminal cho hình ảnh.

```typescript
const image = new Image(
  base64Data,   // base64-encoded image
  "image/png",  // MIME type
  theme,        // ImageTheme
  { filename: "result.png", fallbackOnly: true }
);
```

## Nhập từ bàn phím

Dùng `matchesKey()` để nhận diện phím:

```typescript
import { matchesKey, Key } from "@earendil-works/pi-tui";

handleInput(data: string) {
  if (matchesKey(data, Key.up)) {
    this.selectedIndex--;
  } else if (matchesKey(data, Key.enter)) {
    this.onSelect?.(this.selectedIndex);
  } else if (matchesKey(data, Key.escape)) {
    this.onCancel?.();
  } else if (matchesKey(data, Key.ctrl("c"))) {
    // Ctrl+C
  }
}
```

**Định danh phím** (dùng `Key.*` để tự động hoàn thành hoặc dùng chuỗi ký tự trực tiếp):
- Phím cơ bản: `Key.enter`, `Key.escape`, `Key.tab`, `Key.space`, `Key.backspace`, `Key.delete`, `Key.home`, `Key.end`
- Phím mũi tên: `Key.up`, `Key.down`, `Key.left`, `Key.right`
- Có phím bổ trợ: `Key.ctrl("c")`, `Key.shift("tab")`, `Key.alt("left")`, `Key.ctrlShift("p")`
- Cũng hỗ trợ dạng chuỗi: `"enter"`, `"ctrl+c"`, `"shift+tab"`, `"ctrl+shift+p"`

## Độ rộng dòng

**Quan trọng:** Mỗi dòng do `render()` trả về không được dài quá tham số `width`.

```typescript
import { visibleWidth, truncateToWidth } from "@earendil-works/pi-tui";

render(width: number): string[] {
  // Truncate long lines
  return [truncateToWidth(this.text, width)];
}
```

Tiện ích:
- `visibleWidth(str)` - Lấy độ rộng hiển thị (bỏ qua mã ANSI)
- `truncateToWidth(str, width, ellipsis?)` - Cắt ngắn, có thể thêm dấu ba chấm
- `wrapTextWithAnsi(str, width)` - Tự động ngắt dòng và giữ mã ANSI

## Tạo thành phần tùy chỉnh

Ví dụ: bộ chọn tương tác

```typescript
import {
  matchesKey, Key,
  truncateToWidth, visibleWidth
} from "@earendil-works/pi-tui";

class MySelector {
  private items: string[];
  private selected = 0;
  private cachedWidth?: number;
  private cachedLines?: string[];
  
  public onSelect?: (item: string) => void;
  public onCancel?: () => void;

  constructor(items: string[]) {
    this.items = items;
  }

  handleInput(data: string): void {
    if (matchesKey(data, Key.up) && this.selected > 0) {
      this.selected--;
      this.invalidate();
    } else if (matchesKey(data, Key.down) && this.selected < this.items.length - 1) {
      this.selected++;
      this.invalidate();
    } else if (matchesKey(data, Key.enter)) {
      this.onSelect?.(this.items[this.selected]);
    } else if (matchesKey(data, Key.escape)) {
      this.onCancel?.();
    }
  }

  render(width: number): string[] {
    if (this.cachedLines && this.cachedWidth === width) {
      return this.cachedLines;
    }

    this.cachedLines = this.items.map((item, i) => {
      const prefix = i === this.selected ? "> " : "  ";
      return truncateToWidth(prefix + item, width);
    });
    this.cachedWidth = width;
    return this.cachedLines;
  }

  invalidate(): void {
    this.cachedWidth = undefined;
    this.cachedLines = undefined;
  }
}
```

Cách dùng trong extension:

```typescript
pi.registerCommand("pick", {
  description: "Pick an item",
  handler: async (args, ctx) => {
    const items = ["Option A", "Option B", "Option C"];
    const selector = new MySelector(items);
    
    let handle: { close: () => void; requestRender: () => void };
    
    await new Promise<void>((resolve) => {
      selector.onSelect = (item) => {
        ctx.ui.notify(`Selected: ${item}`, "info");
        handle.close();
        resolve();
      };
      selector.onCancel = () => {
        handle.close();
        resolve();
      };
      handle = ctx.ui.custom(selector);
    });
  }
});
```

## Theme

Các thành phần nhận đối tượng theme để áp dụng kiểu.

**Trong `renderCall`/`renderResult`**, hãy dùng tham số `theme`:

```typescript
renderResult(result, options, theme, context) {
  // Use theme.fg() for foreground colors
  return new Text(theme.fg("success", "Done!"), 0, 0);
  
  // Use theme.bg() for background colors
  const styled = theme.bg("toolPendingBg", theme.fg("accent", "text"));
}
```

**Màu tiền cảnh** (`theme.fg(color, text)`):

| Danh mục | Màu |
|----------|--------|
| Chung | `text`, `accent`, `muted`, `dim` |
| Trạng thái | `success`, `error`, `warning` |
| Đường viền | `border`, `borderAccent`, `borderMuted` |
| Thông báo | `userMessageText`, `customMessageText`, `customMessageLabel` |
| Công cụ | `toolTitle`, `toolOutput` |
| Khác biệt | `toolDiffAdded`, `toolDiffRemoved`, `toolDiffContext` |
| Markdown | `mdHeading`, `mdLink`, `mdLinkUrl`, `mdCode`, `mdCodeBlock`, `mdCodeBlockBorder`, `mdQuote`, `mdQuoteBorder`, `mdHr`, `mdListBullet` |
| Cú pháp | `syntaxComment`, `syntaxKeyword`, `syntaxFunction`, `syntaxVariable`, `syntaxString`, `syntaxNumber`, `syntaxType`, `syntaxOperator`, `syntaxPunctuation` |
| Suy nghĩ | `thinkingOff`, `thinkingMinimal`, `thinkingLow`, `thinkingMedium`, `thinkingHigh`, `thinkingXhigh` |
| Chế độ | `bashMode` |

**Màu nền** (`theme.bg(color, text)`):

`selectedBg`, `userMessageBg`, `customMessageBg`, `toolPendingBg`, `toolSuccessBg`, `toolErrorBg`, `toolPanelBg`

**Với Markdown**, dùng `getMarkdownTheme()`:

```typescript
import { getMarkdownTheme } from "@earendil-works/pi-coding-agent";
import { Markdown } from "@earendil-works/pi-tui";

renderResult(result, options, theme, context) {
  const mdTheme = getMarkdownTheme();
  return new Markdown(result.details.markdown, 0, 0, mdTheme);
}
```

**Với thành phần tùy chỉnh**, hãy định nghĩa giao diện theme riêng:

```typescript
interface MyTheme {
  selected: (s: string) => string;
  normal: (s: string) => string;
}
```

## Ghi nhật ký gỡ lỗi

Đặt `PI_TUI_WRITE_LOG` để ghi lại luồng ANSI thô được ghi vào stdout.

```bash
PI_TUI_WRITE_LOG=/tmp/tui-ansi.log npx tsx packages/tui/test/chat-simple.ts
```

## Hiệu năng

Khi có thể, hãy lưu đệm kết quả hiển thị:

```typescript
class CachedComponent {
  private cachedWidth?: number;
  private cachedLines?: string[];

  render(width: number): string[] {
    if (this.cachedLines && this.cachedWidth === width) {
      return this.cachedLines;
    }
    // ... compute lines ...
    this.cachedWidth = width;
    this.cachedLines = lines;
    return lines;
  }

  invalidate(): void {
    this.cachedWidth = undefined;
    this.cachedLines = undefined;
  }
}
```

Gọi `invalidate()` khi trạng thái thay đổi, sau đó gọi `handle.requestRender()` để kích hoạt hiển thị lại.

## Invalidate và thay đổi theme

Khi theme thay đổi, TUI gọi `invalidate()` trên mọi thành phần để xóa bộ nhớ đệm. Thành phần phải triển khai đúng `invalidate()` để thay đổi theme có hiệu lực.

### Vấn đề

Nếu thành phần tạo sẵn màu theme trong chuỗi (qua `theme.fg()`, `theme.bg()`, v.v.) rồi lưu vào bộ nhớ đệm, các chuỗi đó sẽ chứa mã thoát ANSI của theme cũ. Chỉ xóa bộ nhớ đệm hiển thị là chưa đủ nếu thành phần lưu riêng nội dung đã áp theme.

**Cách làm sai** (màu theme sẽ không cập nhật):

```typescript
class BadComponent extends Container {
  private content: Text;

  constructor(message: string, theme: Theme) {
    super();
    // Pre-baked theme colors stored in Text component
    this.content = new Text(theme.fg("accent", message), 1, 0);
    this.addChild(this.content);
  }
  // No invalidate override - parent's invalidate only clears
  // child render caches, not the pre-baked content
}
```

### Giải pháp

Các thành phần tạo nội dung bằng màu theme phải dựng lại nội dung đó khi `invalidate()` được gọi:

```typescript
class GoodComponent extends Container {
  private message: string;
  private content: Text;

  constructor(message: string) {
    super();
    this.message = message;
    this.content = new Text("", 1, 0);
    this.addChild(this.content);
    this.updateDisplay();
  }

  private updateDisplay(): void {
    // Rebuild content with current theme
    this.content.setText(theme.fg("accent", this.message));
  }

  override invalidate(): void {
    super.invalidate();  // Clear child caches
    this.updateDisplay(); // Rebuild with new theme
  }
}
```

### Mẫu: dựng lại khi invalidate

Đối với thành phần có nội dung phức tạp:

```typescript
class ComplexComponent extends Container {
  private data: SomeData;

  constructor(data: SomeData) {
    super();
    this.data = data;
    this.rebuild();
  }

  private rebuild(): void {
    this.clear();  // Remove all children

    // Build UI with current theme
    this.addChild(new Text(theme.fg("accent", theme.bold("Title")), 1, 0));
    this.addChild(new Spacer(1));

    for (const item of this.data.items) {
      const color = item.active ? "success" : "muted";
      this.addChild(new Text(theme.fg(color, item.label), 1, 0));
    }
  }

  override invalidate(): void {
    super.invalidate();
    this.rebuild();
  }
}
```

### Khi nào cần điều này

Mẫu này cần thiết khi:

1. **Tạo sẵn màu theme** - Dùng `theme.fg()` hoặc `theme.bg()` để tạo chuỗi có kiểu và lưu trong thành phần con
2. **Tô sáng cú pháp** - Dùng `highlightCode()` để áp dụng màu cú pháp theo theme
3. **Bố cục phức tạp** - Dựng cây thành phần con có chứa màu theme

Mẫu này KHÔNG cần thiết khi:

1. **Dùng callback của theme** - Truyền các hàm như `(text) => theme.fg("accent", text)` được gọi trong lúc hiển thị
2. **Bộ chứa đơn giản** - Chỉ nhóm các thành phần khác mà không thêm nội dung có theme
3. **Hiển thị không trạng thái** - Tính toán đầu ra có theme mới trong mỗi lần gọi `render()` (không lưu đệm)

## Mẫu thường dùng

Các mẫu này đáp ứng những nhu cầu UI phổ biến nhất trong extension. **Hãy sao chép các mẫu này thay vì xây dựng từ đầu.**

### Mẫu 1: Hộp thoại chọn (SelectList)

Để cho phép người dùng chọn từ danh sách tùy chọn, hãy dùng `SelectList` từ `@earendil-works/pi-tui` cùng `DynamicBorder` để tạo khung.

```typescript
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { DynamicBorder } from "@earendil-works/pi-coding-agent";
import { Container, type SelectItem, SelectList, Text } from "@earendil-works/pi-tui";

pi.registerCommand("pick", {
  handler: async (_args, ctx) => {
    const items: SelectItem[] = [
      { value: "opt1", label: "Option 1", description: "First option" },
      { value: "opt2", label: "Option 2", description: "Second option" },
      { value: "opt3", label: "Option 3" },  // description is optional
    ];

    const result = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
      const container = new Container();

      // Top border
      container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));

      // Title
      container.addChild(new Text(theme.fg("accent", theme.bold("Pick an Option")), 1, 0));

      // SelectList with theme
      const selectList = new SelectList(items, Math.min(items.length, 10), {
        selectedPrefix: (t) => theme.fg("accent", t),
        selectedText: (t) => theme.fg("accent", t),
        description: (t) => theme.fg("muted", t),
        scrollInfo: (t) => theme.fg("dim", t),
        noMatch: (t) => theme.fg("warning", t),
      });
      selectList.onSelect = (item) => done(item.value);
      selectList.onCancel = () => done(null);
      container.addChild(selectList);

      // Help text
      container.addChild(new Text(theme.fg("dim", "↑↓ navigate • enter select • esc cancel"), 1, 0));

      // Bottom border
      container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));

      return {
        render: (w) => container.render(w),
        invalidate: () => container.invalidate(),
        handleInput: (data) => { selectList.handleInput(data); tui.requestRender(); },
      };
    });

    if (result) {
      ctx.ui.notify(`Selected: ${result}`, "info");
    }
  },
});
```

**Ví dụ:** [preset.ts](../examples/extensions/preset.ts), [tools.ts](../examples/extensions/tools.ts)

### Mẫu 2: Thao tác bất đồng bộ có thể hủy (BorderedLoader)

Đối với các thao tác mất thời gian và cần có thể hủy. `BorderedLoader` hiển thị biểu tượng quay và xử lý phím escape để hủy.

```typescript
import { BorderedLoader } from "@earendil-works/pi-coding-agent";

pi.registerCommand("fetch", {
  handler: async (_args, ctx) => {
    const result = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
      const loader = new BorderedLoader(tui, theme, "Fetching data...");
      loader.onAbort = () => done(null);

      // Do async work
      fetchData(loader.signal)
        .then((data) => done(data))
        .catch(() => done(null));

      return loader;
    });

    if (result === null) {
      ctx.ui.notify("Cancelled", "info");
    } else {
      ctx.ui.setEditorText(result);
    }
  },
});
```

**Ví dụ:** [qna.ts](../examples/extensions/qna.ts), [handoff.ts](../examples/extensions/handoff.ts)

### Mẫu 3: Cài đặt/công tắc (SettingsList)

Để bật tắt nhiều cài đặt, hãy dùng `SettingsList` từ `@earendil-works/pi-tui` cùng `getSettingsListTheme()`.

```typescript
import { getSettingsListTheme } from "@earendil-works/pi-coding-agent";
import { Container, type SettingItem, SettingsList, Text } from "@earendil-works/pi-tui";

pi.registerCommand("settings", {
  handler: async (_args, ctx) => {
    const items: SettingItem[] = [
      { id: "verbose", label: "Verbose mode", currentValue: "off", values: ["on", "off"] },
      { id: "color", label: "Color output", currentValue: "on", values: ["on", "off"] },
    ];

    await ctx.ui.custom((_tui, theme, _kb, done) => {
      const container = new Container();
      container.addChild(new Text(theme.fg("accent", theme.bold("Settings")), 1, 1));

      const settingsList = new SettingsList(
        items,
        Math.min(items.length + 2, 15),
        getSettingsListTheme(),
        (id, newValue) => {
          // Handle value change
          ctx.ui.notify(`${id} = ${newValue}`, "info");
        },
        () => done(undefined),  // On close
        { enableSearch: true }, // Optional: enable fuzzy search by label
      );
      container.addChild(settingsList);

      return {
        render: (w) => container.render(w),
        invalidate: () => container.invalidate(),
        handleInput: (data) => settingsList.handleInput?.(data),
      };
    });
  },
});
```

**Ví dụ:** [tools.ts](../examples/extensions/tools.ts)

### Mẫu 4: Chỉ báo trạng thái duy trì

Hiển thị trạng thái trong footer và duy trì qua các lần hiển thị. Phù hợp cho các chỉ báo chế độ.

```typescript
// Set status (shown in footer)
ctx.ui.setStatus("my-ext", ctx.ui.theme.fg("accent", "● active"));

// Clear status
ctx.ui.setStatus("my-ext", undefined);
```

**Ví dụ:** [status-line.ts](../examples/extensions/status-line.ts), [plan-mode/index.ts](../examples/extensions/plan-mode/index.ts), [preset.ts](../examples/extensions/preset.ts)

### Mẫu 4b: Tùy chỉnh chỉ báo đang làm việc

Tùy chỉnh chỉ báo đang làm việc nội tuyến trong khi Prime Agent đang truyền phản hồi.

```typescript
// Static indicator
ctx.ui.setWorkingIndicator({ frames: [ctx.ui.theme.fg("accent", "●")] });

// Custom animated indicator
ctx.ui.setWorkingIndicator({
  frames: [
    ctx.ui.theme.fg("dim", "·"),
    ctx.ui.theme.fg("muted", "•"),
    ctx.ui.theme.fg("accent", "●"),
    ctx.ui.theme.fg("muted", "•"),
  ],
  intervalMs: 120,
});

// Hide the indicator entirely
ctx.ui.setWorkingIndicator({ frames: [] });

// Restore Prime Agent's default spinner
ctx.ui.setWorkingIndicator();
```

Điều này chỉ ảnh hưởng đến chỉ báo đang làm việc trong quá trình truyền phản hồi thông thường. Bộ tải nén và thử lại vẫn giữ kiểu dựng sẵn. Khung tùy chỉnh được hiển thị nguyên văn, vì vậy extension phải tự thêm màu khi cần.

**Ví dụ:** [working-indicator.ts](../examples/extensions/working-indicator.ts)

### Mẫu 5: Widget phía trên/phía dưới Editor

Hiển thị nội dung duy trì phía trên hoặc phía dưới trình soạn thảo nhập liệu. Phù hợp cho danh sách việc cần làm và tiến độ.

```typescript
// Simple string array (above editor by default)
ctx.ui.setWidget("my-widget", ["Line 1", "Line 2"]);

// Render below the editor
ctx.ui.setWidget("my-widget", ["Line 1", "Line 2"], { placement: "belowEditor" });

// Or with theme
ctx.ui.setWidget("my-widget", (_tui, theme) => {
  const lines = items.map((item, i) =>
    item.done
      ? theme.fg("success", "✓ ") + theme.fg("muted", item.text)
      : theme.fg("dim", "○ ") + item.text
  );
  return {
    render: () => lines,
    invalidate: () => {},
  };
});

// Clear
ctx.ui.setWidget("my-widget", undefined);
```

**Ví dụ:** [widget-placement.ts](../examples/extensions/widget-placement.ts), [plan-mode/index.ts](../examples/extensions/plan-mode/index.ts)

### Mẫu 6: Footer tùy chỉnh

Thay thế chân trang. `footerData` cung cấp dữ liệu mà extension không thể truy cập theo cách khác.

```typescript
ctx.ui.setFooter((tui, theme, footerData) => ({
  invalidate() {},
  render(width: number): string[] {
    // footerData.getGitBranch(): string | null
    // footerData.getExtensionStatuses(): ReadonlyMap<string, string>
    return [`${ctx.model?.id} (${footerData.getGitBranch() || "no git"})`];
  },
  dispose: footerData.onBranchChange(() => tui.requestRender()), // reactive
}));

ctx.ui.setFooter(undefined); // restore default
```

Có thể lấy thống kê token qua `ctx.sessionManager.getBranch()` và `ctx.model`.

**Ví dụ:** [custom-footer.ts](../examples/extensions/custom-footer.ts)

### Mẫu 7: Editor tùy chỉnh (chế độ vim, v.v.)

Thay thế trình soạn thảo nhập liệu chính bằng một triển khai tùy chỉnh. Hữu ích cho chỉnh sửa theo chế độ (vim), bộ phím khác (emacs) hoặc xử lý nhập liệu chuyên biệt.

```typescript
import { CustomEditor, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { matchesKey, truncateToWidth } from "@earendil-works/pi-tui";

type Mode = "normal" | "insert";

class VimEditor extends CustomEditor {
  private mode: Mode = "insert";

  handleInput(data: string): void {
    // Escape: switch to normal mode, or pass through for app handling
    if (matchesKey(data, "escape")) {
      if (this.mode === "insert") {
        this.mode = "normal";
        return;
      }
      // In normal mode, escape aborts agent (handled by CustomEditor)
      super.handleInput(data);
      return;
    }

    // Insert mode: pass everything to CustomEditor
    if (this.mode === "insert") {
      super.handleInput(data);
      return;
    }

    // Normal mode: vim-style navigation
    switch (data) {
      case "i": this.mode = "insert"; return;
      case "h": super.handleInput("\x1b[D"); return; // Left
      case "j": super.handleInput("\x1b[B"); return; // Down
      case "k": super.handleInput("\x1b[A"); return; // Up
      case "l": super.handleInput("\x1b[C"); return; // Right
    }
    // Pass unhandled keys to super (ctrl+c, etc.), but filter printable chars
    if (data.length === 1 && data.charCodeAt(0) >= 32) return;
    super.handleInput(data);
  }

  render(width: number): string[] {
    const lines = super.render(width);
    // Add mode indicator to bottom border (use truncateToWidth for ANSI-safe truncation)
    if (lines.length > 0) {
      const label = this.mode === "normal" ? " NORMAL " : " INSERT ";
      const lastLine = lines[lines.length - 1]!;
      // Pass "" as ellipsis to avoid adding "..." when truncating
      lines[lines.length - 1] = truncateToWidth(lastLine, width - label.length, "") + label;
    }
    return lines;
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    // Factory receives theme and keybindings from the app
    ctx.ui.setEditorComponent((tui, theme, keybindings) =>
      new VimEditor(theme, keybindings)
    );
  });
}
```

**Điểm chính:**

- **Mở rộng `CustomEditor`** (không phải `Editor` cơ sở) để nhận bộ phím của ứng dụng (escape để hủy, ctrl+d để thoát, chuyển model, v.v.)
- **Gọi `super.handleInput(data)`** cho các phím bạn không xử lý
- **Mẫu factory**: `setEditorComponent` nhận một hàm factory được cung cấp `tui`, `theme` và `keybindings`
- **Truyền `undefined`** để khôi phục editor mặc định: `ctx.ui.setEditorComponent(undefined)`

**Ví dụ:** [modal-editor.ts](../examples/extensions/modal-editor.ts)

## Quy tắc chính

1. **Luôn dùng theme từ callback** - Không import theme trực tiếp. Dùng `theme` từ callback `ctx.ui.custom((tui, theme, keybindings, done) => ...)`.

2. **Luôn khai báo kiểu cho tham số màu của DynamicBorder** - Viết `(s: string) => theme.fg("accent", s)`, không viết `(s) => theme.fg("accent", s)`.

3. **Gọi tui.requestRender() sau khi thay đổi trạng thái** - Trong `handleInput`, gọi `tui.requestRender()` sau khi cập nhật trạng thái.

4. **Trả về đối tượng có ba phương thức** - Thành phần tùy chỉnh cần `{ render, invalidate, handleInput }`.

5. **Dùng thành phần có sẵn** - `SelectList`, `SettingsList`, `BorderedLoader` đáp ứng 90% trường hợp. Không cần xây dựng lại chúng.

## Ví dụ

- **Giao diện chọn**: [examples/extensions/preset.ts](../examples/extensions/preset.ts) - SelectList với khung DynamicBorder
- **Bất đồng bộ có thể hủy**: [examples/extensions/qna.ts](../examples/extensions/qna.ts) - BorderedLoader cho các lệnh gọi LLM
- **Công tắc cài đặt**: [examples/extensions/tools.ts](../examples/extensions/tools.ts) - SettingsList để bật/tắt công cụ
- **Chỉ báo trạng thái**: [examples/extensions/status-line.ts](../examples/extensions/status-line.ts) - `setStatus`
- **Widget trình soạn thảo**: [examples/extensions/widget-placement.ts](../examples/extensions/widget-placement.ts) - vị trí của `setWidget`
- **Chỉ báo đang làm việc**: [examples/extensions/working-indicator.ts](../examples/extensions/working-indicator.ts) - `setWorkingIndicator`
- **Footer tùy chỉnh**: [examples/extensions/custom-footer.ts](../examples/extensions/custom-footer.ts) - `setFooter` cùng thống kê
- **Editor tùy chỉnh**: [examples/extensions/modal-editor.ts](../examples/extensions/modal-editor.ts) - chỉnh sửa theo chế độ giống Vim
- **Trò chơi Snake**: [examples/extensions/snake.ts](../examples/extensions/snake.ts) - trò chơi đầy đủ với nhập phím và vòng lặp trò chơi
- **Hiển thị công cụ tùy chỉnh**: [examples/extensions/todo.ts](../examples/extensions/todo.ts) - `renderCall` và `renderResult`

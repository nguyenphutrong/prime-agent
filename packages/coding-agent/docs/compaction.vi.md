# Tóm tắt nén & phân nhánh

LLM có cửa sổ ngữ cảnh hạn chế. Khi cuộc trò chuyện kéo dài quá lâu, Prime Agent sẽ sử dụng tính năng nén để tóm tắt nội dung cũ hơn trong khi vẫn giữ nguyên tác phẩm gần đây. Trang này bao gồm cả việc tự động nén và tóm tắt nhánh.

**Tệp nguồn:**
- [`compaction.ts`](../src/core/compaction/compaction.ts) - Logic tự động nén
- [`branch-summarization.ts`](../src/core/compaction/branch-summarization.ts) - Tóm tắt chi nhánh
- [`utils.ts`](../src/core/compaction/utils.ts) - Tiện ích chia sẻ (theo dõi file, tuần tự hóa)
- [`session-manager.ts`](../src/core/session-manager.ts) - Các loại mục nhập (`CompactionEntry`, `BranchSummaryEntry`)
- [`extensions/types.ts`](../src/core/extensions/types.ts) - Các loại sự kiện mở rộng

Để biết các định nghĩa TypeScript trong dự án của bạn, hãy kiểm tra `node_modules/@earendil-works/pi-coding-agent/dist/`.

## Tổng quan

Prime Agent có hai cơ chế tổng hợp:

| Cơ chế | Kích hoạt | Mục đích |
|-----------|---------|---------|
| Nén | Ngữ cảnh vượt quá ngưỡng hoặc `/compact` | Tóm tắt các tin nhắn cũ để giải phóng ngữ cảnh |
| Tóm tắt chi nhánh | Điều hướng `/tree` | Bảo toàn ngữ cảnh khi chuyển nhánh |

Cả hai đều sử dụng cùng một định dạng tóm tắt có cấu trúc và theo dõi các hoạt động tích lũy của tệp.

## Nén chặt

### Khi Nó Kích Hoạt

Kích hoạt tự động nén khi:

```
contextTokens > contextWindow - reserveTokens
```

Theo mặc định, `reserveTokens` là 16384 mã thông báo (có thể định cấu hình trong `~/.prime/agent/settings.json` hoặc `<project-dir>/.prime/agent/settings.json`). Điều này nhường chỗ cho phản hồi của LLM.

Bạn cũng có thể kích hoạt thủ công bằng `/compact [instructions]`, trong đó các hướng dẫn tùy chọn tập trung vào phần tóm tắt — ví dụ: `/compact focus on the auth refactor, remember the exact migration command`. Các hướng dẫn được chuyển đến lời nhắc tóm tắt với mức độ ưu tiên cao, tồn tại trên `CompactionEntry` và hiển thị trên thông báo `[compaction]` trong TUI.

### Cách thức hoạt động

1. **Tìm điểm cắt**: Đi lùi từ tin nhắn mới nhất, tích lũy ước tính mã thông báo cho đến khi đạt đến `keepRecentTokens` (20k mặc định, có thể định cấu hình trong `~/.prime/agent/settings.json` hoặc `<project-dir>/.prime/agent/settings.json`)
2. **Trích xuất tin nhắn**: Thu thập tin nhắn từ ranh giới được giữ trước đó (hoặc bắt đầu phiên) cho đến điểm cắt
3. **Tạo tóm tắt**: Gọi LLM để tóm tắt ở định dạng có cấu trúc, chuyển bản tóm tắt trước đó dưới dạng ngữ cảnh lặp lại khi có
4. **Nối mục nhập**: Lưu `CompactionEntry` kèm theo bản tóm tắt và `firstKeptEntryId`
5. **Tải lại**: Tải lại phiên, sử dụng tóm tắt + tin nhắn từ `firstKeptEntryId` trở đi

```
Before compaction:

  entry:  0     1     2     3      4     5     6      7      8     9
        ┌─────┬─────┬─────┬─────┬──────┬─────┬─────┬──────┬──────┬─────┐
        │ hdr │ usr │ ass │ tool │ usr │ ass │ tool │ tool │ ass │ tool│
        └─────┴─────┴─────┴──────┴─────┴─────┴──────┴──────┴─────┴─────┘
                └────────┬───────┘ └──────────────┬──────────────┘
               messagesToSummarize            kept messages
                                   ↑
                          firstKeptEntryId (entry 4)

After compaction (new entry appended):

  entry:  0     1     2     3      4     5     6      7      8     9     10
        ┌─────┬─────┬─────┬─────┬──────┬─────┬─────┬──────┬──────┬─────┬─────┐
        │ hdr │ usr │ ass │ tool │ usr │ ass │ tool │ tool │ ass │ tool│ cmp │
        └─────┴─────┴─────┴──────┴─────┴─────┴──────┴──────┴─────┴─────┴─────┘
               └──────────┬──────┘ └──────────────────────┬───────────────────┘
                 not sent to LLM                    sent to LLM
                                                         ↑
                                              starts from firstKeptEntryId

What the LLM sees:

  ┌────────┬─────────┬─────┬─────┬──────┬──────┬─────┬──────┐
  │ system │ summary │ usr │ ass │ tool │ tool │ ass │ tool │
  └────────┴─────────┴─────┴─────┴──────┴──────┴─────┴──────┘
       ↑         ↑      └─────────────────┬────────────────┘
    prompt   from cmp          messages from firstKeptEntryId
```

Trong các lần nén lặp lại, khoảng tóm tắt bắt đầu ở ranh giới được giữ lại của lần nén trước đó (`firstKeptEntryId`), chứ không phải ở chính mục nhập nén, quay trở lại mục nhập sau lần nén trước đó nếu không thể tìm thấy mục nhập được lưu giữ đó trong đường dẫn. Điều này bảo tồn các thông báo còn sót lại sau quá trình nén trước đó bằng cách đưa chúng vào lần tóm tắt tiếp theo. Prime Agent cũng tính toán lại `tokensBefore` từ bối cảnh phiên được xây dựng lại trước khi ghi `CompactionEntry` mới, do đó số lượng mã thông báo phản ánh bối cảnh thực tế trước khi nén trước khi được thay thế.

### Chia lượt

Một "lượt" bắt đầu bằng tin nhắn của người dùng và bao gồm tất cả các phản hồi của trợ lý và lệnh gọi công cụ cho đến tin nhắn tiếp theo của người dùng. Thông thường, độ nén cắt ở ranh giới rẽ.

Khi một lượt vượt quá `keepRecentTokens`, điểm cắt sẽ xuất hiện ở giữa lượt với thông báo trợ lý. Đây là một "lượt rẽ":

```
Split turn (one huge turn exceeds budget):

  entry:  0     1     2      3     4      5      6     7      8
        ┌─────┬─────┬─────┬──────┬─────┬──────┬──────┬─────┬──────┐
        │ hdr │ usr │ ass │ tool │ ass │ tool │ tool │ ass │ tool │
        └─────┴─────┴─────┴──────┴─────┴──────┴──────┴─────┴──────┘
                ↑                                     ↑
         turnStartIndex = 1                  firstKeptEntryId = 7
                │                                     │
                └──── turnPrefixMessages (1-6) ───────┘
                                                      └── kept (7-8)

  isSplitTurn = true
  messagesToSummarize = []  (no complete turns before)
  turnPrefixMessages = [usr, ass, tool, ass, tool, tool]
```

Đối với các lượt chia nhỏ, Prime Agent tạo hai bản tóm tắt và hợp nhất chúng:
1. **Tóm tắt lịch sử**: Bối cảnh trước đó (nếu có)
2. **Tóm tắt tiền tố lượt**: Phần đầu của lượt chia

### Quy tắc điểm cắt

Điểm cắt hợp lệ là:
- Tin nhắn của người dùng
- Tin nhắn trợ lý
- Thông báo BashExecution
- Tin nhắn tùy chỉnh (custom_message, Branch_summary)

Không bao giờ cắt ở kết quả công cụ (họ phải tuân theo lệnh gọi công cụ của mình).

### Cấu trúc mục nhập nén

Được xác định trong [`session-manager.ts`](../src/core/session-manager.ts):

```typescript
interface CompactionEntry<T = unknown> {
  type: "compaction";
  id: string;
  parentId: string;
  timestamp: number;
  summary: string;
  firstKeptEntryId: string;
  tokensBefore: number;
  fromHook?: boolean;  // true if provided by extension (legacy field name)
  details?: T;         // implementation-specific data
  customInstructions?: string;  // user instructions from /compact <instructions>
}

// Default compaction uses this for details (from compaction.ts):
interface CompactionDetails {
  readFiles: string[];
  modifiedFiles: string[];
}
```

Tiện ích mở rộng có thể lưu trữ bất kỳ dữ liệu có thể tuần tự hóa JSON nào trong `details`. Việc nén mặc định theo dõi các hoạt động của tệp, nhưng việc triển khai tiện ích mở rộng tùy chỉnh có thể sử dụng cấu trúc riêng của chúng.

Xem [`prepareCompaction()` và `compact()`](../src/core/compaction/compaction.ts) để biết cách triển khai.

## Tóm tắt chi nhánh

### Khi Nó Kích Hoạt

Khi bạn sử dụng `/tree` để điều hướng đến một chi nhánh khác, Prime Agent sẽ tóm tắt công việc bạn sắp hoàn thành. Thao tác này sẽ chèn ngữ cảnh từ nhánh bên trái vào nhánh mới.

### Cách thức hoạt động

1. **Tìm tổ tiên chung**: Nút sâu nhất được chia sẻ bởi các vị trí cũ và mới
2. **Sưu tầm**: Đi từ lá già về tổ chung
3. **Chuẩn bị ngân sách**: Bao gồm các tin nhắn tối đa ngân sách mã thông báo (mới nhất trước)
4. **Tạo tóm tắt**: Gọi LLM với định dạng có cấu trúc
5. **Thêm mục**: Lưu `BranchSummaryEntry` tại điểm điều hướng

```
Tree before navigation:

         ┌─ B ─ C ─ D (old leaf, being abandoned)
    A ───┤
         └─ E ─ F (target)

Common ancestor: A
Entries to summarize: B, C, D

After navigation with summary:

         ┌─ B ─ C ─ D ─ [summary of B,C,D]
    A ───┤
         └─ E ─ F (new leaf)
```

### Theo dõi tệp tích lũy

Cả tệp theo dõi nén và tóm tắt nhánh đều được tích lũy. Khi tạo bản tóm tắt, Prime Agent sẽ trích xuất các hoạt động của tệp từ:
- Công cụ gọi trong tin nhắn đang được tóm tắt
- Việc nén trước hoặc tóm tắt nhánh `details` (nếu có)

Điều này có nghĩa là việc theo dõi tệp được tích lũy qua nhiều lần nén hoặc tóm tắt nhánh lồng nhau, lưu giữ toàn bộ lịch sử của các tệp đã đọc và sửa đổi.

### Chi nhánhTóm tắtCấu trúc mục nhập

Được xác định trong [`session-manager.ts`](../src/core/session-manager.ts):

```typescript
interface BranchSummaryEntry<T = unknown> {
  type: "branch_summary";
  id: string;
  parentId: string;
  timestamp: number;
  summary: string;
  fromId: string;      // Entry we navigated from
  fromHook?: boolean;  // true if provided by extension (legacy field name)
  details?: T;         // implementation-specific data
}

// Default branch summarization uses this for details (from branch-summarization.ts):
interface BranchSummaryDetails {
  readFiles: string[];
  modifiedFiles: string[];
}
```

Tương tự như nén, tiện ích mở rộng có thể lưu trữ dữ liệu tùy chỉnh trong `details`.

Xem [`collectEntriesForBranchSummary()`, `prepareBranchEntries()` và `generateBranchSummary()`](../src/core/compaction/branch-summarization.ts) để biết cách triển khai.

## Định dạng tóm tắt

Cả việc nén và tóm tắt nhánh đều sử dụng cùng một định dạng có cấu trúc:

```markdown
## Goal
[What the user is trying to accomplish]

## Constraints & Preferences
- [Requirements mentioned by user]

## Progress
### Done
- [x] [Completed tasks]

### In Progress
- [ ] [Current work]

### Blocked
- [Issues, if any]

## Key Decisions
- **[Decision]**: [Rationale]

## Next Steps
1. [What should happen next]

## Critical Context
- [Data needed to continue]

<read-files>
path/to/file1.ts
path/to/file2.ts
</read-files>

<modified-files>
path/to/changed.ts
</modified-files>
```

### Tuần tự hóa tin nhắn

Trước khi tóm tắt, tin nhắn được tuần tự hóa thành văn bản thông qua [`serializeConversation()`](../src/core/compaction/utils.ts):

```
[User]: What they said
[Assistant thinking]: Internal reasoning
[Assistant]: Response text
[Assistant tool calls]: ipython(code="open('foo.ts').read()"); edit(path="bar.ts", ...)
[Tool result]: Output from tool
```

Điều này ngăn mô hình coi nó như một cuộc trò chuyện để tiếp tục.

Kết quả của công cụ bị cắt ngắn còn 2000 ký tự trong quá trình tuần tự hóa. Nội dung vượt quá giới hạn đó sẽ được thay thế bằng điểm đánh dấu cho biết số lượng ký tự bị cắt bớt. Điều này giúp duy trì các yêu cầu tóm tắt trong phạm vi ngân sách mã thông báo hợp lý, vì kết quả của công cụ, đặc biệt là từ `ipython` và `bash` tùy chọn, thường là yếu tố đóng góp lớn nhất cho kích thước ngữ cảnh.

## Tóm tắt tùy chỉnh thông qua tiện ích mở rộng

Các tiện ích mở rộng có thể chặn và tùy chỉnh cả việc nén và tóm tắt nhánh. Xem [`extensions/types.ts`](../src/core/extensions/types.ts) để biết định nghĩa loại sự kiện.

### session_b Before_compact

Được kích hoạt trước khi tự động nén hoặc `/compact`. Có thể hủy bỏ hoặc cung cấp bản tóm tắt tùy chỉnh. Xem `SessionBeforeCompactEvent` và `CompactionPreparation` trong tệp loại.

```typescript
pi.on("session_before_compact", async (event, ctx) => {
  const { preparation, branchEntries, customInstructions, signal } = event;

  // preparation.messagesToSummarize - messages to summarize
  // preparation.turnPrefixMessages - split turn prefix (if isSplitTurn)
  // preparation.previousSummary - previous compaction summary
  // preparation.fileOps - extracted file operations
  // preparation.tokensBefore - context tokens before compaction
  // preparation.firstKeptEntryId - where kept messages start
  // preparation.settings - compaction settings

  // branchEntries - all entries on current branch (for custom state)
  // signal - AbortSignal (pass to LLM calls)

  // Cancel:
  return { cancel: true };

  // Custom summary:
  return {
    compaction: {
      summary: "Your summary...",
      firstKeptEntryId: preparation.firstKeptEntryId,
      tokensBefore: preparation.tokensBefore,
      details: { /* custom data */ },
    }
  };
});
```

#### Chuyển tin nhắn thành văn bản

Để tạo bản tóm tắt bằng mô hình của riêng bạn, hãy chuyển đổi tin nhắn thành văn bản bằng `serializeConversation`:

```typescript
import { convertToLlm, serializeConversation } from "@earendil-works/pi-coding-agent";

pi.on("session_before_compact", async (event, ctx) => {
  const { preparation } = event;
  
  // Convert AgentMessage[] to Message[], then serialize to text
  const conversationText = serializeConversation(
    convertToLlm(preparation.messagesToSummarize)
  );
  // Returns:
  // [User]: message text
  // [Assistant thinking]: thinking content
  // [Assistant]: response text
  // [Assistant tool calls]: ipython(code="open('...').read()"); bash(command="...")
  // [Tool result]: output text

  // Now send to your model for summarization
  const summary = await myModel.summarize(conversationText);
  
  return {
    compaction: {
      summary,
      firstKeptEntryId: preparation.firstKeptEntryId,
      tokensBefore: preparation.tokensBefore,
    }
  };
});
```

Xem [custom-compaction.ts](../examples/extensions/custom-compaction.ts) để biết ví dụ hoàn chỉnh về cách sử dụng một mô hình khác.

### session_b Before_tree

Đã kích hoạt trước điều hướng `/tree`. Luôn kích hoạt bất kể người dùng có chọn tóm tắt hay không. Có thể hủy điều hướng hoặc cung cấp tóm tắt tùy chỉnh.

```typescript
pi.on("session_before_tree", async (event, ctx) => {
  const { preparation, signal } = event;

  // preparation.targetId - where we're navigating to
  // preparation.oldLeafId - current position (being abandoned)
  // preparation.commonAncestorId - shared ancestor
  // preparation.entriesToSummarize - entries that would be summarized
  // preparation.userWantsSummary - whether user chose to summarize

  // Cancel navigation entirely:
  return { cancel: true };

  // Provide custom summary (only used if userWantsSummary is true):
  if (preparation.userWantsSummary) {
    return {
      summary: {
        summary: "Your summary...",
        details: { /* custom data */ },
      }
    };
  }
});
```

Xem `SessionBeforeTreeEvent` và `TreePreparation` trong tệp loại.

## Cài đặt

Định cấu hình nén trong `~/.prime/agent/settings.json` hoặc `<project-dir>/.prime/agent/settings.json`:

```json
{
  "compaction": {
    "enabled": true,
    "reserveTokens": 16384,
    "keepRecentTokens": 20000
  }
}
```

| Cài đặt | Mặc định | Mô tả |
|---------|---------|-------------|
| `enabled` | `true` | Kích hoạt tính năng tự động nén |
| `reserveTokens` | `16384` | Mã thông báo để dự trữ cho phản hồi LLM |
| `keepRecentTokens` | `20000` | Mã thông báo gần đây cần giữ (không được tóm tắt) |

Tắt tính năng tự động nén bằng `"enabled": false`. Bạn vẫn có thể nén thủ công với `/compact`.

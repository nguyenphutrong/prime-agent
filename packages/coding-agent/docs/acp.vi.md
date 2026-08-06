# Chế độ ACP

Chế độ ACP biến Prime Agent thành tác nhân [Agent Client Protocol](https://agentclientprotocol.com), nói JSON-RPC 2.0 qua JSON được phân tách bằng dòng mới trên stdin/stdout. Bất kỳ client ACP nào — trình soạn thảo như Zed hoặc VS Code hoặc test harness đánh giá — đều có thể điều khiển nó mà không cần biết bất kỳ điều gì cụ thể về Prime Agent.

```bash
prime-agent --mode acp
```

Sử dụng chế độ ACP khi có thứ gì đó bên ngoài cần *điều khiển* một phiên tương tác: nhắc nhở, xem luồng cuộc gọi công cụ, hủy lượt. Đối với các lần chạy hàng loạt mà bạn muốn kết xuất mọi sự kiện và mã thoát, [JSON chế độ luồng sự kiện](json.vi.md) phù hợp hơn. [Chế độ RPC](rpc.vi.md) vẫn khả dụng và hiển thị bề mặt lệnh phong phú hơn của Prime Agent.

## Chuyên chở

- Một tin nhắn JSON-RPC trên mỗi dòng trên stdout, yêu cầu đọc từ stdin.
- stdin vẫn mở trong suốt thời gian kết nối; tác nhân thoát ra khi nó đóng lại.
- Chẩn đoán đi tới stderr. Không bao giờ viết bất cứ điều gì khác vào thiết bị xuất chuẩn, thuộc về giao thức.

## Các phương thức được hỗ trợ

| Phương pháp | Ghi chú |
|---|---|
| `initialize` | Trả về phiên bản giao thức, khả năng và thông tin tác nhân. |
| `session/new` | Tạo phiên. Một phiên cho mỗi kết nối. |
| `session/prompt` | Chạy một lượt và giải quyết bằng lý do dừng. |
| `session/cancel` | Thông báo; hủy bỏ lượt của phiên đã được định địa chỉ. |
| `session/close` | Phát hành phiên và giải phóng kết nối cho một phiên mới. |

Một phiên cho mỗi kết nối là một giới hạn có chủ ý: Phiên cơ bản của Prime Agent được cố định khi khởi động quá trình, do đó, phiên đồng thời thứ hai sẽ âm thầm chia sẻ cuộc hội thoại, thư mục làm việc và mô hình của nó. `session/new` thứ hai bị từ chối thay vì giả vờ cô lập. Bắt đầu một quá trình khác cho phiên thứ hai.

Tương tự như vậy, `session/prompt` từ chối một lượt đồng thời trong khi một lượt đang chạy và thư mục làm việc không thể thay đổi sau khi khởi động - một `cwd` do client cung cấp khác với một lượt thực của tác nhân được báo cáo lại trong `_meta` thay vì bị bỏ qua một cách âm thầm.

## Cập nhật trực tuyến

Hoạt động phiên đến dưới dạng thông báo `session/update`:

| Hoạt động của Prime Agent | Cập nhật ACP |
|---|---|
| văn bản trợ lý | `agent_message_chunk` |
| lý luận | `agent_thought_chunk` |
| công cụ bắt đầu | `tool_call` (`in_progress`) |
| hoàn thiện công cụ | `tool_call_update` (`completed` / `failed`) |
| đầu ra vỏ | `tool_call` cộng với `tool_call_update` gia tăng |

IPython là công cụ xử lý mô hình của Prime Agent, do đó, một ô là `tool_call` thuộc loại `execute` có `rawInput` mang nguồn ô.

## Tiện ích mở rộng Prime Agent

Prime Agent có các khả năng ACP không có lĩnh vực dành cho: tác nhân phụ, cổng chất lượng tự trị, mục tiêu, nhịp tim, sàng lọc harness liên tục, nén và đầu ra IPython phong phú. Chúng di chuyển trong một phong bì `_meta` miền ngược:

```json
{
  "sessionUpdate": "session_info_update",
  "_meta": {
    "ai.primeintellect.prime-agent": {
      "subagents": [{ "id": "sub-1", "sessionName": "reviewer", "status": "running" }]
    }
  }
}
```

Máy khách ACP tiêu chuẩn bỏ qua hoàn toàn `_meta` và vẫn hoạt động. Một client nhận biết Prime Agent hoặc một test harness quan tâm đến các cây tác nhân phụ và các lần thử cổng sẽ đọc nó. Không có gì phi tiêu chuẩn được thêm vào gốc đối tượng ACP mà giao thức dự trữ cho các trường trong tương lai.

## Lý do dừng

`session/prompt` giải quyết bằng một trong những lý do dừng của ACP:

- `end_turn` — lượt kết thúc bình thường.
- `cancelled` — `session/cancel` đã hủy bỏ nó.
- `max_tokens` — ngân sách mã thông báo tự trị đã cạn kiệt.
- `max_turn_requests` — giới hạn lượt, tiếp tục hoặc đồng hồ treo tường tự động đã dừng hoạt động.

Cổng chất lượng tự động chạy *bên trong* một lượt nhắc nhở. Cổng bị lỗi là sự tiếp tục chứ không phải lý do dừng lại, do đó, lượt chơi chỉ được giải quyết khi vòng lặp cổng ổn định. Các lần thử cổng sẽ hiển thị trong `_meta` khi điều đó xảy ra.

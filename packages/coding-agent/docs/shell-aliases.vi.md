# Bí danh Shell

Prime Agent chạy bash ở chế độ không tương tác (`bash -c`), chế độ này không mở rộng bí danh theo mặc định.

Để bật bí danh shell của bạn, hãy thêm vào `~/.prime/agent/settings.json`:

```json
{
  "shellCommandPrefix": "shopt -s expand_aliases\neval \"$(grep '^alias ' ~/.zshrc)\""
}
```

Điều chỉnh đường dẫn (`~/.zshrc`, `~/.bashrc`, v.v.) để phù hợp với cấu hình shell của bạn.

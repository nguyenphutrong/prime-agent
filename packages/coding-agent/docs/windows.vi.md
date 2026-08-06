# Cài đặt Windows

Prime Agent yêu cầu bash shell trên Windows. Các vị trí đã kiểm tra (theo thứ tự):

1. Đường dẫn tùy chỉnh từ `~/.prime/agent/settings.json`
2. Git Bash (`C:\Program Files\Git\bin\bash.exe`)
3. `bash.exe` trên PATH (Cygwin, MSYS2, WSL)

Đối với hầu hết người dùng, [Git cho Windows](https://git-scm.com/download/win) là đủ.

## Đường dẫn Shell tùy chỉnh

```json
{
  "shellPath": "C:\\cygwin64\\bin\\bash.exe"
}
```

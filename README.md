# alpha-fullstack

Một bộ skill Claude Code dùng chung cho mọi dự án Alpha Bravo. Bạn gọi slash
command, kèm tên dự án và yêu cầu (hoặc tài liệu). Skill tự đọc profile của
dự án rồi làm việc trong đúng repo ở `../projects/`.

```
/work woodcraft docs/BA/purchase-orders.pdf
/plan shamrock schedule fe
/implement woodcraft purchase-orders be US02
/automation-test shamrock work-orders smoke env=local
```

## Các skill

| Lệnh | Việc |
| --- | --- |
| `/work <project> <yêu cầu>` | Điểm vào chung: phân loại yêu cầu rồi gọi skill phù hợp (hoặc sửa nhỏ trực tiếp) |
| `/plan` | Lên kế hoạch BE/FE theo user story của BA, Lovable và code hiện có; có câu hỏi mở. Không code |
| `/db-design` | Thiết kế hoặc ghi tài liệu DB, xác nhận nguồn mới nhất, có reviewer độc lập |
| `/implement` | Code theo plan đã chốt: tạo branch, code từng story, check, review, commit (không push nếu chưa được bảo) |
| `/review` | Review read-only bằng agent `alpha-code-reviewer` |
| `/how-to-verify` | Viết hướng dẫn kiểm thử thủ công `docs/plans/<module>.verify.md` |
| `/automation-test` | Chạy kịch bản của verify guide trên Chrome, **chỉ local/dev**, rồi ghi báo cáo |

Agents: `alpha-code-reviewer`, `alpha-db-design-reviewer`. Hai agent này có
prefix vì các repo dự án đã có agent tên `code-reviewer`, và agent của project
sẽ được ưu tiên.

### Trùng tên với lệnh có sẵn

Đây là personal skill nên **thay thế** lệnh cùng tên của Claude Code trong
terminal local:

- `/plan` thay lệnh built-in "vào plan mode". Muốn vào plan mode thì dùng
  `Shift+Tab`.
- `/review` của Claude Code là alias của `/code-review`. Tài liệu chưa nói rõ
  skill cá nhân có đè được alias hay không. Nếu `/review` vẫn mở code-review
  của Claude Code, đổi tên thư mục `skills/review` (ví dụ thành `cr`) rồi chạy
  lại `./install.sh`.
- `/db-design` và `/how-to-verify` trùng tên với skill cùng tên đã commit
  trong repo shamrock và woodcraft-be.

## Cài đặt (một lần mỗi máy)

```bash
./install.sh
```

Script này làm ba việc:
- symlink `skills/*` vào `~/.claude/skills/` và `agents/*.md` vào
  `~/.claude/agents/`;
- thêm `ALPHA_HOME` vào `~/.claude/settings.json`;
- thêm hook guard của `/automation-test` vào cùng file đó.

Settings được backup cạnh file gốc trước khi sửa. Script chạy lại nhiều lần
không sao. Gỡ bằng `./uninstall.sh`. Sau khi cài, restart Claude Code.

Vì là symlink, sửa skill, profile hay notes trong repo này là có hiệu lực ngay
từ phiên sau. Không cần cài lại, trừ khi bạn thêm một skill hoặc agent mới.

Tài khoản test cho `/automation-test`: copy `skills/automation-test/credentials.example.yaml` sang
`~/.config/alpha/credentials/<project>.yaml`, điền thông tin, rồi
`chmod 600`. File này **không bao giờ** được nằm trong repo.

Tuỳ chọn: điền `db.local_query` trong profile để `/how-to-verify` và `/automation-test` chạy
được SQL read-only trên DB local.

## Chạy ở đâu

- **Trong repo dự án** (ví dụ `cd ../projects/woodcraft-tech-be && claude`):
  không cần gõ tên dự án, skill tự nhận ra từ thư mục hiện tại.
- **Trong repo này**: `.claude/settings.json` đã cho phép truy cập
  `../projects`, nên một phiên có thể làm việc trên nhiều repo (FE + BE).

## Cấu trúc

```
install.sh / uninstall.sh
shared/               load-project.md: bước 0 chung cho mọi skill
skills/<name>/        SKILL.md + template của từng skill
agents/               alpha-code-reviewer, alpha-db-design-reviewer
hooks/                guard-env.mjs: chặn trình duyệt rời local/dev khi đang chạy /automation-test
projects/<name>/      profile.yaml + notes/<skill>.md (phần riêng của từng dự án)
```

Skill chỉ mô tả **quy trình chung**. Thông tin riêng của dự án (đường dẫn,
lệnh, convention khác nhau) nằm trong `projects/<name>/`. Convention code vẫn
nằm trong `CLAUDE.md` của từng repo dự án, vì team dùng chung file đó. Xem
`projects/README.md` để biết các key của profile và các feature.

## An toàn của `/automation-test`

- `run-lock.mjs` chỉ mở phiên test với `local` (localhost) hoặc `dev` (host
  khai báo trong profile). Mọi môi trường khác đều bị từ chối.
- Trong lúc phiên test đang mở, hook `PreToolUse` chặn mọi lệnh navigate của
  Chrome ra ngoài môi trường đó. Hook này không phụ thuộc vào việc model có
  làm đúng hay không. Phiên tự hết hạn sau 8 giờ. Nếu cần gỡ khoá thủ công:
  `rm ~/.config/alpha/test-run.json`.
- SQL chỉ chạy `SELECT` trong transaction read-only, và chỉ trên local. Lệnh
  reset/seed chỉ chạy trên local và phải hỏi trước.
- Lưu ý: khi đăng nhập qua Chrome, mật khẩu vẫn đi qua ngữ cảnh của model. Vì
  vậy chỉ dùng tài khoản test.

## Thêm dự án mới

Copy `projects/_template/` thành `projects/<name>/`, điền `profile.yaml`, và
chỉ viết notes cho những gì khác với skill chung.

## Quan hệ với skill trong repo dự án

Các repo dự án vẫn giữ skill gốc (`planning`, `db-design`, `how-to-verify`,
agent `code-reviewer`…), vì chúng được commit và team đang dùng. Bộ skill này
không sửa gì trong đó. Khi sửa một quy tắc ở một bên, cân nhắc sửa cả bên kia.

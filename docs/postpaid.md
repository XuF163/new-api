# 先出账后付费（赊账）

本项目默认是“先充值后使用”（按额度扣费）。开启后可支持“先出账后付费”：在额度不足时仍允许继续调用，并在赊账期内完成充值结清。

## 管理员配置

在「运营设置 → 额度设置 → 先出账后付费」中配置：

- `PostpaidEnabled`：是否启用后付费（赊账）。
- `PostpaidCreditDays`：赊账天数（天）。设置为 `0` 表示不允许赊账。

## 行为说明

- 开启后，用户 `quota` 可变为负数，负数部分表示欠费额度。
- 当用户首次进入欠费（`quota < 0`）时，会记录欠费开始时间 `debt_start_time`（Unix 秒）。
- 若当前时间超过 `debt_start_time + PostpaidCreditDays` 且仍处于欠费状态（`quota < 0`），将拒绝继续调用（充值后恢复）。
- 当充值/返还等操作使 `quota >= 0` 时，`debt_start_time` 会被清零。

## 接口返回

`GET /api/user/self` 在响应中新增 `postpaid` 字段（示例字段含义）：

- `postpaid.enabled`：后付费是否生效（`PostpaidEnabled && PostpaidCreditDays > 0`）
- `postpaid.credit_days`：赊账天数
- `postpaid.debt_quota`：欠费额度（仅欠费时）
- `postpaid.debt_start_time`：欠费开始时间（仅欠费时）
- `postpaid.debt_due_time`：到期时间（仅欠费时）


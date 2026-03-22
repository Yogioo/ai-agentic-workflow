# 当前Hooks

## 1. 文档定位

- 本文档定义当前项目启用的可选 Hook 规则。
- Main Agent 在初始化时最多读取一次；若文件不存在，则视为未启用 Hook。
- 若当前会话通过 `/hooks` 更新了规则，则以后续上下文中的最新内容为准。

## 2. Git Commit Tag 规范

- `feat`：新增功能或新增可交付能力
- `fix`：修复缺陷、错误或错误行为
- `docs`：仅文档变更
- `refactor`：重构实现，不改变外部行为
- `test`：新增或调整测试
- `chore`：维护性杂项、流程配置、脚手架变更
- `style`：仅格式调整，不改变逻辑
- `perf`：性能优化
- `build`：构建系统、依赖或打包流程变更
- `ci`：CI/CD 配置变更
- `revert`：回滚既有提交

推荐提交格式：`<tag>(<scope>): <summary>` 或 `<tag>: <summary>`

## 3. Hook 列表

### Hook H-001
- 名称：任务完成后生成 Git 存档建议
- 触发点：task_done
- 执行方式：suggest
- 前置条件：
  - 已收到 Task Result
  - 本任务产出涉及文件变更
- 动作：
  - 生成本次任务的变更摘要
  - 结合任务类型推荐 commit tag
  - 生成 1 条建议 commit message
- 失败策略：skip_and_report

### Hook H-002
- 名称：QA 通过后建议创建提交点
- 触发点：qa_passed
- 执行方式：confirm
- 前置条件：
  - 对应任务已通过 QA
  - 当前任务不存在阻塞项
- 动作：
  - 提醒用户可进行代码存档
  - 推荐执行 `git add` 与 `git commit`
  - 输出建议 commit tag、scope 与 message
- 失败策略：stop_and_report

### Hook H-003
- 名称：阶段收口时生成归档建议
- 触发点：phase_close
- 执行方式：suggest
- 前置条件：
  - 当前阶段达到收口条件
- 动作：
  - 汇总本阶段关键变更
  - 生成阶段级提交或标签建议
  - 提醒用户确认是否进入下一阶段
- 失败策略：skip_and_report

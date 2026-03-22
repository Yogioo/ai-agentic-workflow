---
description: 将当前任务整理成 Dev Sub Agent 可执行任务包
argument-hint: [task-id-or-task-name]
disable-model-invocation: true
---
请按以下流程执行：

1. 优先读取 `{{WORKFLOW_DIR}}/framework/SubAgent任务下发模板.md`、`{{WORKFLOW_DIR}}/framework/命令体系规范.md`
2. 从当前上下文、`当前状态快照.md` 或 `当前阶段Kanban.md` 中识别目标任务
3. 将任务整理为完整的 Dev Task Package

请尽量按以下固定结构输出：

## 目标任务
- Task ID：
- 任务目标：

## Task Package
- 背景与上下文：
- 接口契约：
- 验收标准：
- 测试用例：
- 文件路径范围：
- 风险提示：

生成任务包时，不要要求 Dev Sub Agent 再次读取 `DevSubAgent.md` 或其他角色规范文档；默认视为其角色规范已由 system prompt 提供。

## 契约检查
- 最小必要契约是否完整：是 / 否
- 若不完整，缺失项：

## 后续建议
- 是否可立即派发给 Dev Sub Agent：是 / 否
- 是否建议更新 `当前状态快照.md`：是 / 否

如果当前任务仍不具备最小必要契约，先列出缺失项，再停止派单。

目标开发任务与补充要求： $ARGUMENTS

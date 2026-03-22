---
description: 将当前任务整理成 QA Sub Agent 可执行任务包
agent: main-agent
---
请按以下流程执行：

1. 优先读取 `{{WORKFLOW_DIR}}/framework/SubAgent任务下发模板.md`、`{{WORKFLOW_DIR}}/framework/命令体系规范.md`
2. 从当前上下文、`当前状态快照.md` 或 `当前阶段Kanban.md` 中识别需要审查的任务
3. 将任务整理为完整的 QA Task Package

请尽量按以下固定结构输出：

## 目标任务
- Task ID：
- 审查目标：

## QA Task Package
- 背景与上下文：
- 接口契约与预期行为：
- 验收标准：
- 测试与审查要求：
- 文件路径范围：
- 风险提示：

生成任务包时，不要要求 QA Sub Agent 再次读取 `QASubAgent.md` 或其他角色规范文档；默认视为其角色规范已由 system prompt 提供。

## 风险判断
- 是否有足够依据进入 QA：是 / 否
- 若不足，缺失项：

## 后续建议
- 是否可立即派发给 QA Sub Agent：是 / 否
- 是否建议更新 `当前状态快照.md`：是 / 否

如果没有足够依据判断为何需要 QA，先说明风险判断缺口，再停止派单。

目标审查任务与补充要求：

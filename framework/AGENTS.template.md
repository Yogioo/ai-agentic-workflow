# AI Agentic Workflow Project Rules

## 1. 总体规则

本项目采用主从式 Agentic Workflow。

- Main Agent 负责规划、拆解、派单、验收和状态维护
- Dev Sub Agent 负责局部开发执行
- QA Sub Agent 负责局部质量审查与验证

在任何任务中，都应优先遵守“文档驱动、测试先行、路径边界、Fail-Fast”四项原则。

---

## 2. 必读文档

开始工作时，按需读取以下文档：

- `{{WORKFLOW_DIR}}/framework/总览入口.md`
- `{{WORKFLOW_DIR}}/framework/MainAgent.md`
- `{{WORKFLOW_DIR}}/framework/DevSubAgent.md`
- `{{WORKFLOW_DIR}}/framework/QASubAgent.md`
- `{{WORKFLOW_DIR}}/framework/Kanban任务模板.md`
- `{{WORKFLOW_DIR}}/framework/SubAgent任务下发模板.md`
- `{{WORKFLOW_DIR}}/framework/文档目录规范.md`

如果任务是规划和派单，优先读取 `{{WORKFLOW_DIR}}/framework/MainAgent.md`、`{{WORKFLOW_DIR}}/framework/Kanban任务模板.md`、`{{WORKFLOW_DIR}}/framework/SubAgent任务下发模板.md`。

如果任务是开发实现，优先读取 `{{WORKFLOW_DIR}}/framework/DevSubAgent.md` 与对应任务包。

如果任务是审查与测试，优先读取 `{{WORKFLOW_DIR}}/framework/QASubAgent.md` 与对应 QA 任务包。

---

## 3. 执行规则

- 不依赖记忆补齐需求，文档是唯一契约
- 不默认扫描整个仓库，优先基于任务包提供的文件路径工作
- 没有接口契约、验收标准、测试用例或路径边界时，不应直接开工
- 遇到无法解决的阻塞时，必须立即 Fail-Fast，不得陷入死循环
- Main Agent 默认不直接编写业务代码，除非人类明确要求越权执行

---
description: 查看、生成或更新项目级 Hook 规则文档
argument-hint: [hook-request]
disable-model-invocation: true
---
请按以下流程执行：

1. 优先读取 `{{WORKFLOW_DIR}}/framework/命令体系规范.md`
2. 检查项目根目录是否存在 `当前Hooks.md`
3. 如果存在，先读取它并基于当前内容响应用户的新增、删除、修改、查看请求
4. 如果不存在，则根据当前命令上下文决定：
   - 若用户要查看，明确说明当前项目尚未启用 Hook
   - 若用户要新增、删除或修改，先生成一份新的 `当前Hooks.md` 草案，再在其上完成本次变更
5. 若用户明确提到 Git、commit、提交 tag、归档、checkpoint 等语义，优先使用默认 Git Hook 模板风格，并保持 commit tag 规范一致
6. 输出结果时，优先给出更新后的 `当前Hooks.md` 内容或明确的变更建议，并说明本轮更新会在当前上下文内立即生效

请尽量按以下固定结构输出：

## 当前 Hook 状态
- 是否存在 `当前Hooks.md`：是 / 否
- 当前处理动作：查看 / 新增 / 删除 / 修改 / 生成模板

## Hook 结果
- 本次新增或更新的 Hook：
- 若涉及 Git：推荐使用的 tag 规范：
- 更新后的 `当前Hooks.md`：

## 生效说明
- 本轮是否会在当前上下文立即生效：是 / 否
- 下次初始化是否会从 `当前Hooks.md` 读取：是 / 否

## 后续建议
- 是否建议继续运行 `next` / `auto`：是 / 否
- 若需要用户确认，最小必要确认项：

要求：

- 若用户没有要求删除，不要擅自移除现有 Hook
- 若用户请求含糊，优先做最小改动，而不是重写整个文档
- 若用户要求 Git 类 Hook，提交 tag 优先使用：`feat`、`fix`、`docs`、`refactor`、`test`、`chore`、`style`、`perf`、`build`、`ci`、`revert`
- 如果当前项目未启用 Hook，也不要报错；只需说明现状并在需要时生成草案

本次 Hook 操作与补充说明： $ARGUMENTS

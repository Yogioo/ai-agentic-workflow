# ai-agentic-workflow

这是一个可移植、可复用的 AI Agentic Workflow 模板目录。

## 快速入口

如果你希望直接从根目录启动初始化流程，可运行：

```bat
setup.cmd
```

推荐使用 `setup.cmd` 作为统一入口。

如果上一级项目已经存在 `.ai-agentic-workflow-meta.json`，`setup.cmd` 会先识别这是一个已受管项目，并比较当前工作流 `VERSION` 与已安装版本：

- 如果当前版本更高，会提示“可升级”，由用户显式选择是否升级
- 如果版本相同，会提示“当前已是最新，无需升级”
- 默认都不会自动升级

它会明确要求用户选择：

- `1`：OpenCode
- `2`：Claude Code

也支持命令行直达：

```bat
setup.cmd opencode
setup.cmd claude-code
```

## 目录结构

- `framework/`：通用规则与流程规范
- `templates/bootstrap/`：项目运行文档模板
- `agents/`：OpenCode agent 模板
- `commands/`：OpenCode command 模板
- `claude/`：Claude Code 适配模板
- `scripts/`：安装与适配脚本

## 规范来源

- `framework/` 是唯一的流程规范来源
- `templates/bootstrap/` 是唯一的运行文档模板来源
- 根目录不再保留重复的旧版规范文档

## 默认使用方式

初始化项目后，默认推荐用户只记住两个命令：

- `start`：项目启动、项目接管、已有项目分析、首次规划
- `next`：根据当前状态自动推进下一步
- `auto`：自动推进，可选择 `task`、`phase`、`sisyphus`

两者分工不同：

- `start`：重入口，只用于首次进入、重新接管、状态不明时
- `next`：轻入口，用于日常推进，不应重复做全量项目分析
- `auto`：在 `next` 基础上的自动推进策略，适合减少重复确认操作

可以把三者理解成下面这张表：

| 命令 | 适用时机 | 默认行为 | 是否会停下来等人确认 |
| --- | --- | --- | --- |
| `start` | 第一次进入项目、重新接管、状态不明 | 做状态识别、需求发掘、首轮规划 | 会 |
| `next` | 日常推进 | 只推进一步 | 会，在关键决策节点停下 |
| `auto task` | 想减少重复操作，但仍然保守 | 自动推进到当前任务完成 | 会，不跨关键确认点 |
| `auto phase` | 推荐默认自动化 | 自动推进到当前阶段完成 | 会，在阶段边界停下 |
| `auto sisyphus` | 希望最大化自动推进 | 持续推进直到完成/阻塞/中断 | 通常不停，但阻塞或高风险会停 |

为了让 `next` 更快，工作流建议维护一个轻量索引文件：`当前状态快照.md`。

它的作用是：

- 记录当前项目状态与当前推进状态
- 记录当前最关键缺口
- 记录推荐下一步动作
- 作为 `next` 的优先读取入口

注意：

- `当前状态快照.md` 只是状态缓存，不替代正式文档
- 如果它和 `当前PRD.md`、`当前RoadMap.md`、`当前阶段Kanban.md` 冲突，以正式文档为准

## 初始化后的第一轮用法

项目初始化完成后，普通用户不需要先自己写 PRD 或 RoadMap。

推荐的第一轮实际使用方式是：

1. 先对 AI 使用 `start`
2. 用自然语言说明你的目标、想法、痛点，或当前已有项目背景
3. 让 AI 先分析现状、发掘需求、补全当前文档，而不是直接开始编码

推荐示例：

```text
/start 我想做一个给小团队使用的任务管理工具，先支持任务创建、分配、状态跟踪。请先分析当前项目情况，帮我梳理需求并补全当前PRD和RoadMap，先不要直接开始编码。
```

这些命令支持在命令后面直接跟自然语言补充说明。

例如：

```text
/start 我想做一个离线计算器网页
/next 先推进当前阶段最关键的任务
/dispatch-dev K-003 优先处理参数校验
```

命令后的补充文本会被当作该命令的上下文，而不是孤立附加在末尾。

如果是已有代码项目，可以这样说：

```text
/start 这是一个已经有部分代码的项目。请先分析当前代码库已经实现了什么、缺了什么，再反推当前PRD和RoadMap，先不要直接开始大规模修改。
```

当 `start` 执行完后，用户通常只需要继续使用：

```text
/next
```

如果你希望减少反复交互，也可以使用：

```text
/auto phase
```

`next` 会根据当前状态自动决定下一步，例如：

- 补全 `当前PRD.md`
- 补全 `当前RoadMap.md`
- 生成 `当前阶段Kanban.md`
- 准备首轮 Dev 任务包
- 同步当前阶段状态

但 `next` 不是无条件一直往前推进。

当它遇到关键决策节点时，会停下来让用户 review 和确认，例如：

- 需求草案已经形成，是否确认并进入 RoadMap
- RoadMap 草案已经形成，是否确认并进入任务拆解
- 准备从规划进入第一轮开发，是否现在开始
- 当前阶段接近结束，是否确认收口并进入下一阶段

`auto` 则是在 `next` 之上的自动推进命令，支持三种模式：

- `task`：自动推进到当前任务完成后停下
- `phase`：自动推进到当前阶段完成后停下（推荐默认）
- `sisyphus`：持续自动推进，直到完成、阻塞或用户中断

它们在“确认闸门”上的差异是：

- `task`：不跨过关键确认点，当前任务完成就停
- `phase`：允许在阶段内部自动推进，但在阶段结束和跨阶段时停下
- `sisyphus`：可跨过大多数确认点持续推进，但遇到阻塞、连续无进展或高风险情况会停下

因此，日常开发过程中通常不需要反复运行 `start`。

如果你已经完成了首次状态识别与规划，后续默认优先使用 `/next`。

推荐在项目运行文档中增加：

- `当前状态快照.md`

高级命令仍然保留，但主要面向熟悉工作流的人类或 Main Agent 自身使用：

- `kanban`
- `dispatch-dev`
- `dispatch-qa`
- `status-sync`

这些高级命令现在也遵循统一的结构化输出风格，便于：

- 人类快速判断结果是否可用
- Main Agent 接续推进下一步
- 必要时同步到 `当前状态快照.md` 或正式项目文档

推荐理解为：

- `kanban`：产出任务面板
- `dispatch-dev`：产出开发任务包
- `dispatch-qa`：产出 QA 任务包
- `status-sync`：产出状态更新建议

## OpenCode 适配

如果当前项目把本目录作为子目录引入，例如：

```text
target-project/
  ai-agentic-workflow/
```

则可在 `ai-agentic-workflow/` 根目录运行 `setup.cmd`，然后选择 `1`；

也可以直接运行：

```powershell
./scripts/opencode.ps1
```

该一体化脚本会在上一级项目目录中：

- `AGENTS.md`
- `.opencode/opencode.json`
- `.opencode/agents/*.md`
- `.opencode/commands/*.md`
- `当前PRD.md`
- `当前RoadMap.md`
- `BUG追踪.md`
- `当前阶段Kanban.md`
- `当前状态快照.md`

可选参数：

- `-TargetDir ..`：指定目标目录，默认为上一级目录
- `-ProjectName 项目名`：指定初始化时写入的项目名
- `-WorkflowDirName ai-agentic-workflow`：指定写入目标项目中的工作流目录名
- `-DryRun`：只输出将执行的动作，不真正写入文件
- `-SkipAdapter`：只初始化运行文档，不安装 OpenCode 适配文件
- `-Force`：覆盖目标目录中已存在的文件

初始化完成后，还会写入：

- `.ai-agentic-workflow-meta.json`：记录安装版本、适配器类型、受管文件分类与模板哈希，用于后续升级判断

## Claude Code 适配

如果当前项目把本目录作为子目录引入，例如：

```text
target-project/
  ai-agentic-workflow/
```

则可在 `ai-agentic-workflow/` 根目录运行 `setup.cmd`，然后选择 `2`；

也可以直接运行：

```powershell
./scripts/claude-code.ps1
```

该一体化脚本会在上一级项目目录中：

- `CLAUDE.md`
- `.claude/settings.json`
- `.claude/agents/*.md`
- `.claude/commands/*.md`
- `当前PRD.md`
- `当前RoadMap.md`
- `BUG追踪.md`
- `当前阶段Kanban.md`
- `当前状态快照.md`

可选参数：

- `-TargetDir ..`：指定目标目录，默认为上一级目录
- `-ProjectName 项目名`：指定初始化时写入的项目名
- `-WorkflowDirName ai-agentic-workflow`：指定写入目标项目中的工作流目录名
- `-DryRun`：只输出将执行的动作，不真正写入文件
- `-SkipAdapter`：只初始化运行文档，不安装 Claude Code 适配文件
- `-Force`：覆盖目标目录中已存在的文件

初始化完成后，还会写入：

- `.ai-agentic-workflow-meta.json`：记录安装版本、适配器类型、受管文件分类与模板哈希，用于后续升级判断

当前提供的是最小可用适配：

- 项目根目录 `CLAUDE.md` 作为主规则入口
- `.claude/settings.json` 作为项目级 Claude Code 设置
- `.claude/agents/` 作为 Main / Dev / QA 角色定义
- `.claude/commands/` 提供 `/kanban`、`/dispatch-dev`、`/dispatch-qa`、`/status-sync`

## 初始化项目运行文档

现在不再区分 install 和 init 两类脚本。

统一使用一个用户入口：

- `setup.cmd`：菜单选择适配器并执行初始化

内部实现脚本保留在 `scripts/` 中：

- `scripts/opencode.ps1`
- `scripts/claude-code.ps1`

运行 `setup.cmd` 时，初始化流程会询问是否创建 `当前Hooks.md`，以及是否包含默认 Git Hook 模板。
如果不创建 `当前Hooks.md`，Main Agent 会视为当前项目未启用 Hook，并跳过所有 Hook 相关处理。

## 升级已有项目

当工作流仓库更新后，推荐在工作流目录中执行：

```bat
setup.cmd upgrade
```

如果你只是直接运行：

```bat
setup.cmd
```

脚本也会先检查上一级项目是否已纳入工作流管理，并比较当前版本与已安装版本：

- 若检测到可升级状态，会先弹出升级选择菜单，但仍然需要用户手动选择“upgrade existing managed project”才会真正执行升级
- 若检测到当前已经是最新版本，则会先提示“无需升级”，再让用户决定是否继续做初始化操作或直接退出

也可以直接运行：

```powershell
./scripts/upgrade.ps1
```

升级机制按文件类型分层处理：

- `system`：框架与适配文件，若目标文件未被用户修改则自动升级
- `state`：`当前PRD.md`、`当前RoadMap.md`、`当前阶段Kanban.md`、`BUG追踪.md`，默认不覆盖
- `cache`：`当前状态快照.md`，升级时自动刷新
- `local-extension`：`当前Hooks.md`，默认保留本地版本，仅在引导模式输出新版参考副本

升级模式：

- `-Mode safe`：保守升级，仅更新安全可替换的文件
- `-Mode guided`：默认模式，为冲突文件生成 `.workflow-new` 或 `.upgrade-template` 参考副本
- `-Mode force-system`：强制覆盖 `system` 文件，但仍不覆盖 `state` 文件

升级后会生成：

- `workflow-upgrade-report.md`：本次升级动作与冲突说明

## setup.cmd 帮助

可以直接运行：

```bat
setup.cmd help
```

帮助模式会显示：

- 支持的适配器
- 常见透传参数
- 升级模式参数
- Hook 初始化选项
- 初始化后的推荐使用顺序

初始化完成后，你也可以通过 `/hooks` 查看、生成、追加或修改 `当前Hooks.md`。
如果当前项目还没有 `当前Hooks.md`，`/hooks` 会先按最小草案创建，再承接本次修改请求。

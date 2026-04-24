# SPEC: SPEC_GAME 编码污染修复

## 1. 系统设计说明

- 问题定义：`SPEC_GAME.md` 已被历史写入污染为大量字面量 `?`，后续脚本若继续依赖损坏锚点（如 `?????`）会持续扩散污染。
- 设计目标：
  - 修复脚本不得使用任何损坏中文锚点进行定位。
  - 修复脚本仅基于稳定章节边界（ASCII 标题）执行替换。
  - 在落盘前后做污染检测，避免再次把错误内容写回。
- 设计原则：
  - `replace-by-boundary` 优先于 `replace-by-body-fragment`。
  - 仅从已知健康 UTF-8 源块写入（`fix_spec_b5_b6_utf8.md`、`fix_spec_chunk_b7_to_21.md`）。
  - 写入前必须验证源块包含 CJK 字符，防止空块或坏块覆盖。

## 2. 数据结构定义

```text
EncodingHealthSnapshot
  - filePath: string
  - length: int
  - cjkCount: int
  - questionMarkCount: int
  - utf8Bom: bool

SectionReplacePlan
  - beginMarker: string
  - endMarker: string
  - replacementPath: string
  - replacementCjkCount: int
```

## 3. 接口/API 设计

- 脚本入口：`fix_spec_encoding.ps1`
- 参数设计：
  - `-Path <string>`：目标文件，默认 `SPEC_GAME.md`
  - `-ForceWrite`：当污染指标异常时是否强制写入（默认否）
- 行为接口：
  - `Get-TextHealth(text, bytes)`：返回 `EncodingHealthSnapshot`
  - `Update-BoundedSection(content, beginMarker, endMarker, replacement)`：边界替换
  - `Update-B5B6Section(content, replacement)`：B.5 丢失时自动回退到 B.6 前结构化起点

## 4. 实现优先级

- P0
  - 去除损坏锚点匹配逻辑。
  - 改为 B.5/B.6 与 B.7~2.1 两段边界替换。
- P1
  - 增加失败保护（找不到边界直接失败，避免误写）。
  - 增加源块健康检查（`cjkCount > 0`）。
- P2
  - 后续可扩展更多章节块恢复脚本，统一同一替换框架。

## 5. 技术实现建议

- 全流程使用 `[System.Text.UTF8Encoding]::new($false)` 读写。
- 不使用 `Set-Content` 默认编码路径。
- 每次运行前先备份目标文件（`.pre_fix.bak`）。
- 自定义函数命名遵循 PSScriptAnalyzer `PSUseApprovedVerbs` 规则，优先使用批准动词（如 `Get`、`Set`、`Update`）。
- 调试期日志仅用于排障；验证完成后移除所有会话埋点脚本与日志输出。
- 已污染为 `?` 的原文无法自动逆向还原；修复脚本目标是“停止继续污染 + 用健康块覆盖可恢复区间”。

## 6. 清理状态（已完成）

- 已移除运行时会话埋点策略，恢复为无日志输出的修复脚本执行路径。
- 保留边界替换、污染守卫、源块健康检查、备份写入四项长期安全机制。
- 已清理 `fix_spec_encoding.ps1` 中未使用变量，满足 PSScriptAnalyzer `PSUseDeclaredVarsMoreThanAssignments` 规则，避免噪声告警干扰后续维护。

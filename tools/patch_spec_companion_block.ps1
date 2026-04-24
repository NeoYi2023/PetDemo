$ErrorActionPreference = 'Stop'
$path = Join-Path $PSScriptRoot '..\SPEC_GAME.md'
$utf8 = [System.Text.UTF8Encoding]::new($false)
$c = [System.IO.File]::ReadAllText($path, $utf8)

$old = @'
**???????v2026-04-24 ??????GameBootstrap + PetFollowHero?**  

- ? `SaveData.petRuntimes` ???????????????? `GameBootstrap.BindRuntimeSaveData` ?? `PetManager.BindSaveData` ?????? `GMAddPet("Monster_4001", 1, 1)`?? **Monster_4001** ????????????????????  
- `Monster_4001` ????? `PetCatalogAsset`?`Assets/Data/PetCatalogAsset.asset`???? `Assets/Fantazia Animated 2D Monsters/Prefabs/Monster_4001.prefab` ???  
- ?????????? `Monster_4001` ????? `PetFollowHero`????????? `Free` ??? `NavigationService` ?? + `Vector2` ???????????????? `HeroController`??? `Work` ?? `PetWorkExecutor` ?????`PetFollowHero` ????  
'@

$new = @'
**默认地图首宠（v2026-04-24 增补，实现：GameBootstrap + PetFollowHero）**  

- 当 `SaveData.petRuntimes` 为空（新游戏或空列表续档）时，在 `GameBootstrap.BindRuntimeSaveData` 中于 `PetManager.BindSaveData` 之后自动调用 `GMAddPet("Monster_4001", 1, 1)`，将 **Monster_4001** 作为第一只宠物写入存档并生成营地可视化。  
- `Monster_4001` 必须登记在 `PetCatalogAsset`（`Assets/Data/PetCatalogAsset.asset`）中，与 `Assets/Fantazia Animated 2D Monsters/Prefabs/Monster_4001.prefab` 成对。  
- 跟随表现：仅对模板为 `Monster_4001` 的实例挂载 `PetFollowHero`；当宠物逻辑状态为 `Free` 时，以 `NavigationService` 寻路 + `Vector2` 世界偏移（默认在主角左后方）跟随 `HeroController`；进入 `Work` 时由 `PetWorkExecutor` 驱动位移，`PetFollowHero` 不抢控。  
'@

if (-not $c.Contains($old)) { throw "Old block not found in SPEC_GAME.md" }
$c2 = $c.Replace($old, $new)
[System.IO.File]::WriteAllText($path, $c2, $utf8)
Write-Host "Patched: $path (UTF-8 no BOM)"

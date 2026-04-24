import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const spec = path.join(__dirname, "..", "SPEC_GAME.md");
const t0 = fs.readFileSync(spec, "utf8");

const replacement = `**默认地图首宠（v2026-04-24 增补，实现：GameBootstrap + PetFollowHero）**  

- 当 \`SaveData.petRuntimes\` 为空（新游戏或空列表续档）时，在 \`GameBootstrap.BindRuntimeSaveData\` 中于 \`PetManager.BindSaveData\` 之后自动调用 \`GMAddPet("Monster_4001", 1, 1)\`，将 **Monster_4001** 作为第一只宠物写入存档并生成营地可视化。  
- \`Monster_4001\` 必须登记在 \`PetCatalogAsset\`（\`Assets/Data/PetCatalogAsset.asset\`）中，与 \`Assets/Fantazia Animated 2D Monsters/Prefabs/Monster_4001.prefab\` 成对。  
- 跟随表现：仅对模板为 \`Monster_4001\` 的实例挂载 \`PetFollowHero\`；当宠物逻辑状态为 \`Free\` 时，以 \`NavigationService\` 寻路 + \`Vector2\` 世界偏移（默认在主角左后方）跟随 \`HeroController\`；进入 \`Work\` 时由 \`PetWorkExecutor\` 驱动位移，\`PetFollowHero\` 不抢控。  
`;

const pos = t0.indexOf("GameBootstrap + PetFollowHero");
if (pos < 0) {
  console.error("anchor GameBootstrap + PetFollowHero not found");
  process.exit(1);
}

const start = t0.lastIndexOf("\n**", pos) + 1;
if (start <= 0) {
  console.error("could not find line start for **");
  process.exit(1);
}

const end = t0.indexOf("\n#### 4.4.1.1", pos);
if (end < 0) {
  console.error("end marker #### 4.4.1.1 not found");
  process.exit(1);
}

const t1 = t0.slice(0, start) + replacement.trimEnd() + t0.slice(end);
fs.writeFileSync(spec, t1, "utf8");
console.log("OK: SPEC_GAME.md companion block rewritten as UTF-8");

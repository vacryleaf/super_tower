# 13 套装装备逐件明细

## 设计规则

本文件只记录套装装备的单件信息。每一行代表一件可获得的装备卡，必须包含所属套装、装备名、栏位和基础属性。

套装装备的单件基础属性低于同栏位普通装备，主要价值来自套装效果。项链和戒指没有普通装备版本，只在套装装备中出现。

基础属性默认口径：

- 头部、上身、腰部、下身、护腿：提供生命、护甲上限或开局护甲。
- 手部、武器、副手：提供普通攻击、防御行动、状态卡或职业资源相关基础属性。
- 脚部：提供躲避层、护甲上限或行动节奏相关基础属性。
- 项链、戒指：提供资源上限、融合容量、治疗、奖励筛选或状态卡抽取相关基础属性。

## 通用套装装备

| 套装 ID | 套装 | 装备名 | 栏位 | 基础属性 |
| --- | --- | --- | --- | --- |
| common_traveler | 旅者 | 旅者兜帽 | 头部 | 最大生命 +5。 |
| common_traveler | 旅者 | 旅者行靴 | 脚部 | 护甲上限 +2。 |
| common_apothecary | 药师 | 药师腰包 | 腰部 | 治疗效果 +8%。 |
| common_apothecary | 药师 | 药师项链 | 项链 | 每场战斗首次治疗额外恢复 2 点生命。 |
| common_sentinel | 哨卫 | 哨卫胸甲 | 上身 | 最大生命 +8。 |
| common_sentinel | 哨卫 | 哨卫护腿 | 护腿 | 护甲上限 +3。 |
| common_quick_hand | 快手 | 快手手套 | 手部 | 状态卡持有上限 +1。 |
| common_quick_hand | 快手 | 快手戒指 | 戒指 | 每场战斗开始抽取状态卡候选 +1。 |
| common_deep_lantern | 深灯 | 深灯护符 | 项链 | 负面状态持续层数上限 -1，最低为 1。 |
| common_deep_lantern | 深灯 | 深灯腰带 | 腰部 | 最大生命 +6。 |
| common_bone_charm | 骨符 | 骨符面罩 | 头部 | 最大生命 +6。 |
| common_bone_charm | 骨符 | 骨符戒指 | 戒指 | 生命低于 40% 时防御行动护甲 +1。 |
| common_moon_pair | 清辉/流霜 | 清辉戒指 | 戒指 | 状态卡持有上限 +1。 |
| common_moon_pair | 清辉/流霜 | 流霜戒指 | 戒指 | 每场战斗开始抽取状态卡候选 +1。 |
| common_scavenger | 拾荒者 | 拾荒者兜帽 | 头部 | 金币获得 +5%。 |
| common_scavenger | 拾荒者 | 拾荒者腰包 | 腰部 | 融合碎片携带上限 +2。 |
| common_scavenger | 拾荒者 | 拾荒者手套 | 手部 | 分解卡牌获得融合碎片 +1，每层最多 1 次。 |
| common_clockwork | 发条 | 发条护腕 | 手部 | 每场战斗首次状态卡效果 +1。 |
| common_clockwork | 发条 | 发条靴 | 脚部 | 每场战斗开始获得 1 层躲避。 |
| common_clockwork | 发条 | 发条戒指 | 戒指 | 行动力上限 +1，但每场战斗第 1 回合不生效。 |
| common_clear_mind | 清心 | 清心面纱 | 头部 | 最大生命 +5。 |
| common_clear_mind | 清心 | 清心项链 | 项链 | 负面状态抗性 +1 层。 |
| common_clear_mind | 清心 | 清心戒指 | 戒指 | 每场战斗开始获得 1 层清心候选。 |
| common_old_guard | 旧守备 | 旧守备胸甲 | 上身 | 最大生命 +9。 |
| common_old_guard | 旧守备 | 旧守备护腿 | 护腿 | 护甲上限 +4。 |
| common_old_guard | 旧守备 | 旧守备盾牌 | 副手 | 防御行动护甲 +2。 |
| common_tower_map | 塔图 | 塔图腰带 | 腰部 | 金币获得 +5%。 |
| common_tower_map | 塔图 | 塔图项链 | 项链 | Boss 非装备卡奖励刷新次数 +1，每 3 层恢复 1 次。 |
| common_tower_map | 塔图 | 塔图戒指 | 戒指 | 奖励候选中当前构筑标签权重 +1。 |
| common_dawn_oath | 晨誓 | 晨誓兜帽 | 头部 | 最大生命 +6。 |
| common_dawn_oath | 晨誓 | 晨誓胸甲 | 上身 | 最大生命 +8。 |
| common_dawn_oath | 晨誓 | 晨誓手套 | 手部 | 普通攻击伤害 +1。 |
| common_dawn_oath | 晨誓 | 晨誓靴 | 脚部 | 护甲上限 +2。 |
| common_night_watch | 夜巡 | 夜巡面罩 | 头部 | 最大生命 +5。 |
| common_night_watch | 夜巡 | 夜巡护裤 | 下身 | 护甲上限 +2。 |
| common_night_watch | 夜巡 | 夜巡轻靴 | 脚部 | 每场战斗开始获得 1 层躲避。 |
| common_night_watch | 夜巡 | 夜巡短刃 | 武器 | 普通攻击伤害 +2。 |
| common_deep_miner | 深矿 | 深矿胸甲 | 上身 | 最大生命 +9。 |
| common_deep_miner | 深矿 | 深矿腰带 | 腰部 | 最大生命 +6。 |
| common_deep_miner | 深矿 | 深矿护腿 | 护腿 | 护甲上限 +3。 |
| common_deep_miner | 深矿 | 深矿镐 | 武器 | 普通攻击伤害 +2。 |
| common_echo_archive | 回声档案 | 回声兜帽 | 头部 | 最大生命 +5。 |
| common_echo_archive | 回声档案 | 回声手套 | 手部 | 技能冷却显示提前 1 回合提示。 |
| common_echo_archive | 回声档案 | 回声项链 | 项链 | 每场战斗首次技能附加效果 +1。 |
| common_echo_archive | 回声档案 | 回声戒指 | 戒指 | 状态卡持有上限 +1。 |

## 战士套装装备

| 套装 ID | 套装 | 装备名 | 栏位 | 基础属性 |
| --- | --- | --- | --- | --- |
| warrior_oath_guard | 誓卫 | 誓卫胸甲 | 上身 | 最大生命 +9。 |
| warrior_oath_guard | 誓卫 | 誓卫守盾 | 副手 | 防御行动护甲 +2。 |
| warrior_blood_edge | 血刃 | 血刃战剑 | 武器 | 普通攻击伤害 +2。 |
| warrior_blood_edge | 血刃 | 血刃手甲 | 手部 | 怒气获得 +1，每场战斗最多 2 次。 |
| warrior_stone_step | 岩步 | 岩步腿甲 | 下身 | 护甲上限 +3。 |
| warrior_stone_step | 岩步 | 岩步战靴 | 脚部 | 消耗躲避层后获得 1 点护甲。 |
| warrior_war_cry | 战吼印记 | 战吼盔 | 头部 | 最大生命 +7。 |
| warrior_war_cry | 战吼印记 | 战吼束带 | 腰部 | 怒气上限 +1。 |
| warrior_iron_recruit | 铁训 | 铁训盔 | 头部 | 最大生命 +6。 |
| warrior_iron_recruit | 铁训 | 铁训胸甲 | 上身 | 最大生命 +8。 |
| warrior_iron_recruit | 铁训 | 铁训圆盾 | 副手 | 防御行动护甲 +2。 |
| warrior_counter_chain | 反击链 | 反击链手甲 | 手部 | 反击伤害 +1。 |
| warrior_counter_chain | 反击链 | 反击链护腿 | 护腿 | 护甲上限 +3。 |
| warrior_counter_chain | 反击链 | 反击链短斧 | 武器 | 普通攻击伤害 +2。 |
| warrior_battle_band | 战团 | 战团腰带 | 腰部 | 怒气上限 +1。 |
| warrior_battle_band | 战团 | 战团项链 | 项链 | 消耗怒气后的治疗效果 +1。 |
| warrior_battle_band | 战团 | 战团戒指 | 戒指 | 每场战斗首次获得怒气时额外获得 1 点怒气。 |
| warrior_breaker | 破阵 | 破阵角盔 | 头部 | 最大生命 +6。 |
| warrior_breaker | 破阵 | 破阵手甲 | 手部 | 对破甲目标普通攻击伤害 +1。 |
| warrior_breaker | 破阵 | 破阵战锤 | 武器 | 普通攻击伤害 +3。 |
| warrior_shield_wall | 盾墙卫队 | 盾墙盔 | 头部 | 最大生命 +7。 |
| warrior_shield_wall | 盾墙卫队 | 盾墙胸甲 | 上身 | 最大生命 +9。 |
| warrior_shield_wall | 盾墙卫队 | 盾墙护腿 | 护腿 | 护甲上限 +4。 |
| warrior_shield_wall | 盾墙卫队 | 盾墙巨盾 | 副手 | 防御行动护甲 +3。 |
| warrior_rune_forge | 符文熔炉 | 符文熔炉手甲 | 手部 | 攻击技能伤害 +1。 |
| warrior_rune_forge | 符文熔炉 | 符文熔炉剑 | 武器 | 普通攻击伤害 +2。 |
| warrior_rune_forge | 符文熔炉 | 符文熔炉项链 | 项链 | 技能状态卡抽取候选 +1。 |
| warrior_rune_forge | 符文熔炉 | 符文熔炉戒指 | 戒指 | 每场战斗首次使用技能后获得 1 点怒气。 |
| warrior_mountain_root | 山根 | 山根胸甲 | 上身 | 最大生命 +10。 |
| warrior_mountain_root | 山根 | 山根腰带 | 腰部 | 最大生命 +7。 |
| warrior_mountain_root | 山根 | 山根腿甲 | 下身 | 护甲上限 +4。 |
| warrior_mountain_root | 山根 | 山根战靴 | 脚部 | 回合结束保留护甲上限 +2。 |
| warrior_rage_brand | 怒痕 | 怒痕盔 | 头部 | 最大生命 +6。 |
| warrior_rage_brand | 怒痕 | 怒痕胸甲 | 上身 | 最大生命 +8。 |
| warrior_rage_brand | 怒痕 | 怒痕手甲 | 手部 | 生命低于 50% 时普通攻击伤害 +1。 |
| warrior_rage_brand | 怒痕 | 怒痕斩剑 | 武器 | 普通攻击伤害 +3。 |
| warrior_rage_brand | 怒痕 | 怒痕戒指 | 戒指 | 怒气上限 +1。 |
| warrior_relic_guard | 遗物守护 | 遗物守护胸甲 | 上身 | 最大生命 +9。 |
| warrior_relic_guard | 遗物守护 | 遗物守护腰带 | 腰部 | 最大生命 +6。 |
| warrior_relic_guard | 遗物守护 | 遗物守护护腿 | 护腿 | 护甲上限 +4。 |
| warrior_relic_guard | 遗物守护 | 遗物守护盾 | 副手 | 防御行动护甲 +3。 |
| warrior_relic_guard | 遗物守护 | 遗物守护项链 | 项链 | 回合结束保留护甲上限 +2。 |
| warrior_colossus | 巨像 | 巨像盔 | 头部 | 最大生命 +8。 |
| warrior_colossus | 巨像 | 巨像胸甲 | 上身 | 最大生命 +11。 |
| warrior_colossus | 巨像 | 巨像腰带 | 腰部 | 最大生命 +8。 |
| warrior_colossus | 巨像 | 巨像护腿 | 护腿 | 护甲上限 +4。 |
| warrior_colossus | 巨像 | 巨像战靴 | 脚部 | 护甲上限 +3。 |
| warrior_iron_vanguard | 铁壁先锋 | 铁壁先锋盔 | 头部 | 最大生命 +7。 |
| warrior_iron_vanguard | 铁壁先锋 | 铁壁先锋胸甲 | 上身 | 最大生命 +10。 |
| warrior_iron_vanguard | 铁壁先锋 | 铁壁先锋腰带 | 腰部 | 最大生命 +7。 |
| warrior_iron_vanguard | 铁壁先锋 | 铁壁先锋手甲 | 手部 | 反击伤害 +1。 |
| warrior_iron_vanguard | 铁壁先锋 | 铁壁先锋护腿 | 护腿 | 护甲上限 +4。 |
| warrior_iron_vanguard | 铁壁先锋 | 铁壁先锋塔盾 | 副手 | 防御行动护甲 +3。 |
| warrior_warlord | 战王 | 战王冠盔 | 头部 | 最大生命 +7。 |
| warrior_warlord | 战王 | 战王胸甲 | 上身 | 最大生命 +9。 |
| warrior_warlord | 战王 | 战王手甲 | 手部 | 攻击技能伤害 +1。 |
| warrior_warlord | 战王 | 战王巨剑 | 武器 | 普通攻击伤害 +3。 |
| warrior_warlord | 战王 | 战王项链 | 项链 | 怒气上限 +1。 |
| warrior_warlord | 战王 | 战王戒指 | 戒指 | 怒气达到上限后下一次攻击伤害 +1。 |

## 弓箭手套装装备

| 套装 ID | 套装 | 装备名 | 栏位 | 基础属性 |
| --- | --- | --- | --- | --- |
| archer_falcon_mark | 隼痕 | 隼痕长弓 | 武器 | 远程普通攻击伤害 +2。 |
| archer_falcon_mark | 隼痕 | 隼痕箭袋 | 副手 | 标记目标伤害 +1。 |
| archer_wind_step | 风步 | 风步护裤 | 下身 | 最大生命 +5。 |
| archer_wind_step | 风步 | 风步轻靴 | 脚部 | 每场战斗开始获得 1 层躲避。 |
| archer_focus_string | 凝弦 | 凝弦护腕 | 手部 | 使用暴击状态卡并命中时获得 1 点专注，每场战斗最多 1 次。 |
| archer_focus_string | 凝弦 | 凝弦戒指 | 戒指 | 专注上限 +1。 |
| archer_quick_draw | 快拔 | 快拔兜帽 | 头部 | 状态卡持有上限 +1。 |
| archer_quick_draw | 快拔 | 快拔束带 | 腰部 | 每场战斗开始抽取状态卡候选 +1。 |
| archer_hunter_trace | 猎踪 | 猎踪兜帽 | 头部 | 最大生命 +5。 |
| archer_hunter_trace | 猎踪 | 猎踪长弓 | 武器 | 远程普通攻击伤害 +2。 |
| archer_hunter_trace | 猎踪 | 猎踪轻靴 | 脚部 | 攻击标记目标后获得 1 点护甲。 |
| archer_sky_feather | 天羽 | 天羽护裤 | 下身 | 最大生命 +5。 |
| archer_sky_feather | 天羽 | 天羽轻靴 | 脚部 | 每场战斗开始获得 1 层躲避。 |
| archer_sky_feather | 天羽 | 天羽项链 | 项链 | 消耗躲避层后抽取状态卡候选 +1。 |
| archer_sharp_eye | 锐眼 | 锐眼兜帽 | 头部 | 暴击状态卡抽取概率 +5%。 |
| archer_sharp_eye | 锐眼 | 锐眼护腕 | 手部 | 使用暴击状态卡并命中时伤害 +1。 |
| archer_sharp_eye | 锐眼 | 锐眼戒指 | 戒指 | 每场战斗开始提高暴击状态卡抽取概率。 |
| archer_thorn_quiver | 棘羽箭袋 | 棘羽护腕 | 手部 | 连击技能最后一段伤害 +1。 |
| archer_thorn_quiver | 棘羽箭袋 | 棘羽短弓 | 武器 | 远程普通攻击伤害 +2。 |
| archer_thorn_quiver | 棘羽箭袋 | 棘羽箭袋 | 副手 | 每场战斗首次连击技能抽 1 张状态卡。 |
| archer_storm_bow | 风暴弓弦 | 风暴弓弦兜帽 | 头部 | 暴击状态卡抽取概率 +5%。 |
| archer_storm_bow | 风暴弓弦 | 风暴弓弦护腕 | 手部 | 使用暴击状态卡并命中时伤害 +1。 |
| archer_storm_bow | 风暴弓弦 | 风暴弓弦长弓 | 武器 | 远程普通攻击伤害 +2。 |
| archer_storm_bow | 风暴弓弦 | 风暴弓弦箭袋 | 副手 | 暴击状态卡持有上限 +1。 |
| archer_moon_path | 月径 | 月径束带 | 腰部 | 最大生命 +5。 |
| archer_moon_path | 月径 | 月径护裤 | 下身 | 护甲上限 +2。 |
| archer_moon_path | 月径 | 月径轻靴 | 脚部 | 每场战斗开始获得 1 层躲避。 |
| archer_moon_path | 月径 | 月径项链 | 项链 | 消耗躲避层后下一次普通攻击伤害 +1。 |
| archer_marked_rain | 印雨 | 印雨兜帽 | 头部 | 标记目标伤害 +1。 |
| archer_marked_rain | 印雨 | 印雨长弓 | 武器 | 远程普通攻击伤害 +2。 |
| archer_marked_rain | 印雨 | 印雨箭袋 | 副手 | 标记层数上限 +1。 |
| archer_marked_rain | 印雨 | 印雨戒指 | 戒指 | 攻击标记目标后抽取状态卡候选 +1，每场战斗最多 1 次。 |
| archer_shadow_pursuit | 影追 | 影追兜帽 | 头部 | 最大生命 +5。 |
| archer_shadow_pursuit | 影追 | 影追护裤 | 下身 | 护甲上限 +2。 |
| archer_shadow_pursuit | 影追 | 影追护腕 | 手部 | 消耗躲避层后下一次攻击伤害 +1。 |
| archer_shadow_pursuit | 影追 | 影追轻靴 | 脚部 | 每场战斗开始获得 1 层躲避。 |
| archer_shadow_pursuit | 影追 | 影追短弓 | 武器 | 远程普通攻击伤害 +2。 |
| archer_star_hunter | 星猎 | 星猎兜帽 | 头部 | 专注上限 +1。 |
| archer_star_hunter | 星猎 | 星猎护腕 | 手部 | 使用暴击状态卡并命中时获得 1 点专注，每场战斗最多 1 次。 |
| archer_star_hunter | 星猎 | 星猎长弓 | 武器 | 远程普通攻击伤害 +2。 |
| archer_star_hunter | 星猎 | 星猎项链 | 项链 | 专注上限 +1。 |
| archer_star_hunter | 星猎 | 星猎戒指 | 戒指 | 消耗专注后下一次攻击技能伤害 +1。 |
| archer_mist_walk | 雾行 | 雾行皮甲 | 上身 | 最大生命 +7。 |
| archer_mist_walk | 雾行 | 雾行束带 | 腰部 | 最大生命 +5。 |
| archer_mist_walk | 雾行 | 雾行护裤 | 下身 | 护甲上限 +2。 |
| archer_mist_walk | 雾行 | 雾行轻靴 | 脚部 | 每场战斗开始获得 1 层躲避。 |
| archer_mist_walk | 雾行 | 雾行项链 | 项链 | 消耗躲避层后获得 2 点护甲。 |
| archer_shadow_hunter | 影猎者 | 影猎者兜帽 | 头部 | 暴击状态卡抽取概率 +5%。 |
| archer_shadow_hunter | 影猎者 | 影猎者护裤 | 下身 | 护甲上限 +2。 |
| archer_shadow_hunter | 影猎者 | 影猎者护腕 | 手部 | 使用暴击状态卡并命中时伤害 +1。 |
| archer_shadow_hunter | 影猎者 | 影猎者轻靴 | 脚部 | 每场战斗开始获得 1 层躲避。 |
| archer_shadow_hunter | 影猎者 | 影猎者短弓 | 武器 | 远程普通攻击伤害 +2。 |
| archer_shadow_hunter | 影猎者 | 影猎者箭袋 | 副手 | 每场战斗首次消耗躲避层后抽 1 张状态卡。 |
| archer_sun_piercer | 贯日者 | 贯日者兜帽 | 头部 | 标记目标伤害 +1。 |
| archer_sun_piercer | 贯日者 | 贯日者护腕 | 手部 | 攻击有 3 层以上标记的目标伤害 +1。 |
| archer_sun_piercer | 贯日者 | 贯日者长弓 | 武器 | 远程普通攻击伤害 +3。 |
| archer_sun_piercer | 贯日者 | 贯日者箭袋 | 副手 | 标记层数上限 +1。 |
| archer_sun_piercer | 贯日者 | 贯日者项链 | 项链 | 击败标记目标后恢复 2 点生命。 |
| archer_sun_piercer | 贯日者 | 贯日者戒指 | 戒指 | 击败标记目标后抽取状态卡候选 +1，每场战斗最多 1 次。 |

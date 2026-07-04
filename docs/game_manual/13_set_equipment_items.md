# 13 套装装备逐件明细

## 设计规则

本文件只记录套装装备的单件信息。每一行代表一件可获得的装备卡，必须包含所属套装、装备名、栏位和基础属性。

套装装备的单件基础属性低于同栏位普通装备，主要价值来自套装效果。项链和戒指没有普通装备版本，只在套装装备中出现。

基础属性默认口径：

- 所有套装装备都提供生命、攻击、护甲三项基础属性。
- 三项属性必须显式填写，允许为 0，不允许缺项。
- 头部、上身、腰部、下身、护腿偏向生命和护甲。
- 手部、武器、副手偏向攻击或攻防混合。
- 脚部偏向均衡属性。
- 项链、戒指基础属性较低，主要价值来自套装效果。

## 通用套装装备

| 套装 ID | 套装 | 装备名 | 栏位 | 基础属性 |
| --- | --- | --- | --- | --- |
| common_traveler | 旅者 | 旅者兜帽 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| common_traveler | 旅者 | 旅者行靴 | 脚部 | 生命 +3；攻击 +1；护甲 +1。 |
| common_apothecary | 药师 | 药师腰包 | 腰部 | 生命 +4；攻击 +0；护甲 +1。 |
| common_apothecary | 药师 | 药师项链 | 项链 | 生命 +2；攻击 +0；护甲 +0。 |
| common_sentinel | 哨卫 | 哨卫胸甲 | 上身 | 生命 +6；攻击 +0；护甲 +2。 |
| common_sentinel | 哨卫 | 哨卫护腿 | 护腿 | 生命 +4；攻击 +0；护甲 +2。 |
| common_quick_hand | 快手 | 快手手套 | 手部 | 生命 +2；攻击 +1；护甲 +1。 |
| common_quick_hand | 快手 | 快手戒指 | 戒指 | 生命 +1；攻击 +1；护甲 +0。 |
| common_deep_lantern | 深灯 | 深灯护符 | 项链 | 生命 +2；攻击 +0；护甲 +0。 |
| common_deep_lantern | 深灯 | 深灯腰带 | 腰部 | 生命 +4；攻击 +0；护甲 +1。 |
| common_bone_charm | 骨符 | 骨符面罩 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| common_bone_charm | 骨符 | 骨符戒指 | 戒指 | 生命 +1；攻击 +1；护甲 +0。 |
| common_moon_pair | 清辉/流霜 | 清辉戒指 | 戒指 | 生命 +1；攻击 +1；护甲 +0。 |
| common_moon_pair | 清辉/流霜 | 流霜戒指 | 戒指 | 生命 +1；攻击 +1；护甲 +0。 |
| common_scavenger | 拾荒者 | 拾荒者兜帽 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| common_scavenger | 拾荒者 | 拾荒者腰包 | 腰部 | 生命 +4；攻击 +0；护甲 +1。 |
| common_scavenger | 拾荒者 | 拾荒者手套 | 手部 | 生命 +2；攻击 +1；护甲 +1。 |
| common_clockwork | 发条 | 发条护腕 | 手部 | 生命 +2；攻击 +1；护甲 +1。 |
| common_clockwork | 发条 | 发条靴 | 脚部 | 生命 +3；攻击 +1；护甲 +1。 |
| common_clockwork | 发条 | 发条戒指 | 戒指 | 生命 +1；攻击 +1；护甲 +0。 |
| common_clear_mind | 清心 | 清心面纱 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| common_clear_mind | 清心 | 清心项链 | 项链 | 生命 +2；攻击 +0；护甲 +0。 |
| common_clear_mind | 清心 | 清心戒指 | 戒指 | 生命 +1；攻击 +1；护甲 +0。 |
| common_old_guard | 旧守备 | 旧守备胸甲 | 上身 | 生命 +6；攻击 +0；护甲 +2。 |
| common_old_guard | 旧守备 | 旧守备护腿 | 护腿 | 生命 +4；攻击 +0；护甲 +2。 |
| common_old_guard | 旧守备 | 旧守备盾牌 | 副手 | 生命 +2；攻击 +1；护甲 +2。 |
| common_tower_map | 塔图 | 塔图腰带 | 腰部 | 生命 +4；攻击 +0；护甲 +1。 |
| common_tower_map | 塔图 | 塔图项链 | 项链 | 生命 +2；攻击 +0；护甲 +0。 |
| common_tower_map | 塔图 | 塔图戒指 | 戒指 | 生命 +1；攻击 +1；护甲 +0。 |
| common_dawn_oath | 晨誓 | 晨誓兜帽 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| common_dawn_oath | 晨誓 | 晨誓胸甲 | 上身 | 生命 +6；攻击 +0；护甲 +2。 |
| common_dawn_oath | 晨誓 | 晨誓手套 | 手部 | 生命 +2；攻击 +1；护甲 +1。 |
| common_dawn_oath | 晨誓 | 晨誓靴 | 脚部 | 生命 +3；攻击 +1；护甲 +1。 |
| common_night_watch | 夜巡 | 夜巡面罩 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| common_night_watch | 夜巡 | 夜巡护裤 | 下身 | 生命 +4；攻击 +0；护甲 +2。 |
| common_night_watch | 夜巡 | 夜巡轻靴 | 脚部 | 生命 +3；攻击 +1；护甲 +1。 |
| common_night_watch | 夜巡 | 夜巡短刃 | 武器 | 生命 +0；攻击 +2；护甲 +0。 |
| common_deep_miner | 深矿 | 深矿胸甲 | 上身 | 生命 +6；攻击 +0；护甲 +2。 |
| common_deep_miner | 深矿 | 深矿腰带 | 腰部 | 生命 +4；攻击 +0；护甲 +1。 |
| common_deep_miner | 深矿 | 深矿护腿 | 护腿 | 生命 +4；攻击 +0；护甲 +2。 |
| common_deep_miner | 深矿 | 深矿镐 | 武器 | 生命 +0；攻击 +2；护甲 +0。 |
| common_echo_archive | 回声档案 | 回声兜帽 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| common_echo_archive | 回声档案 | 回声手套 | 手部 | 生命 +2；攻击 +1；护甲 +1。 |
| common_echo_archive | 回声档案 | 回声项链 | 项链 | 生命 +2；攻击 +0；护甲 +0。 |
| common_echo_archive | 回声档案 | 回声戒指 | 戒指 | 生命 +1；攻击 +1；护甲 +0。 |

## 战士套装装备

| 套装 ID | 套装 | 装备名 | 栏位 | 基础属性 |
| --- | --- | --- | --- | --- |
| warrior_oath_guard | 誓卫 | 誓卫胸甲 | 上身 | 生命 +6；攻击 +0；护甲 +2。 |
| warrior_oath_guard | 誓卫 | 誓卫守盾 | 副手 | 生命 +2；攻击 +1；护甲 +2。 |
| warrior_blood_edge | 血刃 | 血刃战剑 | 武器 | 生命 +0；攻击 +2；护甲 +0。 |
| warrior_blood_edge | 血刃 | 血刃手甲 | 手部 | 生命 +2；攻击 +1；护甲 +1。 |
| warrior_stone_step | 岩步 | 岩步腿甲 | 下身 | 生命 +4；攻击 +0；护甲 +2。 |
| warrior_stone_step | 岩步 | 岩步战靴 | 脚部 | 生命 +3；攻击 +1；护甲 +1。 |
| warrior_war_cry | 战吼印记 | 战吼盔 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| warrior_war_cry | 战吼印记 | 战吼束带 | 腰部 | 生命 +4；攻击 +0；护甲 +1。 |
| warrior_iron_recruit | 铁训 | 铁训盔 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| warrior_iron_recruit | 铁训 | 铁训胸甲 | 上身 | 生命 +6；攻击 +0；护甲 +2。 |
| warrior_iron_recruit | 铁训 | 铁训圆盾 | 副手 | 生命 +2；攻击 +1；护甲 +2。 |
| warrior_counter_chain | 反击链 | 反击链手甲 | 手部 | 生命 +2；攻击 +1；护甲 +1。 |
| warrior_counter_chain | 反击链 | 反击链护腿 | 护腿 | 生命 +4；攻击 +0；护甲 +2。 |
| warrior_counter_chain | 反击链 | 反击链短斧 | 武器 | 生命 +0；攻击 +2；护甲 +0。 |
| warrior_battle_band | 战团 | 战团腰带 | 腰部 | 生命 +4；攻击 +0；护甲 +1。 |
| warrior_battle_band | 战团 | 战团项链 | 项链 | 生命 +2；攻击 +0；护甲 +0。 |
| warrior_battle_band | 战团 | 战团戒指 | 戒指 | 生命 +1；攻击 +1；护甲 +0。 |
| warrior_breaker | 破阵 | 破阵角盔 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| warrior_breaker | 破阵 | 破阵手甲 | 手部 | 生命 +2；攻击 +1；护甲 +1。 |
| warrior_breaker | 破阵 | 破阵战锤 | 武器 | 生命 +0；攻击 +2；护甲 +0。 |
| warrior_shield_wall | 盾墙卫队 | 盾墙盔 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| warrior_shield_wall | 盾墙卫队 | 盾墙胸甲 | 上身 | 生命 +6；攻击 +0；护甲 +2。 |
| warrior_shield_wall | 盾墙卫队 | 盾墙护腿 | 护腿 | 生命 +4；攻击 +0；护甲 +2。 |
| warrior_shield_wall | 盾墙卫队 | 盾墙巨盾 | 副手 | 生命 +2；攻击 +1；护甲 +2。 |
| warrior_rune_forge | 符文熔炉 | 符文熔炉手甲 | 手部 | 生命 +2；攻击 +1；护甲 +1。 |
| warrior_rune_forge | 符文熔炉 | 符文熔炉剑 | 武器 | 生命 +0；攻击 +2；护甲 +0。 |
| warrior_rune_forge | 符文熔炉 | 符文熔炉项链 | 项链 | 生命 +2；攻击 +0；护甲 +0。 |
| warrior_rune_forge | 符文熔炉 | 符文熔炉戒指 | 戒指 | 生命 +1；攻击 +1；护甲 +0。 |
| warrior_mountain_root | 山根 | 山根胸甲 | 上身 | 生命 +6；攻击 +0；护甲 +2。 |
| warrior_mountain_root | 山根 | 山根腰带 | 腰部 | 生命 +4；攻击 +0；护甲 +1。 |
| warrior_mountain_root | 山根 | 山根腿甲 | 下身 | 生命 +4；攻击 +0；护甲 +2。 |
| warrior_mountain_root | 山根 | 山根战靴 | 脚部 | 生命 +3；攻击 +1；护甲 +1。 |
| warrior_rage_brand | 怒痕 | 怒痕盔 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| warrior_rage_brand | 怒痕 | 怒痕胸甲 | 上身 | 生命 +6；攻击 +0；护甲 +2。 |
| warrior_rage_brand | 怒痕 | 怒痕手甲 | 手部 | 生命 +2；攻击 +1；护甲 +1。 |
| warrior_rage_brand | 怒痕 | 怒痕斩剑 | 武器 | 生命 +0；攻击 +2；护甲 +0。 |
| warrior_rage_brand | 怒痕 | 怒痕戒指 | 戒指 | 生命 +1；攻击 +1；护甲 +0。 |
| warrior_relic_guard | 遗物守护 | 遗物守护胸甲 | 上身 | 生命 +6；攻击 +0；护甲 +2。 |
| warrior_relic_guard | 遗物守护 | 遗物守护腰带 | 腰部 | 生命 +4；攻击 +0；护甲 +1。 |
| warrior_relic_guard | 遗物守护 | 遗物守护护腿 | 护腿 | 生命 +4；攻击 +0；护甲 +2。 |
| warrior_relic_guard | 遗物守护 | 遗物守护盾 | 副手 | 生命 +2；攻击 +1；护甲 +2。 |
| warrior_relic_guard | 遗物守护 | 遗物守护项链 | 项链 | 生命 +2；攻击 +0；护甲 +0。 |
| warrior_colossus | 巨像 | 巨像盔 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| warrior_colossus | 巨像 | 巨像胸甲 | 上身 | 生命 +6；攻击 +0；护甲 +2。 |
| warrior_colossus | 巨像 | 巨像腰带 | 腰部 | 生命 +4；攻击 +0；护甲 +1。 |
| warrior_colossus | 巨像 | 巨像护腿 | 护腿 | 生命 +4；攻击 +0；护甲 +2。 |
| warrior_colossus | 巨像 | 巨像战靴 | 脚部 | 生命 +3；攻击 +1；护甲 +1。 |
| warrior_iron_vanguard | 铁壁先锋 | 铁壁先锋盔 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| warrior_iron_vanguard | 铁壁先锋 | 铁壁先锋胸甲 | 上身 | 生命 +6；攻击 +0；护甲 +2。 |
| warrior_iron_vanguard | 铁壁先锋 | 铁壁先锋腰带 | 腰部 | 生命 +4；攻击 +0；护甲 +1。 |
| warrior_iron_vanguard | 铁壁先锋 | 铁壁先锋手甲 | 手部 | 生命 +2；攻击 +1；护甲 +1。 |
| warrior_iron_vanguard | 铁壁先锋 | 铁壁先锋护腿 | 护腿 | 生命 +4；攻击 +0；护甲 +2。 |
| warrior_iron_vanguard | 铁壁先锋 | 铁壁先锋塔盾 | 副手 | 生命 +2；攻击 +1；护甲 +2。 |
| warrior_warlord | 战王 | 战王冠盔 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| warrior_warlord | 战王 | 战王胸甲 | 上身 | 生命 +6；攻击 +0；护甲 +2。 |
| warrior_warlord | 战王 | 战王手甲 | 手部 | 生命 +2；攻击 +1；护甲 +1。 |
| warrior_warlord | 战王 | 战王巨剑 | 武器 | 生命 +0；攻击 +2；护甲 +0。 |
| warrior_warlord | 战王 | 战王项链 | 项链 | 生命 +2；攻击 +0；护甲 +0。 |
| warrior_warlord | 战王 | 战王戒指 | 戒指 | 生命 +1；攻击 +1；护甲 +0。 |

## 弓箭手套装装备

| 套装 ID | 套装 | 装备名 | 栏位 | 基础属性 |
| --- | --- | --- | --- | --- |
| archer_falcon_mark | 隼痕 | 隼痕长弓 | 武器 | 生命 +0；攻击 +2；护甲 +0。 |
| archer_falcon_mark | 隼痕 | 隼痕箭袋 | 副手 | 生命 +2；攻击 +1；护甲 +2。 |
| archer_wind_step | 风步 | 风步护裤 | 下身 | 生命 +4；攻击 +0；护甲 +2。 |
| archer_wind_step | 风步 | 风步轻靴 | 脚部 | 生命 +3；攻击 +1；护甲 +1。 |
| archer_focus_string | 凝弦 | 凝弦护腕 | 手部 | 生命 +2；攻击 +1；护甲 +1。 |
| archer_focus_string | 凝弦 | 凝弦戒指 | 戒指 | 生命 +1；攻击 +1；护甲 +0。 |
| archer_quick_draw | 快拔 | 快拔兜帽 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| archer_quick_draw | 快拔 | 快拔束带 | 腰部 | 生命 +4；攻击 +0；护甲 +1。 |
| archer_hunter_trace | 猎踪 | 猎踪兜帽 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| archer_hunter_trace | 猎踪 | 猎踪长弓 | 武器 | 生命 +0；攻击 +2；护甲 +0。 |
| archer_hunter_trace | 猎踪 | 猎踪轻靴 | 脚部 | 生命 +3；攻击 +1；护甲 +1。 |
| archer_sky_feather | 天羽 | 天羽护裤 | 下身 | 生命 +4；攻击 +0；护甲 +2。 |
| archer_sky_feather | 天羽 | 天羽轻靴 | 脚部 | 生命 +3；攻击 +1；护甲 +1。 |
| archer_sky_feather | 天羽 | 天羽项链 | 项链 | 生命 +2；攻击 +0；护甲 +0。 |
| archer_sharp_eye | 锐眼 | 锐眼兜帽 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| archer_sharp_eye | 锐眼 | 锐眼护腕 | 手部 | 生命 +2；攻击 +1；护甲 +1。 |
| archer_sharp_eye | 锐眼 | 锐眼戒指 | 戒指 | 生命 +1；攻击 +1；护甲 +0。 |
| archer_thorn_quiver | 棘羽箭袋 | 棘羽护腕 | 手部 | 生命 +2；攻击 +1；护甲 +1。 |
| archer_thorn_quiver | 棘羽箭袋 | 棘羽短弓 | 武器 | 生命 +0；攻击 +2；护甲 +0。 |
| archer_thorn_quiver | 棘羽箭袋 | 棘羽箭袋 | 副手 | 生命 +2；攻击 +1；护甲 +2。 |
| archer_storm_bow | 风暴弓弦 | 风暴弓弦兜帽 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| archer_storm_bow | 风暴弓弦 | 风暴弓弦护腕 | 手部 | 生命 +2；攻击 +1；护甲 +1。 |
| archer_storm_bow | 风暴弓弦 | 风暴弓弦长弓 | 武器 | 生命 +0；攻击 +2；护甲 +0。 |
| archer_storm_bow | 风暴弓弦 | 风暴弓弦箭袋 | 副手 | 生命 +2；攻击 +1；护甲 +2。 |
| archer_moon_path | 月径 | 月径束带 | 腰部 | 生命 +4；攻击 +0；护甲 +1。 |
| archer_moon_path | 月径 | 月径护裤 | 下身 | 生命 +4；攻击 +0；护甲 +2。 |
| archer_moon_path | 月径 | 月径轻靴 | 脚部 | 生命 +3；攻击 +1；护甲 +1。 |
| archer_moon_path | 月径 | 月径项链 | 项链 | 生命 +2；攻击 +0；护甲 +0。 |
| archer_marked_rain | 印雨 | 印雨兜帽 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| archer_marked_rain | 印雨 | 印雨长弓 | 武器 | 生命 +0；攻击 +2；护甲 +0。 |
| archer_marked_rain | 印雨 | 印雨箭袋 | 副手 | 生命 +2；攻击 +1；护甲 +2。 |
| archer_marked_rain | 印雨 | 印雨戒指 | 戒指 | 生命 +1；攻击 +1；护甲 +0。 |
| archer_shadow_pursuit | 影追 | 影追兜帽 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| archer_shadow_pursuit | 影追 | 影追护裤 | 下身 | 生命 +4；攻击 +0；护甲 +2。 |
| archer_shadow_pursuit | 影追 | 影追护腕 | 手部 | 生命 +2；攻击 +1；护甲 +1。 |
| archer_shadow_pursuit | 影追 | 影追轻靴 | 脚部 | 生命 +3；攻击 +1；护甲 +1。 |
| archer_shadow_pursuit | 影追 | 影追短弓 | 武器 | 生命 +0；攻击 +2；护甲 +0。 |
| archer_star_hunter | 星猎 | 星猎兜帽 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| archer_star_hunter | 星猎 | 星猎护腕 | 手部 | 生命 +2；攻击 +1；护甲 +1。 |
| archer_star_hunter | 星猎 | 星猎长弓 | 武器 | 生命 +0；攻击 +2；护甲 +0。 |
| archer_star_hunter | 星猎 | 星猎项链 | 项链 | 生命 +2；攻击 +0；护甲 +0。 |
| archer_star_hunter | 星猎 | 星猎戒指 | 戒指 | 生命 +1；攻击 +1；护甲 +0。 |
| archer_mist_walk | 雾行 | 雾行皮甲 | 上身 | 生命 +6；攻击 +0；护甲 +2。 |
| archer_mist_walk | 雾行 | 雾行束带 | 腰部 | 生命 +4；攻击 +0；护甲 +1。 |
| archer_mist_walk | 雾行 | 雾行护裤 | 下身 | 生命 +4；攻击 +0；护甲 +2。 |
| archer_mist_walk | 雾行 | 雾行轻靴 | 脚部 | 生命 +3；攻击 +1；护甲 +1。 |
| archer_mist_walk | 雾行 | 雾行项链 | 项链 | 生命 +2；攻击 +0；护甲 +0。 |
| archer_shadow_hunter | 影猎者 | 影猎者兜帽 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| archer_shadow_hunter | 影猎者 | 影猎者护裤 | 下身 | 生命 +4；攻击 +0；护甲 +2。 |
| archer_shadow_hunter | 影猎者 | 影猎者护腕 | 手部 | 生命 +2；攻击 +1；护甲 +1。 |
| archer_shadow_hunter | 影猎者 | 影猎者轻靴 | 脚部 | 生命 +3；攻击 +1；护甲 +1。 |
| archer_shadow_hunter | 影猎者 | 影猎者短弓 | 武器 | 生命 +0；攻击 +2；护甲 +0。 |
| archer_shadow_hunter | 影猎者 | 影猎者箭袋 | 副手 | 生命 +2；攻击 +1；护甲 +2。 |
| archer_sun_piercer | 贯日者 | 贯日者兜帽 | 头部 | 生命 +4；攻击 +0；护甲 +1。 |
| archer_sun_piercer | 贯日者 | 贯日者护腕 | 手部 | 生命 +2；攻击 +1；护甲 +1。 |
| archer_sun_piercer | 贯日者 | 贯日者长弓 | 武器 | 生命 +0；攻击 +2；护甲 +0。 |
| archer_sun_piercer | 贯日者 | 贯日者箭袋 | 副手 | 生命 +2；攻击 +1；护甲 +2。 |
| archer_sun_piercer | 贯日者 | 贯日者项链 | 项链 | 生命 +2；攻击 +0；护甲 +0。 |
| archer_sun_piercer | 贯日者 | 贯日者戒指 | 戒指 | 生命 +1；攻击 +1；护甲 +0。 |

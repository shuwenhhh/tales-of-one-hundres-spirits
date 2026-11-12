# 第三章：青砚动作与战斗

运行中的角色使用[青砚动作原稿](concepts/qingyan_action_strip_v1.png)，由 `tools/prepare_chapter3_art.gd` 统一裁切成 `pixel/qingyan_walk_0.png` 至 `_2.png`、`pixel/qingyan_jump.png`、`pixel/qingyan_cast.png`。所有帧在 110×176 的透明画布上按脚底中央对齐；原立绘另作待机帧。走向玩家时循环三帧行走，后跳时显示腾空帧，施火与瞬移出手时显示抬手帧。

狐火使用已选定的 B 款圆团暖红火焰：深绛红 `#7C2426`、朱红 `#D94132`、暖红 `#EE5835`、橙色 `#FF8A42`、金黄 `#FFD073`。运行时原生像素图为 `pixel/foxfire_b_idle.png` 与 `pixel/foxfire_b_charge.png`。青蓝色雨夜背景让火焰轮廓清晰可见。

## 行动循环

青砚走向玩家，距离太近则后跳；之后出招、停顿 0.6 秒，再继续走位。贴身持续 1.5 秒会打断普通循环，强制后跳并接一次狐火扇射。正常循环依次使用以下三招，不启用旧版地火和狐火雨。

| 招式 | 预兆 | 执行 | 玩家应对 |
| --- | --- | --- | --- |
| 突进 | 全身闪白 0.4 秒 | 从青砚当前位置向玩家一侧冲约 440 像素 | 跳起或冲刺 |
| 狐火扇射 | 抬手蓄火并闪光 0.4 秒 | 三团狐火同时从手边射向玩家，约 390 像素/秒 | 走位、跳跃、冲刺，或按 J 用伞反弹 |
| 瞬移 | 消失片刻 | 出现在玩家背后，有提示圈；停 0.3 秒后向前挥击 | 看落点并离开近身范围 |

血量剩一半及以下，突进和扇射的 0.4 秒前摇缩短到 0.28 秒；瞬移的消失时间和现身后停顿也缩短 30%。双方命中时都有短暂纯白闪烁、少量击退和 60 毫秒命中停顿。

逻辑见 `scripts/chapter3.gd`，回归验证见 `scripts/verify_chapter3.gd`。实机截图见 `art_review/chapter3/walk_0.png`、`backjump.png`、`fan_warning.png`、`fan_flight.png` 和 `teleport_behind.png`。旧概念分镜保留在 `concepts/` 供追溯，但不代表当前玩法。

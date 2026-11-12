# 第三章月夜竹林背景

- 游戏用图：[moon_bamboo_wedding_pixel_v1.png](moon_bamboo_wedding_pixel_v1.png)，960×540，最近邻缩放。
- 生成原图：[moon_bamboo_wedding_source_v1.png](moon_bamboo_wedding_source_v1.png)，1672×941。使用内置 ImageGen 根据用户提供的竹林月夜参考图生成原创像素风场景：左侧竹林与远亭、右侧月亮和石灯、中部雾气留白、横贯全屏的平直石路。未绘入人物、攻击、界面和雨丝。
- 处理脚本：`tools/prepare_chapter3_background.gd` 将原图按最近邻缩放到游戏分辨率。第三章脚本 `scripts/chapter3.gd` 以地面高度 438 放置角色，雨层仍由 `scripts/rain_weather.gd` 独立绘制。
- 暖红狐火与背景采用冷暖对比；右侧石灯为较暗的黄色小光源，与会移动的狐火有不同轮廓。

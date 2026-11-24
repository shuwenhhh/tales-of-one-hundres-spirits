# 桃园背景候选图

## 2026-11-17：选定 D 与复古井修订

用户选定 D，要求井更复古、井顶没有花。使用内置 `image_gen` 编辑 D，保留桃树、远山、月色、旧书石凳、门与石板路，仅重绘画面右侧约 x=72%–88%、y=48%–79% 的井。提示词重点：旧深灰棕木柱、磨旧瓦顶、手砌粗石井圈、木滑轮、绳和旧桶；移除井顶及井架上的花和藤蔓，井的位置与体量不变，不增加第二口井。输出 `peach_orchard_anime_d_well_v2_960x540.png`，使用最近邻缩放；当前游戏使用此版本。

## 2026-11-17：日系庭院与石井候选 G/H/I

使用内置 `image_gen`，以游戏背景作为布局参考，以用户给出的月夜像素树图和日式庭院石井图作为风格参考。三张均是完整背景：月色、远山、日式园景、桃花树、清楚可见的敞口圆形石井、横贯画面的石板路以及路下暗红海波纹墙。树干、枝条和桃花画在同一张图里；不绘人物、UI、文字、水印或满天飘花。

- G：桃树和井在右边；左边是园门，天空与中央战斗区较开阔。提示词重点为深紫月夜像素色调、右侧自然花冠、井口可见水面。
- H：桃树在左、敞口石井在右，右侧加园墙与圆门。提示词强调石板路保持较低、中央留白和大块像素画色块；当前游戏暂用此图。
- I：暖紫色傍晚，右侧桃树和敞口井，左侧圆门与旧书石凳。提示词强调更明显的日漫庭院绘景与柔暖灯光。

输出为 `peach_orchard_japanese_g_960x540.png`、`peach_orchard_japanese_h_960x540.png`、`peach_orchard_japanese_i_960x540.png`；生成原图由内置工具保存在 Codex 生成图片目录，游戏尺寸版本使用最近邻缩放。

## 2026-11-17：整幅日漫绘景候选 D/E/F

使用内置 `image_gen` 编辑现有第二章背景，另以用户提供的桃花树画面作树形与花冠参考；参考图仅用于风格和形态，不复制其构图、水印或白昼色彩。原图统一用最近邻缩放为 960×540。花、枝、树干和远景都是同一张背景画，没有独立花层。当前游戏暂用 F。

三张共同提示词：完整的 16:9 横版 2D 游戏背景；旧桃园月夜、微雨、淡紫山峦与雾、远处暖灯小楼；左侧石凳与摊开的旧书，右侧带屋顶的古井和半掩竹门；画面高度约 83% 处是平直石板路，下方是带淡海波纹的暗红墙；画面中下部留给角色战斗。树干从左侧生长，枝条与灰粉桃花自然连接。整幅图采用日漫场景绘画的色块和气氛，保留适合游戏尺寸的像素画质感。避免鳞片状树皮、密集重复花纹、悬空花瓣、人物、文字、UI 和水印。

- D：最繁盛、最明亮的花冠；树干用宽阔流畅的深棕笔触，花冠铺满左上方。
- E：更冷、更空灵；桃花主要框住左上和中上方，天空和枝条留白更多。
- F：树干轮廓最鲜明，花色最淡；深梅棕色树干、奶粉色花冠，整张画更像月夜的日漫场景镜头。

输出：`peach_orchard_anime_d_960x540.png`、`peach_orchard_anime_e_960x540.png`、`peach_orchard_anime_f_960x540.png`。另保留较早的融合背景候选 `peach_orchard_integrated_{a,b,c}_960x540.png` 供比较。

使用内置 image_gen 生成。参考图：`assets/chapter2/peach_garden_pixel_v1.png`。A、B、C 为同一风格的构图变化。用户选定 C，`peach_orchard_c_960x540.png` 已接入 `scripts/chapter2.gd`。清理后仅保留选定 C 的原图和游戏尺寸版本，A、B 候选图已删除；以下提示词保留作生成记录。原图为 1672×941；另用最近邻缩放导出精确 16:9 的 960×540 游戏尺寸版本。

## A

Create a NEW landscape 2D side-scrolling game background, 16:9 composition, painterly handcrafted pixel art consistent in pixel cluster size, muted palette and misty depth with the attached existing peach garden background used ONLY as a style and palette reference. No characters, no UI, no lettering, no signatures. Scene: an old peach orchard in a moonlit light rain. LEFT: one venerable dark brown peach tree rooted entirely on the far left, curved trunk bending inward toward center, gray dusty-pink blossoms on branches reaching to the upper right; keep the upper-left corner relatively dark and visually quiet with negative space rather than a bright flower mass. Beneath the tree, one low weathered stone bench, an old book unrolled/opened on the seat, recognizable but small. MIDDLE DISTANCE: soft lilac fog, layered pale purple mountain ridges and a few small old Chinese pavilion houses with tiny warm amber windows. RIGHT: one old well with wood frame and a small pitched roof, the well rim glowing faintly; beside it a partly closed woven bamboo garden gate, wrapped with a few flowering peach twigs. The center and center-right immediately above the walking floor remain broad, level, open and EMPTY for moving sprites. FOREGROUND: a flat continuous stone-paved platform crossing the full width, its upper walking edge at exactly 83% of image height; below the stones a dark muted red wall with faint traditional seigaiha wave arcs. Only a few fallen blossoms ON THE GROUND; absolutely no petals suspended or falling in the air. Fine sparse rain streaks, gentle atmospheric mist, quiet tender longing and slight loneliness. Moonlight blue violet, gray pink, old wood brown and just a few warm lantern accents. Side view game environment with crisp but painterly pixel clusters, readable at 960x540, no excessive detail, no watermarks. Make a complete full-bleed background, not a frame, sheet, mockup or screenshot.

## B

Generate a SECOND distinct full-bleed 16:9 side-scrolling 2D game background, using the attached previous candidate ONLY as art-style and palette reference; do not replicate its exact layout. Painterly pixel art with deliberate crisp pixel clusters and soft layered lilac fog, readable at 960x540. Same quiet moonlit rainy old peach orchard: on far LEFT a single gnarled old peach tree with crooked trunk bending toward center, gray muted pale-pink blossoms and branches rising toward upper right; leave upper left dark and spare. Under it, a small weathered stone bench holding a clearly open old rolled book. The distant mountains are more misty and layered than the reference; only a few old Chinese pavilions with small glowing warm windows. On RIGHT a mildly luminous old stone well under a small wood-tile roof, with a half-closed WOVEN BAMBOO garden gate immediately beside it and flowering peach twigs around the gate. Keep middle and center-right of the stage OPEN and uncluttered for two game characters, with a flat uninterrupted full-width stone platform whose WALKING TOP EDGE is at 83% image height. Below the stone platform is a dark desaturated red retaining wall bearing very faint Japanese/Chinese seigaiha wave arc pattern. Fine sparse night rain. Small scattered fallen blossoms only on ground; NO petals floating or falling in the sky. Moonlight blue-violet, dusty gray-pink, old wood brown, tiny warm amber lights. Tender quiet longing, slightly lonely. This variant: more atmospheric negative space and a narrower tree crown, a slightly more visible bench and book, well and bamboo gate gathered neatly near the rightmost 20%. No people, figures, animals, text, UI, logo, border, watermark.

## C

Create a THIRD distinct candidate background for the same 2D pixel-art side-scrolling game. Treat attached orchard image ONLY as reference for painterly pixel clusters, palette and existing game's atmosphere; redraw a NEW composition. EXACT wide 16:9 full-bleed landscape. Old peach orchard at night in fine drizzle, tender melancholic mood. Far-left very old peach tree with a dramatically curved dark wood trunk leaning toward image center, restrained clusters of dusty gray-pink blossoms only on the tree, crown branches arching up and right. Upper-left quadrant should be dark and relatively empty. Directly below trunk: a low worn stone bench with an unfurled old book OPEN on top. Behind the EMPTY playable middle and middle-right: layered lilac fog and hazy purple mountain silhouettes, two or three tiny old pavilion buildings with amber-lit windows, a visible warm-cool contrast but no bright clutter. Far right: historic stone well with timber posts and small pitched roof; well rim has a subtle pale gold glow. Immediately to the well's right a visibly HALF-OPEN woven bamboo garden gate, with one hinged panel angled ajar leaving a dark opening; flowering peach twigs wrap the gate. Reserve a broad clear horizontal zone for player and boss sprites across center and center-right above the path. A seamless FLAT stone-paved walkway spans the entire width, with its walkable TOP EDGE precisely at 83% of canvas height. Below walkway a deep muted terracotta wall with faint seigaiha wave arcs. Very few blossom petals lying on stone floor ONLY; absolutely no falling or floating petals or sparkles anywhere in air. Sparse slender rain lines, softened fog, layered depth. Colors moonlight blue-violet, dusty gray pink, old wood brown, tiny amber lights. Pixel painting rather than smooth anime illustration, medium-sized pixel blocks, clear silhouettes at 960x540. No persons, characters, animals, text, labels, UI, frame, signature, watermark. Keep scenic background complete and game-ready.

$ErrorActionPreference = 'Stop'
$out = $PSScriptRoot
$header = @'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="960" height="540" viewBox="0 0 960 540">
'@
$defs = @'
<defs>
  <linearGradient id="robe" x1="0" x2="1" y1="0" y2="1"><stop stop-color="#f7edf0"/><stop offset="1" stop-color="#c7b9d2"/></linearGradient>
  <linearGradient id="skirt" x1="0" x2="0.9" y1="0" y2="1"><stop stop-color="#e8b9c9"/><stop offset="1" stop-color="#aa7d9e"/></linearGradient>
  <linearGradient id="hair" x1="0" x2="1" y1="0" y2="1"><stop stop-color="#b5a6c9"/><stop offset="1" stop-color="#756b97"/></linearGradient>
  <g id="flower" stroke="#744e69" stroke-width="1.5">
    <ellipse cx="0" cy="-7" rx="5" ry="7" fill="#f7c6ca"/>
    <ellipse cx="6.5" cy="-2" rx="5" ry="7" transform="rotate(70 6.5 -2)" fill="#efb4c2"/>
    <ellipse cx="4" cy="6" rx="5" ry="7" transform="rotate(145 4 6)" fill="#f4bec8"/>
    <ellipse cx="-4" cy="6" rx="5" ry="7" transform="rotate(215 -4 6)" fill="#f8ccd0"/>
    <ellipse cx="-6.5" cy="-2" rx="5" ry="7" transform="rotate(290 -6.5 -2)" fill="#ebb0bf"/>
    <circle r="3" fill="#f7d38e" stroke="none"/>
  </g>
  <g id="leaf" fill="#8c966d" stroke="#4b5144" stroke-width="1.4"><path d="M0 0 Q-5 -10 -15 -7 Q-10 2 0 0Z"/><path d="M0 0 Q5 -10 15 -7 Q10 2 0 0Z"/></g>
  <g id="spirit-core" stroke="#4d3b5b" stroke-width="3.2" stroke-linejoin="round" stroke-linecap="round">
    <!-- One stable head and body are shared by every action. -->
    <path d="M111 162 Q156 158 175 205 Q196 268 182 313 Q169 325 143 282 L128 215Z" fill="#d3c4d8"/>
    <path d="M77 211 Q55 241 49 315 Q36 354 36 369 Q88 382 150 369 Q152 326 135 267 L121 210Z" fill="url(#skirt)"/>
    <path d="M88 252 Q71 311 49 357 Q62 373 83 370 Q106 337 116 299Z" fill="#d69bb4" stroke-width="1.5"/>
    <path d="M117 238 Q137 292 145 360 L129 369 Q116 328 105 293Z" fill="#b581a0" stroke-width="1.5"/>
    <path d="M71 162 Q54 178 57 236 Q47 278 30 335 Q43 351 57 346 Q73 322 91 274 L109 205Z" fill="url(#robe)"/>
    <path d="M103 162 Q132 159 146 197 Q164 250 168 315 Q152 331 138 314 Q121 271 110 231Z" fill="url(#robe)"/>
    <path d="M76 164 Q96 148 116 163 L128 215 Q109 237 75 218Z" fill="#f2e7e9"/>
    <path d="M80 169 L100 203 L113 167" fill="none" stroke="#b989a4" stroke-width="5"/>
    <path d="M74 218 Q102 227 132 215 L134 231 Q100 243 72 231Z" fill="#828a6d"/>
    <path d="M98 229 Q92 247 87 277 Q98 270 106 252 Q110 273 115 279 L112 235Z" fill="#67745d" stroke-width="2"/>
    <path d="M91 232 Q81 223 77 232 Q84 243 95 237 Q102 246 112 235 Q104 225 96 232Z" fill="#a9ae81" stroke-width="2"/>
    <path d="M59 365 Q58 377 74 378 L88 374 L83 366Z" fill="#f7e4df"/>
    <path d="M123 365 Q123 378 138 378 L151 373 L142 364Z" fill="#f7e4df"/>
    <path d="M91 72 Q115 52 149 71 Q173 80 173 114 Q171 138 152 143 Q144 160 121 152 Q105 151 96 135Z" fill="url(#hair)"/>
    <ellipse cx="154" cy="118" rx="26" ry="23" fill="#817598"/>
    <path d="M108 86 Q84 82 75 101 Q63 111 68 135 Q78 151 101 146 Q118 134 124 113Z" fill="#f7dbd3"/>
    <path d="M71 95 Q86 64 121 71 Q141 75 148 96 Q123 90 112 103 Q91 106 75 121 Q66 115 71 95Z" fill="url(#hair)"/>
    <path d="M80 102 Q98 79 118 82 M97 94 Q118 74 133 84 M131 102 Q150 102 155 120" fill="none" stroke="#d4c6dc" stroke-width="3"/>
    <path d="M74 120 Q53 127 47 149 Q45 158 37 165" fill="none" stroke="#84799d" stroke-width="8"/>
    <path d="M77 119 Q58 131 54 147" fill="none" stroke="#c8b9d6" stroke-width="3"/>
    <path d="M78 115 Q83 113 89 116" fill="none" stroke="#51405b" stroke-width="2.4"/>
    <circle cx="84" cy="118" r="1.5" fill="#473950" stroke="none"/>
    <path d="M75 139 Q79 141 84 138" fill="none" stroke="#a9687c" stroke-width="1.6"/>
    <path d="M132 107 Q158 105 168 122" fill="none" stroke="#c0b1d3" stroke-width="3"/>
    <g stroke="none"><use xlink:href="#flower" transform="translate(157 76) scale(.72)"/><use xlink:href="#flower" transform="translate(173 93) scale(.70)"/><use xlink:href="#flower" transform="translate(160 111) scale(.62)"/></g>
  </g>
</defs>
'@
$footer = '</svg>'

$scenes = [ordered]@{}
$scenes['01_small_steps.svg'] = @'
  <path d="M40 479 H920" stroke="#6c5976" stroke-width="3" opacity=".48"/>
  <ellipse cx="666" cy="478" rx="43" ry="7" fill="#524461" opacity=".18"/>
  <g transform="translate(613 101)"><use xlink:href="#spirit-core"/>
    <path d="M78 183 Q56 186 42 201 Q37 214 57 227 Q75 222 83 209Z" fill="url(#robe)" stroke="#4d3b5b" stroke-width="3"/>
    <path d="M58 207 Q49 213 49 223" fill="none" stroke="#e9cabe" stroke-width="9" stroke-linecap="round"/>
    <path d="M52 220 Q11 231 -48 211" fill="none" stroke="#594151" stroke-width="5" stroke-linecap="round"/>
    <use xlink:href="#flower" transform="translate(-43 213) scale(.7)"/>
  </g>
  <path d="M618 477 Q602 469 591 477 M684 479 Q699 471 710 478 M735 479 Q749 471 762 477" fill="none" stroke="#b18ba4" stroke-width="2" opacity=".55"/>
'@
$scenes['02_long_whip.svg'] = @'
  <path d="M40 479 H920" stroke="#6c5976" stroke-width="3" opacity=".48"/>
  <ellipse cx="756" cy="478" rx="44" ry="7" fill="#524461" opacity=".18"/>
  <g transform="translate(694 101)"><use xlink:href="#spirit-core"/>
    <path d="M78 182 Q52 178 29 180 Q16 193 27 211 Q48 217 76 202Z" fill="url(#robe)" stroke="#4d3b5b" stroke-width="3"/>
    <path d="M46 188 Q29 185 15 185" fill="none" stroke="#f0d0c4" stroke-width="9" stroke-linecap="round"/>
    <path d="M18 186 L-65 176" fill="none" stroke="#654858" stroke-width="6" stroke-linecap="round"/>
    <use xlink:href="#flower" transform="translate(-62 176) scale(.62)"/>
  </g>
  <path d="M629 277 C552 250 510 300 431 276 S305 214 234 257 S117 292 61 247" fill="none" stroke="#3e4050" stroke-width="16" stroke-linecap="round"/>
  <path d="M629 277 C552 250 510 300 431 276 S305 214 234 257 S117 292 61 247" fill="none" stroke="#87916d" stroke-width="10" stroke-linecap="round"/>
  <path d="M630 277 C551 253 510 303 431 279 S305 217 234 260 S116 295 60 250" fill="none" stroke="#bdc49b" stroke-width="2" opacity=".8"/>
  <use xlink:href="#leaf" transform="translate(526 278) rotate(35)"/>
  <use xlink:href="#leaf" transform="translate(338 231) rotate(-14)"/>
  <use xlink:href="#flower" transform="translate(203 270) scale(.62)"/>
  <use xlink:href="#flower" transform="translate(72 254) scale(.7)"/>
  <path d="M106 213 Q65 207 28 219" fill="none" stroke="#d8a8ba" stroke-width="3" opacity=".45"/>
'@
$scenes['03_air_whip.svg'] = @'
  <path d="M40 479 H920" stroke="#6c5976" stroke-width="3" opacity=".48"/>
  <ellipse cx="640" cy="478" rx="48" ry="7" fill="#524461" opacity=".18"/>
  <path d="M559 477 Q599 459 640 477 Q674 460 706 476" fill="none" stroke="#c6a5b5" stroke-width="2" stroke-dasharray="5 7" opacity=".5"/>
  <g transform="translate(569 -10) rotate(-6 100 230)"><use xlink:href="#spirit-core"/>
    <path d="M80 183 Q45 180 31 214 Q38 234 57 222 Q72 213 87 206Z" fill="url(#robe)" stroke="#4d3b5b" stroke-width="3"/>
    <path d="M55 202 Q38 199 28 211" fill="none" stroke="#efd0c4" stroke-width="9" stroke-linecap="round"/>
    <path d="M28 211 L-26 234" fill="none" stroke="#654858" stroke-width="6" stroke-linecap="round"/>
    <use xlink:href="#flower" transform="translate(-23 232) scale(.63)"/>
  </g>
  <path d="M545 227 C476 207 431 239 388 271 S284 320 246 361 Q229 382 208 394" fill="none" stroke="#3e4050" stroke-width="17" stroke-linecap="round"/>
  <path d="M545 227 C476 207 431 239 388 271 S284 320 246 361 Q229 382 208 394" fill="none" stroke="#8d9670" stroke-width="11" stroke-linecap="round"/>
  <use xlink:href="#leaf" transform="translate(425 242) rotate(130)"/>
  <use xlink:href="#leaf" transform="translate(307 309) rotate(145)"/>
  <use xlink:href="#flower" transform="translate(216 382) scale(.7)"/>
  <path d="M610 396 Q577 430 573 459" fill="none" stroke="#c6abc2" stroke-width="3" stroke-dasharray="4 10" opacity=".55"/>
'@
$scenes['04_corner_vault.svg'] = @'
  <path d="M40 479 H920" stroke="#6c5976" stroke-width="3" opacity=".48"/>
  <path d="M868 380 V480" stroke="#766279" stroke-width="12" stroke-linecap="round" opacity=".42"/>
  <path d="M545 477 Q628 400 730 448" fill="none" stroke="#bda2c3" stroke-width="3" stroke-dasharray="6 9" opacity=".6"/>
  <ellipse cx="698" cy="478" rx="44" ry="7" fill="#524461" opacity=".18"/>
  <g transform="translate(637 -9) rotate(-8 100 230)"><use xlink:href="#spirit-core"/>
    <path d="M77 183 Q45 166 31 184 Q32 202 59 211 L85 202Z" fill="url(#robe)" stroke="#4d3b5b" stroke-width="3"/>
    <path d="M52 187 Q36 177 19 176" fill="none" stroke="#efcfc4" stroke-width="9" stroke-linecap="round"/>
    <path d="M19 176 L-30 162" fill="none" stroke="#654858" stroke-width="6" stroke-linecap="round"/>
  </g>
  <path d="M610 173 C540 126 509 173 448 187 S352 166 301 207" fill="none" stroke="#3e4050" stroke-width="16" stroke-linecap="round"/>
  <path d="M610 173 C540 126 509 173 448 187 S352 166 301 207" fill="none" stroke="#87916d" stroke-width="10" stroke-linecap="round"/>
  <use xlink:href="#leaf" transform="translate(468 183) rotate(22)"/>
  <use xlink:href="#flower" transform="translate(310 203) scale(.72)"/>
  <path d="M524 479 Q500 468 479 479" fill="none" stroke="#af91b0" stroke-width="2" opacity=".52"/>
'@
$scenes['05_blossom_rain.svg'] = @'
  <path d="M40 479 H920" stroke="#6c5976" stroke-width="3" opacity=".48"/>
  <path d="M102 474 Q121 372 101 247 Q90 180 63 126" fill="none" stroke="#5b465d" stroke-width="51" stroke-linecap="round"/>
  <path d="M102 474 Q121 372 101 247 Q90 180 63 126" fill="none" stroke="#8d6d75" stroke-width="30" stroke-linecap="round"/>
  <path d="M91 207 C228 129 357 136 500 73 M143 287 C255 226 397 263 540 192 M90 152 C189 68 297 73 365 46" fill="none" stroke="#62495d" stroke-width="16" stroke-linecap="round"/>
  <path d="M143 286 C255 225 397 262 540 191 M91 207 C228 129 357 136 500 73" fill="none" stroke="#a37c8b" stroke-width="6" stroke-linecap="round"/>
  <g opacity=".9"><use xlink:href="#flower" transform="translate(164 150) scale(1.05)"/><use xlink:href="#flower" transform="translate(223 104) scale(.9)"/><use xlink:href="#flower" transform="translate(287 136) scale(1.1)"/><use xlink:href="#flower" transform="translate(357 105) scale(.95)"/><use xlink:href="#flower" transform="translate(466 85) scale(1.0)"/><use xlink:href="#flower" transform="translate(210 248) scale(1.0)"/><use xlink:href="#flower" transform="translate(327 229) scale(.95)"/><use xlink:href="#flower" transform="translate(445 238) scale(1.0)"/></g>
  <g opacity=".8"><use xlink:href="#flower" transform="translate(166 315) scale(.76)"/><use xlink:href="#flower" transform="translate(295 347) scale(.82)"/><use xlink:href="#flower" transform="translate(418 376) scale(.74)"/><use xlink:href="#flower" transform="translate(529 329) scale(.77)"/><use xlink:href="#flower" transform="translate(207 421) scale(.76)"/></g>
  <g transform="translate(681 101)"><use xlink:href="#spirit-core"/>
    <path d="M82 182 Q54 152 46 127 Q56 107 72 126 L94 169Z" fill="url(#robe)" stroke="#4d3b5b" stroke-width="3"/>
    <path d="M57 138 Q47 123 44 114" fill="none" stroke="#efd0c4" stroke-width="9" stroke-linecap="round"/>
    <path d="M44 114 L-13 39" fill="none" stroke="#654858" stroke-width="6" stroke-linecap="round"/>
    <use xlink:href="#flower" transform="translate(-12 40) scale(.7)"/>
  </g>
'@

foreach ($name in $scenes.Keys) {
    $path = Join-Path $out $name
    [System.IO.File]::WriteAllText($path, $header + $defs + $scenes[$name] + $footer, [System.Text.UTF8Encoding]::new($false))
}

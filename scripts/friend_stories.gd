extends RefCounted

# Append future friends here; use chapter scene paths as stable progress keys.
const ENTRIES := [
	{
		"scene": "res://chapter0.tscn", "name": "Umbrella Spirit", "chapter": "A FOUND UMBRELLA",
		"background": preload("res://assets/chapter0/concepts/old_manor_road_moonlit_v3.png"),
		"portrait": preload("res://assets/chapter0/encounter/spirit.png"), "role": "An old blue umbrella",
		"intro": "Something is knocking inside a trunk outside the shuttered manor.",
		"summary": "Ten raindrops brought back an old familiar sound.",
		"story": "Left in a trunk when the household moved away, the blue umbrella longed to feel rain again. Xiaoyu caught ten drops. Even on sunny days, they would travel together."
	},
	{
		"scene": "res://chapter1.tscn", "name": "Grandmother", "chapter": "SPRING UNSEEN",
		"chapter_title": "ENDLESS THREADS",
		"background": preload("res://assets/chapter1/backgrounds/rain_town_pixel_v1.png"),
		"role": "A silkworm who waited for wings",
		"portrait": preload("res://assets/chapter1/pixel/granny/pose_0.png"),
		"intro": "An old woman sits at a spinning wheel in the rain. She says she is burning, though she has no kettle and the night is cold.",
		"summary": "She made a cocoon to become something new. The silk was taken before she could see the sky. Xiaoyu stayed and listened; at last, Grandmother could hear the rain.",
		"story": "Grandmother was once a silkworm. She made her cocoon believing it was a waiting room for wings. Instead, humans lowered it into boiling water and took its silk. She never saw the sky outside.\n\nLong afterward, the memory of that heat still held her. She sat beside her spinning wheel in the cold rain, asking it to try harder. Her terror became the white silk that lashed around her.\n\nXiaoyu could not undo what had happened or find words that made it fair. She listened anyway. When the silk grew quiet, Grandmother could finally distinguish the rain from the water she remembered. She asked Xiaoyu to remember the others: they had been waiting for wings, too."
	},
	{
		"scene": "res://chapter2.tscn", "name": "Peach Spirit", "chapter": "PEACH BLOSSOM RAIN",
		"background": preload("res://assets/chapter2/peach_garden_pixel_v1.png"),
		"role": "The keeper of an unspoken invitation",
		"portrait": preload("res://assets/chapter2/peach-spirit-idle.png"),
		"intro": "Beside a quiet well, a spirit asks Xiaoyu not to wrinkle the water. Someone's reflection seems to linger beneath the blossoms.",
		"summary": "She waited for lovelier blossoms before speaking. The person she hoped to invite would not return. When the water stirred, Xiaoyu offered to sit beside her for a while.",
		"story": "A visitor once came to the peach garden to read poetry. The spirit watched from behind her tree. Each evening she wanted to ask him to return the following night, and each evening she decided to wait until the blossoms looked lovelier.\n\nHe stopped coming. In the still water she kept his reflection, as though a single ripple might carry him away. She guarded that quiet with flowering branches and wind, unable to say what she had never said aloud.\n\nWhen the water finally stirred, she admitted that this time she could not make him stay. Xiaoyu did not promise to bring him back. She offered to sit in the garden for a while. The spirit asked her name, then wished her a safe journey."
	},
	{
		"scene": "res://chapter3.tscn", "name": "Qingyan", "chapter": "THE FOX WEDDING",
		"background": preload("res://assets/chapter3/backgrounds/moon_bamboo_wedding_pixel_v1.png"),
		"role": "A masked guide at a thread-thin boundary",
		"portrait": preload("res://assets/chapter3/pixel/qingyan_idle.png"),
		"intro": "On a rainy mountain road, a man in a white fox mask tells Xiaoyu to stop. A red thread has drifted to her shoes.",
		"summary": "Xiaoyu only wanted shelter. Qingyan tried to keep her beyond the wedding's boundary. The foxfire has fallen quiet, but the red thread still leads onward.",
		"story": "Xiaoyu followed a red lantern while looking for shelter. Qingyan stood in the road, wearing a white fox mask and a length of red thread around his wrist. He warned her that she had wandered somewhere unsafe.\n\nRain carried a thread to her shoes. Qingyan called it a threshold, though even he thought it was rather thin. He did not attack because she had spoken out of turn: he was trying to push her out before the ceremony drew her farther in.\n\nXiaoyu raised her umbrella against the thread and the foxfire. When the flames fell quiet, the mountain road and its strange wedding remained. This encounter records the beginning of Qingyan's story; the promises behind his mask are still waiting to be understood."
	}
]

static func find(scene: String) -> Dictionary:
	for entry in ENTRIES:
		if entry.scene == scene:
			return entry
	return {}

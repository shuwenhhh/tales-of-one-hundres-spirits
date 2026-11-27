"""Generate chapter background music with Google's Lyria models through the Gemini API.

Usage:
    python tools/generate_bgm_gemini.py                 # every track, full length
    python tools/generate_bgm_gemini.py silk_battle     # one track
    python tools/generate_bgm_gemini.py --draft         # cheap 30-second drafts into art_review/

The key is read from the GEMINI_API_KEY environment variable, or from a
GEMINI_API_KEY=... line in the git-ignored .env file at the project root.
Lyria needs a paid-tier key. Results differ on every call; rerun to get another take.
"""
from pathlib import Path
import argparse
import base64
import json
import os
import sys
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
MUSIC = ROOT / "assets/audio/music"
DRAFTS = ROOT / "art_review/audio/music"
ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/interactions"
FULL_MODEL = "lyria-3.5"
DRAFT_MODEL = "lyria-3-clip-preview"

TRACKS = {
    # Chapter zero: catching ten bright raindrops with the umbrella spirit.
    "rain_catch": (
        "Instrumental only, no vocals. Background music loop for a gentle 2D pixel-art game scene: "
        "a girl and a small umbrella spirit catch bright raindrops on a moonlit old Chinese road. "
        "D major pentatonic, 88 BPM. Soft guzheng and pipa plucks that fall like single raindrops, "
        "a warm bamboo dizi melody, light glockenspiel sparkles, quiet pizzicato strings and a soft "
        "hand drum keeping a playful skipping pulse. Tender, nostalgic and a little joyful, never sad, "
        "never busy. No intro build-up and no big ending: steady texture from the first bar to the "
        "last so it loops seamlessly. Create a 90-second piece."
    ),
    # Chapter one: the silkworm grandmother's silk battle in the rain.
    "silk_battle": (
        "Instrumental only, no vocals. Boss battle music loop for a 2D pixel-art action game: "
        "a girl with an umbrella duels a grieving silkworm spirit in a rainy old Chinese town. "
        "A natural minor, 178 BPM, urgent and ferocious from the first beat. The rhythm section is "
        "relentless and loud: thundering taiko and Chinese dagu war drums in double time, pounding "
        "floor toms, sharp cymbal and gong crashes on phrase starts, aggressive staccato cello and "
        "double-bass chugs, and a furious tremolo pipa and yangqin ostinato in racing sixteenth notes. "
        "Above it, a long-breathed erhu and dizi melody in minor: sustained notes held across many "
        "bars, sorrowful and thin, never heroic or bombastic, so the grief floats over the fury. "
        "Every two bars a massive accented hit lands like a weapon strike: full drums, low brass and "
        "string stab together, punchy, heavy and satisfying. Add rising string runs and drum fills "
        "that push the tension higher. No quiet sections, no breakdown, no slow intro: full intensity "
        "within one bar, and end on the same groove so it loops seamlessly. Create a 2-minute piece."
    ),
}


def api_key() -> str:
    key = os.environ.get("GEMINI_API_KEY", "").strip()
    env_file = ROOT / ".env"
    if not key and env_file.exists():
        for row in env_file.read_text(encoding="utf-8").splitlines():
            name, _, value = row.partition("=")
            if name.strip() == "GEMINI_API_KEY":
                key = value.strip().strip("\"'")
    if not key:
        sys.exit("No GEMINI_API_KEY in the environment or in .env")
    return key


def find_audio(node):
    """Return the first base64 audio payload anywhere in the response."""
    if isinstance(node, dict):
        if node.get("type") == "audio" and isinstance(node.get("data"), str):
            return node["data"]
        node = list(node.values())
    if isinstance(node, list):
        for child in node:
            found = find_audio(child)
            if found:
                return found
    return None


def generate(prompt: str, model: str, key: str) -> bytes:
    request = urllib.request.Request(
        ENDPOINT,
        data=json.dumps({"model": model, "input": prompt}).encode("utf-8"),
        headers={"Content-Type": "application/json", "Api-Revision": "2026-05-20", "x-goog-api-key": key},
    )
    try:
        with urllib.request.urlopen(request, timeout=600) as response:
            body = json.load(response)
    except urllib.error.HTTPError as error:
        sys.exit("Gemini API error %s: %s" % (error.code, error.read().decode("utf-8", "replace")[:2000]))
    audio = find_audio(body)
    if not audio:
        sys.exit("No audio in the response: " + json.dumps(body)[:2000])
    return base64.b64decode(audio)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("tracks", nargs="*", help="tracks to generate (default: all): " + ", ".join(TRACKS))
    parser.add_argument("--draft", action="store_true", help="30-second drafts saved outside the game assets")
    args = parser.parse_args()
    unknown = [name for name in args.tracks if name not in TRACKS]
    if unknown:
        parser.error("unknown track: " + ", ".join(unknown))
    key = api_key()
    folder = DRAFTS if args.draft else MUSIC
    folder.mkdir(parents=True, exist_ok=True)
    for name in args.tracks or TRACKS:
        print("Generating", name, "...", flush=True)
        clip = generate(TRACKS[name], DRAFT_MODEL if args.draft else FULL_MODEL, key)
        target = folder / (name + ".mp3")
        target.write_bytes(clip)
        print("  saved", target.relative_to(ROOT), "%.1f MB" % (len(clip) / 1e6))


if __name__ == "__main__":
    main()

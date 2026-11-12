"""Cut four short shoe contacts from Wigglesworth's CC0 recording.

Run tools/decode_footsteps.gd first. No extra audio libraries required.
Source and licensing: assets/audio/footsteps/CREDITS.txt.
"""
from pathlib import Path
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/audio/footsteps"
with wave.open(str(OUT / "source/decoded.wav")) as src:
    rate = src.getframerate()
    audio = np.frombuffer(src.readframes(src.getnframes()), dtype="<i2").astype(float) / 32768

for index, contact in enumerate([6.445, 13.28, 26.17, 27.055]):
    # Include the leading shoe contact, retain its short texture, fade the tail.
    start = int((contact - 0.025) * rate)
    clip = audio[start:start + int(0.17 * rate)].copy()
    clip -= clip.mean()
    clip *= 0.58 / max(0.001, np.max(np.abs(clip)))
    attack = int(rate * 0.002)
    release = int(rate * 0.055)
    clip[:attack] *= np.linspace(0, 1, attack)
    clip[-release:] *= np.linspace(1, 0, release)
    target = OUT / f"girl_step_{index + 1}.wav"
    with wave.open(str(target), "wb") as dst:
        dst.setnchannels(1)
        dst.setsampwidth(2)
        dst.setframerate(rate)
        dst.writeframes((np.clip(clip, -1, 1) * 32767).astype("<i2").tobytes())
    print(target.name, "170 ms, mono", rate, "Hz")

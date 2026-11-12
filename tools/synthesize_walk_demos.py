"""Original procedural foley sketches, for listening only; no game asset changes."""
from pathlib import Path
import wave
import numpy as np

RATE = 44100
OUT = Path(__file__).resolve().parents[1] / "art_review/audio/generated_walk"
OUT.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(71026)


def noise(length, lo, hi):
    n = int(length * RATE)
    spectrum = np.fft.rfft(rng.normal(size=n))
    frequency = np.fft.rfftfreq(n, 1 / RATE)
    low = 1 - np.exp(-(frequency / lo) ** 4)
    high = np.exp(-(frequency / hi) ** 4)
    sound = np.fft.irfft(spectrum * low * high, n)
    return sound / (np.std(sound) + 1e-8)


def contact(kind):
    t = np.arange(int(.24 * RATE)) / RATE
    size = rng.uniform(.94, 1.06)
    # Broad, damped sole contact rather than a pitched electronic beep.
    sole = noise(.24, 75, 750 if kind == 0 else 1400)
    sole *= (1 - np.exp(-t / .0014)) * np.exp(-t / .022)
    thud = noise(.24, 45, 230)
    thud *= (1 - np.exp(-t / .002)) * np.exp(-t / .032)
    toe_time = np.maximum(t - .023 * size, 0)
    toe = noise(.24, 550, 2900 if kind == 1 else 1900)
    toe *= (t > .023 * size) * (1 - np.exp(-toe_time / .001)) * np.exp(-toe_time / .012)
    scuff = noise(.24, 850, 4400)
    scuff *= np.exp(-((t - .067) / .028) ** 2)
    sound = .17 * sole + .065 * thud + (.085 if kind == 1 else .038) * toe
    sound += (.012 if kind != 2 else .018) * scuff
    if kind == 2:
        # A restrained damp grit sound, not a large puddle splash.
        grit = noise(.24, 1700, 6500)
        grit *= (1 - np.exp(-t / .003)) * np.exp(-t / .024)
        sound += .026 * grit
    sound *= np.minimum(1, t / .0015)
    sound *= np.minimum(1, (.24 - t) / .035)
    return sound


for kind, name in enumerate(["01_soft_small_steps", "02_crisp_small_steps", "03_damp_stone_steps"]):
    result = np.zeros(int(3.8 * RATE))
    time = .25
    for step in range(10):
        sound = contact(kind) * rng.uniform(.83, 1.05)
        position = int(time * RATE)
        result[position:position + len(sound)] += sound
        time += (.285 if kind == 1 else .315) + rng.uniform(-.018, .018)
    result *= .45 / max(.001, np.max(np.abs(result)))
    with wave.open(str(OUT / (name + ".wav")), "wb") as dest:
        dest.setnchannels(1)
        dest.setsampwidth(2)
        dest.setframerate(RATE)
        dest.writeframes((np.clip(result, -1, 1) * 32767).astype("<i2").tobytes())
    print(name, "3.8 sec, original procedural synthesis")

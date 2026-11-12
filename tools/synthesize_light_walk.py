"""Quiet, airy shoe-contact sketch: no bass impact or tonal percussion."""
from pathlib import Path
import wave
import numpy as np

RATE = 44100
rng = np.random.default_rng(71027)
out = Path(__file__).resolve().parents[1] / "art_review/audio/generated_walk"
out.mkdir(parents=True, exist_ok=True)
game_out = Path(__file__).resolve().parents[1] / "assets/audio/footsteps"
game_out.mkdir(parents=True, exist_ok=True)


def band_noise(n, lo, hi):
    frequencies = np.fft.rfftfreq(n, 1 / RATE)
    band = (1 - np.exp(-(frequencies / lo) ** 6)) * np.exp(-(frequencies / hi) ** 4)
    x = np.fft.irfft(np.fft.rfft(rng.normal(size=n)) * band, n)
    return x / max(1e-8, np.std(x))


result = np.zeros(int(4.2 * RATE))
time = .3
for step in range(10):
    t = np.arange(int(.145 * RATE)) / RATE
    # Gentle contact: rounded noise envelope, deliberately no low-frequency thud.
    touch = band_noise(len(t), 950, rng.uniform(2600, 3400))
    touch *= (t / .006) ** 1.6 * np.exp(-t / .006)
    # A tiny sole brush follows the contact; irregular grains avoid a drum sound.
    brush = band_noise(len(t), 1600, 5600)
    grains = np.interp(t, np.linspace(0, .145, 18), rng.uniform(.2, 1, 18))
    brush *= np.exp(-((t - .028) / .016) ** 2) * grains
    sound = (.026 * touch + .007 * brush) * rng.uniform(.78, 1.05)
    sound[:88] *= np.linspace(0, 1, 88)
    sound[-800:] *= np.linspace(1, 0, 800)
    # Use the first two contacts of the approved demo unchanged as left/right.
    if step < 2:
        with wave.open(str(game_out / f"light_step_{step + 1}.wav"), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes((sound * 32767).astype("<i2").tobytes())
    start = int(time * RATE)
    result[start:start + len(sound)] += sound
    time += rng.uniform(.29, .37)

# Preserve the quiet level; do not normalize every touch to full loudness.
peak = float(np.max(np.abs(result)))
if peak > .12:
    result *= .12 / peak
target = out / "04_airy_light_steps.wav"
with wave.open(str(target), "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(RATE)
    w.writeframes((result * 32767).astype("<i2").tobytes())
print(target.name, "peak", round(float(np.max(np.abs(result))), 4), "RMS", round(float(np.sqrt(np.mean(result**2))), 5))

"""Weighty umbrella impact, blocked-strike and boss attack foley, plus listening previews.

Companion to synthesize_combat_audio.py, which owns the silk and swing sounds.
"""
from pathlib import Path
import wave
import numpy as np

RATE = 44100
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/audio/combat"
PREVIEW = ROOT / "art_review/audio/combat"
OUT.mkdir(parents=True, exist_ok=True)
PREVIEW.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(90417)


def timeline(seconds):
    return np.arange(int(seconds * RATE)) / RATE


def air(t, lo, hi):
    """Noise band-limited between lo and hi Hz."""
    f = np.fft.rfftfreq(len(t), 1 / RATE)
    response = (1 - np.exp(-(f / lo) ** 4)) * np.exp(-(f / hi) ** 4)
    x = np.fft.irfft(np.fft.rfft(rng.normal(size=len(t))) * response, len(t))
    return x / (np.std(x) + 1e-8)


def swept_air(t, start, end, width=.55):
    """Noise whose band centre glides from start to end Hz: the body of a whoosh."""
    out = np.zeros(len(t))
    block = 256
    centre = np.geomspace(start, end, max(1, len(t) // block + 1))
    for index, hz in enumerate(centre):
        piece = slice(index * block, min(len(t), (index + 3) * block))
        if piece.start >= len(t):
            break
        part = air(t[piece], hz * (1 - width), hz * (1 + width))
        out[piece] += part * np.hanning(len(part))
    return out / (np.std(out) + 1e-8)


def drop(t, start, end, glide):
    """Sine falling from start to end Hz: the chest thump of an impact."""
    hz = end + (start - end) * np.exp(-t / glide)
    return np.sin(2 * np.pi * np.cumsum(hz) / RATE)


def finish(x, peak, attack=.004, drive=1.0):
    x = x - x.mean()
    x = np.tanh(drive * x / max(1e-8, np.max(np.abs(x))))
    ramp = min(max(1, int(attack * RATE)), len(x) // 8)
    x[:ramp] *= np.linspace(0, 1, ramp)
    tail = max(ramp, int(.012 * RATE))
    x[-tail:] *= np.linspace(1, 0, tail)
    return x * peak / max(1e-8, np.max(np.abs(x)))


def save(path, x):
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes((np.clip(x, -1, 1) * 32767).astype("<i2").tobytes())


clips = {}

# Confirmed umbrella strike: the crisp crack stays on top, a short low thump and
# a woody knock underneath give it weight. Saturated so it reads loud and dense.
t = timeline(.34)
crack = air(t, 1500, 10000) * np.exp(-t / .006)
# A second, slightly later crack makes the hit crunch instead of click.
crunch = air(t, 900, 6000) * np.exp(-np.maximum(t - .014, 0) / .012) * (t >= .014)
knock = air(t, 280, 1100) * np.exp(-t / .03)
thump = drop(t, 210, 52, .024) * np.exp(-t / .085)
ring = sum(np.sin(2 * np.pi * hz * t + phase) * np.exp(-t / decay)
           for hz, phase, decay in [(820, .2, .030), (1900, .7, .012), (3100, .4, .007)])
# Bright rising "shing" that rings out after the blow lands.
shing_hz = 3200 + 2600 * (1 - np.exp(-t / .05))
shing = np.sin(2 * np.pi * np.cumsum(shing_hz) / RATE) * np.exp(-t / .07) * (1 - np.exp(-t / .004))
shing += .5 * air(t, 5000, 12000) * np.exp(-t / .05)
clips["umbrella_hit_heavy_v3"] = finish(1.3 * crack + .7 * crunch + .9 * knock + .75 * thump + .25 * ring + .2 * shing,
                                        .9, attack=.0003, drive=2.8)

# Strike stopped by a guard: hard wooden clack with a bright ringing rebound and
# almost no low end, so it never sounds like damage landed.
t = timeline(.34)
clack = air(t, 2000, 11000) * np.exp(-t / .004)
bounce = air(t, 1800, 7000) * np.exp(-((t - .055) / .006) ** 2)
ring = sum(amplitude * np.sin(2 * np.pi * hz * t + phase) * np.exp(-t / decay)
           for hz, phase, decay, amplitude in [(1240, .1, .085, 1.0), (1985, .6, .070, .8), (2960, .3, .050, .6),
                                               (4310, .9, .032, .45), (6100, .5, .020, .3)])
wood = air(t, 500, 1500) * np.exp(-t / .014)
clips["umbrella_block"] = finish(.9 * clack + .35 * bounce + .55 * ring + .35 * wood, .7, attack=.0003, drive=1.4)

# Umbrella snapping open into a guard: a quick cloth "fwop" ending in a rib click.
t = timeline(.2)
u = t / .2
cloth = swept_air(t, 300, 1900, .6) * np.sin(np.pi * u ** .6) ** 2
click = air(t, 2000, 8000) * np.exp(-((t - .13) / .005) ** 2)
pop = drop(t, 260, 140, .03) * np.exp(-np.maximum(t - .12, 0) / .03) * (t >= .12)
clips["umbrella_open"] = finish(cloth + .7 * click + .5 * pop, .5, drive=1.3)

# Boss sweep: a broad, heavy branch pushed through the air.
t = timeline(.32)
u = t / .32
body = swept_air(t, 260, 1500) * np.sin(np.pi * u) ** 1.4
edge = air(t, 2200, 7000) * np.exp(-((t - .17) / .035) ** 2)
clips["boss_swing"] = finish(body + .3 * edge, .5, drive=1.2)

# Boss thrust, dash or dive: a fast rising rush that cuts off sharply.
t = timeline(.30)
u = t / .30
rush = swept_air(t, 420, 3400, .45) * u ** 1.6 * (1 - u) ** .35
hiss = air(t, 3000, 9000) * np.exp(-((t - .21) / .03) ** 2)
clips["boss_lunge"] = finish(rush + .35 * hiss, .52, drive=1.3)

# Boss landing: ground thud with a little scattered grit.
t = timeline(.42)
thud = drop(t, 130, 42, .03) * np.exp(-t / .13)
slap = air(t, 180, 900) * np.exp(-t / .03)
grit = air(t, 900, 4500) * np.exp(-((t - .05) / .05) ** 2)
clips["boss_slam"] = finish(1.2 * thud + .7 * slap + .16 * grit, .8, attack=.0006, drive=2.0)

# Blossom gust: airy swell with a faint fluttering shimmer of petals.
t = timeline(1.1)
u = t / 1.1
wind = swept_air(t, 380, 1500, .6) * np.sin(np.pi * u ** .7) ** 2
flutter = air(t, 2600, 8000) * (.5 + .5 * np.sin(2 * np.pi * 17 * t)) * np.sin(np.pi * u) ** 2
clips["petal_gust"] = finish(wind + .28 * flutter, .42, attack=.05)

for name, clip in clips.items():
    save(OUT / (name + ".wav"), clip)
    print(name, round(len(clip) / RATE, 2), "seconds")

# Chapter zero rain game. The catch is tuned to D4; the game raises its pitch
# one pentatonic step per drop, so keep the tone clean and the tail long.
RAIN = ROOT / "assets/audio/rain"
RAIN.mkdir(parents=True, exist_ok=True)
t = timeline(.5)
tap = air(t, 700, 3600) * np.exp(-t / .009)
hz = 293.66 * (1 + .06 * np.exp(-t / .02))
plink = np.sin(2 * np.pi * np.cumsum(hz) / RATE) * np.exp(-t / .13)
bell = .3 * np.sin(2 * np.pi * 2 * 293.66 * t) * np.exp(-t / .07) + .12 * np.sin(2 * np.pi * 3 * 293.66 * t) * np.exp(-t / .04)
rain = {"drop_catch": finish(.5 * tap + plink + bell, .7, attack=.0005)}

# A missed drop: a small dull splash on stone, no pitch, so it reads as a loss.
t = timeline(.3)
splat = air(t, 250, 1400) * np.exp(-t / .03)
spray = air(t, 1800, 6000) * np.exp(-((t - .03) / .03) ** 2)
rain["drop_miss"] = finish(splat + .3 * spray, .45, attack=.001)

for name, clip in rain.items():
    save(RAIN / (name + ".wav"), clip)
    print(name, round(len(clip) / RATE, 2), "seconds")


def sequence(name, entries, seconds):
    mix = np.zeros(int(seconds * RATE))
    for at, cue, db in entries:
        sound = clips[cue] * 10 ** (db / 20)
        start = int(at * RATE)
        mix[start:start + len(sound)] += sound
    save(PREVIEW / name, mix)


sequence("impact_preview_v3.wav", [(.15, "umbrella_hit_heavy_v3", -4), (.75, "umbrella_hit_heavy_v3", -4),
                                   (1.35, "umbrella_block", -6), (2.1, "boss_swing", -7),
                                   (2.8, "boss_lunge", -7), (3.4, "boss_slam", -5), (4.1, "petal_gust", -9)], 5.4)

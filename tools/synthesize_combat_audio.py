"""Original first-chapter silk and umbrella foley, plus listening previews."""
from pathlib import Path
import wave
import numpy as np

RATE = 44100
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/audio/combat"
PREVIEW = ROOT / "art_review/audio/combat"
OUT.mkdir(parents=True, exist_ok=True)
PREVIEW.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(71028)


def air(t, lo, hi):
    f = np.fft.rfftfreq(len(t), 1 / RATE)
    response = (1 - np.exp(-(f / lo) ** 4)) * np.exp(-(f / hi) ** 4)
    x = np.fft.irfft(np.fft.rfft(rng.normal(size=len(t))) * response, len(t))
    return x / (np.std(x) + 1e-8)


def timeline(seconds):
    return np.arange(int(seconds * RATE)) / RATE


def finish(x, peak, attack=.005):
    x -= x.mean()
    ramp = min(max(1, int(attack * RATE)), len(x) // 8)
    x[:ramp] *= np.linspace(0, 1, ramp)
    x[-ramp:] *= np.linspace(1, 0, ramp)
    return x * peak / max(1e-8, np.max(np.abs(x)))


def save(path, x):
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes((np.clip(x, -1, 1) * 32767).astype("<i2").tobytes())


clips = {}
t = timeline(.70)
u = t / .70
fiber = air(t, 950, 5100) * (.25 + .75 * u)
fiber += .26 * air(t, 340, 1200) * np.sin(np.pi * u) ** 2
grain = .7 + .3 * np.sin(2 * np.pi * (23 * t + 16 * t * t)) ** 2
clips["silk_charge"] = finish(fiber * grain * np.sin(np.pi * u) ** 1.5, .25)

t = timeline(.23)
snap = air(t, 1100, 6500) * np.exp(-((t - .028) / .012) ** 2)
trail = air(t, 600, 3800) * np.exp(-((t - .075) / .042) ** 2)
clips["silk_shot"] = finish(.8 * snap + .43 * trail, .42)

t = timeline(.48)
fan = np.zeros(len(t))
for offset, width, amplitude in [(0.025, .016, .8), (.065, .035, .58), (.12, .065, .35)]:
    fan += amplitude * air(t, 850, 6200) * np.exp(-((t - offset) / width) ** 2)
fan += .12 * air(t, 400, 2300) * np.exp(-((t - .13) / .09) ** 2)
clips["silk_burst"] = finish(fan, .48)

t = timeline(.19)
cloth = air(t, 450, 3500) * np.exp(-((t - .065) / .025) ** 2)
edge = air(t, 1900, 6500) * np.exp(-((t - .085) / .015) ** 2)
clips["umbrella_swing"] = finish(cloth + .32 * edge, .32)

t = timeline(.11)
# Sub-millisecond attack, bright dry crack, very little low-mid fabric weight.
clack = air(t, 1600, 10500) * np.exp(-t / .0045)
wood = sum(np.sin(2 * np.pi * frequency * t + phase) * np.exp(-t / decay)
           for frequency, phase, decay in [(1900, .3, .007), (3100, .9, .005), (4700, .2, .003)])
catch = air(t, 2200, 8500) * np.exp(-((t - .006) / .002) ** 2)
cloth = air(t, 1200, 4200) * np.exp(-((t - .013) / .007) ** 2)
clips["umbrella_hit"] = finish(.95 * clack + .20 * wood + .22 * catch + .025 * cloth, .65, attack=.00025)

for name, clip in clips.items():
    filename = "umbrella_hit_crisp_v2" if name == "umbrella_hit" else name
    save(OUT / (filename + ".wav"), clip)
    print(name, len(clip) / RATE, "seconds")


def sequence(name, entries, seconds):
    mix = np.zeros(int(seconds * RATE))
    for at, cue, db in entries:
        sound = clips[cue] * 10 ** (db / 20)
        start = int(at * RATE)
        mix[start:start + len(sound)] += sound
    save(PREVIEW / name, mix)


sequence("silk_preview.wav", [(.15, "silk_charge", -12), (.98, "silk_shot", -8),
                             (1.5, "silk_charge", -12), (2.5, "silk_burst", -8)], 3.3)
sequence("umbrella_crisp_preview_v2.wav", [(.15, "umbrella_swing", -9), (.85, "umbrella_swing", -9),
                                 (.91, "umbrella_hit", -5), (1.65, "umbrella_swing", -9),
                                 (1.71, "umbrella_hit", -5)], 2.2)
sequence("crisp_hit_only_v2.wav", [(.15, "umbrella_hit", -5), (.70, "umbrella_hit", -5),
                                 (1.25, "umbrella_hit", -5)], 1.65)

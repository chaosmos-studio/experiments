"""Render Palewheel 96's original looping four-voice game track."""

from pathlib import Path
import subprocess
import tempfile
import wave

import numpy as np


RATE = 22050
BEAT = 0.5
BARS = 16
DURATION = BARS * 4 * BEAT
SAMPLES = int(DURATION * RATE)
MIX = np.zeros(SAMPLES, dtype=np.float64)
RNG = np.random.default_rng(96)


def hz(note: int) -> float:
    return 440.0 * 2 ** ((note - 69) / 12)


def voice(note: int, start: float, length: float, volume: float, kind: str) -> None:
    first = int(start * RATE)
    count = min(int(length * RATE), SAMPLES - first)
    if count <= 0:
        return
    t = np.arange(count) / RATE
    phase = hz(note) * t
    if kind == "lead":
        wave_data = np.sign(np.sin(2 * np.pi * phase)) * 0.68 + np.sin(4 * np.pi * phase) * 0.18
    elif kind == "bass":
        wave_data = 2 / np.pi * np.arcsin(np.sin(2 * np.pi * phase))
        wave_data += np.sin(4 * np.pi * phase) * 0.15
    else:
        wave_data = 2 * (phase % 1) - 1
    attack = np.minimum(1.0, t / 0.012)
    release = np.minimum(1.0, (length - t) / (0.12 if kind == "lead" else 0.07))
    env = np.maximum(0.0, np.minimum(attack, release))
    MIX[first:first + count] += wave_data * env * volume


chords = [
    (45, (57, 60, 64, 69)),
    (41, (53, 57, 60, 65)),
    (48, (60, 64, 67, 72)),
    (43, (55, 59, 62, 67)),
]
melody = [
    69, 72, 76, 72, 69, 67, 64, 67,
    65, 69, 72, 69, 65, 64, 60, 64,
    67, 72, 76, 79, 76, 72, 67, 72,
    67, 71, 74, 71, 67, 64, 62, 64,
]

for bar in range(BARS):
    root, chord = chords[bar % 4]
    start = bar * 4 * BEAT
    for beat in range(4):
        voice(root + (12 if beat == 2 else 0), start + beat * BEAT, 0.42, 0.14, "bass")
        for eighth in range(2):
            step = (bar % 4) * 8 + beat * 2 + eighth
            voice(melody[step], start + beat * BEAT + eighth * BEAT / 2, 0.23, 0.12, "lead")
        for sixteenth in range(4):
            note = chord[(beat * 4 + sixteenth) % 4] + 12
            voice(note, start + beat * BEAT + sixteenth * BEAT / 4, 0.105, 0.045, "arp")

for beat in range(BARS * 4):
    first = int(beat * BEAT * RATE)
    count = int(0.16 * RATE)
    t = np.arange(count) / RATE
    if beat % 4 in (0, 2):
        kick = np.sin(2 * np.pi * (80 * t - 145 * t * t)) * np.exp(-t * 30)
        MIX[first:first + count] += kick * 0.18
    else:
        snare = RNG.uniform(-1, 1, count) * np.exp(-t * 27)
        MIX[first:first + count] += snare * 0.07
    for half in range(2):
        hat_first = first + int(half * BEAT * RATE / 2)
        hat_count = int(0.035 * RATE)
        hat_t = np.arange(hat_count) / RATE
        hat = RNG.uniform(-1, 1, hat_count) * np.exp(-hat_t * 110)
        MIX[hat_first:hat_first + hat_count] += hat * 0.023

MIX = np.tanh(MIX * 1.4) * 0.78
fade = int(0.012 * RATE)
MIX[:fade] *= np.linspace(0, 1, fade)
MIX[-fade:] *= np.linspace(1, 0, fade)
pcm = (MIX * 32767).astype("<i2")
output = Path(__file__).resolve().parent.parent / "assets/audio/retro_loop.ogg"
with tempfile.TemporaryDirectory() as directory:
    wav_path = Path(directory) / "retro_loop.wav"
    with wave.open(str(wav_path), "wb") as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(pcm.tobytes())
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(wav_path), "-c:a", "libvorbis", "-q:a", "4", str(output)], check=True)
print(output)

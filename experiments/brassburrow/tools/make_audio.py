"""Synthesize Brassburrow's original music and action sounds."""

from pathlib import Path
import math
import wave
import numpy as np

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
OUT.mkdir(parents=True, exist_ok=True)
RNG = np.random.default_rng(73021)


def save(name, samples):
    samples = np.asarray(samples, dtype=np.float64)
    samples = np.clip(samples, -1, 1)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes((samples * 32767).astype("<i2").tobytes())


def time_for(seconds):
    return np.arange(int(seconds * RATE)) / RATE


def env(t, attack, decay):
    return np.minimum(1.0, t / attack) * np.exp(-t * decay)


def chirp(seconds, start, end, decay=10.0, wave_type="sine"):
    t = time_for(seconds)
    freq = start + (end - start) * np.minimum(1, t / seconds)
    phase = 2 * math.pi * np.cumsum(freq) / RATE
    signal = np.sin(phase)
    if wave_type == "triangle":
        signal = 2 / math.pi * np.arcsin(signal)
    return signal * env(t, 0.004, decay)


def noise(seconds, decay=12.0):
    t = time_for(seconds)
    raw = RNG.standard_normal(len(t))
    smooth = np.convolve(raw, np.ones(16) / 16, mode="same")
    return smooth * env(t, 0.006, decay)


save("swing", 0.28 * noise(0.23, 13) + 0.24 * chirp(0.23, 370, 105, 13))
save("hit", 0.55 * chirp(0.18, 145, 52, 24, "triangle") + 0.36 * noise(0.18, 28))
save("harvest", 0.36 * chirp(0.34, 920, 470, 9) + 0.18 * chirp(0.34, 1320, 880, 12))
save("build", 0.35 * chirp(0.38, 230, 84, 7, "triangle") + 0.24 * chirp(0.38, 580, 330, 8))
save("shot", 0.36 * chirp(0.20, 680, 180, 18, "triangle") + 0.18 * noise(0.20, 18))
save("damage", 0.42 * chirp(0.44, 118, 43, 7, "triangle") + 0.22 * noise(0.44, 11))
save("dash", 0.34 * noise(0.28, 8) + 0.23 * chirp(0.28, 230, 530, 9))
save("repair", 0.31 * chirp(0.42, 500, 680, 7) + 0.21 * chirp(0.42, 760, 1000, 9))

beat = 60 / 108
duration = beat * 16
music = np.zeros(int(duration * RATE))


def place(at, samples, volume):
    start = int(at * RATE)
    end = min(len(music), start + len(samples))
    music[start:end] += samples[:end - start] * volume


for step in range(16):
    at = step * beat
    if step % 4 == 0:
        place(at, chirp(0.40, 91, 48, 16, "triangle"), 0.21)
    if step % 4 == 2:
        place(at, noise(0.16, 22), 0.13)
    place(at, noise(0.08, 37), 0.035)
    if step % 2 == 0:
        bass = [110, 110, 130.81, 98.0][step // 4]
        place(at, chirp(0.45, bass, bass, 4, "triangle"), 0.11)

melody = [440.0, 523.25, 587.33, 523.25, 392.0, 440.0, 349.23, 392.0]
for step, freq in enumerate(melody):
    at = step * beat * 2
    note = chirp(0.57, freq, freq * 0.998, 4)
    overtone = chirp(0.57, freq * 2, freq * 2, 8)
    place(at, note + 0.28 * overtone, 0.12)

fade = min(int(0.12 * RATE), len(music) // 2)
music[:fade] *= np.linspace(0, 1, fade)
music[-fade:] *= np.linspace(1, 0, fade)
save("march", music)

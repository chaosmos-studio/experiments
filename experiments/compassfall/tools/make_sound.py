"""Synthesize Compassfall's original short game sounds."""

import math
import struct
import wave
from pathlib import Path


OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "audio" / "sfx"
OUTPUT.mkdir(parents=True, exist_ok=True)
RATE = 24000


def save(name, duration, tone):
    samples = []
    for n in range(int(duration * RATE)):
        t = n / RATE
        value = max(-1.0, min(1.0, tone(t, duration)))
        samples.append(struct.pack("<h", int(value * 16000)))
    with wave.open(str(OUTPUT / f"{name}.wav"), "wb") as sound:
        sound.setnchannels(1)
        sound.setsampwidth(2)
        sound.setframerate(RATE)
        sound.writeframes(b"".join(samples))


def chirp(t, duration, start, end):
    frequency = start + (end - start) * (t / duration)
    return math.sin(math.tau * frequency * t)


save("jump", 0.23, lambda t, d: chirp(t, d, 310, 680) * (1 - t / d) ** 1.4 * 0.45)
save("shift", 0.31, lambda t, d: (chirp(t, d, 170, 570) + 0.4 * chirp(t, d, 350, 800)) * (1 - t / d) ** 1.5 * 0.46)
save("spark", 0.46, lambda t, d: (math.sin(math.tau * 780 * t) + math.sin(math.tau * 1170 * t) * 0.5) * (1 - t / d) ** 2 * 0.4)
save("hit", 0.25, lambda t, d: (chirp(t, d, 280, 70) + math.sin(math.tau * 45 * t) * 0.3) * (1 - t / d) ** 1.8 * 0.5)
save("door", 0.75, lambda t, d: sum(math.sin(math.tau * f * t) for f in (392, 494, 587)) * (1 - t / d) ** 1.2 * 0.18)

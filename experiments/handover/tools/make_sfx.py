"""Synthesize small, gentle UI sounds for Handover."""

from math import exp, pi, sin
from pathlib import Path
from struct import pack
import wave

SAMPLE_RATE = 44_100
OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "audio" / "sfx"


def make(name: str, notes: list[tuple[float, float, float]], length: float) -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    samples = []
    for index in range(int(SAMPLE_RATE * length)):
        time = index / SAMPLE_RATE
        value = 0.0
        for start, frequency, duration in notes:
            relative = time - start
            if 0.0 <= relative < duration:
                envelope = (1.0 - exp(-relative * 85.0)) * exp(-relative * 7.0)
                tone = sin(2.0 * pi * frequency * relative)
                shimmer = 0.24 * sin(2.0 * pi * frequency * 2.0 * relative)
                value += (tone + shimmer) * envelope
        fade = min(1.0, (length - time) * 30.0)
        samples.append(pack("<h", int(max(-1.0, min(1.0, value * fade * 0.18)) * 32767)))
    with wave.open(str(OUTPUT / name), "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(SAMPLE_RATE)
        audio.writeframes(b"".join(samples))


make("shift.wav", [(0.0, 440.0, 0.15), (0.08, 554.37, 0.16)], 0.31)
make("task.wav", [(0.0, 523.25, 0.18)], 0.23)
make("complete.wav", [(0.0, 392.0, 0.34), (0.12, 493.88, 0.35), (0.24, 587.33, 0.39)], 0.68)

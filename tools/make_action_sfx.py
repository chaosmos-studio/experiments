"""Generate the short, deterministic sounds used by the Game Off action drafts."""

import math
import random
import struct
import wave
from pathlib import Path


RATE = 32000
ROOT = Path(__file__).resolve().parents[1] / "experiments"


def write(game: str, name: str, duration: float, tone: str) -> None:
    rng = random.Random(218 + len(game) * 17 + len(name))
    samples = bytearray()
    phase = 0.0
    for index in range(int(RATE * duration)):
        t = index / (RATE * duration)
        if tone == "rise":
            frequency = 280.0 + 820.0 * t * t
            envelope = min(1.0, t * 25.0) * (1.0 - t) ** 1.8
            value = math.sin(phase) * 0.75 + (rng.random() * 2.0 - 1.0) * 0.16
        elif tone == "drop":
            frequency = 940.0 * (1.0 - t) ** 2 + 115.0
            envelope = min(1.0, t * 35.0) * (1.0 - t) ** 1.3
            value = math.sin(phase) * 0.7 + math.sin(phase * 0.5) * 0.25
        elif tone == "pass":
            frequency = 760.0 + 520.0 * t
            envelope = min(1.0, t * 30.0) * (1.0 - t) ** 3
            value = math.sin(phase) * 0.82 + math.sin(phase * 2.0) * 0.12
        else:
            frequency = 160.0 * (1.0 - t) + 55.0
            envelope = min(1.0, t * 70.0) * (1.0 - t) ** 2
            value = math.sin(phase) * 0.55 + (rng.random() * 2.0 - 1.0) * 0.36
        phase += 2.0 * math.pi * frequency / RATE
        samples.extend(struct.pack("<h", int(max(-1.0, min(1.0, value * envelope * 0.75)) * 32767)))
    destination = ROOT / game / "assets" / "audio" / f"{name}.wav"
    destination.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(destination), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(samples)
    print(destination)


if __name__ == "__main__":
    for project, shift_tone in (("flipline", "rise"), ("timefall", "drop")):
        write(project, "shift", 0.22, shift_tone)
        write(project, "pass", 0.11, "pass")
        write(project, "crash", 0.43, "crash")

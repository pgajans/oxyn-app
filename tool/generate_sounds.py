#!/usr/bin/env python3
"""
Oxyn sound synthesizer.

Generates small, royalty-free UI sound effects (16-bit PCM mono WAV, 44.1 kHz)
directly from math so no external audio assets are required. Re-run any time to
regenerate: `python3 tool/generate_sounds.py`.

Outputs to assets/sounds/.
"""
import math
import os
import struct
import wave

SR = 44100
OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "sounds")

os.makedirs(OUT_DIR, exist_ok=True)


def _write(name, samples):
    # clamp + convert to 16-bit
    path = os.path.join(OUT_DIR, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for s in samples:
            v = max(-1.0, min(1.0, s))
            frames += struct.pack("<h", int(v * 32767))
        w.writeframes(bytes(frames))
    print(f"  wrote {name} ({len(samples)/SR*1000:.0f} ms, {os.path.getsize(path)} bytes)")


def _env(i, n, attack=0.01, release=0.2):
    # simple attack/release envelope, times in fraction of total
    a = int(n * attack)
    r = int(n * release)
    if i < a:
        return i / max(1, a)
    if i > n - r:
        return max(0.0, (n - i) / max(1, r))
    return 1.0


def tap():
    """Very short soft click."""
    n = int(SR * 0.045)
    out = []
    import random
    random.seed(1)
    for i in range(n):
        t = i / SR
        env = math.exp(-t * 90)
        tone = math.sin(2 * math.pi * 880 * t) * 0.5
        click = (random.random() * 2 - 1) * 0.25 * math.exp(-t * 300)
        out.append((tone + click) * env * 0.5)
    _write("tap.wav", out)


def pop():
    """Playful upward pop for reveals/selection."""
    n = int(SR * 0.14)
    out = []
    for i in range(n):
        t = i / SR
        f = 420 + 900 * (i / n)
        env = _env(i, n, 0.02, 0.6) * math.exp(-t * 6)
        out.append(math.sin(2 * math.pi * f * t) * env * 0.5)
    _write("pop.wav", out)


def charge():
    """Rising electric hum used while holding the battery button (~1.6s, loopable-ish)."""
    n = int(SR * 1.6)
    out = []
    import random
    random.seed(7)
    for i in range(n):
        t = i / SR
        prog = i / n
        # rising fundamental
        f = 90 + 260 * prog
        base = math.sin(2 * math.pi * f * t) * 0.35
        # buzzy harmonic
        harm = math.sin(2 * math.pi * (f * 2.01) * t) * 0.18 * prog
        # electric sizzle grows with progress
        sizzle = (random.random() * 2 - 1) * 0.12 * prog
        env = _env(i, n, 0.05, 0.05)
        out.append((base + harm + sizzle) * env * 0.6)
    _write("charge.wav", out)


def zap():
    """Sharp electric zap + short thunder body for the 100% strike."""
    n = int(SR * 0.55)
    out = []
    import random
    random.seed(3)
    for i in range(n):
        t = i / SR
        # descending zap
        f = 1600 * math.exp(-t * 6) + 120
        zap_tone = math.sin(2 * math.pi * f * t) * 0.5
        # crackle
        crackle = (random.random() * 2 - 1) * 0.5 * math.exp(-t * 9)
        # low thunder rumble
        rumble = math.sin(2 * math.pi * 70 * t) * 0.4 * math.exp(-t * 3.5)
        env = _env(i, n, 0.002, 0.5)
        out.append((zap_tone + crackle + rumble) * env * 0.8)
    _write("zap.wav", out)


def success():
    """Pleasant two-note success chime."""
    n = int(SR * 0.6)
    out = []
    notes = [(0.0, 660.0), (0.12, 880.0), (0.24, 1174.66)]  # E5, A5, D6-ish arpeggio
    for i in range(n):
        t = i / SR
        s = 0.0
        for start, f in notes:
            if t >= start:
                lt = t - start
                s += math.sin(2 * math.pi * f * lt) * math.exp(-lt * 4) * 0.4
        env = _env(i, n, 0.005, 0.3)
        out.append(s * env * 0.6)
    _write("success.wav", out)


def whoosh():
    """Soft transition whoosh."""
    n = int(SR * 0.3)
    out = []
    import random
    random.seed(11)
    # filtered noise sweep (one-pole low-pass, cutoff moving up)
    prev = 0.0
    for i in range(n):
        prog = i / n
        raw = random.random() * 2 - 1
        alpha = 0.02 + 0.35 * prog
        prev = prev + alpha * (raw - prev)
        env = math.sin(math.pi * prog)
        out.append(prev * env * 0.5)
    _write("whoosh.wav", out)


if __name__ == "__main__":
    print(f"Generating sounds into {OUT_DIR}")
    tap()
    pop()
    charge()
    zap()
    success()
    whoosh()
    print("Done.")

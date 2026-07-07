#!/usr/bin/env python3
"""Synthesize the game's sound effects as small 44.1kHz 16-bit mono WAV files
(stdlib only — no external audio assets). Writes to assets/sounds/.

Run: python3 tool/gen_sounds.py
"""
import math
import struct
import wave
import os

SR = 44100
OUT_DIR = "/Users/sangdo/Documents/Source/Flutter/flutter_paper_block/assets/sounds"

def write_wav(name, samples):
    # clamp + convert to 16-bit
    frames = bytearray()
    for s in samples:
        v = max(-1.0, min(1.0, s))
        frames += struct.pack("<h", int(v * 32767))
    path = os.path.join(OUT_DIR, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(bytes(frames))
    print(f"wrote {name}  ({len(samples)/SR*1000:.0f} ms)")

def env_ad(n, attack=0.004, decay=25.0):
    """Fast attack, exponential decay envelope over n samples."""
    out = []
    for i in range(n):
        t = i / SR
        a = min(1.0, t / attack) if attack > 0 else 1.0
        out.append(a * math.exp(-t * decay))
    return out

def tone(freq, dur, decay=25.0, attack=0.004, harmonics=((1, 1.0),)):
    n = int(SR * dur)
    e = env_ad(n, attack, decay)
    out = []
    for i in range(n):
        t = i / SR
        s = sum(amp * math.sin(2 * math.pi * freq * mult * t) for mult, amp in harmonics)
        out.append(s * e[i])
    return out

def mix(layers, total_dur):
    """Overlay (start_sample, samples) layers into a buffer of total_dur."""
    n = int(SR * total_dur)
    buf = [0.0] * n
    for start, samples in layers:
        for i, s in enumerate(samples):
            j = start + i
            if 0 <= j < n:
                buf[j] += s
    return buf

# ---- place: soft "pop" with a quick high transient ----
def make_place():
    body = tone(510, 0.11, decay=34, harmonics=((1, 0.7), (2, 0.18)))
    click = tone(1250, 0.02, decay=120, attack=0.0005)
    buf = mix([(0, [0.9 * s for s in click]), (0, [0.85 * s for s in body])], 0.12)
    return buf

# ---- pickup: gentle short tick ----
def make_pickup():
    return [0.5 * s for s in tone(760, 0.06, decay=55, harmonics=((1, 0.8), (2, 0.15)))]

# ---- invalid: soft low "nope" buzz ----
def make_invalid():
    t1 = tone(180, 0.09, decay=22, harmonics=((1, 0.6), (2, 0.25), (3, 0.12)))
    t2 = tone(150, 0.11, decay=20, harmonics=((1, 0.6), (2, 0.25), (3, 0.12)))
    buf = mix([(0, t1), (int(SR * 0.085), t2)], 0.22)
    return [0.55 * s for s in buf]

# ---- complete: cheerful ascending arpeggio C-E-G-C ----
def make_complete():
    notes = [523.25, 659.25, 783.99, 1046.50]
    step = 0.11
    layers = []
    for i, f in enumerate(notes):
        note = tone(f, 0.42, decay=6.5, attack=0.005,
                    harmonics=((1, 0.6), (2, 0.22), (3, 0.08)))
        layers.append((int(SR * step * i), note))
    total = step * (len(notes) - 1) + 0.42
    buf = mix(layers, total + 0.02)
    return [0.42 * s for s in buf]

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    write_wav("place.wav", make_place())
    write_wav("pickup.wav", make_pickup())
    write_wav("invalid.wav", make_invalid())
    write_wav("complete.wav", make_complete())
    print("done ->", OUT_DIR)

if __name__ == "__main__":
    main()

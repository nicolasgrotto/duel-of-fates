"""Synthesizes every original sound and music stem of the game into assets/audio/.

Usage (from the project root): python tools/audio/synth_audio.py
All sounds are generated from oscillators, noise and envelopes: no samples are used.
"""
import math
import os
import wave

import numpy as np

RATE = 44100
MUSIC_RATE = 32000
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RNG = np.random.default_rng(1977)


def t_axis(seconds, rate=RATE):
    return np.arange(int(seconds * rate)) / rate


def envelope(seconds, attack, decay_power=3.0, rate=RATE):
    t = t_axis(seconds, rate)
    env = np.minimum(t / max(attack, 1e-4), 1.0) * (1.0 - t / seconds) ** decay_power
    return env


def noise(seconds, rate=RATE):
    return RNG.normal(0.0, 1.0, int(seconds * rate))


def lowpass(signal, cutoff, rate=RATE):
    alpha = 1.0 - math.exp(-2.0 * math.pi * cutoff / rate)
    out = np.empty_like(signal)
    acc = 0.0
    for i, value in enumerate(signal):
        acc += alpha * (value - acc)
        out[i] = acc
    return out


def highpass(signal, cutoff, rate=RATE):
    return signal - lowpass(signal, cutoff, rate)


def bandpass(signal, low, high, rate=RATE):
    return highpass(lowpass(signal, high, rate), low, rate)


def sweep(f0, f1, seconds, shape=1.0, rate=RATE):
    t = t_axis(seconds, rate)
    freq = f0 + (f1 - f0) * (t / seconds) ** shape
    return np.sin(2 * math.pi * np.cumsum(freq) / rate)


def saw(freq, seconds, rate=RATE):
    t = t_axis(seconds, rate)
    phase = (t * freq) % 1.0
    return 2.0 * phase - 1.0


def partials(freqs, seconds, decays, rate=RATE):
    t = t_axis(seconds, rate)
    out = np.zeros_like(t)
    for freq, decay in zip(freqs, decays):
        out += np.sin(2 * math.pi * freq * t) * np.exp(-t * decay)
    return out


def crackle(seconds, density=0.02, rate=RATE):
    spikes = (RNG.random(int(seconds * rate)) < density) * RNG.normal(0, 1, int(seconds * rate))
    return bandpass(spikes, 900, 7000, rate)


def thump(freq, seconds, drop=0.5, rate=RATE):
    return sweep(freq, freq * drop, seconds, 0.5, rate) * envelope(seconds, 0.002, 4.0, rate)


def normalize(signal, peak=0.89):
    top = np.max(np.abs(signal))
    return signal * (peak / top) if top > 0 else signal


def loop_crossfade(signal, fade_seconds, rate=RATE):
    fade = int(fade_seconds * rate)
    head, body, tail = signal[:fade], signal[fade:-fade], signal[-fade:]
    ramp = np.linspace(0.0, 1.0, fade)
    joined = tail * (1.0 - ramp) + head * ramp
    return np.concatenate([body, joined])


def save(path, signal, rate=RATE, peak=0.89):
    full = os.path.join(ROOT, "assets", "audio", path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    data = (np.clip(normalize(signal, peak), -1, 1) * 32767).astype(np.int16)
    with wave.open(full, "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(rate)
        handle.writeframes(data.tobytes())


def hum_core(seconds, base=82.0):
    t = t_axis(seconds)
    tone = (np.sin(2 * math.pi * base * t) + 0.55 * np.sin(2 * math.pi * base * 2.0 * t + 0.4)
            + 0.25 * np.sin(2 * math.pi * base * 3.01 * t) + 0.12 * saw(base * 0.5, seconds))
    wobble = 1.0 + 0.08 * np.sin(2 * math.pi * 3.0 * t) + 0.05 * np.sin(2 * math.pi * 7.0 * t)
    return lowpass(tone * wobble + 0.05 * noise(seconds), 1400)


def blade_sounds():
    save("sfx/blade_hum.wav", loop_crossfade(hum_core(2.25), 0.25), peak=0.6)
    swing = bandpass(noise(0.26), 300, 2600) * envelope(0.26, 0.06, 2.0) + 0.6 * sweep(160, 260, 0.26) * envelope(0.26, 0.08, 2.0)
    save("sfx/swing_light.wav", swing)
    heavy = bandpass(noise(0.46), 180, 1800) * envelope(0.46, 0.14, 2.0) + 0.7 * sweep(110, 190, 0.46, 0.7) * envelope(0.46, 0.15, 2.0)
    save("sfx/swing_heavy.wav", heavy)
    ignition = hum_core(0.6) * np.minimum(t_axis(0.6) / 0.08, 1.0) * envelope(0.6, 0.01, 0.6)
    rise = np.concatenate([sweep(70, 380, 0.22, 0.6) * envelope(0.22, 0.004, 1.2), np.zeros(int(0.38 * RATE))])
    save("sfx/ignition.wav", ignition + 0.5 * rise + 0.3 * crackle(0.6, 0.01) * envelope(0.6, 0.002, 3.0))
    save("sfx/extinguish.wav", sweep(260, 50, 0.7, 0.8) * envelope(0.7, 0.01, 1.4) * 0.8 + 0.2 * crackle(0.7, 0.006) * envelope(0.7, 0.01, 2.0))


def impact_sounds():
    save("sfx/hit_light.wav", crackle(0.25, 0.08) * envelope(0.25, 0.001, 3.0) + 0.9 * thump(95, 0.25))
    save("sfx/hit_heavy.wav", crackle(0.45, 0.1) * envelope(0.45, 0.001, 2.5) + 1.3 * thump(70, 0.45, 0.45))
    metal = partials([820, 1290, 2110, 3170], 0.32, [14, 18, 24, 30])
    save("sfx/block.wav", 0.8 * metal + 0.6 * crackle(0.32, 0.05) * envelope(0.32, 0.001, 3.0))
    clash = partials([640, 1010, 1730, 2650, 3900], 0.7, [7, 9, 12, 15, 20]) + 1.0 * crackle(0.7, 0.12) * envelope(0.7, 0.001, 2.5) + 1.2 * thump(60, 0.7, 0.5)
    save("sfx/clash.wav", clash)
    save("sfx/parry.wav", partials([1400, 2800, 4210], 0.45, [8, 11, 16]) + 0.3 * crackle(0.45, 0.02) * envelope(0.45, 0.001, 4.0))
    perfect = partials([1180, 1770, 2360, 3540], 0.9, [3.5, 4.5, 6, 8]) + 0.25 * sweep(2400, 3600, 0.9) * envelope(0.9, 0.05, 2.0)
    save("sfx/perfect_parry.wav", perfect)
    save("sfx/guard_break.wav", sweep(1200, 140, 0.5, 0.5) * envelope(0.5, 0.001, 2.0) + crackle(0.5, 0.15) * envelope(0.5, 0.001, 2.0) + thump(80, 0.5))
    save("sfx/knockout.wav", 1.4 * thump(55, 1.3, 0.4) + 0.4 * lowpass(noise(1.3), 300) * envelope(1.3, 0.005, 2.0))
    save("sfx/shove.wav", thump(110, 0.22, 0.6) + 0.3 * lowpass(noise(0.22), 500) * envelope(0.22, 0.002, 3.0))
    save("sfx/wound.wav", 1.2 * thump(65, 0.55, 0.5) + 0.6 * crackle(0.55, 0.08) * envelope(0.55, 0.001, 2.0))


def blade_lock_sounds():
    seconds = 1.6
    buzz = (saw(50, seconds) * 0.4 + bandpass(noise(seconds), 600, 4000) * 0.8) * (1.0 + 0.3 * np.sin(2 * math.pi * 9 * t_axis(seconds)))
    save("sfx/lock_loop.wav", loop_crossfade(buzz, 0.2), peak=0.6)
    save("sfx/lock_press.wav", partials([520, 900, 1500], 0.16, [30, 40, 50]) + thump(90, 0.16))
    save("sfx/lock_win.wav", bandpass(noise(0.5), 400, 3000) * envelope(0.5, 0.05, 2.0) + partials([700, 1180, 1900], 0.5, [8, 10, 14]))
    save("sfx/lock_tie.wav", bandpass(noise(0.3), 2000, 8000) * envelope(0.3, 0.01, 2.0))


def body_sounds():
    save("sfx/step.wav", lowpass(noise(0.09), 1200) * envelope(0.09, 0.002, 4.0) + 0.4 * partials([340, 760], 0.09, [40, 60]))
    save("sfx/jump.wav", bandpass(noise(0.22), 200, 1500) * envelope(0.22, 0.03, 2.0))
    save("sfx/land.wav", thump(90, 0.22, 0.6) + 0.4 * lowpass(noise(0.22), 900) * envelope(0.22, 0.002, 3.0))
    save("sfx/dodge.wav", bandpass(noise(0.2), 900, 5000) * envelope(0.2, 0.03, 2.0))
    save("sfx/evade.wav", bandpass(noise(0.22), 600, 3000) * envelope(0.22, 0.12, 1.0) * 0.6 + 0.5 * partials([2400], 0.22, [18]))
    save("sfx/exhaustion.wav", lowpass(noise(0.7), 500) * envelope(0.7, 0.15, 1.5) + 0.3 * sweep(160, 90, 0.7) * envelope(0.7, 0.1, 2.0))
    save("sfx/rejected.wav", bandpass(noise(0.07), 200, 1200) * envelope(0.07, 0.001, 5.0) + 0.5 * partials([180], 0.07, [60]))
    beat = np.concatenate([thump(55, 0.18, 0.6), np.zeros(int(0.07 * RATE)), 0.7 * thump(50, 0.18, 0.6), np.zeros(int(0.17 * RATE))])
    save("sfx/heartbeat.wav", lowpass(beat, 400))


def interface_sounds():
    save("sfx/ui_move.wav", partials([1800], 0.05, [80]) * envelope(0.05, 0.001, 2.0))
    save("sfx/ui_confirm.wav", partials([880, 1320], 0.18, [20, 24]))
    save("sfx/ui_back.wav", partials([660, 440], 0.16, [24, 20]))


def music_layer(seconds, notes, voice, rate=MUSIC_RATE):
    out = np.zeros(int(seconds * rate))
    for start, length, freq, gain in notes:
        part = voice(freq, length, rate) * gain
        begin = int(start * rate)
        end = min(begin + part.size, out.size)
        out[begin:end] += part[: end - begin]
    return out


def string_voice(freq, length, rate):
    t = t_axis(length, rate)
    tone = sum(saw(freq * detune, length, rate) for detune in (0.997, 1.0, 1.004)) / 3.0
    swell = np.minimum(t / 1.2, 1.0) * np.minimum((length - t) / 1.2, 1.0)
    return lowpass(tone, 700, rate) * swell


def tremolo_voice(freq, length, rate):
    t = t_axis(length, rate)
    tone = sum(saw(freq * detune, length, rate) for detune in (0.995, 1.0, 1.006)) / 3.0
    shimmer = 0.55 + 0.45 * np.sin(2 * math.pi * 8.0 * t)
    swell = np.minimum(t / 0.8, 1.0) * np.minimum((length - t) / 0.6, 1.0)
    return lowpass(tone, 2400, rate) * shimmer * swell


def drum_voice(freq, length, rate):
    hit = sweep(freq, freq * 0.45, length, 0.4, rate) * envelope(length, 0.002, 3.5, rate)
    skin = lowpass(noise(length, rate), 900, rate) * envelope(length, 0.001, 6.0, rate) * 0.4
    return hit + skin


def music():
    seconds = 16.0
    beat = 60.0 / 75.0
    d2, a2, f2, c3, bb1 = 73.42, 110.0, 87.31, 130.81, 58.27
    harmony = [(d2, a2), (bb1, f2), (c3 / 2, a2 * 0.89), (d2, a2)]
    base_notes = []
    for bar, (root, fifth) in enumerate(harmony):
        start = bar * 4.0
        base_notes += [(start, 4.4, root, 1.0), (start, 4.4, fifth, 0.6), (start, 4.4, root * 2, 0.35)]
    base = music_layer(seconds + 0.6, base_notes, string_voice)
    timpani = music_layer(seconds + 0.6, [(bar * 4.0, 1.2, harmony[bar][0], 0.8) for bar in range(4)], drum_voice)
    save("music/duel_base.wav", loop_crossfade(base + timpani, 0.6, MUSIC_RATE), MUSIC_RATE, 0.7)
    pattern = [0.0, 1.5, 2.0, 2.75, 3.0, 3.5]
    drum_notes = []
    step = 0.0
    while step < seconds:
        for offset in pattern:
            time = step + offset * beat * 0.5
            if time < seconds:
                drum_notes.append((time, 0.4, 62.0 if offset in (0.0, 2.0) else 95.0, 1.0 if offset in (0.0, 2.0) else 0.55))
        step += 4 * beat * 0.5
    drums = music_layer(seconds + 0.6, drum_notes, drum_voice)
    save("music/duel_percussion.wav", loop_crossfade(drums, 0.6, MUSIC_RATE), MUSIC_RATE, 0.7)
    tension_notes = []
    for bar, (root, fifth) in enumerate(harmony):
        tension_notes += [(bar * 4.0, 4.3, root * 4, 0.6), (bar * 4.0, 4.3, fifth * 4 * 1.0, 0.35)]
    tension = music_layer(seconds + 0.6, tension_notes, tremolo_voice)
    save("music/duel_tension.wav", loop_crossfade(tension, 0.6, MUSIC_RATE), MUSIC_RATE, 0.55)


def ambience():
    seconds = 12.0
    rate = MUSIC_RATE
    t = t_axis(seconds + 1.0, rate)
    hiss = bandpass(noise(seconds + 1.0, rate), 500, 5000, rate) * (0.35 + 0.25 * np.sin(2 * math.pi * 0.11 * t) + 0.15 * np.sin(2 * math.pi * 0.37 * t))
    pings = np.zeros_like(t)
    for start in (1.3, 4.1, 7.7, 10.2):
        ring = partials([310 * RNG.uniform(0.9, 1.2), 517, 803], 2.5, [1.6, 2.2, 3.0], rate) * 0.3
        begin = int(start * rate)
        end = min(begin + ring.size, pings.size)
        pings[begin:end] += ring[: end - begin]
    rumble = lowpass(noise(seconds + 1.0, rate), 90, rate) * 1.5
    save("ambience/refinery.wav", loop_crossfade(hiss + pings + rumble, 1.0, rate), rate, 0.5)


if __name__ == "__main__":
    blade_sounds()
    impact_sounds()
    blade_lock_sounds()
    body_sounds()
    interface_sounds()
    music()
    ambience()
    print("audio written")

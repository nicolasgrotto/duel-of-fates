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
AMBIENCE_RATE = 22050
AMBIENCE_SECONDS = 10.0
THEME_RATE = 22050


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


def scatter(seconds, times, voice, rate):
    out = np.zeros(int(seconds * rate))
    for start in times:
        part = voice()
        begin = int(start * rate)
        end = min(begin + part.size, out.size)
        out[begin:end] += part[: end - begin]
    return out


def drop_voice(rate, low=900, high=2200):
    length = 0.12
    freq = RNG.uniform(low, high)
    return sweep(freq, freq * 0.55, length, 0.6, rate) * envelope(length, 0.001, 4.0, rate)


def bell_voice(rate, base, length=3.0):
    return partials([base, base * 2.76, base * 5.4], length, [1.2, 2.0, 3.4], rate)


def slow_wave(t, rate_hz, depth=0.4, phase=0.0):
    return 1.0 - depth + depth * (0.5 + 0.5 * np.sin(2 * math.pi * rate_hz * t + phase))


def save_ambience(name, signal, peak=0.5):
    save("ambience/%s.wav" % name, loop_crossfade(signal, 1.0, AMBIENCE_RATE), AMBIENCE_RATE, peak)


def arena_ambiences():
    rate = AMBIENCE_RATE
    total = AMBIENCE_SECONDS + 1.0
    t = t_axis(total, rate)
    random_times = lambda count: sorted(RNG.uniform(0.2, AMBIENCE_SECONDS, count))
    flow = lowpass(noise(total, rate), 700, rate) * slow_wave(t, 0.13) * 1.4
    drops = scatter(total, random_times(14), lambda: drop_voice(rate), rate) * 0.5
    save_ambience("sanctuary", flow + drops)
    drips = scatter(total, random_times(9), lambda: drop_voice(rate, 1400, 2800), rate) * 0.6
    crystal = scatter(total, random_times(4), lambda: bell_voice(rate, RNG.uniform(1800, 2600), 3.5) * 0.12, rate)
    cave = lowpass(noise(total, rate), 80, rate) * 1.2
    save_ambience("crystal_mine", drips + crystal + cave)
    rain = highpass(noise(total, rate), 1800, rate) * 0.5 * slow_wave(t, 0.07, 0.2)
    city = lowpass(noise(total, rate), 220, rate) * 0.9
    horns = scatter(total, random_times(2), lambda: string_voice(RNG.uniform(140, 190), 1.6, rate) * 0.05, rate)
    save_ambience("neon_rooftop", rain + city + horns)
    hum = (np.sin(2 * math.pi * 55 * t) + 0.4 * np.sin(2 * math.pi * 110.4 * t)) * slow_wave(t, 0.09, 0.5) * 0.25
    creaks = scatter(total, random_times(2), lambda: partials([410, 655, 980], 1.4, [3, 4, 6], rate) * 0.08, rate)
    save_ambience("orbital_ring", hum + creaks, 0.3)
    chirp_t = t_axis(0.25, rate)
    chirp = lambda: np.sin(2 * math.pi * RNG.uniform(3800, 5200) * chirp_t) * (0.5 + 0.5 * np.sign(np.sin(2 * math.pi * 28 * chirp_t))) * envelope(0.25, 0.02, 1.5, rate) * 0.12
    insects = scatter(total, random_times(26), chirp, rate)
    leaves = bandpass(noise(total, rate), 1200, 4500, rate) * slow_wave(t, 0.2, 0.8) * 0.5
    save_ambience("luminous_forest", insects + leaves, 0.4)
    wind = bandpass(noise(total, rate), 250, 1400, rate) * slow_wave(t, 0.06, 0.6) * 1.2
    sand = highpass(crackle(total, 0.01, rate), 3000, rate) * 0.6
    save_ambience("glass_salt_flats", wind + sand)
    gale = bandpass(noise(total, rate), 180, 2200, rate) * slow_wave(t, 0.17, 0.7, 1.0) * 1.4
    engine = lowpass(saw(46, total, rate) + 0.5 * saw(92.5, total, rate), 260, rate) * slow_wave(t, 0.5, 0.15) * 0.5
    save_ambience("skyborne_deck", gale + engine, 0.55)
    blizzard = bandpass(noise(total, rate), 400, 6000, rate) * slow_wave(t, 0.11, 0.75, 2.0)
    bells = scatter(total, [2.0, 7.5], lambda: bell_voice(rate, 310, 4.0) * 0.06, rate)
    save_ambience("snowbound_peak", blizzard + bells)
    room = lowpass(noise(total, rate), 120, rate) * 0.8
    echo = lambda: np.concatenate([np.zeros(1)] + [bandpass(noise(0.05, rate), 300, 2000, rate) * 0.5 ** k for k in range(6)]) * 0.25
    echoes = scatter(total, random_times(3), lambda: lowpass(np.concatenate([echo(), np.zeros(int(0.4 * rate))]), 1500, rate), rate)
    save_ambience("eclipse_citadel", room + echoes, 0.35)


def choir_voice(freq, length, rate):
    t = t_axis(length, rate)
    tone = sum(saw(freq * detune, length, rate) for detune in (0.996, 1.0, 1.005)) / 3.0
    vowel = bandpass(tone, 500, 1200, rate) * 1.6 + lowpass(tone, 400, rate) * 0.4
    swell = np.minimum(t / 1.5, 1.0) * np.minimum((length - t) / 1.2, 1.0)
    return vowel * swell


def bell_note(freq, length, rate):
    return bell_voice(rate, freq, length)


def theme(name, harmony, bpm, pad_voice, accent_voice, accents, hits, rate=THEME_RATE):
    seconds = 16.0
    beat = 60.0 / bpm
    pad = []
    for bar, (root, fifth) in enumerate(harmony):
        start = bar * 4.0
        pad += [(start, 4.4, root, 1.0), (start, 4.4, fifth, 0.6), (start, 4.4, root * 2, 0.3)]
    base = music_layer(seconds + 0.6, pad, pad_voice, rate)
    base += music_layer(seconds + 0.6, [(time, 2.5, freq, 0.35) for time, freq in accents], accent_voice, rate)
    save("music/%s_base.wav" % name, loop_crossfade(base, 0.6, rate), rate, 0.7)
    drum_notes = []
    step = 0.0
    while step < seconds:
        for offset, freq, gain in hits:
            time = step + offset * beat
            if time < seconds:
                drum_notes.append((time, 0.5, freq, gain))
        step += 4 * beat
    drums = music_layer(seconds + 0.6, drum_notes, drum_voice, rate)
    save("music/%s_percussion.wav" % name, loop_crossfade(drums, 0.6, rate), rate, 0.7)
    tension = music_layer(seconds + 0.6, [(bar * 4.0, 4.3, root * 4, 0.6) for bar, (root, _fifth) in enumerate(harmony)] + [(bar * 4.0 + 2.0, 2.2, fifth * 4, 0.3) for bar, (_root, fifth) in enumerate(harmony)], tremolo_voice, rate)
    save("music/%s_tension.wav" % name, loop_crossfade(tension, 0.6, rate), rate, 0.55)


def themes():
    e2, c2, d2, g2 = 82.41, 65.41, 73.42, 98.0
    theme("sacred", [(e2, e2 * 1.5), (c2, c2 * 1.5), (d2, d2 * 1.5), (e2, e2 * 1.5)], 64.0, string_voice, bell_note,
        [(0.0, 659.3), (2.0, 587.3), (4.0, 523.3), (8.0, 587.3), (10.0, 659.3), (12.0, 493.9)],
        [(0.0, 55.0, 0.9), (2.0, 70.0, 0.5)])
    c2b, ab1, f2, g1 = 65.41, 51.91, 87.31, 49.0
    theme("boss", [(c2b, c2b * 1.5), (ab1, ab1 * 1.5), (f2, f2 * 1.5), (g1 * 2, g1 * 3)], 66.0, choir_voice, string_voice,
        [(0.0, 261.6), (4.0, 207.7), (8.0, 174.6), (12.0, 196.0)],
        [(0.0, 48.0, 1.0), (1.0, 62.0, 0.6), (1.5, 62.0, 0.5), (2.0, 48.0, 1.0), (3.0, 75.0, 0.7), (3.5, 75.0, 0.6)])


def power_sounds():
    rumble = lambda seconds, cutoff=140: lowpass(noise(seconds), cutoff) * 2.5
    save("powers/cast.wav", bandpass(noise(0.3), 400, 2600) * envelope(0.3, 0.2, 1.0) * 0.5 + 0.4 * sweep(220, 520, 0.3) * envelope(0.3, 0.2, 1.0))
    save("powers/repulse.wav", bandpass(noise(0.35), 150, 3000) * envelope(0.35, 0.004, 3.0) + 0.9 * thump(120, 0.35, 0.5))
    save("powers/supreme_push.wav", 1.5 * thump(48, 1.2, 0.4) + rumble(1.2) * envelope(1.2, 0.01, 2.0) + 0.5 * bandpass(noise(1.2), 200, 2500) * envelope(1.2, 0.005, 4.0))
    save("powers/pull.wav", bandpass(noise(0.45), 300, 2400) * envelope(0.45, 0.35, 0.6) * np.linspace(0.3, 1.0, int(0.45 * RATE)) + 0.6 * sweep(600, 140, 0.45, 0.6) * envelope(0.45, 0.3, 0.8))
    rock = crackle(0.6, 0.06) * envelope(0.6, 0.005, 1.5) + rumble(0.6, 200) * envelope(0.6, 0.02, 1.5)
    save("powers/rock_lift.wav", rock + 0.4 * sweep(70, 120, 0.6) * envelope(0.6, 0.05, 1.5))
    save("powers/rock_impact.wav", 1.3 * thump(70, 0.5, 0.45) + crackle(0.5, 0.12) * envelope(0.5, 0.001, 2.5) + rumble(0.5, 300) * envelope(0.5, 0.002, 3.0))
    save("powers/fracture.wav", rumble(0.9, 160) * envelope(0.9, 0.05, 1.0) + 0.6 * crackle(0.9, 0.03) * envelope(0.9, 0.05, 1.2))
    save("powers/fracture_burst.wav", 1.1 * thump(85, 0.35, 0.5) + crackle(0.35, 0.15) * envelope(0.35, 0.001, 3.0))
    twist_t = t_axis(0.8)
    beating = (np.sin(2 * math.pi * np.cumsum(np.linspace(520, 380, twist_t.size)) / RATE) + np.sin(2 * math.pi * np.cumsum(np.linspace(527, 386, twist_t.size)) / RATE)) * envelope(0.8, 0.05, 1.5)
    save("powers/mind_twist.wav", 0.6 * beating + 0.8 * np.concatenate([thump(70, 0.4, 0.6), np.zeros(twist_t.size - int(0.4 * RATE))]))
    field_t = t_axis(2.0)
    field = (np.sin(2 * math.pi * 110 * field_t) + 0.5 * np.sin(2 * math.pi * 221 * field_t) + 0.3 * bandpass(noise(2.0), 1500, 5000)) * (1.0 + 0.2 * np.sin(2 * math.pi * 5 * field_t))
    save("powers/barrier_loop.wav", loop_crossfade(lowpass(field, 2400), 0.25), peak=0.5)
    save("powers/barrier_absorb.wav", partials([660, 990, 1480], 0.4, [9, 12, 16]) + 0.4 * bandpass(noise(0.4), 2000, 6000) * envelope(0.4, 0.002, 3.0))
    chord = np.zeros(int(1.0 * RATE))
    for i, freq in enumerate([392.0, 494.0, 587.0, 784.0]):
        part = sweep(freq * 0.98, freq, 1.0 - i * 0.15) * envelope(1.0 - i * 0.15, 0.2, 1.5)
        begin = int(i * 0.15 * RATE)
        chord[begin:begin + part.size] += part
    save("powers/sanctuary.wav", chord)
    save("powers/sanctuary_break.wav", partials([2210, 3170, 4430, 5900, 7100], 0.7, [7, 9, 12, 15, 19]) * 0.6 + bandpass(noise(0.7), 3000, 9000) * envelope(0.7, 0.001, 3.0))
    save("powers/absorption.wav", bandpass(noise(0.6), 600, 3000) * envelope(0.6, 0.15, 1.2) * 0.6 + 0.6 * sweep(900, 300, 0.6, 0.7) * envelope(0.6, 0.1, 1.2))
    save("powers/heal.wav", (sweep(330, 495, 1.1, 0.5) + 0.5 * sweep(495, 660, 1.1, 0.5)) * envelope(1.1, 0.3, 1.2))
    save("powers/focus.wav", partials([880, 1320], 1.2, [2.0, 3.0]) * np.minimum(t_axis(1.2) / 0.08, 1.0))
    arc_t = t_axis(1.5)
    arc = crackle(1.5, 0.08) * (0.6 + 0.4 * np.abs(np.sin(2 * math.pi * 6 * arc_t))) + 0.25 * saw(60, 1.5) * (1.0 + 0.4 * np.sin(2 * math.pi * 11 * arc_t))
    save("powers/lightning_loop.wav", loop_crossfade(arc, 0.2), peak=0.6)
    save("powers/lightning_snap.wav", crackle(0.18, 0.4) * envelope(0.18, 0.001, 3.0) + 0.5 * thump(160, 0.18, 0.5))
    save("powers/choke.wav", lowpass(noise(1.0), 220) * envelope(1.0, 0.2, 0.8) * 2.0 + 0.5 * sweep(65, 55, 1.0) * envelope(1.0, 0.2, 1.0))
    save("powers/freeze.wav", partials([1900, 2600, 3400, 4700], 0.8, [5, 7, 9, 12]) * 0.4 * np.minimum(t_axis(0.8) / 0.25, 1.0) + 0.5 * crackle(0.8, 0.02) * envelope(0.8, 0.2, 1.0))
    save("powers/freeze_break.wav", partials([2400, 3550, 5100], 0.35, [12, 16, 22]) * 0.5 + crackle(0.35, 0.2) * envelope(0.35, 0.001, 3.0))
    save("powers/storm_rise.wav", crackle(1.2, 0.05) * np.linspace(0.1, 1.0, int(1.2 * RATE)) + 0.4 * sweep(60, 160, 1.2, 1.5) * envelope(1.2, 0.8, 0.5))
    save("powers/thunder.wav", rumble(2.6, 120) * envelope(2.6, 0.02, 1.6) * 1.3 + 0.7 * crackle(2.6, 0.03) * envelope(2.6, 0.005, 3.0) + thump(45, 2.6, 0.5))
    save("powers/mark_tick.wav", crackle(0.1, 0.3) * envelope(0.1, 0.001, 4.0) + 0.3 * partials([2600], 0.1, [40]))
    save("powers/bolt_strike.wav", crackle(0.5, 0.35) * envelope(0.5, 0.001, 3.0) + 1.2 * thump(60, 0.5, 0.45))
    save("powers/mass_rumble.wav", rumble(1.2, 160) * np.linspace(0.2, 1.0, int(1.2 * RATE)) + 0.6 * crackle(1.2, 0.04) * np.linspace(0.0, 1.0, int(1.2 * RATE)))
    save("powers/whistle.wav", sweep(2200, 700, 0.8, 0.8) * envelope(0.8, 0.1, 1.0) * 0.5)
    save("powers/wrath.wav", (saw(55, 1.0) * 0.5 + sweep(55, 110, 1.0, 2.0)) * np.minimum(t_axis(1.0) / 0.7, 1.0) * envelope(1.0, 0.001, 0.4))
    save("powers/wrath_armor.wav", 1.2 * thump(60, 0.3, 0.5) + bandpass(noise(0.3), 200, 1800) * envelope(0.3, 0.002, 2.5))
    drain_t = t_axis(1.6)
    drain = lowpass(noise(1.6), 400) * (1.0 + 0.5 * np.sin(2 * math.pi * 2.5 * drain_t)) * 2.0 + 0.4 * np.sin(2 * math.pi * 73 * drain_t)
    save("powers/drain_loop.wav", loop_crossfade(drain, 0.3), peak=0.6)
    save("powers/arsenal_launch.wav", bandpass(noise(0.3), 1200, 6000) * envelope(0.3, 0.01, 2.0) + 0.6 * sweep(400, 1400, 0.3, 0.5) * envelope(0.3, 0.01, 2.0))
    save("powers/cleave.wav", bandpass(noise(0.5), 400, 4000) * envelope(0.5, 0.04, 2.0) + 0.8 * sweep(140, 420, 0.5, 0.6) * envelope(0.5, 0.05, 1.5))
    save("powers/cleave_return.wav", partials([1250, 1880, 2840], 0.5, [8, 10, 14]) + 0.3 * crackle(0.5, 0.03) * envelope(0.5, 0.001, 3.0))
    save("powers/resisted.wav", lowpass(thump(90, 0.3, 0.7) + 0.4 * noise(0.3) * envelope(0.3, 0.001, 4.0), 600))


def instinct_sounds():
    rng = np.random.default_rng(404)
    air = bandpass(rng.normal(0, 1, int(0.8 * RATE)), 1600, 4800)
    save("powers/instinct.wav", (sweep(540, 1080, 0.8) * 0.4 + air * 0.2) * envelope(0.8, 0.08, 1.8))
    air = bandpass(rng.normal(0, 1, int(0.2 * RATE)), 2500, 6800)
    save("powers/instinct_evade.wav", (air * 0.6 + sweep(1200, 700, 0.2) * 0.2) * envelope(0.2, 0.01, 2.5))


def singularity_sounds():
    rng = np.random.default_rng(505)
    def stone(seconds):
        return bandpass(rng.normal(0, 1, int(seconds * RATE)), 160, 2200)
    save("powers/singularity.wav", (sweep(42, 120, 1.0) + stone(1.0) * 0.35) * envelope(1.0, 0.3, 1.2))
    save("powers/singularity_extract.wav", (thump(100, 0.35) + stone(0.35) * 0.5) * envelope(0.35, 0.01, 1.4))
    save("powers/singularity_throw.wav", (sweep(210, 48, 0.6) + stone(0.6) * 0.6) * envelope(0.6, 0.02, 1.6))
    save("powers/singularity_impact.wav", thump(45, 0.8) + stone(0.8) * envelope(0.8, 0.005, 3.0))


def bolt_sounds():
    rng = np.random.default_rng(606)
    crack = highpass(rng.normal(0, 1, int(0.12 * RATE)), 2400)
    save("bolts/bolt_shot.wav", (sweep(1500, 380, 0.12, 0.6) * 0.7 + crack * 0.25) * envelope(0.12, 0.002, 2.2))
    hiss = bandpass(rng.normal(0, 1, int(0.16 * RATE)), 3000, 9000)
    save("bolts/bolt_deflect.wav", (hiss * 0.6 + partials([2350.0, 3710.0], 0.16, [18.0, 26.0]) * 0.3) * envelope(0.16, 0.001, 2.0))
    hiss = bandpass(rng.normal(0, 1, int(0.24 * RATE)), 2600, 8000)
    save("bolts/bolt_reflect.wav", (hiss * 0.45 + sweep(620, 1640, 0.24, 0.7) * 0.4) * envelope(0.24, 0.002, 1.8))
    thud = lowpass(rng.normal(0, 1, int(0.14 * RATE)), 1200)
    save("bolts/bolt_hit.wav", (thump(160, 0.14) * 0.7 + thud * 0.4) * envelope(0.14, 0.002, 2.4))


def magma_ambience():
    rate = AMBIENCE_RATE
    total = AMBIENCE_SECONDS + 1.0
    rng = np.random.default_rng(707)
    t = t_axis(total, rate)
    rumble = lowpass(rng.normal(0, 1, len(t)), 70, rate) * slow_wave(t, 0.08, 0.5) * 1.6
    bubble = lambda: sweep(rng.uniform(70, 120), rng.uniform(160, 260), 0.18, 1.0, rate) * envelope(0.18, 0.02, 2.0, rate) * 0.25
    bubbles = scatter(total, sorted(rng.uniform(0.2, AMBIENCE_SECONDS, 18)), bubble, rate)
    crackles = highpass(crackle(total, 0.004, rate), 2500, rate) * 0.35
    save_ambience("magma_forge", rumble + bubbles + crackles)


def infiltration_sounds():
    save("infiltration/suspicion.wav", partials([740, 1110], 0.22, [16, 20]) * envelope(0.22, 0.005, 1.0))
    t = t_axis(1.0)
    pulse = np.maximum(0, np.sin(2 * math.pi * 2 * t)) ** 2
    save("infiltration/alarm.wav", (np.sin(2 * math.pi * 410 * t) + 0.35 * np.sin(2 * math.pi * 615 * t)) * pulse * 0.5)


if __name__ == "__main__":
    blade_sounds()
    impact_sounds()
    blade_lock_sounds()
    body_sounds()
    interface_sounds()
    music()
    ambience()
    power_sounds()
    instinct_sounds()
    singularity_sounds()
    bolt_sounds()
    magma_ambience()
    arena_ambiences()
    themes()
    infiltration_sounds()
    print("audio written")

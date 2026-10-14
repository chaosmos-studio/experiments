# Room to Breathe

Original ambient score for this experiment: 16 bars, 72 BPM, D major.
A warm pad and bass form one stem; soft FM keys and stereo echoes form the other.
Both loops are 53.333 seconds and start together. The melody becomes more audible
as the web clears. Gains change smoothly without restarting the composition.

Music starts after a pointer or keyboard gesture, pauses when focus is lost, and
fades before pausing when muted. Music, effects, and music volume are independent
saved preferences. The short interaction notes use the same D-major harmony.

No downloaded songs, samples, or third-party music are used. The synthesis source
is `tools/compose_music.py`; committed Ogg assets keep normal builds self-contained.
To regenerate, install NumPy and FFmpeg, then run:

```sh
python3 tools/compose_music.py
```

`audio-audit.json` records source duration, peak, RMS and loop-boundary sample step.
Circular rendering carries note releases and echo tails across the boundary. Native
tests verify stream loading, matching loop lengths, playback, mute, focus handling,
volume limits and saved preferences. Browser tests inspect actual Web Audio PCM
with music enabled and both channels muted, in addition to testing controls.

## Fonts

- Manrope: https://github.com/google/fonts/tree/main/ofl/manrope
- Cormorant Garamond Italic: https://github.com/google/fonts/tree/main/ofl/cormorantgaramond

Both use the SIL Open Font License. Original notices are in `assets/fonts/` and
are copied into `licenses/` in the published web build. UI artwork is drawn in code.

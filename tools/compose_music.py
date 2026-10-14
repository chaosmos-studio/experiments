"""Original score: 'Room to Breathe'. No samples or third-party music.

16 bars, 72 BPM, D major. Two phase-aligned, circularly rendered stems.
Needs numpy and ffmpeg. Run from anywhere; writes the committed audio assets.
"""
import json, math, subprocess, tempfile, wave
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
RATE=32000
BEAT=60/72
DURATION=64*BEAT
N=round(DURATION*RATE)
tracks=[np.zeros((N,2),np.float64) for _ in range(2)]

def voice(track,midi,start,duration,level,pan=0.,kind='pad'):
    t=np.arange(round(duration*RATE))/RATE
    hz=440*2**((midi-69)/12)
    phase=2*np.pi*hz*t
    if kind=='pad':
        env=(1-np.exp(-t/0.55))*np.minimum(1,np.maximum(0,(duration-t)/1.8))
        # Warm, slow beating oscillators, never noisy or percussive.
        signal=(np.sin(phase)+.40*np.sin(phase*1.0017)+.18*np.sin(phase*2))*env
    elif kind=='bass':
        env=(1-np.exp(-t/.12))*np.exp(-t/.95)*np.minimum(1,(duration-t)/.12)
        signal=np.sin(phase)*env
    else:
        env=(1-np.exp(-t/.009))*np.exp(-t/1.0)*np.minimum(1,(duration-t)/.12)
        signal=(np.sin(phase+.55*np.sin(phase*2)*np.exp(-t*4))+.18*np.sin(phase*3)*np.exp(-t*5))*env
    gains=np.array([math.sqrt((1-pan)/2),math.sqrt((1+pan)/2)])
    note=signal[:,None]*gains[None,:]*level
    positions=(np.arange(len(t))+round(start*RATE))%N
    np.add.at(tracks[track],positions,note)
    if kind=='felt':
        for delay,gain in [(.375*BEAT,.25),(.75*BEAT,.17),(1.5*BEAT,.10),(2.25*BEAT,.06)]:
            np.add.at(tracks[track],(positions+round(delay*RATE))%N,note[:,::-1]*gain)

chords=[[50,57,61,64,69],[47,54,57,61,66],[43,55,59,62,66],[45,57,59,62,64]]
sequence=[0,1,2,3,0,2,1,3]
melodies=[[74,73,69,66,69,76],[73,69,66,62,66,69],[71,69,66,62,67,74],[69,71,74,76,74,69],
          [78,76,73,69,74,73],[74,71,69,66,67,71],[73,74,69,66,62,66],[69,71,74,73,69,64]]
for section,chord_id in enumerate(sequence):
    start=section*8*BEAT
    chord=chords[chord_id]
    for j,note in enumerate(chord):voice(0,note,start,8*BEAT+1.8,.055 if j==0 else .026,(j-2)*.22)
    for beat in [0,4]:voice(0,chord[0]-12,start+beat*BEAT,3.2,.055,kind='bass')
    for j,(beat,note) in enumerate(zip([.5,2,3.5,4.5,6,7.25],melodies[section])):
        voice(1,note,start+beat*BEAT,4.2,.14 if j in [0,3] else .105,math.sin(section+j)*.45,'felt')

# Tiny, diffuse stereo taps; circular accumulation preserves release tails at seam.
for k in range(2):
    dry=tracks[k].copy()
    for seconds,gain in [(.071,.11),(.113,.08),(.191,.05),(.311,.03)]:
        tracks[k]+=np.roll(dry[:,::-1],round(seconds*RATE),axis=0)*gain
    tracks[k]*=.60/max(np.max(np.abs(tracks[k])),1e-9)

output=ROOT/'assets/audio';output.mkdir(parents=True,exist_ok=True)
metrics=[]
with tempfile.TemporaryDirectory() as tmp:
    for name,data in zip(['room-to-breathe-bed','room-to-breathe-melody'],tracks):
        wav=Path(tmp)/(name+'.wav')
        pcm=np.round(data*32767).astype('<i2')
        with wave.open(str(wav),'wb') as f:
            f.setnchannels(2);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(pcm.tobytes())
        subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(wav),'-c:a','libvorbis','-q:a','2','-map_metadata','-1',str(output/(name+'.ogg'))],check=True)
        peak=float(np.max(np.abs(data)));rms=float(np.sqrt(np.mean(data**2)))
        seam=float(np.max(np.abs(data[0]-data[-1])))
        assert peak<.9 and rms>.015 and seam<.03
        metrics.append(dict(stem=name,seconds=N/RATE,peak=round(peak,5),rms=round(rms,5),seam_step=round(seam,5)))
(ROOT/'docs/audio-audit.json').write_text(json.dumps(metrics,indent=2)+'\n')
print(json.dumps(metrics,indent=2))
print('Original stereo stems:',[(p.name,p.stat().st_size) for p in output.glob('*.ogg')])

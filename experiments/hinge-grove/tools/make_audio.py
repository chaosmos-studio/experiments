"""Original, seeded garden score and short tactile sounds. No external recordings."""
from pathlib import Path
import wave, subprocess
import numpy as np

ROOT=Path(__file__).resolve().parents[1]/'assets/audio'
RATE=22050

def note(freq,duration,soft=False):
    t=np.arange(int(RATE*duration))/RATE
    env=(1-np.exp(-t*(12 if soft else 100)))*np.exp(-t*(1.8 if soft else 8))
    return (np.sin(2*np.pi*freq*t)+0.28*np.sin(2*np.pi*freq*2*t)+0.09*np.sin(2*np.pi*freq*3*t))*env

def save(name,a):
    a=np.clip(a,-0.95,0.95)
    with wave.open(str(ROOT/name),'wb') as f:
        f.setnchannels(1 if a.ndim==1 else 2);f.setsampwidth(2);f.setframerate(RATE)
        f.writeframes((a*32767).astype('<i2').tobytes())

def main():
    ROOT.mkdir(parents=True,exist_ok=True)
    for name,freq in [('turn',330),('root',440),('undo',260)]:save(name+'.wav',note(freq,0.2)*0.45)
    t=np.arange(int(RATE*0.8))/RATE
    save('bloom.wav',sum(note(f,0.8) for f in (392,494,587))*0.18)
    duration=32.0;count=int(RATE*duration);mix=np.zeros((count,2))
    chords=[(48,55,60,64),(45,52,57,60),(41,48,53,57),(43,50,55,59)]
    melody=[72,76,79,76,69,72,76,72,65,69,72,69,67,71,74,71]
    for bar,chord in enumerate(chords):
        for k,midi in enumerate(chord):
            sound=note(440*2**((midi-69)/12),8,True)*0.055
            at=int(RATE*(bar*8+k*0.08))
            idx=(np.arange(len(sound))+at)%count
            mix[idx,0]+=sound*(0.8+0.1*(k%2));mix[idx,1]+=sound*(0.9-0.1*(k%2))
    for i,midi in enumerate(melody):
        sound=note(440*2**((midi-69)/12),3)*0.06
        idx=(np.arange(len(sound))+int(RATE*(i*2+0.5)))%count
        mix[idx,0]+=sound*(0.8 if i%2 else 1);mix[idx,1]+=sound*(1 if i%2 else 0.8)
    save('grove.wav',mix)
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(ROOT/'grove.wav'),'-c:a','libvorbis','-q:a','3',str(ROOT/'grove.ogg')],check=True)
    (ROOT/'grove.wav').unlink()
    print('Original 32-second music loop and four effects generated')

if __name__=='__main__':main()

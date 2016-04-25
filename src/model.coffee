# global vars
try
  audioCtx = window.audioCtx = window.audioCtx || new (window.AudioContext || window.webkitAudioContext)()
catch
  alert 'Web Audio API not supported'

# global classes
class @DeckModel
  constructor: ->


sampleps = 44100;
dur = 1.5;
nchs = 2;
nsamples = Math.floor(dur * sampleps);
buffer = audioCtx.createBuffer(2, nsamples, sampleps);
wfreq = 440 * 2 * Math.PI / sampleps;
amp = 0.6;
for c in  [0...nchs]
  chdata = buffer.getChannelData c
  chdata.forEach (e,i,a) ->
    a[i] = amp * Math.sin(wfreq * i)
    return








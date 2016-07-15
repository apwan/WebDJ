# global vars
try
  audioCtx = window.audioCtx = window.audioCtx || new (window.AudioContext || window.webkitAudioContext)()
catch
  alert 'Web Audio API not supported'


class @TrackSource
  constructor: (@buffer, @name) ->
    @source = null


  play: () ->
    if @buffer == null
      console.log 'no buffer'
      return
    if @source
      @source.disconnect()
    source = audioCtx.createBufferSource()
    source.buffer = @buffer
    source.connect audioCtx.destination
    source.ended = ->
      source.disconnect()
    source.start(audioCtx.currentTime, 0, 6);
    @source = source

  isValid: ->
    @buffer?
  getSnap: (w,h,buffer, getALL)->
    buffer = buffer || @buffer
    if not buffer?
      console.log 'empty buffer'
      return
    durs = Math.floor(20.0 * 44100) # 20secs
    if getALL
      durs = buffer.length
    binn = 5
    npts = 1000 # at most 1000 points
    binn = Math.max(binn, Math.floor(durs/npts))
    npts = Math.floor(durs/binn)



    nChs = buffer.numberOfChannels
    scaleY = h/nChs/2
    trs = []

    for trn in [0...nChs]
      console.log 'chNo', trn
      samps = []
      arr = buffer.getChannelData(trn)
      i = 0
      while i<durs
        tm = tM = 0
        for j in [0...binn] by 1
          if arr[i] > tM
            tM = arr[i]
          else if arr[i] < tm
            tm = arr[i]
          i++
        samps.push(tm)
        samps.push(tM)
      scaleX = w/samps.length
      offsetY = scaleY*(2*trn+1)
      points = _.map samps, (e,i) ->
        x: i*scaleX, y: offsetY-e*scaleY
      trs.push new fabric.Polyline points, {stroke:'rgb(200,200,100)',strokeWidth:1}
      console.log trs[trn]

    return new fabric.Group trs



# global classes
class @DeckModel
  constructor: (@sampleps=44100) ->
    @source = null
    @curTime = 0
    @preTime = 0
    @analyser = audioCtx.createAnalyser()
    @buffer = null
    @status = 'empty'
    @samples = new Float32Array(1024 * 2)
    @srcbuf = null

    @ss = null


    @pnode = null

    @gnode = audioCtx.createGain();
    #@pnode.connect @gnode
    @gnode.connect audioCtx.destination

    @rateTrans = null #new RateTransposer(true)
    @stre = null #new Stretch(true);






  extract: (buffer,bsize) ->
    @srcbuf = buffer
    return @fk.extract(@samples,bsize)

  setGain: (val) ->

    console.log 'gain', @gnode.gain.value = val

  setRate: (val) ->
    if @ss
      console.log 'rate', @ss.t.rate = val

  setTempo: (val) ->
    if @ss
      console.log 'tempo', @ss.s.tempo = val



  setStatus: (status) ->
    console.log 'status:', @status, '->', status
    if status == 'started'
      console.log 'animate'

    @status = status

  connect: ->
    if @source
      @source.disconnect()
      @pnode.disconnect()
    if @buffer?
      @source = audioCtx.createBufferSource()
      @source.buffer = @buffer
      @source.connect @pnode
      #@source.connect @gnode
      @pnode.connect @gnode
      @source.connect @analyser
      return true
    return false

  readAudio: (buffer,flag) ->
      @buffer = buffer
      @curTime = 0
      @setStatus 'loaded'

      console.log @ss = new sndt(buffer,flag)
      @pnode = @ss.n
      @rateTrans = @ss.t
      @stre = @ss.s





  start: (offset, duration) ->
    @connect()
    if @source
      @source.ended = =>
        @setStatus 'stopped'
        @readAudio(@buffer)
        @curTime = 0


      @preTime =   audioCtx.currentTime
      @source.start @preTime, @curTime, duration
      @setStatus 'started'

  pause: ->
    if @source
      @source.stop()
      @curTime += audioCtx.currentTime - @preTime
      @source.disconnect()
      @pnode.disconnect()
      @source = null
      @setStatus 'loaded'







  stft: (winsize=2048) ->
    hann = new WindowFunction DSP.HANN

    arr = @buffer.getChannelData(0)
    sampleps = @buffer.sampleRate
    fft = new FFT(winsize, sampleps)
    nchunk = Math.floor(arr.length/winsize)
    console.log nchunk
    nchunk = Math.min(600,nchunk)
    @spectrum = []
    i = 0
    st = 0
    while i< nchunk * 2 - 1
      spt = []
      fft.forward(hann.gen(arr[st...st+winsize]))
      sp = fft.spectrum
      j = 0
      while j<sp.length
        if sp[j] > 0.01
          #console.log sp[j], j
          spt.push freq: sampleps/winsize*j, amp:sp[j]
        j++
      if spt.length
        @spectrum.push({chunkid:i,spect:spt})
      i++
      st += winsize/2

class @DJ
  play_once: (buffer) ->
    source = audioCtx.createBufferSource()
    source.buffer = buffer
    source.connect audioCtx.destination
    source.start()

  play: (freq, dur) ->

    @play_once @osc(freq, dur)


  osc: (freq, dur) ->
    osc = new Oscillator DSP.SINE,freq,1,Math.floor(dur*44100),44100
    osc.generate()
    buffer = audioCtx.createBuffer(1,Math.floor(dur*44100),44100)
    ch = buffer.getChannelData(0)
    ch.forEach (e,i,arr)->
      arr[i] = osc.signal[i]
      return
    buffer



  OLA: (input) ->


  PV: (input) ->


  HPS: (input) ->














# global vars
try
  audioCtx = window.audioCtx = window.audioCtx || new (window.AudioContext || window.webkitAudioContext)()
catch
  alert 'Web Audio API not supported'

# global classes
class @DeckCtrl
  constructor: (@sampleps=44100) ->
    @source = null
    @analyser = audioCtx.createAnalyser()
    @buffer = null
    @status = 'empty'

  setStatus: (status) ->
    console.log 'status:', @status, '->', status
    @status = status

  connect: ->
    if @source
      @source.disconnect();
    if @buffer?
      @source = audioCtx.createBufferSource()
      @source.buffer = @buffer
      @source.connect audioCtx.destination
      @source.connect @analyser
      return true
    return false

  readAudio: (blob) ->
    # if read from url
    if typeof blob is 'string'
      console.log 'url', blob
      request = new XMLHttpRequest()
      request.open "GET", blob, true
      request.responseType = "blob"
      request.onload = =>
        @readAudio request.response
        return
      request.send();
      return true
    else if typeof blob is 'object'
      reader = new FileReader
      reader.onload = (e) =>
        audioCtx.decodeAudioData e.target.result, (decdata) =>
          console.log 'currentTime', audioCtx.currentTime
          @buffer = decdata
          @connect()
          @setStatus 'loaded'
      reader.readAsArrayBuffer blob
      return true
    return false
  start: (offset, duration) ->
    if @status in ['started','stopped']
      return
    if @source
      @source.ended = =>
        @setStatus 'stopped'
      @source.start 0, offset, duration
      @setStatus 'started'



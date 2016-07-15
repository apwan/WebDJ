# global vars
@deckViews = [];
# global classes

class @WaveForm extends fabric.StaticCanvas
  initialize: (el, options) ->
    super el,options
    @lpad = 4
    @tpad = 4
    @fwidth = 330
    @fheight = 92
    @setWidth @fwidth+@lpad*2
    @setHeight @fheight+@tpad*2
    @formRect = new fabric.Rect left:0,top:0,width:@fwidth,height:@fheight,fill:'rgba(5,50,5,80)'
    lchline = new fabric.Polyline [{x:0,y:@fheight*0.25},{x:@fwidth,y:@fheight*0.25}],stroke:'rgb(20,240,0)',strokeWidth:1
    chline = new fabric.Polyline [{x:0,y:@fheight*0.5},{x:@fwidth,y:@fheight*0.5}],stroke:'rgb(200,200,200)',strokeWidth:2
    rchline = new fabric.Polyline [{x:0,y:@fheight*0.75},{x:@fwidth,y:@fheight*0.75}],stroke:'rgb(20,240,0)',strokeWidth:1
    @tracks = new fabric.Group [@formRect,lchline,chline,rchline],left:@lpad,top:@tpad
    @polyl = null

    @add @tracks

  initWave: (buffer) ->
    if @polyl
      @remove @polyl
    @polyl = new TrackSource(buffer).getSnap(@fwidth,@fheight, null,'all');

    @polyl.left = @lpad
    @polyl.top = @tpad
    console.log('check new1')
    @add @polyl
    @renderAll()


  render: (obj) ->
    @add obj


class @Snapshot extends fabric.StaticCanvas
  initialize: (el, options) ->
    super el,options
    @lpad = 0
    @tpad = 0
    @setWidth 300
    @setHeight 50
    @fwidth = @width
    @fheight = @height
    @formRect = new fabric.Rect left:0,top:0,width:@fwidth,height:@fheight,fill:'rgba(5,50,5,80)'
    lchline = new fabric.Polyline [{x:0,y:@fheight*0.25},{x:@fwidth,y:@fheight*0.25}],stroke:'rgb(20,240,0)',strokeWidth:1
    chline = new fabric.Polyline [{x:0,y:@fheight*0.5},{x:@fwidth,y:@fheight*0.5}],stroke:'rgb(200,200,200)',strokeWidth:1
    rchline = new fabric.Polyline [{x:0,y:@fheight*0.75},{x:@fwidth,y:@fheight*0.75}],stroke:'rgb(20,240,0)',strokeWidth:1
    @tracks = new fabric.Group [@formRect,lchline,chline,rchline],left:@lpad,top:@tpad
    @add @tracks

  render: (obj) ->
    @add obj

class @CtrlPanel extends fabric.Canvas
  initialize: (el,@idx, options) ->
    super el,options
    @setBackgroundColor 'rgba(100,100,100,10)'
    @cir1 = new fabric.Circle left:-20,top:-20,radius:20,fill:'yellow'
    @cir2 = new fabric.Circle left:-45,top:-45,radius:45,fill:'black'

    @line1 = new fabric.Polyline [{x:-45,y:0},{x:-20,y:0}], stroke:'red',strokeWidth:2
    @twocirs = new fabric.Group [@cir2,@cir1,@line1], left:50,top:50,originX:'center',originY:'center'

    @twocirs.set 'selectable',false
    @add @twocirs
    rect1 = new fabric.Rect left:40,top:40,width:20,height:20, fill:'red'

    rect1.lockScalingX=true
    rect1.lockScalingY=true
    rect1.hasControls=false

    rect1.on 'moving', (e)=>
      pt = @getPointer(e.e)
      console.log pt.x, pt.y
      console.log 'idx',@idx,deckViews[@idx]
      deckViews[@idx].mouseAct(pt)

    @add rect1
    @rect1 = rect1





    @twocirs.animate 'angle', '+=1600', duration:20000,onChange: =>
      @renderAll()
    @renderAll()






class @DeckView
  constructor: (e, c1, c2) ->
    @idx = deckViews.length
    console.log e,c1
    deckViews.push @
    console.log @
    @el = $ e
    @wfv = new WaveForm c1,backgroundColor:'rgb(180,20,140)',width:500,height:120
    @ctrl = new CtrlPanel c2, @idx, width:100,height:100
    $(@el).append '<ul><li>Hello</li></ul>'
    @core = new DeckModel();
    # _.bindAll @, 'render'

  readAudio: (buffer,name,flag) ->
    name = name || 'Untitled'
    @el.children('.panel-heading').children('.panel-title').html(name)
    @core.readAudio(buffer,flag)
    @wfv.initWave(buffer)


  mouseAct: (pt) ->
    if !@core
      console.log 'no core', @core
      return
    @core.setGain(1.0+(50-pt.y)/50.0)
    @core.setTempo(0.25+0.25*Math.pow(pt.x/25.0,2))
    @core.setRate(0.25+0.25*Math.pow(pt.x/25.0,2))




  render: ->
    super()

  getSnap: (w,h,buffer)->
    buffer = buffer || @buffer
    if not buffer?
      console.log 'empty buffer'
      return
    durs = buffer.length #Math.floor(20.0 * 44100) # 20secs
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

  stft: ->
    @core.stft()
    sp = @core.spectrum
    console.log 'spect len', sp.length

    nchunk = sp[sp.length-1].chunkid + 1
    scaleX = @wfv.fwidth/nchunk
    scaleY = @wfv.fheight/Math.log(10000)
    offsetY = @wfv.fheight
    rects = []
    i=0
    sp.forEach (e,i) ->
      cx = e.chunkid * scaleX
      e.spect.forEach (e2)->
        cy = offsetY-(Math.log(e2.freq/2+10)-Math.log(10)) * scaleY
        cl = Math.min(e2.amp*20,1.0)
        rects.push x:cx, y: cy, c:cl
    gp = new fabric.Group [],left:@lpad,top:@tpad

    cHL = [[240,10],[200,50],[10,200]]

    rects.forEach (e)->
      c = _.map cHL, (e2)->
        Math.floor e2[0]*e.c + e2[1]*(1-e.c)
      gp.add new fabric.Rect left:e.x, top:e.y, fill:"rgb(#{c[0]},#{c[1]},#{c[2]})",width:1,height:1
    @gp = gp




  test1: ->
    @readAudio 'chopin.m4a'
    @stft(4096)
    @wfv.render @gp

  test2: ->
    new DJ().play 261,1.5

@LoadedTracks = []
@addTrack = (buffer,name) ->
  # set up view

  name = name || 'Untitled'
  trk = new TrackSource(buffer,name)
  LoadedTracks.push trk
  console.log LoadedTracks
  trNo = LoadedTracks.length
  # append html
  pa = $ '#loaded_tracks'
  res = ['<div class="row trk"><div class="col col-md-4 col-lg-4"><div class="input-group">',
         '<span class="input-group-addon"><label class="label label-default">' + trNo + '<label></span>',
         '<span class="input-group-addon"><input name="song-deck-1" value="'+ trNo + '" type="radio" aria-label="..."></span>',
         '<span class="input-group-addon"><input name="song-deck-2" value="' + trNo + '" type="radio" aria-label="..."></span>',
         '<span class="input-group-btn"> <button class="btn btn-default" id="trk-play-'+trNo+'">Play</button></span>',
         '</div></div>',
         '<div class="col col-md-2 col-lg-2 song-name"><h4><label class="label label-info">'+name+'</label><h4></div>',
         '<div class="col-md-6 col-lg-6 canvas-holder"><canvas id="trk-snap-'+ trNo + '"></canvas></div></div>']
  console.log res.join('')
  pa.data 'total',trNo
  pa.append res.join('')
  cv = new Snapshot 'trk-snap-'+trNo
  console.log 'break point 1'
  tmp = trk.getSnap(cv.width,cv.height)
  console.log tmp
  cv.add tmp
  $('#trk-play-'+trNo).on 'click',->
    trk.play()


@handleLoading = (blob, callback) ->
  if typeof blob is 'string'
    console.log 'url', blob
    request = new XMLHttpRequest()
    request.open "GET", blob, true
    request.responseType = "blob"
    request.onload = =>
      handleLoading request.response, (decdata)->
        addTrack decdata,blob
      return
    request.send();
    return true
  else if typeof blob is 'object'
    console.log 'read blob', blob.name
    reader = new FileReader
    reader.onload = (e) =>

      audioCtx.decodeAudioData e.target.result, (decdata) =>
        if callback?
          callback decdata
        else
          addTrack decdata,blob.name
    reader.readAsArrayBuffer blob
    return true
  return false







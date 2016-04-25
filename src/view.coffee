# global vars

# global classes

class @WaveFormView extends Backbone.View
  initialize: (c) ->
    @cvs = new fabric.Canvas(c)
    _.bindAll @, 'render'
    @render()

  render: ->
    rect = new fabric.Rect left:100,top:100,fill:'red',width:20,height:20,angle:45
    @cvs.add rect

class @DeckView extends Backbone.View
  initialize: (e, c) ->
    @el = $ e
    @wfv = new WaveFormView c
    $(@el).append '<ul><li>Hello</li></ul>'
    _.bindAll @, 'render'
    @render()

  render: ->
    console.log $(@el).find('li').html()
    $(@el).find('li').html('Hello, Web DJ Deck')

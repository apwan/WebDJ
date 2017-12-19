function sndt(buffer, flag) {

    var context = window.audioCtx = window.audioCtx || new (AudioContext || webkitAudioContext)();

    var buffer = buffer;



    function createBuffer(arrayBuffer) {

        // NOTE the second parameter is required, or a TypeError is thrown
        buffer = context.createBuffer(arrayBuffer, false);


        console.log('loaded audio in ' + (new Date() - start));
    }


    //loadSample('Chopin.m4a');

    var BUFFER_SIZE = 1024;

    var node = context.createScriptProcessor(BUFFER_SIZE, 2, 2);

    var samples = new Float32Array(BUFFER_SIZE * 2);
    var midsamples = new Float32Array(BUFFER_SIZE * 2);

    node.onaudioprocess = function (e) {
        var l = e.outputBuffer.getChannelData(0);
        var r = e.outputBuffer.getChannelData(1);
        var framesExtracted = f.extract(samples, BUFFER_SIZE);
        if (framesExtracted == 0) {
            node.disconnect();
        }
        for (var i = 0; i < framesExtracted; i++) {
            l[i] = samples[i * 2];
            r[i] = samples[i * 2 + 1];
        }
    };
    var source1;
    var s1curTime = 0;
    var s1preTime = 0;

    function play() {
        source1 = context.createBufferSource();
        source1.buffer = buffer;
        source1.connect(node);
        node.connect(context.destination);
        s1preTime = context.currentTime;

        source1.start(s1preTime, s1curTime);
    }

    function pause() {
        if (source1) {
            s1curTime += context.currentTime - s1preTime;
            source1.stop();
            source1.disconnect();
            node.disconnect();


        }
    }


    var source0 = {
        extract: function (target, numFrames, position) {
            var l = buffer.getChannelData(0);
            var r = buffer.getChannelData(1);
            for (var i = 0; i < numFrames; i++) {
                target[i * 2] = l[i + position];
                target[i * 2 + 1] = r[i + position];
            }
            return Math.min(numFrames, l.length - position);
        }
    };


    var t = new RateTransposer(true);
    var s = new Stretch(true);
    s.tempo = 1.0;
    t.rate = 1.0;

    var f = flag? new SimpleFilter(source0, t): new SimpleFilter(source0, s);

    var source2 = {
        extract: function (target, numFrames, position) {

            var l = buffer.getChannelData(0);
            var r = buffer.getChannelData(1);
            for (var i = 0; i < numFrames; i++) {
                target[i * 2] = l[i + position];
                target[i * 2 + 1] = r[i + position];
            }
            return Math.min(numFrames, l.length - position);
        }

    };


    this.t = t;
    this.s = s;
    this.n = node;
    this.play = play;
    this.pause = pause;

};
#Bell 

A simple wrapper of the AVFoundation's audio part to provide more convenient
play controlling and volume fade-in/out effect.

It has been used as the audio core of [diumoo](http://diumoo.net)

#Usage

Bell is easy to use:

    // play an url
    [[BellPlayer sharedPlayer] playURL:@"http://url/for/audio/file"];

    // pause
    [[BellPlayer sharedPlayer] pause];

    // play/resume
    [[BellPlayer sharedplayer] play];

BellPlayer will handle audio fade-in/ fade-out effect for you, you can change 
the duration of fading by set the value of `fadingDuration` :

    [Bellplayer sharedplayer].fadingDuration = 3.0;


#License
see `LICENSE`

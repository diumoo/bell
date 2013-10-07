//
//  bellPlayer.m
//  bell
//
//  Created by AnakinGWY on 9/9/13.
//  Copyright (c) 2013 xiuxiude. All rights reserved.
//

#import "BellPlayer.h"
#import <libkern/OSAtomic.h>

static BellPlayer *sharedPlayer;

enum BellFadingState {
    BellNoFadingState = 0,
    BellNewPlayItemFadingOutState = 1,
    BellPauseFadingOutState = 2,
    BellResumeFadingInState = 3,
};

@interface BellPlayer()
{
    NSTimer *_timer;
    AVPlayerItem *_waitingItem;
    int _fadeState;
    float _volume;
}

@property(nonatomic) float realVolume;

extern NSTimeInterval const _timerInterval;

@end

@implementation BellPlayer

NSTimeInterval const _timerInterval = 0.1;

#pragma mark - Initailize and dealloc functions
+ (instancetype)sharedPlayer
{
    if (sharedPlayer == nil) {
        sharedPlayer = [[BellPlayer alloc] init];
    }
    return sharedPlayer;
}

- (id)init
{
    self = [super init];
    if (self) {
        _fadeState = BellNoFadingState;
        _fadingDuration = 1.0;
        _volume = 1;
        
        self.playerItemClass = [AVPlayerItem class];
        
        [self addObserver:self
               forKeyPath:@"rate"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
        
        [self addObserver:self
               forKeyPath:@"currentItem.status"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"rate"];
    [self removeObserver:self forKeyPath:@"currentItem.status"];
}

#pragma mark - Play control functions

- (void)pause
{
    if (self.rate != 0.0 && (OSAtomicCompareAndSwapInt(BellNoFadingState,
                                                       BellPauseFadingOutState,
                                                       &_fadeState))) {
        [self triggerFading];
    }
}

- (void)play
{
    if (self.rate < 0.1 && (OSAtomicCompareAndSwapInt(BellNoFadingState,
                                                      BellResumeFadingInState,
                                                      &_fadeState))) {
        [super play];
        [self triggerFading];
    }
}

- (void)playURL:(NSURL *)url
{
    _waitingItem = [self.playerItemClass playerItemWithURL:url];
    if (_waitingItem == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerFailedPlayItem object:nil];
        return;
    }
    if (self.rate > 0.0) {
        _fadeState = BellNewPlayItemFadingOutState;
        [self triggerFading];
    }
    else {
        [self replaceCurrentItemWithPlayerItem: _waitingItem];
        self.realVolume = 0;
        [self play];
    }
}

#pragma mark - Private functions to handle volume fading in/out

- (void)invalidateTimer
{
    if (_timer) {
        CFRunLoopRemoveTimer(CFRunLoopGetMain(),
                             (__bridge CFRunLoopTimerRef)_timer,
                             kCFRunLoopCommonModes);
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)triggerFading
{
    [self invalidateTimer];
    
    if (_fadingDuration >= _timerInterval) {
        _timer = [NSTimer timerWithTimeInterval:_timerInterval
                                         target:self
                                       selector:@selector(timerPulse:)
                                       userInfo:@{@"state": @(_fadeState)}
                                        repeats:YES];
        CFRunLoopAddTimer(CFRunLoopGetMain(),
                          (__bridge CFRunLoopTimerRef)_timer,
                          kCFRunLoopCommonModes);
        [_timer fire];
    }
    else {
        if (_fadeState != BellResumeFadingInState)
            self.realVolume = 0.0;
        else
            self.realVolume = _volume;
        [self fadingFinishedWithState:_fadeState];
    }
}


- (void)timerPulse:(NSTimer *)sender
{
    NSDictionary *info = sender.userInfo;
    int state = [[info objectForKey:@"state"] intValue];
    float step = _volume * _timerInterval / _fadingDuration;
    if (state != BellResumeFadingInState) {
        if (self.realVolume < step ) {
            self.realVolume = 0.0;
            [self fadingFinishedWithState:state];
        }
        else {
            self.realVolume -= step;
        }
    }
    else {
        if (fabsf(self.realVolume - _volume) <= step ) {
            
            self.realVolume = _volume;
            [self fadingFinishedWithState:state];
        }
        else {
            self.realVolume += step;
        }
    }
}

- (void)fadingFinishedWithState:(int) state
{
    [self invalidateTimer];
    switch (state) {
        case BellPauseFadingOutState:
            [super pause];
            break;
        case BellNewPlayItemFadingOutState:
            [super pause];
            [self replaceCurrentItemWithPlayerItem:_waitingItem];
            self.realVolume = _volume;
            [super play];
            break;
    }
    OSAtomicCompareAndSwapInt(state, BellNoFadingState, &_fadeState);
}

- (float)volume
{
    return _volume;
}

- (void)setVolume:(float)volume
{
    _volume = volume;
    if (_timer==nil) {
        self.realVolume = _volume;
    }
}

- (float)realVolume
{
    return super.volume;
}

- (void)setRealVolume:(float)realVolume
{
    super.volume = realVolume;
}


#pragma mark - Register playerItem class
- (void) setPlayerItemClass:(Class)playerItemClass
{
    if ([playerItemClass isSubclassOfClass:[AVPlayerItem class]]) {
        _playerItemClass = playerItemClass;
    }
    else {
        NSException *exception = [NSException exceptionWithName:@"ClassTypeException"
                                                         reason:@"PlayerItemClass must be subclass of AVPlayerItem"
                                                       userInfo:nil];
        @throw exception;
    }
}

#pragma mark - KVO observing

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.currentItem == nil || self.status == AVPlayerStatusUnknown)
        return;
    
    if ([keyPath isEqualToString:@"rate"]) {
        float rate = self.rate;
        
        Float64 currentTime = CMTimeGetSeconds(self.currentItem.currentTime);
        Float64 duration = CMTimeGetSeconds(self.currentItem.duration);
        
        if (duration <= _timerInterval || isnan(duration))
            return;
        
        if (rate <= 0.01) {
            if (duration - currentTime < 0.5) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerDidEndItem object:self.currentItem];
            }
            else {
                [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerDidPauseItem object:self.currentItem];
            }
        }
        else{
            [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerDidPlayItem object:self.currentItem];
        }
    }
    else if([keyPath isEqualToString:@"currentItem.status"]) {
        switch (self.currentItem.status) {
            case AVPlayerStatusReadyToPlay:
                [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerReadyPlayItem object:self.currentItem];
                break;
            case AVPlayerStatusFailed:
                [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerFailedPlayItem object:self.currentItem.error];
                break;
        }
    }
}

@end

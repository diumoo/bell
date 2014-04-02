//
//  bellPlayer.m
//  bell
//
//  Created by AnakinGWY on 9/9/13.
//  Copyright (c) 2013 xiuxiude. All rights reserved.
//

#import "BellPlayer.h"
#import <libkern/OSAtomic.h>

#pragma mark - BellPlayerItem

@implementation BellPlayerItem
- (id) initWithURL:(NSURL *)URL userInfo:(NSDictionary *)userInfo
{
    self = [super initWithURL:URL];
    if (self) {
        _userInfo = userInfo;
    }
    return self;
}

+ (instancetype)playerItemWithURL:(NSURL *)url userInfo:(NSDictionary *)userInfo
{
    return [[BellPlayerItem alloc] initWithURL:url userInfo:userInfo];
}

@end

#pragma mark - BellPlayer

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
    BellPlayerItem *_waitingItem;
    int _fadeState;
    float _bellVolume;
}

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
        _bellVolume = 1;
        
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
    [self playURL:url userInfo:nil];
}

- (void)playURL:(NSURL *)url userInfo:(NSDictionary *)userInfo
{
    [self startToPlayItem:[BellPlayerItem playerItemWithURL:url userInfo:userInfo]];
    
}

- (void)startToPlayItem:(BellPlayerItem *)playeritem
{
    _waitingItem = playeritem;
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
        self.volume = 0;
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
            self.volume = 0.0;
        else
            self.volume = _bellVolume;
        [self fadingFinishedWithState:_fadeState];
    }
}


- (void)timerPulse:(NSTimer *)sender
{
    NSDictionary *info = sender.userInfo;
    int state = [[info objectForKey:@"state"] intValue];
    float step = _bellVolume * _timerInterval / _fadingDuration;
    if (state != BellResumeFadingInState) {
        if (self.volume < step ) {
            self.volume = 0.0;
            [self fadingFinishedWithState:state];
        }
        else {
            self.volume -= step;
        }
    }
    else {
        if (fabsf(self.volume - _bellVolume) <= step ) {
            
            self.volume = _bellVolume;
            [self fadingFinishedWithState:state];
        }
        else {
            self.volume += step;
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
            self.volume = _bellVolume;
            [super play];
            break;
    }
    OSAtomicCompareAndSwapInt(state, BellNoFadingState, &_fadeState);
}


- (void)setBellVolume:(float)volume
{
    _bellVolume = volume;
    if (_timer==nil) {
        self.volume = _bellVolume;
    }
}


#pragma mark - KVO observing

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.currentItem == nil || self.status == AVPlayerStatusUnknown)
        return;
    
    NSDictionary *userInfo = nil;
    if ([self.currentItem respondsToSelector:@selector(userInfo)]) {
        userInfo = [self.currentItem performSelector:@selector(userInfo)];
    }
    
    if ([keyPath isEqualToString:@"rate"]) {
        float rate = self.rate;
        
        Float64 currentTime = CMTimeGetSeconds(self.currentItem.currentTime);
        Float64 duration = CMTimeGetSeconds(self.currentItem.duration);
        
        if (rate <= 0.01) {
            
            if (duration <= _timerInterval || isnan(duration))
                return;

            if (duration - currentTime < 0.5) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerDidEndItem object:userInfo];
            }
            else {
                [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerDidPauseItem object:userInfo];
            }
        }
        else{
            if (isnan(duration)) return;
            [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerDidPlayItem object:userInfo];
        }
    }
    else if([keyPath isEqualToString:@"currentItem.status"]) {
        switch (self.currentItem.status) {
            case AVPlayerStatusReadyToPlay:
                [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerReadyPlayItem object:userInfo];
                break;
            case AVPlayerStatusFailed:
                [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerFailedPlayItem object:self.currentItem.error];
                break;
        }
    }
}

@end


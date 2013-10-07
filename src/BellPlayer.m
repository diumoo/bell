//
//  bellPlayer.m
//  bell
//
//  Created by AnakinGWY on 9/9/13.
//  Copyright (c) 2013 xiuxiude. All rights reserved.
//

#import "BellPlayer.h"
#import <libkern/OSAtomic.h>

const NSTimeInterval timerInterval=0.1;
static BellPlayer *sharedPlayer;

enum BellFadingState {
  BellNoFadingState = 0,
  BellNewPlayItemFadingOutState = 1,
  BellPauseFadingOutState = 2,
  BellResumeFadingInState = 3,
  };

@interface BellPlayer()
{
  NSTimer *timer;
  AVPlayerItem *waitingItem;
  float volume;
  int fadeState;
}

@property(nonatomic) float realVolume;

@end

@implementation BellPlayer

@synthesize fadingDuration = fadingDuration;


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
    fadeState = BellNoFadingState;
    fadingDuration = 1.0;
    volume = 1;
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
  if (self.rate == 0.0) return;
  if (OSAtomicCompareAndSwapInt(BellNoFadingState,
                                 BellPauseFadingOutState,
                                 &fadeState)) {
    [self triggerFading];
  }
}

- (void)play
{
  if (self.rate > 0.1) return;

  if (OSAtomicCompareAndSwapInt(BellNoFadingState,
                                BellResumeFadingInState,
                                &fadeState)) {
    [super play];
    [self triggerFading];
  }
}

- (void)playURL:(NSURL *)url
{
  
  waitingItem = [self.playerItemClass playerItemWithURL:url];
  if (waitingItem == nil) {
    [self.delegate bellPlayer:self failedToPlayWithPlayItem:nil error:nil];
    return;
  }
  if (self.rate > 0.0) {
    fadeState = BellNewPlayItemFadingOutState;
    [self triggerFading];
  }
  else {
    [super replaceCurrentItemWithPlayerItem: waitingItem];
    self.realVolume = volume;
    [super play];
  }
}

#pragma mark - Private functions to handle volume fading in/out

- (void)invalidateTimer
{
  if (timer) {
    CFRunLoopRemoveTimer(CFRunLoopGetMain(),
                         (__bridge CFRunLoopTimerRef)timer,
                         kCFRunLoopCommonModes);
    [timer invalidate];
    timer = nil;
  }
}

- (void)triggerFading
{
  [self invalidateTimer];
  
  if (fadingDuration >= 0.1) {
    NSDictionary *info = @{@"state": @(fadeState)};
    timer = [NSTimer timerWithTimeInterval:timerInterval
                                    target:self
                                  selector:@selector(timerPulse:)
                                  userInfo:info
                                   repeats:YES];
    CFRunLoopAddTimer(CFRunLoopGetMain(),
                      (__bridge CFRunLoopTimerRef)timer,
                      kCFRunLoopCommonModes);
    [timer fire];
  }
  else {
    if (fadeState != BellResumeFadingInState)
      self.realVolume = 0.0;
    else
      self.realVolume = volume;
    [self fadingFinishedWithState:fadeState];
  }
}

- (float)volume
{
  return volume;
}

- (void)setVolume:(float)v
{
  volume = v;
  if (timer == nil) self.realVolume = v;
}

- (void)timerPulse:(NSTimer *)sender
{
  NSDictionary *info = sender.userInfo;
  int state = [[info objectForKey:@"state"] intValue];
  float step = volume * timerInterval / fadingDuration;
  if (state != BellResumeFadingInState) {
    if (self.realVolume < step) {
      self.realVolume = 0.0;
      [self fadingFinishedWithState:state];
    }
    else {
      self.realVolume -= step;
    }
  }
  else {
    if (fabsf(self.realVolume - volume) <= step) {
      
      self.realVolume = volume;
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
      [super replaceCurrentItemWithPlayerItem:waitingItem];
      self.realVolume = volume;
      [super play];
      break;
  }
  OSAtomicCompareAndSwapInt(state, BellNoFadingState, &fadeState);
}

- (float)realVolume
{
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
  AVPlayerItem *currentItem = self.currentItem;
  NSArray *params = [currentItem audioMix].inputParameters;
  AVAudioMixInputParameters *parameters = nil;
  
  if ([params count])parameters = params[0];
  else return 0.0;
  
  CMTimeRange range = CMTimeRangeMake(self.currentTime, CMTimeMake(0, 0));
  float start;
  float end;
  BOOL ok = [parameters getVolumeRampForTime:self.currentTime
                                 startVolume:&start
                                   endVolume:&end
                                   timeRange:&range];
  if (ok)
    return start;
  else
    return end;

#else
  return super.volume;
#endif
}

- (void)setRealVolume:(float) v
{
  
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
  AVPlayerItem *currentItem = self.currentItem;
  AVAsset *asset = currentItem.asset;
  NSMutableArray *allAudioParams = [NSMutableArray array];
  for (AVAssetTrack *track in [asset tracksWithMediaType:AVMediaTypeAudio]) {
    AVMutableAudioMixInputParameters *audioInputParams = nil;
    audioInputParams = [AVMutableAudioMixInputParameters audioMixInputParameters];
    [audioInputParams setVolume:v atTime:kCMTimeZero];
    [audioInputParams setTrackID:[track trackID]];
    [allAudioParams addObject:audioInputParams];
  }
  
  AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
  [audioMix setInputParameters:allAudioParams];
  [currentItem setAudioMix:audioMix];
#else
  super.volume = v;
#endif
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
  if (self.currentItem == nil || self.status == AVPlayerStatusUnknown) return;
  
  if ([keyPath isEqualToString:@"rate"]) {
    float rate = self.rate;
    
    Float64 currentTime = CMTimeGetSeconds(self.currentItem.currentTime);
    Float64 duration = CMTimeGetSeconds(self.currentItem.duration);
    
    if (duration <= 0.1 || isnan(duration)) return;
    if (rate <= 0.01) {
      if (duration - currentTime < 0.5) {
        [self.delegate bellPlayer:self didEndWithPlayItem:self.currentItem];
      }
      else {
        [self.delegate bellPlayer:self didPauseWithPlayItem:self.currentItem];
      }
    }
    else{
      [self.delegate bellPlayer:self didPlayWithPlayItem:self.currentItem];
    }
  }
  else if([keyPath  isEqualToString:@"currentItem.status"]) {
    switch (self.currentItem.status) {
      case AVPlayerStatusReadyToPlay:
        [self.delegate bellPlayer:self readyToPlayWithPlayItem:self.currentItem];
        break;
      case AVPlayerStatusFailed:
        [self.delegate bellPlayer:self
         failedToPlayWithPlayItem:self.currentItem
         error:self.currentItem.error];
        break;
    }
  }
}

@end

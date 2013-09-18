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
  }
  return self;
}

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
  waitingItem = [AVPlayerItem playerItemWithURL:url];
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
#if defined(TARGET_OS_IPHONE) || defined (TARGET_IPHONE_SIMULATOR)
  AVPlayerItem *currentItem = self.currentItem;
  NSArray *params = [currentItem audioMix].inputParameters;
  AVAudioMixInputParameters *parameters = params[0];
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
  
#if defined(TARGET_OS_IPHONE) || defined (TARGET_IPHONE_SIMULATOR)
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

@end

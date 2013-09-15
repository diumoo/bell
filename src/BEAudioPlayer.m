//
//  BEAudioPlayer.m
//  BellMacDemo
//
//  Created by Chase Zhang on 9/13/13.
//  Copyright (c) 2013 diumoo. All rights reserved.
//

#import "BEAudioPlayer.h"

@interface BEAudioPlayer()

@property(nonatomic) AVAudioPlayer *player;
@property(nonatomic) NSTimer *timer;

@end

@implementation BEAudioPlayer

@synthesize volume = _volume;

- (id) init
{
  self = [super init];
  if (self) {
    _volume = 1.0;
    self.fadeInOutTimeInterval = 1.0;
  }
  return self;
}

- (void)playContentsOfURL:(NSString *)url
{
  
}

- (void)pause
{

}

- (void)resume
{

}

@end

//
//  BEAudioPlayer.h
//  BellMacDemo
//
//  Created by Chase Zhang on 9/13/13.
//  Copyright (c) 2013 diumoo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class BEAudioPlayer;

@protocol BEAudioPlayerDelegate <NSObject>

- (void)playerDidStartToPlay:(BEAudioPlayer *)player;
- (void)playerDidPause:(BEAudioPlayer *)player;
- (void)playerDidStop:(BEAudioPlayer *)player;
- (void)playerDidResume:(BEAudioPlayer *)player;
- (void)playerDidFinishPlaying:(BEAudioPlayer *)player;

@end


@interface BEAudioPlayer : NSObject

@property(nonatomic) NSTimeInterval fadeInOutTimeInterval;
@property(nonatomic) float volume;
@property(weak) id<BEAudioPlayerDelegate> delegate;

- (void)pause;
- (void)resume;

@end



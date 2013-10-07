//
//  bellPlayer.h
//  bell
//
//  Created by AnakinGWY on 9/9/13.
//  Copyright (c) 2013 xiuxiude. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>


@class BellPlayer;

@protocol BellPlayerDelegate <NSObject>

@optional
- (void)bellPlayer:(BellPlayer *)player didPlayWithPlayItem:(AVPlayerItem *)playItem;
- (void)bellPlayer:(BellPlayer *)player didPauseWithPlayItem:(AVPlayerItem *)playItem;
- (void)bellPlayer:(BellPlayer *)player didEndWithPlayItem:(AVPlayerItem *)playItem;

- (void)bellPlayer:(BellPlayer *)player readyToPlayWithPlayItem:(AVPlayerItem *)playItem;
- (void)bellPlayer:(BellPlayer *)player failedToPlayWithPlayItem:(AVPlayerItem *)playItem error:(NSError *) error;

@end

@interface BellPlayer : AVPlayer

@property(weak, nonatomic) Class playerItemClass;
@property(weak, nonatomic) id<BellPlayerDelegate> delegate;
@property(nonatomic) NSTimeInterval fadingDuration;
@property(nonatomic) float volume;


+ (instancetype)sharedPlayer;
- (void)playURL:(NSURL *) url;

@end

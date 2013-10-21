//
//  bellPlayer.h
//  bell
//
//  Created by AnakinGWY on 9/9/13.
//  Copyright (c) 2013 xiuxiude. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>


#define kPlayerDidPlayItem @"player_played"
#define kPlayerDidPauseItem @"player_paused"
#define kPlayerDidEndItem @"player_end"

#define kPlayerReadyPlayItem @"player_ready"
#define kPlayerFailedPlayItem @"player_failed"


@interface BellPlayerItem : AVPlayerItem
@property(nonatomic, readonly) NSDictionary *userInfo;
+ (instancetype)playerItemWithURL:(NSURL *)url userInfo:(NSDictionary *)userInfo;
@end

@interface BellPlayer : AVPlayer

// Should be atomic, prevent change fading duration at the same time
@property(atomic) NSTimeInterval fadingDuration;
@property(nonatomic) float bellVolume; // the volume value when the real volume fading stopped

+ (instancetype)sharedPlayer;
- (void)playURL:(NSURL *) url;
- (void)playURL:(NSURL *) url userInfo:(NSDictionary *)userInfo;
- (void)startToPlayItem:(BellPlayerItem *)playeritem;

@end

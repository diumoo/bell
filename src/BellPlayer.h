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

@class BellPlayer;

@interface BellPlayer : AVPlayer

// Should be atomic, prevent change fading duration at the same time
@property(atomic) NSTimeInterval fadingDuration;


+ (instancetype)sharedPlayer;
- (void)playURL:(NSURL *) url;
- (void)playURL:(NSURL *) url userInfo:(NSDictionary *)userInfo;

@end

//
//  bellPlayer.h
//  bell
//
//  Created by AnakinGWY on 9/9/13.
//  Copyright (c) 2013 xiuxiude. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface BellPlayer : AVPlayer

@property (strong) AVPlayer *playerCore;
@property (atomic, weak) AVPlayerItem *currentItem;

// Create a shared player core for all
+(id) sharedPlayer;

@end

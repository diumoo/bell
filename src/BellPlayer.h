//
//  bellPlayer.h
//  bell
//
//  Created by AnakinGWY on 9/9/13.
//  Copyright (c) 2013 xiuxiude. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface BellPlayer : AVPlayer

@property(nonatomic) NSTimeInterval fadingDuration;
@property(nonatomic) float volume;

+ (instancetype)sharedPlayer;
- (void)playURL:(NSURL *) url;

@end

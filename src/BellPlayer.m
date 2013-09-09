//
//  bellPlayer.m
//  bell
//
//  Created by AnakinGWY on 9/9/13.
//  Copyright (c) 2013 xiuxiude. All rights reserved.
//

#import "bellPlayer.h"

static BellPlayer *sharedPlayer;

@implementation BellPlayer
@synthesize playerCore=_playerCore;


+(id) sharedPlayer
{
    if (sharedPlayer == nil) {
        sharedPlayer = [[BellPlayer alloc] init];
    }
    return sharedPlayer;
}

-(id) init
{
    self = [super init];
    if (self) {
        _playerCore = [[AVPlayer alloc] init];
    }
    return self;
}

@end

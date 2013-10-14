//
//  BellAppDelegate.m
//  BellDemo
//
//  Created by Chase Zhang on 9/16/13.
//  Copyright (c) 2013 diumoo. All rights reserved.
//

#import "BellAppDelegate.h"

@implementation BellAppDelegate

@synthesize window, audioUrlField, fadingDuration, volume, volumeText;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bellPlayerDidPlayWithPlayItem:) name:kPlayerDidPlayItem
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bellPlayerDidEndWithPlayItem:) name:kPlayerDidEndItem
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bellPlayerDidPauseWithPlayItem:) name:kPlayerDidPauseItem
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bellPlayerFailedToPlayWithPlayItem:) name:kPlayerFailedPlayItem
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bellPlayerReadyToPlayWithPlayItem:) name:kPlayerReadyPlayItem
                                               object:nil];
    
    
    self.volume = [NSNumber numberWithDouble:1.0];
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSNumber *) fadingDuration
{
    return @([BellPlayer sharedPlayer].fadingDuration);
}

- (void) setFadingDuration:(NSNumber *)fadingTimeDuration
{
    [BellPlayer sharedPlayer].fadingDuration = [fadingTimeDuration doubleValue];
}

- (NSNumber *) volume
{
    return @([BellPlayer sharedPlayer].bellVolume);
}

- (void) setVolume:(NSNumber *)targetVolume
{
    BellPlayer *player = [BellPlayer sharedPlayer];
    player.bellVolume = [targetVolume doubleValue];
    volumeText.stringValue = [NSString stringWithFormat:@"%f",player.bellVolume*100];
    NSLog(@"player volume = %f",player.bellVolume);
}

- (void) buttonAction:(id)sender
{
    BellPlayer *player = [BellPlayer sharedPlayer];
    switch ([sender tag]) {
        case 0:
            [player playURL:[NSURL URLWithString:self.audioUrlField.stringValue]];
            break;
        case 1:
            [player play];
            break;
        case 2 :
            [player pause];
        default:
            break;
    }
}

- (void)bellPlayerDidPlayWithPlayItem:(NSNotification *)aNotification
{
    NSLog(@"Did play with %@", aNotification.userInfo);
}

- (void)bellPlayerDidPauseWithPlayItem:(NSNotification *)aNotification
{
    NSLog(@"Did pause with %@", aNotification.userInfo);
}

- (void)bellPlayerDidEndWithPlayItem:(NSNotification *)aNotification
{
    NSLog(@"Did end with %@", aNotification.userInfo);
}

- (void)bellPlayerFailedToPlayWithPlayItem:(NSNotification *)aNotification
{
    NSLog(@"Failed to play with error %@", aNotification.userInfo);
}

- (void)bellPlayerReadyToPlayWithPlayItem:(NSNotification *)aNotification
{
    NSLog(@"Ready to play %@", aNotification);
}

@end

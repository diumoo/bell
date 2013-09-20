//
//  BellDemoController.m
//  BellDemo
//
//  Created by Chase Zhang on 9/18/13.
//  Copyright (c) 2013 diumoo. All rights reserved.
//

#import "BellDemoController.h"
#import "BellPlayer.h"

@implementation BellDemoController

- (void)awakeFromNib
{
  [BellPlayer sharedPlayer].delegate = self;
  [self updateValueDisplay];
}

- (void)updateValueDisplay
{
  BellPlayer *player = [BellPlayer sharedPlayer];
  self.durationLabel.text = [NSString stringWithFormat:@"%.1f", player.fadingDuration];
  self.volumeLabel.text = [NSString stringWithFormat:@"%.1f", player.volume];
}

- (void) playAction:(id)sender
{
  switch ([sender tag]) {
    case 0:
    {
      NSString *urlString = self.audioUrlField.text;
      NSURL *url = [NSURL URLWithString:urlString];
      [[BellPlayer sharedPlayer] playURL:url];
    }
      break;
    case 1:
      [[BellPlayer sharedPlayer] play];
      break;
    case 2 :
      [[BellPlayer sharedPlayer] pause];
      break;
    case 3:
      [BellPlayer sharedPlayer].volume = [(UISlider *)sender value];
      [self updateValueDisplay];
      break;
    case 4:
      [BellPlayer sharedPlayer].fadingDuration = [(UISlider *)sender value];
      [self updateValueDisplay];
      break;
  }
}

- (void)bellPlayer:(BellPlayer *)player didPlayWithPlayItem:(AVPlayerItem *)playItem
{
  NSLog(@"%@ did play with %@", player, playItem);
}

- (void)bellPlayer:(BellPlayer *)player didPauseWithPlayItem:(AVPlayerItem *)playItem
{
  NSLog(@"%@ did pause with %@", player, playItem);
}

- (void)bellPlayer:(BellPlayer *)player didEndWithPlayItem:(AVPlayerItem *)playItem
{
  NSLog(@"%@ did end with %@", player, playItem);
}

- (void)bellPlayer:(BellPlayer *)player failedToPlayWithPlayItem:(AVPlayerItem *)playItem error:(NSError *)error
{
  NSLog(@"%@ failed to play %@ with error %@", player, playItem, error);
}

- (void)bellPlayer:(BellPlayer *)player readyToPlayWithPlayItem:(AVPlayerItem *)playItem
{
  NSLog(@"%@ ready to play %@", player, playItem);
}

@end

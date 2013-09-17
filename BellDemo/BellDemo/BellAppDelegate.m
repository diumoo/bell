//
//  BellAppDelegate.m
//  BellDemo
//
//  Created by Chase Zhang on 9/16/13.
//  Copyright (c) 2013 diumoo. All rights reserved.
//

#import "BellAppDelegate.h"
#import "BellPlayer.h"

@implementation BellAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  
}

- (NSNumber *) fadingTimeDuration
{
  return @([BellPlayer sharedPlayer].fadingTimeDuration);
}

- (void) setFadingTimeDuration:(NSNumber *)fadingTimeDuration
{
  [BellPlayer sharedPlayer].fadingTimeDuration = [fadingTimeDuration doubleValue];
}

- (void) buttonAction:(id)sender
{
  switch ([sender tag]) {
    case 0:
    {
      NSString *urlString = self.audioUrlField.stringValue;
      NSURL *url = [NSURL URLWithString:urlString];
      [[BellPlayer sharedPlayer] playURL:url];
    }
      break;
    case 1:
      [[BellPlayer sharedPlayer] play];
      break;
    case 2 :
      [[BellPlayer sharedPlayer] pause];
    default:
      break;
  }
}

@end

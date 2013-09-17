//
//  BellAppDelegate.h
//  BellDemo
//
//  Created by Chase Zhang on 9/16/13.
//  Copyright (c) 2013 diumoo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BellPlayer;

@interface BellAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *audioUrlField;
@property (nonatomic) NSNumber *fadingTimeDuration;

- (IBAction)buttonAction:(id)sender;

@end

//
//  BellAppDelegate.h
//  BellDemo
//
//  Created by Chase Zhang on 9/16/13.
//  Copyright (c) 2013 diumoo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BellPlayer.h"

@interface BellAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *audioUrlField;
@property (assign) IBOutlet NSTextField *volumeText;
@property (atomic) NSNumber *fadingDuration;
@property (atomic) NSNumber *volume;

- (IBAction)buttonAction:(id)sender;

@end

//
//  BellDemoController.h
//  BellDemo
//
//  Created by Chase Zhang on 9/18/13.
//  Copyright (c) 2013 diumoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BellPlayer.h"

@interface BellDemoController : NSObject

@property(nonatomic, weak) IBOutlet UITextField *audioUrlField;

@property(weak) IBOutlet UILabel *volumeLabel;
@property(weak) IBOutlet UILabel *durationLabel;

- (IBAction)playAction:(id)sender;

@end

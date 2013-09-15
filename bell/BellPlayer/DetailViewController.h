//
//  DetailViewController.h
//  BellPlayer
//
//  Created by AnakinGWY on 9/15/13.
//  Copyright (c) 2013 xiuxiude. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end

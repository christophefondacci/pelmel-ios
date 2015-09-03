//
//  PMLMessageAudienceTableViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 31/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Place.h"
@interface PMLMessageAudienceTableViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UILabel *reachLabel;
@property (weak, nonatomic) IBOutlet UILabel *reachValueLabel;
@property (weak, nonatomic) IBOutlet UITextView *infoLabel;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;


@property (nonatomic,retain) Place *place;
@end

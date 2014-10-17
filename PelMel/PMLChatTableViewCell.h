//
//  PMLChatTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 26/09/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLChatTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *chatImageView;
@property (weak, nonatomic) IBOutlet UITextView *chatTextView;

@end

//
//  PMLAddTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 20/10/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PMLAddTableViewCell;

@protocol PMLAddModifyDelegate
-(void)addTapped:(PMLAddTableViewCell*)sourceCell;
-(void)modifyTapped:(PMLAddTableViewCell*)sourceCell;
@end

@interface PMLAddTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UIButton *addButtonIcon;
@property (weak, nonatomic) IBOutlet UIButton *modifyButton;
@property (weak, nonatomic) IBOutlet UIButton *modifyButtonIcon;

// The delegate for add/modify callback actions
@property (nonatomic,weak) NSObject<PMLAddModifyDelegate> *delegate;
@end

//
//  ClosableBoxView.h
//  togayther
//
//  Created by Christophe Fondacci on 17/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ClosableBoxView;

@protocol ClosableBoxDelegate <NSObject>

- (void)closeableButtonTapped:(ClosableBoxView*)source;

@end


@interface ClosableBoxView : UIView
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *closableViewButton;
@property (weak, nonatomic) IBOutlet UILabel *reviewsCountLabel;
@property (nonatomic) id<ClosableBoxDelegate> delegate;
@end

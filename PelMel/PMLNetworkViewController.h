//
//  PMLNetworkViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 15/07/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    PMLNetworkTabNoTab,
    PMLNetworkTabMyNetwork,
    PMLNetworkTabCheckins
}PMLNetworkTab;

@interface PMLNetworkViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *mainContainerView;
@property (weak, nonatomic) IBOutlet UIView *tabContainerView;
@property (weak, nonatomic) IBOutlet UIButton *networkTab;
@property (weak, nonatomic) IBOutlet UIButton *checkinsTab;

@end

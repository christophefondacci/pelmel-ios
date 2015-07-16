//
//  PMLNetworkViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 15/07/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLNetworkViewController.h"
#import "PMLPhotosCollectionViewController.h"
#import "PMLPrivateNetworkPhotoProvider.h"
#import "PMLNetworkCheckinsTableViewController.h"
#import "TogaytherService.h"
#import "MKNumberBadgeView.h"

@interface PMLNetworkViewController ()

@property (nonatomic,retain) UIService *uiService;
@property (nonatomic) PMLNetworkTab activeTab;
@property (nonatomic,retain) PMLPhotosCollectionViewController *networkController;
@property (nonatomic,retain) PMLNetworkCheckinsTableViewController *checkinsController;
@property (nonatomic,retain) MKNumberBadgeView *networkBadgeView;
@property (nonatomic,retain) MKNumberBadgeView *checkinsBadgeView;
@end

@implementation PMLNetworkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Service init
    _uiService = [TogaytherService uiService];
    
    self.title = NSLocalizedString(@"grid.title.privateNetwork", @"grid.title.privateNetwork");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mnuIconClose"] style:UIBarButtonItemStylePlain target:self action:@selector(closeMenu:)];
    
    // Preparing main view for network tab
    _networkController = (PMLPhotosCollectionViewController*)[_uiService instantiateViewController:SB_ID_PHOTOS_COLLECTION];
    PMLPrivateNetworkPhotoProvider *provider = [[PMLPrivateNetworkPhotoProvider alloc] init];
    _networkController.provider = provider;
    
    // Preparing main controller for checkins tab
    _checkinsController = (PMLNetworkCheckinsTableViewController*)[_uiService instantiateViewController:SB_ID_NETWORK_CHECKINS];
    
    // Wiring actions
    [self.networkTab addTarget:self action:@selector(networkTabTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.checkinsTab addTarget:self action:@selector(checkinsTabTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // Badging
    _networkBadgeView = [[MKNumberBadgeView alloc] init];
    CGRect frame = _networkTab.frame;
    _networkBadgeView.frame = CGRectMake(frame.size.width-30, frame.size.height/2-10, 30, 10);
    _networkBadgeView.font = [UIFont fontWithName:PML_FONT_BADGES size:10];
    _networkBadgeView.shadow = NO;
    _networkBadgeView.shine=NO;
    _networkBadgeView.hidden=YES;
    [_networkTab addSubview:_networkBadgeView];

    _checkinsBadgeView = [[MKNumberBadgeView alloc] init];
    frame = _checkinsTab.frame;
    _checkinsBadgeView.frame = CGRectMake(frame.size.width-30, frame.size.height/2-10, 30, 20);
    _checkinsBadgeView.font = [UIFont fontWithName:PML_FONT_BADGES size:10];
    _checkinsBadgeView.shadow = NO;
    _checkinsBadgeView.shine=NO;
    _checkinsBadgeView.hidden=YES;
    [_checkinsTab addSubview:_checkinsBadgeView];
    
    [self setActiveTab:PMLNetworkTabMyNetwork];
    
    // Registering for notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushNotificationReceived:) name:PML_NOTIFICATION_PUSH_RECEIVED object:nil];
    [self updateData];

    // Do any additional setup after loading the view.
}

- (void)updateData {
    [[TogaytherService userService] privateNetworkListWithSuccess:^(id obj) {
        CurrentUser *user = [[TogaytherService userService] getCurrentUser];
        _networkBadgeView.value = user.networkPendingApprovals.count;
        _networkBadgeView.hidden =user.networkPendingApprovals.count<=0;
        
        NSInteger checkinsCount = 0;
        for(User *networkUser in user.networkUsers) {
            if(networkUser.lastLocation!=nil) {
                checkinsCount++;
            }
        }
        _checkinsBadgeView.value = checkinsCount;
        _checkinsBadgeView.hidden =checkinsCount<=0;
        [_networkController updateData];
        [_checkinsController updateData];
    } failure:^(id obj) {
        [[TogaytherService uiService] alertError];
    }];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
-(void)setActiveTab:(PMLNetworkTab)activeTab {
    if(_activeTab != activeTab) {
        _activeTab = activeTab;
        
        NSString *networkTabImg;
        NSString *checkinsTabImg;
        switch(activeTab) {
            case PMLNetworkTabMyNetwork:
                networkTabImg=@"bgTab";
                checkinsTabImg=@"bgTabDisabled";
                [self activateViewController:_networkController];
                break;
            case PMLNetworkTabCheckins:
                networkTabImg=@"bgTabDisabled";
                checkinsTabImg=@"bgTab";
                [self activateViewController:_checkinsController];
                break;
            default:
                break;
        }
        
        
        [self.networkTab setBackgroundImage:[UIImage imageNamed:networkTabImg] forState:UIControlStateNormal];
        [self.checkinsTab setBackgroundImage:[UIImage imageNamed:checkinsTabImg] forState:UIControlStateNormal];
    }
    
}
-(void)removeViewController:(UIViewController*)controller {
    [controller willMoveToParentViewController:nil];
    [controller.view removeFromSuperview];
    [controller removeFromParentViewController];
}
-(void)activateViewController:(UIViewController*)controller {

    // Clearing everything
    [self removeViewController:_networkController];
    [self removeViewController:_checkinsController];
    
    // Preparing integration of sub controller
    [controller willMoveToParentViewController:self];
    [self addChildViewController:controller];
    UIView *networkView = controller.view;
    [networkView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    // Autolayout constraint (fit the container)
    [self.mainContainerView addSubview:networkView];
    [self.mainContainerView addConstraints:[NSLayoutConstraint
                                            constraintsWithVisualFormat:@"H:|-0-[networkView]-0-|"
                                            options:NSLayoutFormatDirectionLeadingToTrailing
                                            metrics:nil
                                            views:NSDictionaryOfVariableBindings(networkView)]];
    [self.mainContainerView addConstraints:[NSLayoutConstraint
                                            constraintsWithVisualFormat:@"V:|-0-[networkView]-0-|"
                                            options:NSLayoutFormatDirectionLeadingToTrailing
                                            metrics:nil
                                            views:NSDictionaryOfVariableBindings(networkView)]];
    
    [controller didMoveToParentViewController:self];
}
#pragma mark - Actions callback
-(void)networkTabTapped:(id)sender {
    [self setActiveTab:PMLNetworkTabMyNetwork];
}
-(void)checkinsTabTapped:(id)sender {
    [self setActiveTab:PMLNetworkTabCheckins];
}
-(void)closeMenu:(id)sender {
    [_uiService presentSnippetFor:nil opened:NO root:YES];
}

#pragma mark - Push notifications
-(void)pushNotificationReceived:(NSNotification*)notification {
    [self updateData];
}
@end

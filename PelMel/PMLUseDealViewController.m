//
//  PMLUseDealViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 18/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLUseDealViewController.h"
#import "TogaytherService.h"
#import "PMLDeal.h"
#import <PBWebViewController.h>

#define kPhaseAlphaDuration 1.0
#define kPhaseAngleDuration 2.0

#define kSuccessAnimationDuration 0.5

#define kCircleDefaultSize 200.0

#define kDealPressMinTime 2.0

@interface PMLUseDealViewController ()

@property (nonatomic) NSInteger phaseCount;
@property (nonatomic) NSInteger animationPhase;
@property (nonatomic,retain) NSArray *phaseAlpha;
@property (nonatomic,retain) NSArray *phaseViews;
@property (nonatomic,retain) NSTimer *pressTimer;
@property (nonatomic) NSInteger pressTimerCountdown;
@property (nonatomic) BOOL canProceedWithDeal;
@property (nonatomic) BOOL viewDisappeared;
@end

@implementation PMLUseDealViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [TogaytherService applyCommonLookAndFeel:self];
            self.edgesForExtendedLayout = UIRectEdgeAll;
    [self.navigationController setNavigationBarHidden:NO];
//    [self.navigationController.navigationBar setBarTintColor:UIColorFromRGB(0xf4eeee)];
//    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:1]];
//    [self.navigationController.navigationItem.leftBarButtonItem setTintColor:[UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:1]];
//    [self.navigationController.navigationBar
//     setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:PML_FONT_DEFAULT size:19.0], NSForegroundColorAttributeName : [UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:1]}];
//
//    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:PML_FONT_DEFAULT size:19.0], NSForegroundColorAttributeName : [UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:1]} forState:UIControlStateNormal];
//    [self.navigationController.navigationBar
//     setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:PML_FONT_DEFAULT size:19.0], NSForegroundColorAttributeName : [UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:1]}];
//    [self.navigationController.navigationBar setTranslucent:NO];
    
    
    // Wiring button actions
    [self.dealButton addTarget:self action:@selector(didStartDealTap:) forControlEvents:UIControlEventTouchDown];
    [self.dealButton addTarget:self action:@selector(didEndDealTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.reportProblemButton addTarget:self action:@selector(didTapReport:) forControlEvents:UIControlEventTouchUpInside];
}
-(void)viewDidDisappear:(BOOL)animated {
    self.viewDisappeared = YES;
}
- (void)viewDidAppear:(BOOL)animated {
    self.viewDisappeared = NO;
    self.title = ((Place*)self.deal.relatedObject).title;
    _phaseViews = @[_circleExternalImage,_circleCenterImage,_circleBackgroundImage];
    _phaseAlpha = @[@0,@0,@0];
    _phaseCount = 3;
    
    _circleExternalImage.alpha = 1.0;
    _circleCenterImage.alpha = 0;
    _circleBackgroundImage.alpha = 0;
    
    // Do any additional setup after loading the view.
    //    [self animateAlphaPhase:0 delay:0.0];
    [self animateAlphaPhase:1 delay:0.3];
    [self animateAlphaPhase:2 delay:0.6];
    
    [self animateAnglePhase:0 delay:0.0];
    [self animateAnglePhase:1 delay:1.0];
    [self animateAnglePhase:2 delay:2.0];
    
    CurrentUser *user = [[TogaytherService userService] getCurrentUser];
    CALImage *image = [[TogaytherService imageService] imageOrPlaceholderFor:user allowAdditions:NO];
    [[TogaytherService imageService] load:image to:self.userThumbImage thumb:NO];
    self.userNicknameLabel.text = user.pseudo;
    
    
    NSString *template = NSLocalizedString(@"deal.use.legal",@"deal.use.legal");
    self.legalLabel.text = [NSString stringWithFormat:template, self.title];
    [self refreshPresentLabel];
    self.dealCountLabel.text = nil;
    
    // Deal title
    NSString *dealTypeCode = [NSString stringWithFormat:@"deal.type.%@",self.deal.dealType];
    NSString *dealType = NSLocalizedString(dealTypeCode,dealTypeCode);
    self.dealLabel.text = dealType;
    
    // Buttons
    [self.reportProblemButton setTitle:NSLocalizedString(@"deal.button.problem",@"deal.button.problem") forState:UIControlStateNormal];
    [self.helpButton setTitle:NSLocalizedString(@"deal.button.whatsthis",@"deal.button.whatsthis") forState:UIControlStateNormal];

}
-(void)animateAlphaPhase:(NSInteger)phase delay:(CGFloat)delay {
    [UIView animateWithDuration:(kPhaseAlphaDuration-delay) delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
        UIView *view = [_phaseViews objectAtIndex:phase];
        view.alpha = (view.alpha == 1 ? 0.8 : 1);
    } completion:^(BOOL finished) {
        if(!self.viewDisappeared) {
            [self animateAlphaPhase:phase delay:delay];
        }
    }];
}
-(void)animateAnglePhase:(NSInteger)phase delay:(CGFloat)delay {
    [UIView animateWithDuration:(kPhaseAngleDuration-delay) delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
        UIView *view = [_phaseViews objectAtIndex:phase];
        view.layer.affineTransform = CGAffineTransformMakeRotation(M_PI_4*rand());
    } completion:^(BOOL finished) {
        if(!self.viewDisappeared) {
            [self animateAnglePhase:phase delay:delay];
        }
    }];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)didStartDealTap:(UIButton*)button {
    self.greenOverlay.hidden = NO;
    self.greenOverlay.alpha = 0;
    self.greenOverlay.backgroundColor = UIColorFromRGB(0xA1E3BB);
    self.dealCountLabel.text = nil;
    self.canProceedWithDeal = NO;
    [self.pressTimer invalidate];
    self.pressTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(dealCountdown) userInfo:nil repeats:YES];
    self.pressTimerCountdown = kDealPressMinTime;
    [self refreshCountdown];
    [UIView animateWithDuration:kDealPressMinTime delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.greenOverlay.alpha = 0.9;
    } completion:NULL];

    [self resizeCircles:kCircleDefaultSize+60 duration:kDealPressMinTime/4];

}
-(void)resizeCircles:(CGFloat)size duration:(NSTimeInterval)duration {
    self.circleWidthConstraint.constant = size;
    self.circleHeightConstraint.constant = size;
    [self.view setNeedsUpdateConstraints];
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        [self.view layoutIfNeeded];
    } completion:NULL];
}
-(void)refreshCountdown {
    NSString *template = NSLocalizedString(@"deal.use.countdown",@"deal.use.countdown");
    NSString *countdownLabel = [NSString stringWithFormat:template,self.pressTimerCountdown];
    self.presentLabel.text = countdownLabel;
}
-(void)refreshPresentLabel {
    self.presentLabel.text = NSLocalizedString(@"deal.present", @"Present to bartender");
}
-(void)didEndDealTap:(UIButton*)button {
    [self.pressTimer invalidate];
    if(self.canProceedWithDeal) {

    } else {
        NSLog(@"Too short");
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.greenOverlay.alpha=0;
        } completion:NULL];
        [self refreshPresentLabel];
        [self resizeCircles:kCircleDefaultSize duration:0.1];
    }
}
-(void)didTapReport:(UIButton*)reportButton {
    [[TogaytherService dealsService] reportDealProblem:self.deal onSuccess:^(id obj) {
        [[TogaytherService uiService] alertWithTitle:@"deal.report.title" text:@"deal.report.text"];
    } onFailure:^(NSInteger errorCode, NSString *errorMessage) {
        [[TogaytherService uiService] alertError];
    }];
}
-(void)dealCountdown {
    self.pressTimerCountdown--;
    if(self.pressTimerCountdown>0) {
        [self refreshCountdown];
    } else {
        self.canProceedWithDeal = YES;
        [self proceedWithDeal];
        [self.pressTimer invalidate];
    }
}
-(void)proceedWithDeal {
    NSLog(@"Can Proceed");
    self.presentLabel.text=NSLocalizedString(@"deal.activation.message", @"deal.activation.message");
    [[TogaytherService dealsService] useDeal:self.deal onSuccess:^(id obj) {
        PMLDeal *deal = (PMLDeal*)obj;
        self.presentLabel.text = NSLocalizedString(@"deal.proceed",@"Proceed with the deal");
        self.dealCountLabel.text = [NSString stringWithFormat:@"# %d",(int)deal.usedToday+1];
        [self resizeCircles:1 duration:kSuccessAnimationDuration];
    } onFailure:^(NSInteger errorCode, PMLDeal *deal, NSString *userMessage) {
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.greenOverlay.backgroundColor = UIColorFromRGBAlpha(0xff0000, 0.7f);
        } completion:NULL];
        [self resizeCircles:1 duration:kSuccessAnimationDuration];
        self.presentLabel.text = userMessage;
//        [[TogaytherService uiService] alertError];
    }];
}
- (IBAction)didTapDealHelp:(id)sender {
    PBWebViewController *webviewController= [[PBWebViewController alloc] init];
    NSString *server = [TogaytherService propertyFor:PML_PROP_SERVER];
    NSString *url = [NSString stringWithFormat:@"%@/deal-help", server];
    webviewController.URL = [[NSURL alloc] initWithString:url];
//    [TogaytherService applyCommonLookAndFeel:self];
    [self.navigationController pushViewController:webviewController animated:YES];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

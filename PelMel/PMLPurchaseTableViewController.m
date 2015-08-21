//
//  PMLPurchaseTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 11/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLPurchaseTableViewController.h"
#import "PMLImagedTitleTableViewCell.h"
#import "PMLButtonTableViewCell.h"
#import "PMLTextViewTableViewCell.h"
#import "TogaytherService.h"
#import <MBProgressHUD.h>
#define kSectionCount 1

#define kSectionFeatures 0
#define kRowFeatureHeader 0
#define kRowFeatureIntro 1
#define kRowFeatureListOffset 2

#define kCellIdButton @"purchaseButtonCell"


@interface PMLPurchaseTableViewController ()

@end

@implementation PMLPurchaseTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.separatorColor = [UIColor clearColor];
//    [self.tableView registerNib:[UINib nibWithNibName:@"PMLButtonTableViewCell" bundle:nil] forCellReuseIdentifier:kCellIdButton];

    self.view.backgroundColor = UIColorFromRGB(0x141A2F);
    self.tableView.backgroundColor = UIColorFromRGB(0x141A2F);
    self.tableView.opaque=YES;
    self.tableView.separatorColor = UIColorFromRGB(0x141A2F);
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    
    self.view.layer.cornerRadius = 5;
    self.view.layer.masksToBounds=YES;
    self.view.layer.borderWidth=2;
    self.view.layer.borderColor = UIColorFromRGB(0xe0e0e1).CGColor;
    
    [[TogaytherService storeService] loadProducts:@[kPMLProductClaim30]];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purchaseSuccess:) name:PML_NOTIFICATION_PAYMENT_DONE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purchaseFailed:) name:PML_NOTIFICATION_PAYMENT_FAILED object:nil];
}
- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return kSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 4+[_provider featuresCount];
}

-(NSString*)rowIdForIndexPath:(NSIndexPath*)indexPath {
    NSString *rowId = nil;
    switch(indexPath.section) {
        case kSectionFeatures:
            if(indexPath.row==kRowFeatureHeader) {
                rowId = @"headerCell";
            } else if(indexPath.row == kRowFeatureIntro) {
                rowId = @"introCell";
            } else if(indexPath.row == [self tableView:self.tableView numberOfRowsInSection:indexPath.section]-2) {
                rowId = kCellIdButton;
            } else if(indexPath.row == [self tableView:self.tableView numberOfRowsInSection:indexPath.section]-1) {
                rowId = @"termsCell";
            } else {
                rowId = @"featureCell";
            }
    }
    return rowId;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // Dequeueing cell
    NSString *rowId = [self rowIdForIndexPath:indexPath];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:rowId forIndexPath:indexPath];
    
    // Formatting cell
    if(indexPath.row==kRowFeatureHeader) {
        [self configureHeaderCell:(PMLImagedTitleTableViewCell*)cell];
    } else if(indexPath.row == kRowFeatureIntro) {
        [self configureIntroCell:(PMLImagedTitleTableViewCell*)cell];
    } else if(indexPath.row == [self tableView:self.tableView numberOfRowsInSection:indexPath.section]-2) {
        [self configurePurchaseCell:(PMLButtonTableViewCell*)cell];
    } else if(indexPath.row == [self tableView:self.tableView numberOfRowsInSection:indexPath.section]-1) {
        [self configureTermsCell:(PMLTextViewTableViewCell*)cell];
    } else {
        [self configureFeatureCell:(PMLImagedTitleTableViewCell*)cell atIndex:indexPath.row];
    }

    
    return cell;
}

-(void)configureHeaderCell:(PMLImagedTitleTableViewCell*)cell {
    cell.titleLabel.text = [_provider headerFirstLine];
    cell.subtitleLabel.text = [_provider headerSecondLine];
}
-(void)configureIntroCell:(PMLImagedTitleTableViewCell*)cell {
    cell.titleLabel.text = [_provider featureIntroLabel];
}
-(void)configurePurchaseCell:(PMLButtonTableViewCell*)cell {
    [cell.button setTitle:[_provider purchaseButtonLabel] forState:UIControlStateNormal];
    [cell.button addTarget:self action:@selector(purchaseTapped) forControlEvents:UIControlEventTouchUpInside];
//    cell.buttonLabel.text = [_provider purchaseButtonLabel];
//    cell.buttonImageView.image = [_provider purchaseButtonIcon];
//    cell.backgroundColor = [UIColor clearColor];
}

-(void)configureFeatureCell:(PMLImagedTitleTableViewCell*)cell atIndex:(NSInteger)index {
    cell.titleLabel.text = [_provider featureLabelAtIndex:index-kRowFeatureListOffset];
    cell.titleImage.image = [_provider featureIconAtIndex:index-kRowFeatureListOffset];
    cell.widthTitleConstraint.constant = [cell.titleLabel sizeThatFits:CGSizeMake(MAXFLOAT, cell.titleLabel.bounds.size.height)].width;
}
- (void)configureTermsCell:(PMLTextViewTableViewCell*)cell {
    cell.textView.text = NSLocalizedString(@"purchase.claim.terms",@"Terms");
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.section) {
        case kSectionFeatures:
            switch(indexPath.row) {
                case kRowFeatureHeader:
                    return 86;
                case kRowFeatureIntro:
                    return 44;
                default:
                    if(indexPath.row == [self tableView:self.tableView numberOfRowsInSection:indexPath.section]-2) {
                        return 95;
                    } else if(indexPath.row == [self tableView:self.tableView numberOfRowsInSection:indexPath.section]-1) {
                        UITextView *templateView = [[UITextView alloc] init];
                        templateView.text =NSLocalizedString(@"purchase.claim.terms",@"Terms");
                        return [templateView sizeThatFits:CGSizeMake(self.tableView.bounds.size.width-10,MAXFLOAT)].height;
                    } else {
                        return 32;
                    }
            }
    }
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.section) {
        case kSectionFeatures:
            if(indexPath.row == [self tableView:self.tableView numberOfRowsInSection:indexPath.section]-2) {
                [self purchaseTapped];
            }
            break;
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
-(void)purchaseTapped {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = NSLocalizedString(@"banner.store.payment.inprogress",@"banner.store.payment.inprogress");
    [hud show:YES];
    [_provider didTapPurchaseButton];
}
- (void)purchaseSuccess:(NSNotification*)notification {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [self dismissViewControllerAnimated:YES completion:NULL];
}
- (void)purchaseFailed:(NSNotification*)notification {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}
@end

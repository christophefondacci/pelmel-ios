//
//  PMLMessageAudienceTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 31/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLMessageAudienceTableViewController.h"
#import "TogaytherService.h"
#import <MBProgressHUD.h>

@interface PMLMessageAudienceTableViewController ()

@end

@implementation PMLMessageAudienceTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Look'n feel
    [TogaytherService applyCommonLookAndFeel:self];
    self.tableView.backgroundColor = BACKGROUND_COLOR;
    self.tableView.opaque=YES;
    self.tableView.separatorColor = BACKGROUND_COLOR;
    self.navigationController.view.layer.cornerRadius = 10;
    self.navigationController.view.layer.masksToBounds = YES;
    self.title = NSLocalizedString(@"msgAudience.title", @"msgAudience.title");
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mnuIconClose"] style:UIBarButtonItemStylePlain target:self action:@selector(cancelTapped:)];
    [self refresh];
}
-(void)refresh {
    self.reachLabel.text = NSLocalizedString(@"msgAudience.reach",@"msgAudience.reach");
    self.infoLabel.text = NSLocalizedString(@"msgAudience.info", @"msgAudience.info");
    self.infoLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:14];
    self.infoLabel.textColor = [UIColor whiteColor];
    self.reachValueLabel.text = NSLocalizedString(@"msgAudience.reach.computing", @"msgAudience.reach.computing");
    [self.sendButton setTitle:NSLocalizedString(@"msgAudience.send", @"msgAudience.send") forState:UIControlStateNormal];
    [self.sendButton addTarget:self action:@selector(didTapSendMessage:) forControlEvents:UIControlEventTouchUpInside];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = NSLocalizedString(@"msgAudience.reach.computing", @"msgAudience.reach.computing");
    [hud show:YES];
    
    [[TogaytherService getMessageService] countAudienceOf:self.place onSuccess:^(NSInteger usersReachedCount,NSDate *nextAnnouncementDate) {
        NSString *reachText = [[TogaytherService uiService] localizedString:@"msgAudience.reachValue" forCount:usersReachedCount];
        self.reachValueLabel.text = reachText;
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    } onFailure:^(BOOL isOwnershipError, NSDate *nextAnnouncementDate, NSInteger usersReached) {
        NSString *reachText = [[TogaytherService uiService] localizedString:@"msgAudience.reachValue" forCount:usersReached];
        self.reachValueLabel.text = reachText;
        if(isOwnershipError) {
            [[TogaytherService uiService] alertWithTitle:@"msgAudience.ownershipError.title" text:@"msgAudience.ownershipError"];
            [self dismissViewControllerAnimated:YES completion:NULL];
        } else if(nextAnnouncementDate != nil) {
            NSString *delay = [[[TogaytherService uiService] delayStringFrom:nextAnnouncementDate] lowercaseString];
            NSString *template = NSLocalizedString(@"msgAudience.delayError", @"msgAudience.delayError");
            self.infoLabel.text = [NSString stringWithFormat:template,delay];
        }
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 4;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

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
- (void) cancelTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}
-(void)didTapSendMessage:(id)sender {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = NSLocalizedString(@"msgAudience.sending", @"msgAudience.sending");
    [[TogaytherService getMessageService] messageAudienceOf:self.place message:self.messageTextView.text onSuccess:^(NSInteger usersReachedCount, NSDate *nextAnnouncementDate) {
        [self dismissViewControllerAnimated:YES completion:NULL];
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [[TogaytherService uiService] alertWithTitle:@"msgAudience.successTitle" text:@"msgAudience.success"];
        
    } onFailure:^(BOOL ownershipError, NSDate *nextAnnouncementDate, NSInteger usersReachedCount) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [[TogaytherService uiService] alertError];
        [self refresh];
    }];
}
@end

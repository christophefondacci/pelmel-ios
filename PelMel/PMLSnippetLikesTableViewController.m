//
//  PMLSnippetLikesTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 08/10/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLSnippetLikesTableViewController.h"
#import "Activity.h"
#import "TogaytherService.h"
#import "PMLSnippetLikeTableViewCell.h"
#import "PMLSnippetTableViewController.h"
#import "PMLInfoProvider.h"

#define kSectionsCount 1

@interface PMLSnippetLikesTableViewController ()

@end

@implementation PMLSnippetLikesTableViewController {
    ImageService *_imageService;
    UIService *_uiService;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor =UIColorFromRGB(0x272a2e);
    self.tableView.backgroundColor =  UIColorFromRGB(0x272a2e);
    self.tableView.separatorColor = [UIColor clearColor];
    
    _imageService = [TogaytherService imageService];
    _uiService = [TogaytherService uiService];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
- (void)viewDidAppear:(BOOL)animated {
    [self.view layoutIfNeeded];
    [self.tableView reloadData];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return kSectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.activities.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PMLSnippetLikeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"likeCell" forIndexPath:indexPath];
    
    Activity *activity = [self.activities objectAtIndex:indexPath.row];
    
    CALObject *activityObject = [self activityObjectFor:activity];
    NSObject<PMLInfoProvider> *provider = [_uiService infoProviderFor:activityObject];
    
    cell.imageView.layer.cornerRadius = 25;
    cell.imageView.layer.masksToBounds = YES;
    NSLog(@"W=%d / H=%d",(int)cell.imageView.frame.size.width,(int)cell.imageView.frame.size.height );
    cell.imageView.layer.borderColor = [[provider color] CGColor];
    CALImage *calImage = [_imageService imageOrPlaceholderFor:activityObject allowAdditions:NO];
    [_imageService load:calImage to:cell.imageView thumb:YES];
    cell.nameLabel.text = [provider title];
    NSString *delay = [_uiService delayStringFrom:activity.activityDate];
    cell.timeLabel.text = delay;
    
    return cell;
}

- (CALObject*)activityObjectFor:(Activity*)activity {
    CALObject *activityObject ;
    if(_likeMode) {
        activityObject = activity.activityObject;
    } else {
        activityObject = activity.user;
    }
    return activityObject;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Activity *activity = [self.activities objectAtIndex:indexPath.row];
    
    CALObject *activityObject = [self activityObjectFor:activity];
    PMLSnippetTableViewController *controller = (PMLSnippetTableViewController*)[_uiService instantiateViewController:SB_ID_SNIPPET_CONTROLLER];
    controller.snippetItem = activityObject;
    [self.parentMenuController.navigationController pushViewController:controller animated:YES ];
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}
#pragma mark - Data setup
- (void)setActivities:(NSArray *)activities {
    _activities = activities;
    [self.tableView reloadData];
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

@end

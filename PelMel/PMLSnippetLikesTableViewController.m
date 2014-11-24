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
#import "PMLTextTableViewCell.h"
#import "PMLSnippetTableViewController.h"
#import "PMLInfoProvider.h"

#define kSectionsCount 2
#define kSectionNoResult 0
#define kSectionLikes 1

@interface PMLSnippetLikesTableViewController ()

@end

@implementation PMLSnippetLikesTableViewController {
    ImageService *_imageService;
    UIService *_uiService;
    BOOL _loading;
    
    int _heightNoLike;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor =UIColorFromRGB(0x272a2e);
    self.tableView.backgroundColor =  UIColorFromRGB(0x272a2e);
    self.tableView.separatorColor = [UIColor clearColor];
    
    _heightNoLike = -1;
    
    _imageService = [TogaytherService imageService];
    _uiService = [TogaytherService uiService];
    
}
-(void)viewWillAppear:(BOOL)animated {
    if(self.activities==nil) {
        _loading = YES;
    } else {
        _loading = NO;
    }
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
    switch(section) {
        case kSectionNoResult:
            return !_loading && self.activities.count == 0 ? 1 : 0;
        case kSectionLikes:
            return _loading ? 1 : self.activities.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellId;
    switch (indexPath.section) {
        case kSectionNoResult:
            cellId = @"noLikeCell";
            break;
        default:
            cellId = _loading ? @"loadCell" :@"likeCell";
            break;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    cell.backgroundColor = UIColorFromRGB(0x272a2e);
    switch(indexPath.section) {
        case kSectionLikes:
            if(_loading) {
                [self configureRowLoading:(PMLTextTableViewCell*)cell];
            } else {
                [self configureRowLikes:(PMLSnippetLikeTableViewCell*)cell forIndex:indexPath.row];
            }
            break;
        case kSectionNoResult:
            [self configureRowNoResult:(PMLSnippetLikeTableViewCell*)cell];
            break;
    }
    return cell;
}

-(void) configureRowLikes:(PMLSnippetLikeTableViewCell*)cell forIndex:(NSInteger)row {
    Activity *activity = [self.activities objectAtIndex:row];
    
    CALObject *activityObject = [self activityObjectFor:activity];
    NSObject<PMLInfoProvider> *provider = [_uiService infoProviderFor:activityObject];
    
    cell.imageView.layer.cornerRadius = 25;
    cell.imageView.layer.masksToBounds = YES;
    cell.imageView.image = [CALImage getDefaultUserThumb];
    NSLog(@"W=%d / H=%d",(int)cell.imageView.frame.size.width,(int)cell.imageView.frame.size.height );
    cell.imageView.layer.borderColor = [[provider color] CGColor];
    CALImage *calImage = [_imageService imageOrPlaceholderFor:activityObject allowAdditions:NO];
    [_imageService load:calImage to:cell.imageView thumb:YES];
    cell.nameLabel.text = [provider title];
    NSString *delay = [_uiService delayStringFrom:activity.activityDate];
    cell.timeLabel.text = delay;
}

-(void) configureRowNoResult:(PMLSnippetLikeTableViewCell*)cell {
    cell.nameLabel.text = NSLocalizedString(@"likes.list.noResult", @"likes.list.noResult");
    cell.thumbImageView.image = [UIImage imageNamed:@"snpIconLike"];
    CGSize size = [cell.nameLabel sizeThatFits:CGSizeMake(self.view.frame.size.width-52,FLT_MAX)];
    cell.widthConstraint.constant=self.view.frame.size.width-52;
    cell.heightConstraint.constant = size.height+1;

}

-(void)configureRowLoading:(PMLTextTableViewCell*)cell {
    cell.cellTextLabel.text = NSLocalizedString(@"likes.list.loading", @"likes.list.loading");
    CGSize size = [cell.cellTextLabel sizeThatFits:CGSizeMake(self.view.frame.size.width-82,FLT_MAX)];
    cell.textHeightConstraint.constant = size.height;
    cell.textWidthConstraint.constant=self.view.frame.size.width-82;
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
    switch(indexPath.section) {
        case kSectionNoResult: {
            PMLSnippetLikeTableViewCell  *cell = [self.tableView dequeueReusableCellWithIdentifier:@"noLikeCell"];
            cell.nameLabel.text = NSLocalizedString(@"likes.list.noResult", @"likes.list.noResult");
            CGSize size = [cell.nameLabel sizeThatFits:CGSizeMake(self.view.frame.size.width-52,FLT_MAX)];
            return MAX(60,size.height+1+5);

        }
    }
    return 60;
}
#pragma mark - Data setup
- (void)setActivities:(NSArray *)activities {
    _loading = NO;
    _activities = activities;
    [self.tableView reloadData];
}

@end

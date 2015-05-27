//
//  PMLBannerListTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 22/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLBannerListTableViewController.h"
#import "TogaytherService.h"
#import "PMLBannerViewTableViewCell.h"
#import "PMLBannerMapTableViewCell.h"

#define kSectionCount 1
#define kSectionBanners 0

#define kRowIdBanner @"bannerCell"
#define kRowIdMap @"mapCell"

@interface PMLBannerListTableViewController ()
@property (nonatomic,retain) NSArray *banners;
@property (nonatomic) BOOL mapVisible;
@property (nonatomic) NSInteger mapIndex;
@property (nonatomic,retain) DataService *dataService;
@property (nonatomic,retain) ImageService *imageService;
@property (nonatomic,retain) NSDateFormatter *dateFormatter;
@end

@implementation PMLBannerListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Service init
    self.dataService = [TogaytherService dataService];
    self.imageService = [TogaytherService imageService];
    
    // Look'n feel
    [TogaytherService applyCommonLookAndFeel:self];
    self.tableView.backgroundColor = UIColorFromRGB(0x272a2e);
    self.tableView.opaque=YES;
    self.tableView.separatorColor = UIColorFromRGB(0x272a2e);
    
    // Vars init
    self.mapVisible = NO;
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    // Loading data
    [self.dataService listBanners:^(NSArray *banners) {
        self.banners = banners;
        [self.tableView reloadData];
    } onFailure:^(NSInteger errorCode, NSString *errorMessage) {
        [[TogaytherService uiService] alertError];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return kSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.banners.count + (self.mapVisible ? 1 : 0);
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellId = (self.mapVisible && self.mapIndex == indexPath.row) ? kRowIdMap : kRowIdBanner;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    
    if([cellId isEqualToString:kRowIdBanner]){
        [self configureRowBanner:(PMLBannerViewTableViewCell*)cell forIndex:indexPath.row];
    } else {
        [self configureRowMap:(PMLBannerMapTableViewCell*)cell forIndex:indexPath.row];
    }
    // Configure the cell...
    
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 110;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.mapVisible) {
        if(indexPath.row == self.mapIndex-1) {
            self.mapVisible = NO;
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.mapIndex inSection:kSectionBanners]] withRowAnimation:UITableViewRowAnimationAutomatic];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.mapIndex-1 inSection:kSectionBanners]];
            [cell setSelected:NO animated:YES];
        } else {
            // Delta to add to map index after the delete / insert phase
//            NSInteger delta = (self.mapIndex < indexPath.row) ? -1 : 0;
//            self.mapIndex = indexPath.row + delta;
//            [self.tableView reloadData];
            
            
            
            NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:self.mapIndex inSection:kSectionBanners];
            NSInteger mapRow = indexPath.row;
            if(oldIndexPath == nil || oldIndexPath.row>indexPath.row ) {
                mapRow ++;
            }
            self.mapIndex = mapRow;
            
            // Inserting picker
            // Deleting any previous picker
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[oldIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.mapIndex inSection:kSectionBanners]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        }
    } else {
        self.mapVisible=YES;
        self.mapIndex = indexPath.row+1;
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.mapIndex inSection:kSectionBanners]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}
- (void)configureRowBanner:(PMLBannerViewTableViewCell*)cell forIndex:(NSInteger)row {
    
    NSInteger bannerIndex = row;
    if(self.mapVisible && self.mapIndex<row) {
        bannerIndex--;
    }
    
    // Setting up banner information into cell
    PMLBanner *banner = [self.banners objectAtIndex:bannerIndex];
    cell.bannerImageView.image = nil;
    [self.imageService load:banner.mainImage to:cell.bannerImageView thumb:NO];
    cell.startDateLabel.text = [self.dateFormatter stringFromDate:banner.startDate];
    cell.startedOnLabel.text = NSLocalizedString(@"banner.list.startDateLabel", @"banner.list.startDateLabel");
    cell.usageLabel.text = NSLocalizedString(@"banner.list.usage", @"Usage");
    cell.usageCounterLabel.text = [NSString stringWithFormat:@"%d / %d", (int)banner.displayCount,(int)banner.targetDisplayCount ];
    
    // Buttons
    cell.playButton.tag = bannerIndex;
    cell.pauseButton.tag = bannerIndex;
    if([banner.status isEqualToString:kPMLBannerStatusReady]) {
        cell.playButton.alpha = 0.4;
        cell.pauseButton.alpha= 1;
        [cell.playButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
        [cell.pauseButton addTarget:self action:@selector(pauseTapped:) forControlEvents:UIControlEventTouchUpInside];
    } else if([banner.status isEqualToString:kPMLBannerStatusPendingPayment]) {
        cell.usageCounterLabel.text = NSLocalizedString(@"banner.list.pending", @"banner.list.pending");
        cell.pauseButton.alpha=0.4;
        cell.playButton.alpha=1;
        [cell.pauseButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
        [cell.playButton addTarget:self action:@selector(resumePaymentTapped:) forControlEvents:UIControlEventTouchUpInside];
    } else if([banner.status isEqualToString:kPMLBannerStatusPaused]) {
        cell.pauseButton.alpha=0.4;
        cell.playButton.alpha=1;
        [cell.pauseButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
        [cell.playButton addTarget:self action:@selector(resumeBannerDisplayTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    
}
- (void)configureRowMap:(PMLBannerMapTableViewCell*)cell forIndex:(NSInteger)row {
    PMLBanner *banner = [self.banners objectAtIndex:row];
    [cell setBanner:banner];
    
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

#pragma mark - Action callbacks
- (void)pauseTapped:(UIButton*)sender {
    [self updateStatus:kPMLBannerStatusPaused forIndex:sender.tag];
}

-(void)resumePaymentTapped:(UIButton*)sender {
    
}

-(void)resumeBannerDisplayTapped:(UIButton*)sender {
    [self updateStatus:kPMLBannerStatusReady forIndex:sender.tag];
}

-(void)updateStatus:(NSString*)status forIndex:(NSInteger)index {
    PMLBanner *banner = [self.banners objectAtIndex:index];
    [self.dataService updateBanner:banner withStatus:status onSuccess:^(PMLBanner *newBanner) {
        // Should be the same object, but just in case
        banner.status =newBanner.status;
        [self.tableView reloadData];
    } onFailure:^(NSInteger errorCode, NSString *errorMessage) {
        [[TogaytherService uiService] alertError];
    }];
}

@end

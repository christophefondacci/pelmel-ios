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
#import <MBProgressHUD.h>
#import "PMLButtonTableViewCell.h"

#define kSectionCount 2
#define kSectionButton 0
#define kSectionBanners 1

#define kRowIdBanner @"bannerCell"
#define kRowIdMap @"mapCell"
#define kRowIdButton @"addBanner"

@interface PMLBannerListTableViewController ()
@property (nonatomic,retain) NSMutableArray *banners;
//@property (nonatomic) BOOL mapVisible;
//@property (nonatomic) NSInteger mapIndex;
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
    self.title = NSLocalizedString(@"banner.list.title", @"banner.list.title");
    // Vars init
//    self.mapVisible = NO;
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    // Registering button cell
    [self.tableView registerNib:[UINib nibWithNibName:@"PMLButtonTableViewCell" bundle:nil] forCellReuseIdentifier:kRowIdButton];

}
- (void)viewWillAppear:(BOOL)animated {
    // Loading data
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = NSLocalizedString(@"banner.loading", @"Loading");
    [hud show:YES];
    [self.dataService listBanners:^(NSArray *banners) {
        self.banners = [banners mutableCopy];
        [self.tableView reloadData];
        [hud hide:YES];
    } onFailure:^(NSInteger errorCode, NSString *errorMessage) {
        [hud hide:YES];
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
    switch(section) {
        case kSectionBanners:
            return self.banners.count;
        case kSectionButton:
            return 1;
    }
    return 0;
}

-(BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == kSectionButton;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.section) {
        case kSectionButton:
            [[TogaytherService actionManager] execute:PMLActionTypeAddPlaceBanner onObject:nil];
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellId = indexPath.section == kSectionBanners ? kRowIdBanner : kRowIdButton;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    cell.backgroundColor = BACKGROUND_COLOR;
    switch(indexPath.section) {
        case kSectionBanners:
            [self configureRowBanner:(PMLBannerViewTableViewCell*)cell forIndex:indexPath.row];
            break;
        case kSectionButton:
            [self configureRowButton:(PMLButtonTableViewCell*)cell];
            break;
    }

    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.section) {
        case kSectionButton:
            return 62;
        default:
            return 288;
    }

}
- (void)configureRowButton:(PMLButtonTableViewCell*)cell {
    cell.buttonImageView.image = [UIImage imageNamed:@"btnAddBanner"];
    cell.buttonLabel.text = NSLocalizedString(@"banner.button.addPlaceBanner", @"banner.button.addPlaceBanner");
    cell.buttonContainer.backgroundColor = [UIColor clearColor];

}
- (void)configureRowBanner:(PMLBannerViewTableViewCell*)cell forIndex:(NSInteger)bannerIndex {
    
    // Setting up banner information into cell
    PMLBanner *banner = [self.banners objectAtIndex:bannerIndex];
    cell.bannerImageView.image = nil;
    [self.imageService load:banner.mainImage to:cell.bannerImageView thumb:NO];
    cell.startDateLabel.text = [self.dateFormatter stringFromDate:banner.startDate];
    cell.startedOnLabel.text = NSLocalizedString(@"banner.list.startDateLabel", @"banner.list.startDateLabel");
    cell.usageLabel.text = NSLocalizedString(@"banner.list.usage", @"Usage");
    cell.usageCounterLabel.text = [NSString stringWithFormat:@"%d / %d", (int)banner.displayCount,(int)banner.targetDisplayCount ];
    
    // Setting up banner link / target object name
    if(banner.targetObject != nil) {
        id<PMLInfoProvider> provider = [[TogaytherService uiService] infoProviderFor:banner.targetObject];
        cell.targetLinkLabel.text = [provider title];
    } else {
        cell.targetLinkLabel.text = banner.targetUrl;
    }
    [cell setBanner:banner];
    
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

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


-(PMLBanner*)bannerFromIndexPath:(NSIndexPath*)indexPath {
    NSInteger row = indexPath.row;
//    if(self.mapVisible && self.mapIndex<indexPath.row) {
//        row--;
//    }
    return [self.banners objectAtIndex:row];
}
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        PMLBanner *banner = [self bannerFromIndexPath:indexPath];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        [hud show:YES];
        [_dataService updateBanner:banner withStatus:kPMLBannerStatusDeleted onSuccess:^(PMLBanner *banner) {
            [self.banners removeObject:banner];
            // Delete the row from the data source
            @try {
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            } @catch(NSException *e) {
                [tableView reloadData];
            }
            [hud hide:YES];
        } onFailure:^(NSInteger errorCode, NSString *errorMessage) {
            NSLog(@"DeleteBannerFailed: %@", errorMessage);
            [[TogaytherService uiService] alertError];
            [hud hide:YES];
        }];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


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
    PMLBanner *banner = [self.banners objectAtIndex:sender.tag];
    [[TogaytherService actionManager] execute:PMLActionTypeEditBanner onObject:banner];
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

//
//  PMLPlacesTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 19/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLItemSelectionTableViewController.h"
#import "TogaytherService.h"

#define kPMLRowId @"placeOrEvent"

#define kSectionsCount 1
#define kSectionList 0

@interface PMLItemSelectionTableViewController ()

@property (nonatomic,retain) UIService *uiService;
@property (nonatomic,retain) ConversionService *conversionService;
@property (nonatomic,retain) NSArray *items;

@end

@implementation PMLItemSelectionTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Service initialization
    self.uiService = [TogaytherService uiService];
    self.conversionService = [TogaytherService getConversionService];
    
    // Common look and feel
    [TogaytherService applyCommonLookAndFeel:self];
    self.tableView.backgroundColor = UIColorFromRGB(0x272a2e);
    self.tableView.opaque=YES;
    self.tableView.separatorColor = UIColorFromRGB(0x272a2e);
    
    // Navbar button
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelTapped:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mnuIconClose"] style:UIBarButtonItemStylePlain target:self action:@selector(cancelTapped:)];
    if(self.navigationController != _uiService.menuManagerController.navigationController) {
        self.navigationController.view.layer.cornerRadius = 10;
        self.navigationController.view.layer.masksToBounds = YES;
    }
    
    // Building title
    if(self.titleKey == nil) {
        NSString *titleKey;
        switch(self.targetType) {
            case PMLTargetTypePlace:
                titleKey = @"selector.title.place";
                break;
            case PMLTargetTypeEvent:
                titleKey = @"selector.title.event";
                break;
            default:
                titleKey=nil;
        }
        self.titleKey = titleKey;
    }
    self.title = NSLocalizedString(self.titleKey,titleKey);

    // Registering rows
    [self.tableView registerNib:[UINib nibWithNibName:@"PMLEventTableViewCell" bundle:nil] forCellReuseIdentifier:kPMLRowId];
    
    // Snapshotting content
    if(self.targetType == PMLTargetTypePlace) {
        self.items = [[[[TogaytherService dataService] modelHolder] places] copy];
        [self sortAndFilterItems];
        if(self.items.count == 0) {
            [_uiService alertWithTitle:@"checkin.noplace.title" text:@"checkin.noplace"];
            [self dismissViewControllerAnimated:YES completion:NULL];
        }
    } else if(self.targetType == PMLTargetTypeEvent) {
        self.items = [[[[TogaytherService dataService] modelHolder] events] copy];
    }
    
}
-(void)sortAndFilterItems {
    if(self.filterStrategy == PMLSortStrategyNearby) {
        NSMutableArray *filteredItems = [[NSMutableArray alloc] init];
        for(CALObject *item in self.items) {
            if([self.conversionService numericDistanceTo:item] <= PML_CHECKIN_DISTANCE) {
                [filteredItems addObject:item];
            }
        }
        self.items = filteredItems;
    }
    self.items = [self.items sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Place *p1 = (Place*)obj1;
        Place *p2 = (Place*)obj2;
        switch(self.sortStrategy) {
            case PMLSortStrategyName:
                return [p1.title compare:p2.title];
            case PMLSortStrategyNearby: {
                CLLocationDistance d1 = [[TogaytherService getConversionService] numericDistanceTo:p1];
                CLLocationDistance d2 = [[TogaytherService getConversionService] numericDistanceTo:p2];
                return d1>d2 ? NSOrderedDescending : NSOrderedAscending;
            }
            default:
                return NSOrderedAscending;
        }
    }];
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
    return self.items.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PMLEventTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPMLRowId forIndexPath:indexPath];
    cell.backgroundColor = UIColorFromRGB(0x272a2e);
    //
    CALObject *item = [self.items objectAtIndex:indexPath.row];
    switch(self.targetType) {
        case PMLTargetTypePlace:
            [_uiService configureRowPlace:cell place:(Place*)item];
            break;
        case PMLTargetTypeEvent:
            [_uiService configureRowOvEvents:cell forEvent:(Event*)item usingInfoProvider:[_uiService infoProviderFor:item]];
            break;
        default:
            break;
    }
    // Configure the cell...
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CALObject *item = [self.items objectAtIndex: indexPath.row];
    if(self.delegate != nil) {
        if([self.delegate itemSelected:item]) {
            [self dismissViewControllerAnimated:YES completion:NULL];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 144;
}

#pragma mark - Actions
-(void)cancelTapped:(id)source {
    [self dismissViewControllerAnimated:YES completion:NULL];
}
@end

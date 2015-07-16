//
//  PMLNetworkCheckinsTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 15/07/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLNetworkCheckinsTableViewController.h"
#import "TogaytherService.h"
#import "ItemsThumbPreviewProvider.h"
#import "PMLThumbCollectionViewController.h"

#define kSectionCount 1
#define kSectionCheckins 0

#define kRowIdPlace @"place"
#define kRowCheckinsHeight 144

@interface PMLNetworkCheckinsTableViewController ()

@property (nonatomic,retain) NSMutableDictionary *usersPlaceKeyMap;
@property (nonatomic,retain) NSMutableArray *places;
@property (nonatomic,retain) UserService *userService;
@property (nonatomic,retain) UIService *uiService;

@property (nonatomic,retain) NSMutableDictionary *thumbControllersMap;
@end

@implementation PMLNetworkCheckinsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Service init
    _userService = [TogaytherService userService];
    _uiService = [TogaytherService uiService];
    
    // Initializing data
    _thumbControllersMap = [[NSMutableDictionary alloc] init];
    [self updateData];
    
    // Appearance
    self.tableView.backgroundColor = BACKGROUND_COLOR;
    self.tableView.opaque=YES;
    self.tableView.separatorColor = BACKGROUND_COLOR;
    
    // Registering row
    [self.tableView registerNib:[UINib nibWithNibName:@"PMLEventTableViewCell" bundle:nil] forCellReuseIdentifier:kRowIdPlace];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)updateData {
    
    // (Re)initializing structures
    _usersPlaceKeyMap = [[NSMutableDictionary alloc] init];
    _places = [[NSMutableArray alloc] init];
    
    // Processing users
    NSArray *networkUsers = [[_userService getCurrentUser] networkUsers];
    for(User *user in networkUsers) {
        if(user.lastLocation != nil) {
            
            // Getting any pre-existing entry
            NSMutableArray *usersInPlace = [_usersPlaceKeyMap objectForKey:user.lastLocation.key];
            
            // Initializing if needed
            if(usersInPlace == nil) {
                usersInPlace = [[NSMutableArray alloc] init];
                [_usersPlaceKeyMap setObject:usersInPlace forKey:user.lastLocation.key];
                [_places addObject:user.lastLocation];
            }
            
            // Adding our user to the list
            [usersInPlace addObject:user];
        }
    }
    
    // Sorting places array by number of users
    [_places sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Place *p1 = (Place*)obj1;
        Place *p2 = (Place*)obj2;
        
        NSInteger p1Size = [[_usersPlaceKeyMap objectForKey:p1.key] count];
        NSInteger p2Size = [[_usersPlaceKeyMap objectForKey:p2.key] count];
        if(p1Size>p2Size) {
            return NSOrderedAscending;
        } else if(p1Size == p2Size) {
            return NSOrderedSame;
        } else {
            return NSOrderedDescending;
        }
    }];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch(section) {
        case kSectionCheckins:
            return _places.count;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kRowIdPlace forIndexPath:indexPath];
    
    switch(indexPath.section) {
        case kSectionCheckins:
            [self configureRowCheckins:(PMLEventTableViewCell*)cell forIndexPath:indexPath];
            break;
    }

    // Configure the cell...
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.section) {
        case kSectionCheckins:
            return kRowCheckinsHeight;
    }
    return 0;
}
-(PMLThumbCollectionViewController*)controllerForCell:(PMLEventTableViewCell*)cell {
    
    // Controllers are stored by their pointer in a map
    NSString * cellKey = [NSString stringWithFormat:@"%p",cell];
    
    // Retrieving stored controller
    PMLThumbCollectionViewController *controller = [_thumbControllersMap objectForKey:cellKey];
    
    // If not found
    if(controller == nil) {
        
        // We instantiate a new one
        controller = (PMLThumbCollectionViewController*)[_uiService instantiateViewController:@"thumbCollectionCtrl"];
        
        // And store it at the address of the cell
        [_thumbControllersMap setObject:controller forKey:cellKey];
    } else {
        [controller willMoveToParentViewController:nil];
        [controller.view removeFromSuperview];
        [controller removeFromParentViewController];
    }
    return controller;
}
-(void)configureRowCheckins:(PMLEventTableViewCell*)cell forIndexPath:(NSIndexPath*)indexPath {
    cell.backgroundColor = BACKGROUND_COLOR;
    // Retrieving place object
    Place *place = [_places objectAtIndex:indexPath.row];
    
    // Configuring cell
    [_uiService configureRowPlace:cell place:place];
    
    // Getting checked in users
    NSArray *users = [_usersPlaceKeyMap objectForKey:place.key];
    ItemsThumbPreviewProvider *provider = [[ItemsThumbPreviewProvider alloc] initWithParent:place items:users moreSegueId:nil labelKey:nil icon:nil];
    
    PMLThumbCollectionViewController *controller = [self controllerForCell:cell];
    if(provider != nil) {
        [self addChildViewController:controller];
        controller.view.frame = cell.usersContainerView.bounds;
        [cell.usersContainerView addSubview:controller.view];
        cell.usersContainerView.hidden=NO;
        cell.usersContainerView.backgroundColor = UIColorFromRGB(0x31363a);
        [controller didMoveToParentViewController:self];
        
        controller.actionDelegate=self;
        controller.size = @50;
        [controller setThumbProvider:provider];

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
#pragma mark - PMLThumbsCollectionViewActionDelegate
- (void)thumbsTableView:(PMLThumbCollectionViewController *)thumbsController thumbTapped:(int)thumbIndex forThumbType:(PMLThumbType)type {
    
}
@end
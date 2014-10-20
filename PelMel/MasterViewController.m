//
//  MasterViewController.m
//  nativeTest
//
//  Created by Christophe Fondacci on 20/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "MasterViewController.h"
#import "UITablePlaceViewCell.h"
#import "Place.h"
#import "DetailViewController.h"
#import "TogaytherService.h"
#import "MapViewController.h"
#import "UITableSearchViewCell.h"
#import "UITableSegmentViewCell.h"
#import "UITableNoResultViewCell.h"
#import "MessageViewController.h"
#import "TogaytherTabBarController.h"
#import "CityMasterProvider.h"
#import "City.h"
#import "UIColor+Expanded.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <QuartzCore/QuartzCore.h>

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) //1
#define kImgFormat @"%@.png"

#define kSectionSearch 2
#define kSectionResults 0
#define kSectionCities 1
//#define kSectionMessages 1

#define kSectionsCount 1

#define kSearchIndex 0
#define kSortIndex 1
#define kMessageIndex 2

#define kSortTypePopularity 0
#define kSortTypeDistance 1
#define kSortTypeName 2

@implementation MasterViewController {
    NSMutableArray *_objects;
    NSMutableSet *pendingObjectsForImageDownload;
    CLLocationDegrees lat;
    CLLocationDegrees lng;
    NSDate *lastLocationDate;
    DataService *dataService;
    UserService *userService;
    ImageService *imageService;
    ModelHolder *_modelHolder;
    NSObject<MasterProvider> *currentProvider;
    NSMutableArray *filteredObjects;
    NSMutableArray *displayedObjects;
    NSMutableArray *displayedCities;
    BOOL isLogged ;
    BOOL isLocalized;
    BOOL isLoading;
    NSDate *lastRefresh;
    
    BOOL locationServicesAvailable;
    
    NSString *currentSearchText;
    UISearchBar *_searchBar;
    BOOL searchInProgress;
    
    BOOL showServerSearchCell;
    BOOL serverSearchInProgress;
    NSString *moreResultsCellTitle;
    NSString *moreResultsCellSubtitle;
    UITableNoResultViewCell *noresultCell;
    
    BOOL isOffsetPositioned;
    BOOL isAccountPageShown;
    
    NSInteger currentSortType;
    NSMutableArray *modifiedPaths;
    
    NSInteger previousSectionRows;

}
@synthesize accountButton;


- (void)viewWillAppear:(BOOL)animated {
    [dataService registerDataListener:self];
    [self filterPlaces];
    [self.tableView reloadData];
    if((!isOffsetPositioned || !isLocalized || self.tableView.contentOffset.y == 0) && !isLoading) {
        [self hideFirstSection];
        isOffsetPositioned = YES;
    }
}
-(void)viewWillDisappear:(BOOL)animated {
    [dataService unregisterDataListener:self];
}
-(void)hideFirstSection {
    if(_modelHolder.searchedText == nil) {
        // Getting the proper number of rows in first section
        int preResultsRowHeight = 0;
        for(int i = 0 ; i < kSectionResults ; i++) {
            NSInteger sectionRows = [self tableView:self.tableView numberOfRowsInSection:i];
            for(int j = 0 ; j < sectionRows ; j++) {
                preResultsRowHeight+=[self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:j inSection:i]];
            }
        }

        // Setting the offset so that we hide them
        self.tableView.contentOffset = CGPointMake(0, preResultsRowHeight);
    }
}
-(void)viewDidAppear:(BOOL)animated {

    // Check whether we still have a user connected
    CurrentUser *user = [userService getCurrentUser];
    if(user == nil && !isLoading) {
        isLogged = NO;
        isLoading = YES;
        
        
        [self.tableView reloadData];
        [self performSegueWithIdentifier:@"login" sender:self];
        return;
    }
    
    // Requesting update
//    [dataService registerDataListener:self];
//    if(!userService.isAuthenticated) {
//        [userService authenticateWithLastLogin:self];
//    } else {
//        if(!isLogged) {
//            [self initDataAfterLogin];
//        }
//    }
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.separatorColor = [UIColor clearColor];
//    self.title = NSLocalizedString(@"places.title", @"Places list page title / tab title");
    // Adjusting tint
    [TogaytherService applyCommonLookAndFeel:self];
    [TogaytherService.settingsService addSettingsListener:self];
    
    // Loading nav bar custom view
    NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"TogaytherTitleView" owner:self options:nil];
    UIView *view = [views objectAtIndex:0];
    self.navigationItem.titleView=view;
    [self.navigationController.toolbar setTintColor:[UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:1]];
    
    // Setting up the refresh button
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)];
    self.navigationItem.rightBarButtonItem = refreshButton;
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // Setting the search button
    UIImage *filterImage = [UIImage imageNamed:@"tab_settings.png"]; //[UIImage imageNamed:@"barbutton-funnel.png"];
    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithImage:filterImage landscapeImagePhone:filterImage style:UIBarButtonItemStyleBordered target:self action:@selector(searchTapped:)];
    self.navigationItem.leftBarButtonItem = searchButton;
    

    // Adjusting account button label
    accountButton.title = NSLocalizedString(@"account.button", nil);
   
    [_placeEventsSwitch addTarget:self action:@selector(switchPlaceEventsMode:) forControlEvents:UIControlEventValueChanged];
    // Initializing togayther services
    dataService = [TogaytherService dataService];
    userService = [TogaytherService userService];
    imageService = [TogaytherService imageService];
    _modelHolder = [dataService modelHolder];
    currentSearchText = @"";
    pendingObjectsForImageDownload = [[NSMutableSet alloc] init];
    // Preparing view when no data available
    if([[_modelHolder getCALObjects] count] == 0) {
        isLoading = YES;

        // Account is not available until user is logged
        [accountButton setEnabled:NO];
    }
    
    // Handling toolbar
    [[TogaytherService getMessageService] handleToolbar:self];
    
    
    // Handling refresh of tableview
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
//    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    refreshControl.tintColor = [UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:1];
    [refreshControl addTarget:self action:@selector(reloadTableViewDataSource) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;

//    numberBadge.fillColor = [UIColor clearColor];
}

- (void)viewDidUnload
{
    [self setAccountButton:nil];
    [self setPlaceEventsSwitch:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    filteredObjects = nil;
    displayedObjects = nil;
    displayedCities = nil;
    _searchBar = nil;
    _objects = nil;
    dataService = nil;
    userService = nil;
    imageService = nil;
    [TogaytherService.settingsService removeSettingsListener:self];
//    _modelHolder = nil;

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)insertNewObject:(id)sender
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    [_objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:kSectionSearch];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}
- (void) filterPlaces {
    if(filteredObjects == nil) {
        filteredObjects = [[NSMutableArray alloc] init];
    } else {
        [filteredObjects removeAllObjects];
    }
    CALObject *object;
    
    // Getting the object provider
    currentProvider = _modelHolder.getMasterProvider;
    // Filtering objects
    for(object in [_modelHolder getCALObjects]) {
        if([currentProvider isDisplayed:object]) {
            [filteredObjects addObject:object];
        }
    }
    // By default we display everything
    displayedObjects = [NSMutableArray arrayWithArray:filteredObjects];
    displayedCities = [NSMutableArray arrayWithArray:_modelHolder.cities];
    if(_searchBar != nil) {
        _searchBar.text = @"";
        [_searchBar resignFirstResponder];
    }
    
    CurrentUser *user = userService.getCurrentUser;
    if(user.lat == 0 && user.lng==0) {
        locationServicesAvailable = NO;
    } else {
        locationServicesAvailable = YES;
    }

    // Sorting
    [self sort];
    
}

#pragma mark - NavBar Buttons callbacks
- (void)refresh:(id)sender {
    // When we refresh, we remove the optional parent context (nonsense to refresh a static location)
    _parentObject = nil;
    if([sender isKindOfClass:[CALObject class]]) {
        _parentObject = (CALObject*)sender;
    }
    isLocalized = NO;
    isLoading = YES;

    isLogged = NO;
    [imageService cancelRunningProcesses];
    [self.tableView reloadData];
    [userService authenticateWithLastLogin:self];
}

- (void)searchTapped:(id)sender {
    [TogaytherService.uiService showFiltersViewControllerFor:self];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(isLoading && displayedObjects.count == 0) {
        return 1;
    } else {
        return kSectionsCount;
    }
}
-(BOOL)hasCities {
    return _modelHolder.cities.count>0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(isLoading && displayedObjects.count == 0) {
        return 1;
    } else {
        switch(section) {
            case kSectionSearch:
                if(searchInProgress) {
                    return previousSectionRows;
                } else {
                    if((displayedObjects.count>0 || displayedCities.count>0) && _modelHolder.searchedText==nil) {
                        previousSectionRows = 2;
                        // Adding one row when geoloc is not active
                        if(![self isGeolocActive]) {
                            previousSectionRows+=1;
                        }
                    } else {
                        previousSectionRows = 1;
                    }
                    return previousSectionRows;
                }
            case kSectionResults:
                if(showServerSearchCell) {
                    // 1 search cell, 1 sort cell, all results + one more results cell
                    return displayedObjects.count+1;
                } else {
                    // 1 search cell, 1 sort cell + all results
                    return displayedObjects.count;
                }
            case kSectionCities:
                return displayedCities.count;
        }
    }
    return 0;
}
- (BOOL) isGeolocActive {
    return locationServicesAvailable;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch(section) {
        default:
            return nil;
        case kSectionResults:
            if([self hasCities] || _modelHolder.searchedText!=nil) {
                if(displayedObjects.count>0) {
                    return NSLocalizedString(@"places.section.searchPlaces", "Searched places section title");
                } else {
                    return nil;
                }
            } else if(_parentObject != nil && [_parentObject isKindOfClass:[City class]]){
                NSString *template = NSLocalizedString(@"places.section.incity",@"Places in city section title template");
                NSString *sectionTitle = [NSString stringWithFormat:template,((City*)_parentObject).name];
                return sectionTitle;
            } else {
                if(_modelHolder.currentListviewType == PLACES_LISTVIEW) {
                    return NSLocalizedString(@"places.section.nearby",@"Section for default nearby places listing");
                } else {
                    return NSLocalizedString(@"places.section.nearby.events",@"Section for default nearby events listing");
                }
            }
        case kSectionCities:
            if([self hasCities]) {
                return NSLocalizedString(@"places.section.searchCities","Searched cities section title");
            } else {
                return nil;
            }
    }
    return @"Bad section";
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellId = @"PlaceViewCell";
    if(isLoading  && displayedObjects.count == 0) {
        cellId=@"loading";
    } else if(indexPath.row == kSearchIndex && indexPath.section == kSectionSearch) {
        cellId = @"search";
    } else if(indexPath.row == kMessageIndex && indexPath.section == kSectionSearch) {
        cellId = @"noGeoLoc";
    } else if (indexPath.row == kSortIndex && indexPath.section == kSectionSearch) {
        cellId = @"sort";
    } else if(showServerSearchCell && indexPath.section == kSectionResults && indexPath.row == displayedObjects.count) {
        cellId = @"noresult";
    } 
    UITableViewCell *basicCell = [tableView dequeueReusableCellWithIdentifier:cellId];
    
    // If this is our initial doc we only set the waiting message
    if(isLoading && displayedObjects.count == 0) {
        UITablePlaceViewCell *cell = (UITablePlaceViewCell*)basicCell;
        if(!isLogged) {
            NSString *msg = NSLocalizedString(@"login.logging", @"Logging waiting message");
            cell.waitingLabel.text = msg;
        } else if(!isLocalized){
            NSString *msg = NSLocalizedString(@"login.localizing", @"Localization waiting message");
            cell.waitingLabel.text = msg;
        } else {
            // Default load message
            if(_parentObject == nil) {
                switch(_modelHolder.currentListviewType) {
                    case PLACES_LISTVIEW: {
                        NSString *msg = NSLocalizedString(@"loading", @"Loading message");

                        // Wait message while fetching places
                        cell.waitingLabel.text = msg;
                        self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:msg];
                        break;
                    }
                    case EVENTS_LISTVIEW: {
                        // Wait message while fetching events
                        NSString *msg = NSLocalizedString(@"loading.events", @"Loading message for events");
                        cell.waitingLabel.text = msg;
                        self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:msg];
                        break;
                    }
                }
            } else {
                // Wait message indicating we are in the scope of a city search
                NSString *template = NSLocalizedString(@"loading.city", @"Loading message for city search");
                NSString *msg = [NSString stringWithFormat:template,((City*)_parentObject).name];
                cell.waitingLabel.text = msg;
                self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:msg];
            }
        }
        [cell.activityIndicator startAnimating];
        return cell;
    }
    
    
    // Preparing provider and object to be filled depending on cell
    NSObject<MasterProvider> *dataProvider;

    // Registering us as a delegate to the search bar
    switch(indexPath.section) {
        case kSectionSearch:
            switch(indexPath.row) {
                case kSearchIndex: {
                    UITableSearchViewCell *searchCell = (UITableSearchViewCell*)basicCell;
                    [searchCell.searchBar setTintColor:[UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:1]];
                    searchCell.searchBar.delegate=self;
                    _searchBar = searchCell.searchBar;
                    switch(_modelHolder.currentListviewType) {
                        case PLACES_LISTVIEW:
                            _searchBar.placeholder = NSLocalizedString(@"places.search.placeholder",@"Search placeholder");
                            break;
                        case EVENTS_LISTVIEW:
                            _searchBar.placeholder = NSLocalizedString(@"places.search.placeholder.event",@"Search placeholder for events");
                            break;
                    }
                    break;
                }
                case kSortIndex: {
                    UITableSegmentViewCell *sortCell = (UITableSegmentViewCell*)basicCell;
                    [sortCell.segmentedControl addTarget:self action:@selector(sortChanged:) forControlEvents:UIControlEventValueChanged];
                    switch(_modelHolder.currentListviewType) {
                        case PLACES_LISTVIEW:
                            [sortCell.segmentedControl setTitle:NSLocalizedString(@"sort.popularity",@"Popularity") forSegmentAtIndex:0];
                            [sortCell.segmentedControl setTitle:NSLocalizedString(@"sort.distance",@"Popularity") forSegmentAtIndex:1];
                            [sortCell.segmentedControl setTitle:NSLocalizedString(@"sort.name",@"Popularity") forSegmentAtIndex:2];
                            break;
                        case EVENTS_LISTVIEW:
                            [sortCell.segmentedControl setTitle:NSLocalizedString(@"sort.date",@"Date") forSegmentAtIndex:0];
                            [sortCell.segmentedControl setTitle:NSLocalizedString(@"sort.distance",@"Popularity") forSegmentAtIndex:1];
                            [sortCell.segmentedControl setTitle:NSLocalizedString(@"sort.name",@"Popularity") forSegmentAtIndex:2];
                            break;
                    }
                    
                    break;
                }
                case kMessageIndex: {
                    UITableNoResultViewCell *noResultCell = (UITableNoResultViewCell*)basicCell;
                    noResultCell.noResultTitle.text = NSLocalizedString(@"geoloc.deactivated.title",@"geoloc.deactivated.title");
                    noResultCell.noResultSubtitle.text = NSLocalizedString(@"geoloc.deactivated.subtitle",@"geoloc.deactivated.subtitle");
                    break;
                }
            }
            break;
        case kSectionResults:
            // Specific "search from server" cell at the very bottom of search results
            if(showServerSearchCell && indexPath.row == displayedObjects.count) {
                
                // Getting the cell
                noresultCell = (UITableNoResultViewCell*)basicCell
                ;
                // Is our search currently in progress ?
                if(serverSearchInProgress) {
                    [noresultCell.searchActivity startAnimating];
                } else {
                    [noresultCell.searchActivity stopAnimating];
                }
                noresultCell.noResultTitle.text = moreResultsCellTitle;
                noresultCell.noResultSubtitle.text = moreResultsCellSubtitle;
                noresultCell.searchLabel.text = NSLocalizedString(@"noresult.searching", "Label displayed when searching from the no result cell");
            } else {
                dataProvider = currentProvider;
            }
            break;
        case kSectionCities: {
            dataProvider = [[CityMasterProvider alloc] init];
        }
        break;
    }

    CALObject *object = [self objectFromIndexPath:indexPath];
    // Filling the specific table cell if object exists
    if(object != nil) {
        UITablePlaceViewCell *cell = (UITablePlaceViewCell*)basicCell;
        // Filling the cell from object and provider
        [self fillTableCell:cell withObject:object andProvider:dataProvider];
    }

    return basicCell;
}

-(CALObject*)objectFromIndexPath:(NSIndexPath*)indexPath {
    CALObject *object = nil;
    switch(indexPath.section) {
        case kSectionResults:
            if(!showServerSearchCell || indexPath.row != displayedObjects.count) {
                if(indexPath.row<displayedObjects.count) {
                    object = [displayedObjects objectAtIndex:indexPath.row];
                }
            }
            break;
        case kSectionCities:
            object = [displayedCities objectAtIndex:indexPath.row];
            break;
    }
    return object;
}

-(void) fillTableCell:(UITablePlaceViewCell*)cell withObject:(CALObject*)object andProvider:(NSObject<MasterProvider>*)dataProvider {

    // Updating activity
    CALImage *img = object.mainImage;
    [cell.activityIndicator stopAnimating];
    
    cell.waitingLabel.text=@"";
    cell.placeType.text = [[dataProvider getTypeLabel:object]  uppercaseString];
    cell.placeType.transform = CGAffineTransformMakeRotation(-M_PI_2);
    CGRect thumbFrame = cell.thumb.frame;
    cell.placeType.frame = CGRectMake(thumbFrame.origin.x+thumbFrame.size.width, thumbFrame.origin.y, 20, thumbFrame.size.height);
    cell.placeType.backgroundColor = [TogaytherService.uiService colorForObject:object];
    
    cell.placeName.text = [dataProvider getTitle:object];
    
    // Adjusting
    cell.thumb.clipsToBounds = YES;
    cell.thumbBackground.clipsToBounds = YES;
//    if([TogaytherService.uiService isIpad:self]) {
//        cell.thumbBackground.hidden=YES;
//    }

    UIImage *thumbImg = img.thumbImage;
    UIImage *fullImg = img.fullImage;
    if(fullImg != nil) {
        cell.thumb.image = fullImg;
    } else if( thumbImg != nil) {
        cell.thumb.image = thumbImg;
    } else {
        // Loading cell if not moving
        if (!self.tableView.decelerating) {
            [imageService load:img to:cell.thumb thumb:NO];
        } else {
            cell.thumb.image = CALImage.getDefaultThumbLandscape;
        }
    }
    [self applyGradient:cell.nameBackground];
    [cell.nameBackground addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    
    cell.distance.text = [dataProvider getDistanceLabel:object];
    cell.tag1.image=nil;
    cell.tag2.image=nil;
    cell.tag3.image=nil;
    
    if([dataProvider isMenLabelVisible:object]) {
        cell.menInfoLabel.text=[dataProvider getMenLabel:object];
        [cell.menViewGroup setHidden:NO];
    } else {
        [cell.menViewGroup setHidden:YES];
    }
    cell.likeInfoLabel.text=[dataProvider getLikeLabel:object];

    for(NSString *tag in object.tags) {
        UIImage *tagImage = [imageService getTagImage:tag];
        if(cell.tag1.image == nil) {
            cell.tag1.image = tagImage;
        } else if(cell.tag2.image == nil) {
            cell.tag2.image= tagImage;
        } else if(cell.tag3.image == nil) {
            cell.tag3.image = tagImage;
        } else {
            break;
        }
    }
    // Coloring the background of sponsorised places
    if(object.adBoost>0) {
        cell.backgroundColor = [UIColor yellowColor];
        UIView *myBackView = [[UIView alloc] initWithFrame:cell.frame];
        myBackView.backgroundColor = [UIColor colorWithHexString:@"FEFFE8"];
        cell.backgroundView = myBackView;
    } else {
        cell.backgroundView = nil;
    }
    
    cell.specialsSubtitleLabel.text = nil;
    cell.specialsSubtitleLabel.backgroundColor = [UIColor clearColor];
    // Specials management
    if([dataProvider respondsToSelector:@selector(getSpecialFor:)]) {
        Special *special = [dataProvider getSpecialFor:object];
        
        if(special != nil) {
            cell.specialsContainer.hidden=NO;
            NSString *intro = [dataProvider getSpecialIntroLabel:special];
            NSString *mainLabel = [dataProvider getSpecialsMainLabel:special];
            cell.specialsIntro.text=intro;
            cell.specialsMainLabel.text=mainLabel;
            cell.specialsContainer.backgroundColor = [dataProvider getSpecialsColor:special];
        } else {
            cell.specialsContainer.hidden=YES;
        }
        
        if([dataProvider respondsToSelector:@selector(hasSubtitle:)]) {
            cell.specialsSubtitleGroup.hidden = ![dataProvider hasSubtitle:object];
        } else {
            cell.specialsSubtitleGroup.hidden = YES;
        }

        if([dataProvider respondsToSelector:@selector(getSpecialSubtitleFor:currentBestSpecial:)]) {
            Special *subtitleSpecial = [dataProvider getSpecialSubtitleFor:object currentBestSpecial:special];
            if(subtitleSpecial != nil) {
                NSString *subtitle = [dataProvider getSpecialsSubtitleLabel:subtitleSpecial];
//                UIColor *color = [dataProvider getSpecialsColor:subtitleSpecial];
                cell.specialsSubtitleLabel.text = subtitle;
            }
        }
    } else {
        cell.specialsContainer.hidden=YES;
        cell.specialsSubtitleGroup.hidden=YES;
    }
}
-(void)applyGradient:(UIView*)nameBackground {
    // Applying gradient
    CAGradientLayer *l = [CAGradientLayer layer];
    l.frame = nameBackground.bounds;
    l.colors = [NSArray arrayWithObjects:(id)[UIColor whiteColor].CGColor, (id)[UIColor clearColor].CGColor, nil];
    l.startPoint = CGPointMake(1.0, 1.0f);
    l.endPoint = CGPointMake(1.0f, 0.0f);
    nameBackground.layer.mask = l;
}
-(void) sortChanged:(UISegmentedControl*)control {
    currentSortType = control.selectedSegmentIndex;
    [self sort];
    [self.tableView reloadData];
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    int defaultHeight=125;
    if([TogaytherService.uiService isIpad:self]) {
        defaultHeight = 200;
    }
    switch(indexPath.section) {
        case kSectionSearch:
            switch(indexPath.row) {
                case kSearchIndex:
                    return 44;
                case kSortIndex:
                    return 30;
                case kMessageIndex:
                    return 44;
            }
            break;
        case kSectionResults: {
            if(indexPath.row < displayedObjects.count) {
                CALObject *obj = [displayedObjects objectAtIndex:indexPath.row];
                if([currentProvider respondsToSelector:@selector(hasSubtitle:)]) {
                    BOOL hasSubtitle = [currentProvider hasSubtitle:obj];
                    if(hasSubtitle) {
                        return defaultHeight;
                    }
                }
            }
        }
            
    }
    return defaultHeight;// [super tableView:tableView heightForRowAtIndexPath:indexPath];
}
/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
//        Place *place = [displayedObjects objectAtIndex:indexPath.row];
//        self.detailViewController.detailItem = place;
//    }

    if(showServerSearchCell && indexPath.section == kSectionResults && indexPath.row == displayedObjects.count) {
        [noresultCell.noResultTitle setHidden:YES];
        [noresultCell.noResultSubtitle setHidden:YES];
//        [noresultCell.searchActivity setHidden:NO];
        [noresultCell.searchLabel setHidden:NO];
        [noresultCell.searchActivity startAnimating];

        [noresultCell setSelected:NO animated:YES];
        serverSearchInProgress = YES;
        [dataService fetchPlacesFor:nil searchTerm:_searchBar.text];
    } else if(indexPath.section == kSectionResults) {
        [self performSegueWithIdentifier:@"overview" sender:self];
    } else if(indexPath.section == kSectionCities) {
        CALObject *city = [displayedCities objectAtIndex:indexPath.row];
        [self refresh:city];
//        [self performSegueWithIdentifier:@"listplaces" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqual:@"overview"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        CALObject *obj = [displayedObjects objectAtIndex:indexPath.row];
        [[segue destinationViewController] setDetailItem:obj];
        [self.navigationController setToolbarHidden:YES animated:YES];
    } else if([[segue identifier] isEqual:@"listplaces"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        CALObject *city = [displayedCities objectAtIndex:indexPath.row];
        MasterViewController *controller = [segue destinationViewController];
        controller.parentObject = city;
    } else if([[segue identifier] isEqualToString:@"map"]) {
        MapViewController *controller = [segue destinationViewController];
        CLLocationCoordinate2D coords;
        coords.latitude =userService.getCurrentUser.lat;
        coords.longitude = userService.getCurrentUser.lng;
        controller.center = coords;
    } else if([[segue identifier] isEqualToString:@"account"]) {
        isAccountPageShown = YES;
    } else if([[segue identifier] isEqualToString:@"showMyMessages"]) {
        MessageViewController *controller = [segue destinationViewController];
        controller.withObject = [userService getCurrentUser];
    }
}

#pragma mark DataRefreshCallback
- (void)didLoadData:(ModelHolder *)modelHolder {
    isLoading = NO;

    showServerSearchCell = NO;
    serverSearchInProgress = NO;
    searchInProgress = NO;
    [self resetMoreResults];
    [self filterPlaces];
    [self.tableView reloadData];
    if(_modelHolder.searchedText==nil) {
        [self hideFirstSection];
    }
    if([TogaytherService.uiService isIpad:self]) {
        MapViewController *mapController = [TogaytherService.uiService mapControllerFromSplitView:self.splitViewController];
        mapController.centralObject=nil;
        [mapController updateMap];
    }
    
    // Notifying our refresh view
    [self doneLoadingTableViewData];
}
- (void)didLocalizeDevice:(CLLocation *)location {
    isLocalized = YES;
    if(!searchInProgress) {
        [self.tableView reloadData];
    }
}

#pragma mark UserLoginCallback
- (void)authenticationFailed:(NSString *)reason {
    isLogged = NO;
    [self performSegueWithIdentifier:@"login" sender:self];
}
- (void)dataLoginFailed {
    isLogged = NO;
    [userService authenticateWithLastLogin:self];
}
-(void)initDataAfterLogin {
    isLogged = YES;
    [accountButton setEnabled:YES];
    [self.tableView reloadData];
    [dataService fetchPlacesFor:_parentObject];
}
- (void)userAuthenticated:(CurrentUser *)user {
    int age = [userService getAge:user];
    if(age<12) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"profile.mustBe18.title", @"profile.mustBe18.title")
                                                        message:NSLocalizedString(@"profile.mustBe18", @"profile.mustBe18")
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [self performSegueWithIdentifier:@"account" sender:self];
        return;
    }
    
    
    [self initDataAfterLogin];
}

#pragma mark UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    NSLog(@"searchBar didBeginEditing");
    currentSearchText = searchBar.text;
    searchInProgress = YES;
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    NSLog(@"searchBar cancel");
//    searchBar.text = currentSearchText;
    [searchBar resignFirstResponder];
    // Setting the no result flag
//    showServerSearchCell = displayedObjects.count == 0;
    [self.tableView reloadData];
    searchInProgress = NO;
}
//- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
//    NSLog(@"searchBar didEndEditing");
//    searchBar.text = currentSearchText;
//}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    searchInProgress = NO;
    if(_modelHolder.searchedText==nil) {
        [searchBar resignFirstResponder];
    } else {
        // If already in search mode, we search next string on server directly
        [dataService fetchPlacesFor:nil searchTerm:searchBar.text];
        [self.tableView reloadData];
    }
}

-(void)searchText:(NSString*)searchText {
    NSLog(@"searchBar search");
    if(searchText.length == 0) {
        displayedObjects = [NSMutableArray arrayWithArray:filteredObjects];
        displayedCities =[NSMutableArray arrayWithArray:_modelHolder.cities];
    } else if(_modelHolder.searchedText!=nil) {
        // If already in search mode, we search next string on server directly
        [dataService fetchPlacesFor:nil searchTerm:searchText];
    } else {
        displayedObjects = [[NSMutableArray alloc] initWithCapacity:filteredObjects.count];
        displayedCities = [[NSMutableArray alloc] initWithCapacity:_modelHolder.cities.count];
        
        // Getting current provider
        for(CALObject *object in filteredObjects) {
            // Getting object's title
            NSString *title = [currentProvider getTitle:object];
            // Searching the text to match
            NSRange range = [title rangeOfString:searchText options:NSCaseInsensitiveSearch];
            // If matched, we display this object
            if(range.location != NSNotFound) {
                [displayedObjects addObject:object];
            }
        }
        for(City *city in _modelHolder.cities) {
            // Searching text in city name
            NSString *name = city.name;
            NSRange range = [name rangeOfString:searchText options:NSCaseInsensitiveSearch];
            // If it matches, we add it to display list
            if(range.location != NSNotFound) {
                [displayedCities addObject:city];
            }
        }
        [self sort];
    }
    currentSearchText = searchText;
    // Setting the no result flag
    showServerSearchCell = searchText.length > 0;
    if(showServerSearchCell) {
        if(displayedObjects.count==0) {
            moreResultsCellTitle = NSLocalizedString(@"noresult.title", "Title of the no results cell");
            moreResultsCellSubtitle = NSLocalizedString(@"noresult.subtitle", "Subtitle of the no results cell");
        } else {
            moreResultsCellTitle = NSLocalizedString(@"moreresults.title","Title of the more results cell");
            moreResultsCellSubtitle = NSLocalizedString(@"moreresults.subtitle","Subtitle of the more results cell");
        }
        // Resetting the more result cell
        [self resetMoreResults];
    }
    // Trying a specific update
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSetWithIndex:kSectionResults];
    if(_modelHolder.cities.count>0) {
        [indexSet addIndex:kSectionCities];
    }
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
}
-(void)resetMoreResults {
    if(noresultCell != nil) {
        [noresultCell.noResultTitle setHidden:NO];
        [noresultCell.noResultSubtitle setHidden:NO];
        [noresultCell.searchActivity stopAnimating];
        [noresultCell.searchLabel setHidden:YES];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if(searchText.length == 0) {
        displayedObjects = filteredObjects;
        currentSearchText = @"";
        searchInProgress = NO;
        // Setting the no result flag
        showServerSearchCell = NO;
        [searchBar resignFirstResponder];
        [self.tableView reloadData];
    } else {
        if(_modelHolder.searchedText==nil) {
            [self searchText:searchText];
        }
    }
}

-(void)sort {
    NSArray *places = [displayedObjects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        switch(currentSortType) {
            default: {
                NSInteger index1 = [filteredObjects indexOfObject:obj1];
                NSInteger index2 = [filteredObjects indexOfObject:obj2];
                if(index1 == index2) {
                    return NSOrderedSame;
                } else {
                    return index1 < index2 ? NSOrderedAscending : NSOrderedDescending;
                }
            }
            case kSortTypeDistance: {
                CALObject *place1 = (CALObject*)obj1;
                CALObject *place2 = (CALObject*)obj2;
                NSInteger adBoost1 = place1.adBoost;
                NSInteger adBoost2 = place2.adBoost;
                // We preserve ad boosted elements, whatever sort is selected
                if(adBoost1 != adBoost2) {
                    return adBoost1 < adBoost2 ? NSOrderedDescending : NSOrderedAscending;
                } else {
                    
//                    CLLocation *place1Loc = [[CLLocation alloc] initWithLatitude:place1.lat longitude:place1.lng];
//                    CLLocation *place2Loc = [[CLLocation alloc] initWithLatitude:place2.lat longitude:place2.lng];
//                    CLLocation *userLoc = TogaytherService.userService .currentLocation;
//                    CLLocationDistance place1Distance = [place1Loc distanceFromLocation:userLoc];
//                    CLLocationDistance place2Distance = [place2Loc distanceFromLocation:userLoc];
//                    return place1Distance == place2Distance ? NSOrderedSame : place1Distance<place2Distance ? NSOrderedAscending : NSOrderedDescending;
                }
            }
            case kSortTypeName: {
                CALObject *place1 = (CALObject*)obj1;
                CALObject *place2 = (CALObject*)obj2;
                NSInteger adBoost1 = place1.adBoost;
                NSInteger adBoost2 = place2.adBoost;
                // We preserve ad boosted elements, whatever sort is selected
                if(adBoost1 != adBoost2) {
                    return adBoost1 < adBoost2 ? NSOrderedDescending : NSOrderedAscending;
                } else {
                    NSString *n1 = [currentProvider getTitle:place1];
                    NSString *n2 = [currentProvider getTitle:place2];
                    return [n1 compare:n2];
                }
            }
        }
//        NSString *label1 = [(PlaceType *)obj1 label];
//        NSString *label2 = [(PlaceType *)obj2 label];
//        return [label1 compare:label2];
    }];
    
    NSArray *cities = [displayedCities sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        switch(currentSortType) {
            case kSortTypePopularity: {
                NSInteger index1 = [_modelHolder.cities indexOfObject:obj1];
                NSInteger index2 = [_modelHolder.cities indexOfObject:obj2];
                if(index1 == index2) {
                    return NSOrderedSame;
                } else {
                    return index1 < index2 ? NSOrderedAscending : NSOrderedDescending;
                }
            }
                break;
            default: {
                City *c1 = (City*)obj1;
                City *c2 = (City*)obj2;
                return [c1.name compare:c2.name];
            }
        }
    }];

    displayedObjects = [NSMutableArray arrayWithArray:places];
    displayedCities = [NSMutableArray arrayWithArray:cities];
}

- (IBAction)switchPlaceEventsMode:(id)sender {
    ListviewType currentType = _modelHolder.currentListviewType;
    switch(currentType) {
        case PLACES_LISTVIEW:
            [_modelHolder setCurrentListviewType:EVENTS_LISTVIEW];
             break;
        case EVENTS_LISTVIEW:
            [_modelHolder setCurrentListviewType:PLACES_LISTVIEW];
            break;
    }
    // Checking if we got something
    NSArray *objects = [_modelHolder getCALObjects];
    if(objects == nil || objects.count==0) {
        [self refresh:nil];
    } else {
        [self filterPlaces];
        [self.tableView reloadData];
    }
}

#pragma mark - ScrollView
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSArray *cells = [self.tableView visibleCells];
    [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if([obj isKindOfClass:[UITablePlaceViewCell class]]) {
            // Getting our cell
            UITablePlaceViewCell *cell = (UITablePlaceViewCell*)obj;
            // Getting corresponding path
            NSIndexPath *path = [self.tableView indexPathForCell:cell];
            // Getting corresponding model object
            CALObject *object = [self objectFromIndexPath:path];
            if(object.mainImage.fullImage == nil) {
                [imageService load:object.mainImage to:cell.thumb thumb:NO];
            } else {
                cell.thumb.image = object.mainImage.fullImage;
            }
        }
    }];
}
//- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
//	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
//    
//}
//
//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
//	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
//	
//}
//-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
//    NSLog(@"Scrolled");
//    [self loadPendingImages];
//}
//-(void)loadPendingImages {
//    if(pendingObjectsForImageDownload.count>0) {
//        @synchronized(pendingObjectsForImageDownload) {
//            // Double check after getting semaphore
//            if(pendingObjectsForImageDownload.count>0) {
//                // Downloading image if needed
//                [imageService getThumbsMulti:[pendingObjectsForImageDownload allObjects] mainImageOnly:YES callback:self];
//                [pendingObjectsForImageDownload removeAllObjects];
//            }
//        }
//    }
//
//}

#pragma mark - SettingsListener
- (void)filtersChanged {
    [self filterPlaces];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kSectionResults] withRowAnimation:UITableViewRowAnimationAutomatic];
}
#pragma mark - KeyValue observer
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([@"frame" isEqualToString:keyPath] && [object isKindOfClass:[UIView class]]) {
        [self applyGradient:(UIView*)object];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource{
	
    // Refreshing
	[self refresh:self];
	
}

- (void)doneLoadingTableViewData{
	
	//  model should call this when its done loading
    lastRefresh = [NSDate date];
    [self.refreshControl endRefreshing];
	
}

//#pragma mark -
//#pragma mark EGORefreshTableHeaderDelegate Methods
//
//- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
//	
//	[self reloadTableViewDataSource];
//	
//}
//
//- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
//	
//	return isLoading; // should return if data source model is reloading
//	
//}
//
//- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
//	
//	return lastRefresh; // should return date data source was last changed
//	
//}
@end

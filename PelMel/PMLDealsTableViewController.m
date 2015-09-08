//
//  PMLDealsTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 24/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLDealsTableViewController.h"
#import "TogaytherService.h"
#import "PMLListedDealTableViewCell.h"
#import "PMLDeal.h"

#define kSectionsCount 1
#define kSectionDeals 0


@interface PMLDealsTableViewController ()
@property (nonatomic,weak) DataService *dataService;
@end

@implementation PMLDealsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [TogaytherService applyCommonLookAndFeel:self];
    self.title = NSLocalizedString(@"deal.use.title", @"deal.use.title");
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mnuIconClose"] style:UIBarButtonItemStylePlain target:self action:@selector(cancelTapped:)];
    self.dataService = [TogaytherService dataService];
    self.tableView.backgroundColor = BACKGROUND_COLOR;
    self.tableView.opaque=YES;
    self.tableView.separatorColor = BACKGROUND_COLOR;
    self.navigationController.view.layer.cornerRadius = 10;
    self.navigationController.view.layer.masksToBounds = YES;

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
    return kSectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [[[_dataService modelHolder] deals] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"dealCell" forIndexPath:indexPath];
    
    // Configure the cell...
    switch(indexPath.section) {
        case kSectionDeals:
            [self configureDealCell:(PMLListedDealTableViewCell*)cell forRow:indexPath.row];
            break;
    }
    return cell;
}

-(void)configureDealCell:(PMLListedDealTableViewCell*)cell forRow:(NSInteger)row {
    cell.clipsToBounds = YES;
    PMLDeal *deal = [[[_dataService modelHolder] deals] objectAtIndex:row];
    NSString *template = [NSString stringWithFormat:@"deal.type.%@",deal.dealType];
    cell.placeLabel.text = ((Place*)deal.relatedObject).title;
    cell.dealLabel.text = NSLocalizedString(template,@"2 For 1");
    cell.dealConditionLabel.text= nil; //[[TogaytherService dealsService] dealConditionLabel:deal];
    CALImage *image = [[TogaytherService imageService] imageOrPlaceholderFor:deal.relatedObject allowAdditions:NO];
    [[TogaytherService imageService] load:image to:cell.placeImage thumb:NO];
    
    [cell.useDealButton setTitle:NSLocalizedString(@"deal.use.button", @"Use this deal") forState:UIControlStateNormal];
    cell.useDealButton.hidden = ![[TogaytherService dealsService] isDealUsable:deal considerCheckinDistance:YES];
    cell.useDealButton.tag = row;
    [cell.useDealButton addTarget:self action:@selector(didTapUseDeal:) forControlEvents:UIControlEventTouchUpInside];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.section) {
        case kSectionDeals: {
            PMLDeal *deal = [[[_dataService modelHolder] deals] objectAtIndex:indexPath.row];
            if([[TogaytherService dealsService] isDealUsable:deal considerCheckinDistance:YES]) {
                return 120;
            } else {
                return 92;
            }
        }
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PMLDeal *deal = [[[_dataService modelHolder] deals] objectAtIndex:indexPath.row];

    [[TogaytherService uiService] presentSnippetFor:deal.relatedObject opened:YES];
    [self dismissViewControllerAnimated:YES completion:NULL];
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
-(void)cancelTapped:(id)source {
    [self dismissViewControllerAnimated:YES completion:NULL];
}
-(void)didTapUseDeal:(UIButton*)source {
    PMLDeal *deal = [[[_dataService modelHolder] deals] objectAtIndex:source.tag];
    [[TogaytherService actionManager] execute:PMLActionTypeUseDeal onObject:deal];
    [self dismissViewControllerAnimated:YES completion:NULL];
}
@end

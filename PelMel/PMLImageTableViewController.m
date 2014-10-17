//
//  PMLImageTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 10/08/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLImageTableViewController.h"
#import "TogaytherService.h"
#import "PMLImageTableViewCell.h"

@interface PMLImageTableViewController ()

@end

@implementation PMLImageTableViewController {

    NSMutableArray *_images;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

//- (instancetype)initWithImages:(NSArray *)images inView:(UIView *)view
//{
//    self = [super init];
//    if (self) {
//        self.images = images;
//        _parentView = view;
//        
//    }
//    return self;
//}
//- (instancetype)initWithCALObject:(CALObject*)object inView:(UIView *)view
//{
//    NSMutableArray *images = [[NSMutableArray alloc] init ];
//    if(object.mainImage!=nil) {
//        [images addObject:object.mainImage];
//        [images addObjectsFromArray:object.otherImages];
//    }
//
//    return [self initWithImages:images inView:view];
//}

- (void)setCalObject:(CALObject *)calObject {
    _calObject = calObject;
    _images = [[NSMutableArray alloc] init ];
    if(calObject.mainImage!=nil) {
        [_images addObject:calObject.mainImage];
        [_images addObjectsFromArray:calObject.otherImages];
    }
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    self.view.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.backgroundColor = [UIColor greenColor];
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
//    self.tableView.pagingEnabled=YES;
    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _images.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"imageCell";
    PMLImageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];

    // Loading
    cell.backgroundColor = [UIColor blueColor];
    cell.cellImageView.backgroundColor = [UIColor redColor];
    NSLog(@"Image x=%d y=%d",(int)cell.imageView.frame.origin.x,(int)cell.imageView.frame.origin.y);
//    imgView.transform = CGAffineTransformMakeRotation(M_PI_2);
    cell.cellImageView.frame = cell.bounds; // CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    cell.cellImageView.opaque=YES;
    cell.cellImageView.image = [CALImage getDefaultImage];
    cell.cellImageView.contentMode = UIViewContentModeScaleAspectFit;
//    cell.imageView.clipsToBounds=YES;

//    [TogaytherService.getImageService load:[_images objectAtIndex:indexPath.row] to:cell.imageView thumb:NO];
    
    // Configure the cell...
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"TableView width=%d",(int)self.view.bounds.size.width);
    return self.view.bounds.size.height;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate imageTappedAtIndex:(int)indexPath.row image:[_images objectAtIndex:(int)indexPath.row]];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

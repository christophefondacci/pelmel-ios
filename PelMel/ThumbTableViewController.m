//
//  ThumbTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 27/01/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "ThumbTableViewController.h"
#import "ThumbCell.h"
#import "CALImage.h"
#import "CALObject.h"
#import "DisplayHelper.h"
#import "TogaytherService.h"
#import "UITouchBehavior.h"

@interface ThumbTableViewController ()

@end

@implementation ThumbTableViewController {
    ImageService *imageService;
    UIService *_uiService;
    
    UIDynamicAnimator *_animator;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if(_size==nil) {
        _size = [NSNumber numberWithInt:50];
    }
    imageService = [TogaytherService imageService];
    _uiService = [TogaytherService uiService];
    
    self.view.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;

    
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
    if(self.thumbProvider != nil) {
        return self.thumbProvider.items.count;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"thumbCellNew";
    ThumbCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.containerView.transform = CGAffineTransformMakeRotation(M_PI_2);
    // Configure the cell...
     cell.containerView.backgroundColor = [UIColor clearColor];
    if([self.thumbProvider respondsToSelector:@selector(isSelected:)]) {
        if([self.thumbProvider isSelected:indexPath.row]) {
            cell.containerView.backgroundColor = UIColorFromRGB(0xf48020);
            cell.containerView.layer.cornerRadius =4;
            cell.containerView.clipsToBounds = YES;
        }
    }

    cell.backgroundColor = [UIColor clearColor];
    
    // Configuring image
    int cellSize = [_size intValue];
    cell.thumbImage.image=nil;
    CALImage *image = [self.thumbProvider imageAtIndex:indexPath.row];
    if(image.thumbImage == nil) {
        [imageService load:image to:cell.thumbImage thumb:YES];
    } else {
        cell.thumbImage.image = image.thumbImage;
    }
    
    // Setting rounded corners (or not)
    BOOL rounded= YES;
    if([self.thumbProvider respondsToSelector:@selector(rounded)]) {
        rounded= [self.thumbProvider rounded];
    }
    if(rounded) {
        cell.thumbImage.layer.cornerRadius = cellSize/2;
    } else {
        cell.thumbImage.layer.cornerRadius = 0;
        cell.thumbImage.layer.borderWidth=0;
    }
    
    // Configuring decorator
    if([self.thumbProvider respondsToSelector:@selector(colorFor:)]) {
        cell.thumbImage.layer.borderColor = [self.thumbProvider colorFor:indexPath.row].CGColor;
    } else {
        cell.thumbImage.layer.borderColor = [UIColor whiteColor].CGColor;
    }
//    UIImage *decorator = [self.thumbProvider topLeftDecoratorForIndex:(int)indexPath.row];
//    cell.onlineImage.image=decorator;

    cell.containerView.frame = CGRectMake(0,0, cellSize+18, cellSize+18);

    // Configuring bottom right decorator
    cell.bottomDecorator.image = [self.thumbProvider bottomRightDecoratorForIndex:(int)indexPath.row];
    NSInteger labelSize = 9;
    cell.titleLabel.text = [self.thumbProvider titleAtIndex:indexPath.row];
    // Custom font size if supported
    if([self.thumbProvider respondsToSelector:@selector(fontSize)]) {
        NSInteger fontSize = [self.thumbProvider fontSize];
        cell.titleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:fontSize];
    }
    cell.titleLabel.minimumScaleFactor=0.8;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.actionDelegate != nil) {
        
//        // Animating cell
//        ThumbCell *cell = (ThumbCell*)[self tableView:tableView cellForRowAtIndexPath:indexPath];
//        UITouchBehavior *touchBehavior = [[UITouchBehavior alloc] initWithTarget:cell.thumbImage];
//        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:cell];
//        [_animator addBehavior:touchBehavior];
        
        // Firing action
        [self.actionDelegate thumbsTableView:self thumbTapped:(int)indexPath.row];
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [_size floatValue]+18;//+8;
}

- (void)setThumbProvider:(id<ThumbsPreviewProvider>)thumbProvider {
    _thumbProvider = thumbProvider;
    [self.tableView reloadData];
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
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
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

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end

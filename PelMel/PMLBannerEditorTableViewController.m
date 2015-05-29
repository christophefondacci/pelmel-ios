//
//  PMLBannerEditorTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 12/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLBannerEditorTableViewController.h"
#import "PMLBannerEditorTableViewCell.h"
#import "TogaytherService.h"
#import "PMLItemSelectionTableViewController.h"
#import "PMLImageTableViewCell.h"
#import "PMLButtonTableViewCell.h"

#define kSectionCount 1
#define kSectionEditor 0
#define kRowsEditor 2

#define kRowEditor 0
#define kRowBanner 1

#define kRowIdEditor @"editorCell"
#define kRowIdButton @"buttonCell"
#define kRowIdBanner @"bannerCell"
#define kRowHeightBannerEditor 117


@interface PMLBannerEditorTableViewController ()

@property (nonatomic,retain) ImageService *imageService;
@property (nonatomic,retain) PMLStoreService *storeService;
@property (nonatomic,retain) id<PMLInfoProvider> infoProvider;

@end

@implementation PMLBannerEditorTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Service init
    self.imageService = [TogaytherService imageService];
    self.storeService = [TogaytherService storeService];
    
    // Nav bar and appearance configuration
    [TogaytherService applyCommonLookAndFeel:self];
    self.tableView.backgroundColor = UIColorFromRGB(0x272a2e);
    self.tableView.opaque=YES;
    self.tableView.separatorColor = UIColorFromRGB(0x272a2e);
    self.navigationController.edgesForExtendedLayout=UIRectEdgeAll;
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];

    
    if(self.banner == nil) {
        self.banner = [[PMLBanner alloc] init];
    }
    
    // Registering custom nib for rows
    [self.tableView registerNib:[UINib nibWithNibName:@"PMLButtonTableViewCell" bundle:nil] forCellReuseIdentifier:kRowIdButton];

    
    // Loading products
    [self.storeService loadProducts:@[kPMLProductBanner1000,kPMLProductBanner2500,kPMLProductBanner6000]];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
-(void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsDefinitionChanged:) name:PML_NOTIFICATION_PRODUCTS_LOADED object:NULL];
}
- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    // Return the number of rows in the section.
    return kRowsEditor;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellId;
    switch(indexPath.row) {
        case kRowEditor:
            cellId = kRowIdEditor;
            break;
        default:
            if(self.banner.mainImage != nil) {
                cellId = kRowIdBanner;
            } else {
                cellId = kRowIdButton;
            }
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    
    switch(indexPath.row) {
        case kRowEditor:
            [self configureRowEditor:(PMLBannerEditorTableViewCell*)cell];
            break;
        default:
            if(self.banner.mainImage!=nil) {
                [self configureRowBanner:(PMLImageTableViewCell*)cell];
            } else {
                [self configureRowButton:(PMLButtonTableViewCell*)cell];
            }
            break;
    }
    return cell;
}
-(void)configureRowEditor:(PMLBannerEditorTableViewCell*)cell {
    cell.targetUrlTextField.delegate = self;
    cell.delegate = self;
    [cell refreshWithBanner:self.banner];
    [cell.targetUrlTextField addTarget:self
                       action:@selector(targetUrlDidChange:)
             forControlEvents:UIControlEventEditingChanged];
}
-(void)configureRowBanner:(PMLImageTableViewCell*)cell {
    // Loading banner image
    cell.cellImageView.image = self.banner.mainImage.fullImage;
    [[TogaytherService imageService] registerImageUploadFromLibrary:cell.cellImageView forViewController:self callback:self];
}
-(void)configureRowButton:(PMLButtonTableViewCell*)cell {
    cell.buttonImageView.image = [UIImage imageNamed:@"btnAddPhoto"];
    cell.buttonLabel.text = NSLocalizedString(@"banner.button.uploadImage",@"Tap to upload 320x50 banner image");
    cell.backgroundColor = UIColorFromRGB(0x272a2e);
    [[TogaytherService imageService] registerImageUploadFromLibrary:cell.buttonContainer forViewController:self callback:self];
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.row) {
        case kRowEditor:
            return kRowHeightBannerEditor;
        default:
//            if(self.banner.mainImage!=nil) {
//                return 50;
//            } else {
                return 62;
//            }
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
#pragma mark - PMLBannerEditorDelegate
- (void)bannerEditor:(PMLBannerEditorTableViewCell *)bannerEditorCell targetTypeSelected:(PMLTargetType)targetType {

    switch(targetType) {
        case PMLTargetTypePlace:
        case PMLTargetTypeEvent: {
            PMLItemSelectionTableViewController *itemSelectionController = (PMLItemSelectionTableViewController*)[[TogaytherService uiService] instantiateViewController:SB_ID_ITEM_SELECTION];
            itemSelectionController.targetType = targetType;
            itemSelectionController.delegate = self;
            [self.parentMenuController.navigationController pushViewController:itemSelectionController animated:YES];
            break;
        }
        case PMLTargetTypeURL:
            bannerEditorCell.targetItemImage.hidden=YES;
            bannerEditorCell.targetItemLabel.hidden=YES;
            bannerEditorCell.targetUrlTextField.hidden=NO;
            self.banner.targetObject=nil;
            [bannerEditorCell.targetUrlTextField becomeFirstResponder];
            break;
    }
}
- (void)bannerEditorDidTapOk:(PMLBannerEditorTableViewCell *)bannerEditorCell {
    NSLog(@"OK tapped");
    PMLEditor *editor = [PMLEditor editorFor:self.banner];
    [editor commit];

}

-(void)bannerEditorDidTapCancel:(PMLBannerEditorTableViewCell *)bannerEditorCell {
    NSLog(@"Cancel tapped");
    if([bannerEditorCell.targetUrlTextField isFirstResponder]) {
        [bannerEditorCell.targetUrlTextField resignFirstResponder];
    } else {
        PMLEditor *editor = [PMLEditor editorFor:self.banner];
        [editor cancel];
        [[[TogaytherService uiService] menuManagerController] dismissControllerSnippet];
    }
}
#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    self.banner.targetUrl = textField.text;
    [textField resignFirstResponder];
    return YES;
}
-(BOOL)textFieldShouldClear:(UITextField *)textField {
    self.banner.targetUrl = nil;
    textField.text = nil;
    return YES;
}
#pragma mark - Actions
-(void)targetUrlDidChange:(UITextField*)textField {
    self.banner.targetUrl = textField.text;
}

#pragma mark - PMLImagePickerCallback
- (void)imagePicked:(CALImage *)image {
    CGSize size = image.fullImage.size;
    if(((int)size.width % 320) == 0 && (((int)size.height % 50) == 0))  {
        self.banner.mainImage = image;
        [self.tableView reloadData];
    } else {
        [[TogaytherService uiService] alertWithTitle:@"banner.image.formatErrorTitle" text:@"banner.image.formatError"];
    }
}
- (void)setBanner:(PMLBanner *)banner {
    _banner = banner;
    if(banner.targetObject!=nil) {
        self.infoProvider = [[TogaytherService uiService] infoProviderFor:self.banner.targetObject];
    } else {
        self.infoProvider = nil;
    }
    [self.tableView reloadData];
}

#pragma mark - Store product callback
- (void)productsDefinitionChanged:(id)source {
    [self.tableView reloadData];
}
#pragma mark - PMLItemSelectionDelegate
- (void)itemSelected:(CALObject *)item {
    if(item != nil) {
        self.banner.targetObject = item;
        self.banner.targetUrl = nil;
        [self.tableView reloadData];
    }
}
@end

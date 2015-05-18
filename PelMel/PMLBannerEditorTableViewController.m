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

#define kSectionCount 1
#define kSectionEditor 0
#define kRowsEditor 1
#define kRowHeightBannerEditor 150

#define kPMLProductBanner1000 @"com.fgp.pelmel.banner1000"
#define kPMLProductBanner2500 @"com.fgp.pelmel.banner2500"
#define kPMLProductBanner5000 @"com.fgp.pelmel.banner5000"

@interface PMLBannerEditorTableViewController ()

@property (nonatomic,retain) ImageService *imageService;
@property (nonatomic,retain) id<PMLInfoProvider> infoProvider;
@property (nonatomic,retain) SKProductsRequest *skProductsRequest;
@property (nonatomic,retain) NSMutableDictionary *storeProducts;
@end

@implementation PMLBannerEditorTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Service init
    self.imageService = [TogaytherService imageService];
    
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
    
    // Requesting products from Store Kit
    self.skProductsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:@[kPMLProductBanner1000,kPMLProductBanner2500,kPMLProductBanner5000]]];
    self.skProductsRequest.delegate = self;
    [self.skProductsRequest start];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
-(void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:NO];
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
    PMLBannerEditorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bannerEditorCell" forIndexPath:indexPath];
    
    if(self.banner.targetObject != nil) {
        // Adjusting visibility
        cell.targetUrlTextField.hidden=YES;
        cell.targetItemImage.hidden = NO;
        cell.targetItemLabel.hidden = NO;
        
        // Loading place thumb
        CALImage *image = [self.imageService imageOrPlaceholderFor:self.banner.targetObject allowAdditions:NO];
        cell.targetItemImage.image = [[CALImage defaultNoPhotoCalImage] fullImage];
        [self.imageService load:image to:cell.targetItemImage thumb:YES];
        
        // Setting up title
        cell.targetItemLabel.text = [self.infoProvider title];
    } else {
        // Adjusting visibility
        cell.targetUrlTextField.hidden = NO;
        cell.targetItemImage.hidden=YES;
        cell.targetItemLabel.hidden = YES;
        
        // Filling URL
        cell.targetUrlTextField.text = self.banner.targetUrl;
        cell.targetUrlTextField.placeholder = NSLocalizedString(@"banner.url.placeholder", @"banner.url.placeholder");
    }
    if(self.storeProducts == nil) {
        cell.firstDisplayPackageContainer.hidden = YES;
        cell.secondDisplayPackageContainer.hidden = YES;
        cell.thirdDisplayPackageContainer.hidden = YES;
    } else {
        cell.firstDisplayPackageContainer.hidden = NO;
        cell.secondDisplayPackageContainer.hidden = NO;
        cell.thirdDisplayPackageContainer.hidden = NO;
        
        SKProduct *banner1000 = [self.storeProducts objectForKey:kPMLProductBanner1000];
        cell.firstDisplayPackagePriceLabel.text = [self priceFromProduct:banner1000];
        SKProduct *banner2500 = [self.storeProducts objectForKey:kPMLProductBanner2500];
        cell.secondDisplayPackagePriceLabel.text = [self priceFromProduct:banner2500];
        SKProduct *banner5000 = [self.storeProducts objectForKey:kPMLProductBanner5000];
        cell.thirdDisplayPackagePriceLabel.text = [self priceFromProduct:banner5000];

        if(self.banner.targetDisplayCount==0) {
            self.banner.targetDisplayCount = 1000;
        }
    }
    cell.targetUrlTextField.delegate = self;
    cell.delegate = self;
    [cell.targetUrlTextField addTarget:self
                       action:@selector(targetUrlDidChange:)
             forControlEvents:UIControlEventEditingChanged];
    
    [[TogaytherService imageService] registerTappable:cell.bannerUploadButton forViewController:self callback:self];
    // Loading banner image
    [cell.bannerUploadButton setBackgroundImage:self.banner.mainImage.fullImage forState:UIControlStateNormal];
    if(self.banner.mainImage.fullImage !=nil) {
        [cell.bannerUploadButton setTitle:nil forState:UIControlStateNormal];
    }
    // Configure the cell...
    return cell;
}
-(NSString*)priceFromProduct:(SKProduct *)product {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:product.priceLocale];
     NSString *localizedMoneyString = [formatter stringFromNumber:product.price];
    return localizedMoneyString;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kRowHeightBannerEditor;
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
- (void)bannerEditor:(PMLBannerEditorTableViewCell *)bannerEditorCell packageSelected:(NSInteger)packageIndex {
    NSLog(@"package selected: %d",packageIndex);
    switch(packageIndex) {
        case 0:
            [self.banner setTargetDisplayCount:1000];
            break;
        case 1:
            [self.banner setTargetDisplayCount:2500];
            break;
        case 2:
            [self.banner setTargetDisplayCount:6000];
            break;
    }
}
- (void)bannerEditorDidTapOk:(PMLBannerEditorTableViewCell *)bannerEditorCell {
    NSLog(@"OK tapped");
    PMLPopupEditor *editor = [PMLPopupEditor editorFor:self.banner];
    [editor commit];

}

-(void)bannerEditorDidTapCancel:(PMLBannerEditorTableViewCell *)bannerEditorCell {
    NSLog(@"Cancel tapped");
    PMLPopupEditor *editor = [PMLPopupEditor editorFor:self.banner];
    [editor cancel];
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
    if(size.width!=320 && size.height != 50) {
        [[TogaytherService uiService] alertWithTitle:@"banner.image.formatErrorTitle" text:@"banner.image.formatError"];
    } else {
        self.banner.mainImage = image;
        [self.tableView reloadData];
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

#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    self.storeProducts = [[NSMutableDictionary alloc] init];
    for(SKProduct *product in response.products) {
        [self.storeProducts setObject:product forKey:product.productIdentifier];
    }
    [self.tableView reloadData];
}
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    [[TogaytherService uiService] alertWithTitle:@"banner.store.failureTitle" text:@"banner.store.failure"];
}
@end

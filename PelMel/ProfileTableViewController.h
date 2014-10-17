//
//  ProfileTableViewController.h
//  nativeTest
//
//  Created by Christophe Fondacci on 05/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DatePickerDataSource.h"
#import "LanguagePickerDataSource.h"
#import "UITableMeasureViewCell.h"
#import "ImageService.h"
@interface ProfileTableViewController : UITableViewController <DateCallback,MeasureSliderDelegate,LanguageCallback, PMLImagePickerCallback, PMLImageUploadCallback>

- (IBAction)dismiss:(id)sender;

@end

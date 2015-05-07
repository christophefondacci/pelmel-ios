//
//  PMLPhotosCollectionViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 06/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMLActivityStatistic.h"
#import "MessageService.h"


@interface PMLPhotosCollectionViewController : UICollectionViewController <ActivitiesCallback,UICollectionViewDelegateFlowLayout>

// Array of CALImage
@property (nonatomic,retain) PMLActivityStatistic *activityStat;
@end

//
//  PMLObjectsPhotoProvider.h
//  PelMel
//
//  Created by Christophe Fondacci on 04/06/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMLPhotosCollectionViewController.h"

@interface PMLObjectsPhotoProvider : NSObject<PMLPhotosProvider>

@property (nonatomic,retain) NSString *title;

-(instancetype)initWithObjects:(NSArray*)objects;

@end

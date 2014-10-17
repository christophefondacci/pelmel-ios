//
//  PlaceDetailProvider.h
//  togayther
//
//  Created by Christophe Fondacci on 18/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../DetailViewController.h"
#import "../ThumbsPreviewView.h"

@interface PlaceDetailProvider : NSObject <DetailProvider, PMLImagePickerCallback>

-(id)initWithPlace:(Place*)place;

@end

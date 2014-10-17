//
//  EventDetailProvider.h
//  togayther
//
//  Created by Christophe Fondacci on 20/12/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../DetailViewController.h"
#import "../Event.h"

@interface EventDetailProvider : NSObject <DetailProvider,PMLImagePickerCallback>

-(id)initWithEvent:(Event*)event;

@end

//
//  MessageTableViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 21/04/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CALObject.h"
#import "MessageService.h"
#import <CoreData/CoreData.h>

@protocol PMLMessageProvider <NSObject>

- (NSFetchedResultsController *)fetchedResultsController:(NSManagedObjectContext*)managedObjectContext delegate:(id<NSFetchedResultsControllerDelegate>)delegate;
- (Message*)messageFromIndexPath:(NSIndexPath*)indexPath;
- (NSInteger)numberOfResults;
- (void)setNumberOfResults:(NSInteger)maxResults;
@end
@interface PMLMessageTableViewController : UITableViewController <MessageCallback,NSFetchedResultsControllerDelegate>

@property (strong,nonatomic) CALObject *withObject;
@property (nonatomic) BOOL showComments;
@property (strong,nonatomic) id<PMLMessageProvider> messageProvider;

@end

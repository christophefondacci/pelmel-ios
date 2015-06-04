//
//  PMLObjectsPhotoProvider.m
//  PelMel
//
//  Created by Christophe Fondacci on 04/06/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLObjectsPhotoProvider.h"
#import "TogaytherService.h"
@interface PMLObjectsPhotoProvider()
@property (nonatomic,retain) NSArray *objects;
@end

@implementation PMLObjectsPhotoProvider

- (instancetype)initWithObjects:(NSArray *)objects
{
    self = [super init];
    if (self) {
        self.objects = objects;
    }
    return self;
}

-(void)photoControllerStartContentLoad:(PMLPhotosCollectionViewController *)controller {
    controller.loadFullImage=YES;
    [controller updateData];
}
- (NSArray *)objectsForSection:(NSInteger)section {
    return self.objects;
}
- (NSInteger)sectionsCount {
    return 1;
}
- (CALImage *)photoController:(PMLPhotosCollectionViewController *)controller imageForObject:(NSObject *)object inSection:(NSInteger)section {
    return ((CALObject*)object).mainImage;
}
- (NSString *)photoController:(PMLPhotosCollectionViewController *)controller labelForObject:(NSObject *)object inSection:(NSInteger)section {
    id<PMLInfoProvider> provider = [[TogaytherService uiService] infoProviderFor:(CALObject*)object];
    return [provider title];
}
- (NSString *)title {
    return NSLocalizedString(@"grid.title.nearbyUsers", @"grid.title.nearbyUsers");
}
- (void)photoController:(PMLPhotosCollectionViewController *)controller objectTapped:(NSObject *)object inSection:(NSInteger)section {
    [[TogaytherService uiService] presentSnippetFor:(CALObject*)object opened:YES];
}
-(UIImage *)defaultImageFor:(NSObject *)object {
    if([object isKindOfClass:[User class]]) {
        return [[CALImage getDefaultUserCalImage] fullImage];
    } else {
        return nil;
    }
}
- (UIColor *)borderColorFor:(NSObject *)object {
    if([object isKindOfClass:[User class]]) {
        User *user = (User*)object;
        if(user.isOnline) {
            UIColor *color = [[TogaytherService uiService] colorForObject:object];
            return [color colorWithAlphaComponent:0.5];
        }
    }
    return nil;
}
@end

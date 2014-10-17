//
//  ItemsThumbPreviewProvider.m
//  togayther
//
//  Created by Christophe Fondacci on 23/01/13.
//  Copyright (c) 2013 Christophe Fondacci. All rights reserved.
//

#import "ItemsThumbPreviewProvider.h"
#import "TogaytherService.h"
#import "MosaicListViewController.h"
#import "DetailViewController.h"
#import "Event.h"
#import "DisplayHelper.h"

@implementation ItemsThumbPreviewProvider {
    CALObject *_parent;
    NSMutableArray *_items;
    NSMutableDictionary *_itemsTypes;
    NSMutableSet *_itemKeys;
    NSString *_segueId;
    NSString *_labelKey;
    UIImage *_icon;
    
    int lastTappedThumb;
    BOOL isMoreTapped;
    ImageService *imageService;
    UIService *_uiService;
}

- (id)initWithParent:(CALObject *)parent items:(NSArray*)items moreSegueId:(NSString*)segueId labelKey:(NSString*)labelKey icon:(UIImage*)icon
{
    self = [self initWithParent:parent items:items forType:PMLThumbsOther];
        _segueId = segueId;
        _labelKey = labelKey;
        _icon = icon;


    return self;
}

- (instancetype)initWithParent:(CALObject *)place items:(NSArray *)items forType:(PMLThumbType)type
{
    self = [super init];
    if (self) {
        imageService = [TogaytherService imageService];
        _uiService = [TogaytherService uiService];
        _parent = place;
        _items = [[NSMutableArray alloc ] init ];
        _itemsTypes = [[NSMutableDictionary alloc] init];
        _itemKeys = [[NSMutableSet alloc] init];
        [self addItems:items forType:type];
    }
    return self;
}

- (void)addItems:(NSArray *)items forType:(PMLThumbType)type {
    for(CALObject *item in items) {
        if(![_itemKeys containsObject:item.key]) {
            [_itemKeys addObject:item.key];
            [_items addObject:item];
            UIImage *icon;
            switch(type) {
                case PMLThumbsCheckin:
                    icon = [UIImage imageNamed:@"snpDecoratorCheckin"];
                    break;
                case PMLThumbsLike:
                    icon = [UIImage imageNamed:@"snpDecoratorLike"];
                    break;
                default:
                    icon = nil;
            }
            if(icon != nil) {
                [_itemsTypes setObject:icon forKey:item.key];
            }
        }
    }
}

- (CALImage *)imageAtIndex:(NSInteger)index {
    if(_items.count>index) {
        CALObject *item = [_items objectAtIndex:index];
        return item.mainImage;
    } else {
        return nil;
    }
}
- (UIImage*)topLeftDecoratorForIndex:(NSInteger)index {
    if(_items.count>index) {
        CALObject *item = [_items objectAtIndex:index];
        if([item isKindOfClass:[User class]] ) {
            User *user = (User*)item;
            // Getting the online / offline state
            BOOL offline = user == nil || !user.isOnline;
            UIImage *imgDecorator = [imageService getOnlineImage:YES];
            return offline ? nil : imgDecorator;
        }
    }
    return nil;
}
-(UIImage *)bottomRightDecoratorForIndex:(NSInteger)index {
    CALObject *item = [_items objectAtIndex:index];
    UIImage *icon = [_itemsTypes objectForKey:item.key];
    return icon;
}
- (NSArray *)items {
    return _items;
}
- (NSString *)titleAtIndex:(NSInteger)index {
    CALObject *obj = [[self items] objectAtIndex:index];
    NSString *label = [DisplayHelper getName:obj];
    return label;
}
- (void)prepareSegue:(UIViewController *)c {
    if(isMoreTapped) {
        MosaicListViewController *controller = (MosaicListViewController*)c;
        [controller setObjects:[self items]];
        [controller setParentObject:_parent];
        if([_parent isKindOfClass:[Place class]]) {
            [controller setViewTitle:((Place*)_parent).title];
        } else if([_parent isKindOfClass:[User class]]) {
            [controller setViewTitle:((User*)_parent).pseudo];
        } else if([_parent isKindOfClass:[Event class]]) {
            [controller setViewTitle:((Event*)_parent).name];
        }
    } else {
        DetailViewController *controller = (DetailViewController*)c;
        controller.detailItem = [_items objectAtIndex:lastTappedThumb];
    }
}
- (NSString *)getPreviewSegueIdForThumb:(int)thumbIndex {
    isMoreTapped = NO;
    lastTappedThumb = thumbIndex;
    
    CALObject *item = [_items objectAtIndex:thumbIndex];
    if(item.key != nil) {
        return @"detail";
    } else {
        return nil;
    }
}
- (NSString *)getMoreSegueId {
    isMoreTapped = YES;
    lastTappedThumb = -1;
    return _segueId;
}
-(BOOL)showMoreButton {
    return _items.count>5 && _segueId != nil;
}
- (NSString *)getLabel {
    return NSLocalizedString(_labelKey, @"Key of message to display");
}
- (UIImage *)getIcon {
    return _icon;
}
-(BOOL)shouldShow {
    return _items.count>0;
}
- (UIColor *)colorFor:(NSInteger)index {
    CALObject *item = [_items objectAtIndex:index];
    UIColor *color = [UIColor whiteColor];
    if([item isKindOfClass:[User class]]) {
        color = [_uiService colorForObject:item];
    }
    return color;
}
@end

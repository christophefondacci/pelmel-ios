//
//  ConversionService.m
//  nativeTest
//
//  Created by Christophe Fondacci on 05/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "ConversionService.h"
#import <CoreLocation/CoreLocation.h>
#import "TogaytherService.h"

@implementation ConversionService {
    CLGeocoder *_geocoder;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _geocoder = [[CLGeocoder alloc] init];
    }
    return self;
}

-(int)getFeetFromCm:(double)cm {
    double inches = cm/2.54f;
    
    return (int) (inches / 12);
}
-(int)getInchesFromCm:(double)cm {
    double inches = cm/2.54f;
    return ((int)inches % 12);
}
- (double)getCmFromFeet:(int)feets inches:(int)inches {
    double cm = ((double)feets)*30.48f+((double)inches)*2.54f;
    return cm;
}
- (NSString *)getHeightLabel:(double)measureInCm imperial:(BOOL)isImperial {
    if(isImperial) {
        int feet = [self getFeetFromCm:measureInCm];
        int inches = [self getInchesFromCm:measureInCm];
        return [[NSString alloc] initWithFormat:@"%d ' %d ''",feet,inches];
    } else {
        return [[NSString alloc] initWithFormat:@"%d cm",(int)measureInCm];
    }
}
- (NSString *)getWeightLabel:(float)weightInKg imperial:(BOOL)isImperial {
    if(isImperial) {
        float pounds = weightInKg / 0.45359237;
        return [[NSString alloc]initWithFormat:@"%d lb",(int)pounds];
    } else {
        return [[NSString alloc] initWithFormat:@"%d kg",(int)weightInKg];
    }
}

- (NSString *)distanceTo:(CALObject *)p {
    CLLocation *placeLoc = [[CLLocation alloc] initWithLatitude:p.lat longitude:p.lng];
    CLLocation *userLoc = TogaytherService.userService.currentLocation;
    if(userLoc != nil) {
        CLLocationDistance distance = [placeLoc distanceFromLocation:userLoc];
        
        NSLocale *locale = [NSLocale currentLocale];
        BOOL isMetric = [[locale objectForKey:NSLocaleUsesMetricSystem] boolValue];
        
        NSString *currentTemplate;
        double currentValue = 0;
        if(isMetric) {
            if(distance > 1000) {
                currentTemplate = @"distance.template.kilometers";
                currentValue = distance/100;
                currentValue = (double)(int)currentValue;
                currentValue = currentValue/10;
            } else {
                currentTemplate =@"distance.template.meters";
                currentValue = (double)(int)distance;
            }
        } else {
            double miles = distance / 1609.34;
            if(miles < 0.5) {
                double feet = distance / 0.3048;
                currentTemplate = @"distance.template.feet";
                currentValue = (double)(int)feet;
            } else {
                currentTemplate = @"distance.template.miles";
                currentValue = (double)(int)(miles*10.0);
                currentValue = round(currentValue);
                currentValue = currentValue / 10.0;
            }
        }
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        NSString *formattedNumberString = [numberFormatter stringFromNumber:[NSNumber numberWithDouble:currentValue]];
        return [NSString stringWithFormat:NSLocalizedString(currentTemplate,@"template"),formattedNumberString];
    } else {
        return nil;
    }
}

-(void)geocodeAddressFor:(CALObject *)object completion:(AddressClosure)closure {
    // Geocoding
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:object.lat longitude:object.lng];
    [_geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
        if(error == nil && placemarks.count>0) {
            // Getting first result
            CLPlacemark *placemark = placemarks[0];
            
            NSArray *addressLines = [placemark.addressDictionary objectForKey:@"FormattedAddressLines"];
            NSMutableString *address = [[NSMutableString alloc ] init];
            NSString *separator = @"";
            for(NSString *addressLine in addressLines) {
                [address appendString:separator];
                [address appendString:addressLine];
                separator = @", ";
            }
            // Calling back
            if(closure != nil) {
                closure(address);
            }
        }
    }];

}
/**
 * Informs whether the special is currently valid or not
 */
-(SpecialMode) specialModeFor:(Special*)special {
    NSDate *date = [NSDate date];
    if(([special.nextStart compare:special.nextEnd] == NSOrderedDescending ||[date compare:special.nextStart] == NSOrderedDescending)) {
        if([date compare:special.nextEnd] == NSOrderedAscending) {
            return CURRENT;
        } else {
            return PAST;
        }
    } else {
        return SOON;
    }
}
-(Special*)specialFor:(CALObject*)place ofType:(NSString *)specialType{
    Special *bestSpecial = nil;
    if([place isKindOfClass:[Place class]]) {
        NSArray *specials = ((Place*)place).specials;
        for(Special *special in specials) {
            if([special.type isEqualToString:specialType]) {
                bestSpecial = special;
            }
        }
    }
    return bestSpecial;
}
@end

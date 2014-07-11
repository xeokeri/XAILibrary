//
//  UIColorRGBValueTransformer.m
//  XAIDataStorage
//
//  Created by Xeon Xai <xeonxai@me.com> on 7/4/10.
//  Copyright (c) 2010 Black Panther White Leopard. All rights reserved.
//

#import "UIColorRGBValueTransformer.h"

@implementation UIColorRGBValueTransformer

+ (Class)transformedValueClass {
    return [NSData class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

#pragma mark - UIColor to NSData

- (id)transformedValue:(id)value {
    UIColor *transformColor    = (UIColor *) value;
    NSInteger numberOfCompents = CGColorGetNumberOfComponents(transformColor.CGColor);
    const CGFloat *components  = CGColorGetComponents(transformColor.CGColor);
    
    CGFloat
        red   = 1.0f,
        green = 1.0f,
        blue  = 1.0f,
        alpha = 1.0f;
    
    switch (numberOfCompents) {
        case 2: { // UIDeviceWhiteColorSpace
            red   = components[0];
            green = components[0];
            blue  = components[0];
            alpha = components[1];
        }
            
            break;
            
        case 4: { // UIDeviceRGBColorSpace
            red   = components[0];
            green = components[1];
            blue  = components[2];
            alpha = components[3];
        }
            
            break;
            
        default:
            
            break;
    }
    
    NSString *colorAsString = [NSString stringWithFormat:
                               @"%f,%f,%f,%f",
                               red,
                               green,
                               blue,
                               alpha];
    
    return [colorAsString dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark - NSData to UIColor

- (id)reverseTransformedValue:(id)value {
    NSString *colorAsString = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
    NSArray *colorComponents = [colorAsString componentsSeparatedByString:@","];
    
    #if !__has_feature(objc_arc)
        [colorAsString release];
    #endif
    
    CGFloat
        red   = [[colorComponents objectAtIndex:0] floatValue],
        green = [[colorComponents objectAtIndex:1] floatValue],
        blue  = [[colorComponents objectAtIndex:2] floatValue],
        alpha = [[colorComponents objectAtIndex:3] floatValue];
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

@end

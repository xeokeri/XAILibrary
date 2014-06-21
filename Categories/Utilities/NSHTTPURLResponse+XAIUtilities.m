//
//  NSHTTPURLResponse+XAIUtilities.m
//  XAILibrary Category
//
//  Created by Xeon Xai <xeonxai@me.com> on 6/20/14.
//  Copyright (c) 2011-2014 Black Panther White Leopard. All rights reserved.
//

#import "NSHTTPURLResponse+XAIUtilities.h"

NSString * const kXAIUtilitiesLastModifiedHeaderKey  = @"Last-Modified";
NSString * const kXAIUtilitiesLastModifiedDateFormat = @"EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz";

@implementation NSHTTPURLResponse (XAIUtilities)

- (NSDate *)lastModifiedDate {
    NSDictionary *headers  = [self allHeaderFields];
    
    if (![[headers allKeys] containsObject:kXAIUtilitiesLastModifiedHeaderKey]) {
        return nil;
    }
    
    NSString *lastModifiedHeader   = [headers objectForKey:kXAIUtilitiesLastModifiedHeaderKey];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:kXAIUtilitiesLastModifiedDateFormat];
    
    NSDate *filteredDate = [dateFormatter dateFromString:lastModifiedHeader];
    
    #if !__has_feature(objc_arc)
        [dateFormatter release];
    #endif
    
    return filteredDate;
}

@end

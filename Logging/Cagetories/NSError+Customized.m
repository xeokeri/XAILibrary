//
//  NSError+Customized.m
//  XAILogging
//
//  Created by Xeon Xai on 3/16/12.
//  Copyright (c) 2012 Bonnier Corp. All rights reserved.
//

#import "NSError+Customized.h"
#import <CoreData/CoreData.h>

@implementation NSError (Customized)

#pragma mark - Error Logging

- (void)logDetailsFailedOnSelector:(SEL)failedSelector line:(NSUInteger)lineNumber {
    NSArray *errors = [[self userInfo] objectForKey:NSDetailedErrorsKey];
    
    for (NSError *detailedError in errors) {
        NSLog(@"Error on %@: %@", [[detailedError userInfo] valueForKey:NSValidationKeyErrorKey], [[detailedError userInfo] valueForKey:NSValidationObjectErrorKey]);
    }
    
    NSLog(@"%@, Line %d, %@", NSStringFromSelector(failedSelector), lineNumber, [self localizedDescription]);
}

@end

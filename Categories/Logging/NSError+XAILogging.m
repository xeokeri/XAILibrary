//
//  NSError+XAILogging.m
//  XAILibrary Category
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/16/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "NSError+XAILogging.h"
#import <CoreData/CoreData.h>

@implementation NSError (XAILogging)

#pragma mark - Error Logging

- (void)logDetailsFailedOnSelector:(SEL)failedSelector line:(NSUInteger)lineNumber {
    if (!kLogErrorDebugging) {
        return;
    }
    
    NSArray *detailedErrors      = [[self userInfo] objectForKey:NSDetailedErrorsKey];
    NSArray *conflictErrors      = [[self userInfo] objectForKey:NSPersistentStoreSaveConflictsErrorKey];
    NSString *validationErrorKey = [[self userInfo] objectForKey:NSValidationKeyErrorKey];
    
    NSLog(@"Error: %@, Line %lu, %@", NSStringFromSelector(failedSelector), (unsigned long)lineNumber, [self localizedDescription]);
    
    if (validationErrorKey) {
        NSLog(@"Validation Error for key: %@\n%@", validationErrorKey, [[self userInfo] objectForKey:NSValidationObjectErrorKey]);
    }
    
    for (NSError *detailedError in detailedErrors) {
        NSLog(@"Error on %@: %@", [[detailedError userInfo] valueForKey:NSValidationKeyErrorKey], [[detailedError userInfo] valueForKey:NSValidationObjectErrorKey]);
    }
    
    for (NSMergeConflict *conflictError in conflictErrors) {
        NSLog(@"Conflict: %@", [conflictError description]);
    }
}

@end

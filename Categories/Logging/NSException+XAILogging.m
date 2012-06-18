//
//  NSException+XAILogging.m
//  XAILibrary Category
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/16/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "NSException+XAILogging.h"
#import <CoreData/CoreData.h>

@implementation NSException (XAILogging)

#pragma mark - Exception Logging

- (void)logDetailsFailedOnSelector:(SEL)failedSelector line:(NSUInteger)lineNumber onClass:(NSString *)exceptionOnClass {
    NSArray *exceptions = [[self userInfo] objectForKey:NSDetailedErrorsKey];
    
    for (NSError *detailedException in exceptions) {
        if (kLogExceptionDebugging) {
            NSLog(@"Exception: %@, %@, Line %d, %@", exceptionOnClass, NSStringFromSelector(failedSelector), lineNumber, [[detailedException userInfo] valueForKey:NSValidationKeyErrorKey]);
        }
    }
    
    if (kLogExceptionDebugging) {
        NSLog(@"Exception: %@, %@, Line %d, %@", exceptionOnClass, NSStringFromSelector(failedSelector), lineNumber, [self reason]);
    }
}

@end

//
//  NSException+XAILogging.m
//  XAILibrary Category
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/16/12.
//  Copyright (c) 2011-2014 Black Panther White Leopard. All rights reserved.
//

#import "NSException+XAILogging.h"
#import <CoreData/CoreData.h>

@implementation NSException (XAILogging)

#pragma mark - Exception Logging

- (void)logDetailsFailedOnSelector:(SEL)failedSelector line:(NSUInteger)lineNumber onClass:(NSString *)exceptionOnClass {
    #ifndef DEBUG
        return;
    #endif
    
    NSArray *exceptions = [self userInfo][NSDetailedErrorsKey];
    
    for (NSError *detailedException in exceptions) {
        NSLog(@"Exception: %@, %@, Line %lu, %@", exceptionOnClass, NSStringFromSelector(failedSelector), (unsigned long) lineNumber, [detailedException userInfo][NSValidationKeyErrorKey]);
    }
    
    NSLog(@"Exception: %@, %@, Line %lu, %@\n %@", exceptionOnClass, NSStringFromSelector(failedSelector), (unsigned long) lineNumber, [self reason], [self callStackSymbols]);
}

@end

//
//  NSException+Customized.m
//  XAILogging
//
//  Created by Xeon Xai on 3/16/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "NSException+Customized.h"
#import <CoreData/CoreData.h>

@implementation NSException (Customized)

#pragma mark - Exception Logging

- (void)logDetailsFailedOnSelector:(SEL)failedSelector line:(NSUInteger)lineNumber {
    NSArray *exceptions = [[self userInfo] objectForKey:NSDetailedErrorsKey];
    
    for (NSError *detailedException in exceptions) {
        NSLog(@"Exception: %@", [[detailedException userInfo] valueForKey:NSValidationKeyErrorKey]);
    }
    
    NSLog(@"%@, Line %d, %@", NSStringFromSelector(failedSelector), lineNumber, [self reason]);
}

@end

//
//  NSException+XAILogging.h
//  XAILibrary Category
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/16/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kLogExceptionDebugging     YES

@interface NSException (XAILogging)

- (void)logDetailsFailedOnSelector:(SEL)failedSelector line:(NSUInteger)lineNumber onClass:(NSString *)exceptionOnClass;

@end

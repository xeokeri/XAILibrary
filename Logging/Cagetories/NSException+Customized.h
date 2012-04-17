//
//  NSException+Customized.h
//  XAILogging
//
//  Created by Xeon Xai on 3/16/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSException (Customized)

- (void)logDetailsFailedOnSelector:(SEL)failedSelector line:(NSUInteger)lineNumber;

@end

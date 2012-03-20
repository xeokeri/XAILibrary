//
//  NSError+Customized.h
//  XAILogging
//
//  Created by Xeon Xai on 3/16/12.
//  Copyright (c) 2012 Bonnier Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (Customized)

- (void)logDetailsFailedOnSelector:(SEL)failedSelector line:(NSUInteger)lineNumber;

@end

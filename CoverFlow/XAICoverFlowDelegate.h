//
//  XAICoverFlowDelegate.h
//  XAICoverFlow
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/29/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - XAICoverFlow Delegate

@protocol XAICoverFlowDelegate <NSObject>

@required
- (void)coverPanel:(XAICoverFlowPanel *)coverPanel wasDoubleTappedAtIndex:(NSUInteger)idx;

@end

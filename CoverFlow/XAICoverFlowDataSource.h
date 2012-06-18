//
//  XAICoverFlowDataSource.h
//  XAICoverFlow
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/29/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - XAICoverFlow Data Source

@protocol XAICoverFlowDataSource <NSObject>

@optional
- (NSString *)imageNameForCoverFlowPanelAtIndex:(NSUInteger)idx;
- (NSString *)urlForCoverFlowPanelAtIndex:(NSUInteger)idx;

@required
- (NSUInteger)coverFlowNumberOfPanels;

@end
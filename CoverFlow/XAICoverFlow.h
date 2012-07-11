//
//  XAICoverFlow.h
//  XAICoverFlow
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/29/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

/** XAIImageCache */
#import "XAIImageCacheDelegate.h"

@class XAICoverFlowPanel;
@protocol XAICoverFlowDelegate, XAICoverFlowDataSource;

@interface XAICoverFlow : UIScrollView <UIScrollViewDelegate, XAIImageCacheDelegate> {
    @private
    id <XAICoverFlowDelegate> __unsafe_unretained coverFlowDelegate;
    id <XAICoverFlowDataSource> coverFlowDataSource;
    
    CATransform3D leftSideTransform;
    CATransform3D rightSideTransform;
    
    CGSize coverPanelSize;
    
    CGFloat coverPanelSpace;
    CGFloat coverPanelAngle;
    CGFloat lastPosition;
    
    NSInteger lastIndex;
    NSInteger motionSpeed;
    
    NSUInteger numberOfPanels;
    NSUInteger coverPanelBuffer;
    
    UIView *touchedView;
    
    NSMutableArray *panelPlaceholders;
    NSMutableArray *panelViews;
    NSMutableSet   *panelQueue;
    
    NSRange coverPanelRange;
    
    BOOL directionOfMovementRight;
}

@property (nonatomic, unsafe_unretained) id <XAICoverFlowDelegate> coverFlowDelegate;
@property (nonatomic, strong) id <XAICoverFlowDataSource> coverFlowDataSource;
@property (nonatomic) CATransform3D leftSideTransform;
@property (nonatomic) CATransform3D rightSideTransform;
@property (nonatomic) CGSize coverPanelSize;
@property (nonatomic) CGFloat coverPanelSpace;
@property (nonatomic) CGFloat coverPanelAngle;
@property (nonatomic) CGFloat lastPosition;
@property (nonatomic) NSInteger lastIndex;
@property (nonatomic) NSInteger motionSpeed;
@property (nonatomic) NSUInteger numberOfPanels;
@property (nonatomic) NSUInteger coverPanelBuffer;
@property (nonatomic, strong) IBOutlet UIView *touchedView;
@property (nonatomic, strong) NSMutableArray *panelPlaceholders;
@property (nonatomic, strong) NSMutableArray *panelViews; /** @todo fix name. */
@property (nonatomic, strong) NSMutableSet *panelQueue;
@property (nonatomic) NSRange coverPanelRange;
@property (nonatomic, getter = isDirectionOfMovementRight) BOOL directionOfMovementRight;

- (id)initWithFrame:(CGRect)frame delegate:(id)incomingDelegate dataSource:(id)incomingDataSource;

@end

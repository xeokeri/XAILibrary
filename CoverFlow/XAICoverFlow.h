//
//  XAICoverFlow.h
//  CoverFlow
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/29/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#define kXAICoverFlowMotionSpeedUpdateMaximum   180
#define kXAICoverFlowPanelBufferPadding         3
#define kXAICoverFlowPanelEndCap                15

#define kXAICoverFlowPanelSpace                 70.0f
#define kXAICoverFlowPanelSpaceSubdivide        2.4f
#define kXAICoverFlowPanelAngle                 1.4f

#define kXAICoverFlowPanelAnimationSpeedSlow    0.5f
#define kXAICoverFlowPanelAnimationSpeedFast    0.2f

#define kXAICoverFlowPanelSizeWidth             224.0f
#define kXAICoverFlowPanelSizeHeight            224.0f

#define kXAICoverFlowPanelTagPrefix             10000

#define kXAICoverFlowPanelAnimationIdFormat     @"XAICoverFlowAnimationForIndex:%d"

@class XAICoverFlowPanel;
@protocol XAICoverFlowDelegate, XAICoverFlowDataSource;

@interface XAICoverFlow : UIScrollView <UIScrollViewDelegate> {
    @private
    id <XAICoverFlowDelegate> coverFlowDelegate;
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
    
    NSMutableArray *coverFlowViews;
    NSMutableArray *views;
    NSMutableArray *coverPanelQueue;
    
    NSRange coverPanelRange;
    
    BOOL directionOfMovementRight;
}

@property (nonatomic, assign) id <XAICoverFlowDelegate> coverFlowDelegate;
@property (nonatomic, retain) id <XAICoverFlowDataSource> coverFlowDataSource;
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
@property (nonatomic, retain) IBOutlet UIView *touchedView;
@property (nonatomic, retain) NSMutableArray *coverFlowViews;
@property (nonatomic, retain) NSMutableArray *views;
@property (nonatomic, retain) NSMutableArray *coverPanelQueue;
@property (nonatomic) NSRange coverPanelRange;
@property (nonatomic, getter = isDirectionOfMovementRight) BOOL directionOfMovementRight;

- (id)initWithFrame:(CGRect)frame delegate:(id)incomingDelegate dataSource:(id)incomingDataSource;

@end

#pragma mark - XAI Library Cover Flow Data Source

@protocol XAICoverFlowDataSource <NSObject>

@optional
- (NSString *)imageNameForCoverFlowPanelAtIndex:(NSUInteger)idx;
- (NSString *)urlForCoverFlowPanelAtIndex:(NSUInteger)idx;

@required
- (NSUInteger)coverFlowNumberOfPanels;

@end

#pragma mark - XAI Library Cover Flow Delegate

@protocol XAICoverFlowDelegate <NSObject>

@required
- (void)coverPanel:(XAICoverFlowPanel *)coverPanel wasDoubleTappedAtIndex:(NSUInteger)idx;

@end

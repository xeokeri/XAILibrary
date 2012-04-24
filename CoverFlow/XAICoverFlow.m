//
//  XAICoverFlow.m
//  CoverFlow
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/29/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "XAICoverFlow.h"
#import "XAICoverFlowPanel.h"

@interface XAICoverFlow()

- (XAICoverFlowPanel *)coverPanelAtIndex:(NSUInteger)idx;

- (void)updateAllCoverPanels;
- (void)configureTransformations;
- (void)configureCoverPanelRange;

- (void)destroyCoverPanelsFrom:(NSUInteger)from to:(NSUInteger)to;
- (void)loadCoverPanelsFrom:(NSUInteger)from to:(NSUInteger)to;

- (void)jumpToCurrentCoverPanelAnimated:(BOOL)animated;
- (void)moveToIndex:(NSUInteger)idx animated:(BOOL)animated;

@end

@implementation XAICoverFlow

@synthesize coverFlowDelegate, coverFlowDataSource;
@synthesize coverPanelAngle, coverPanelSize, coverPanelSpace;
@synthesize leftSideTransform, rightSideTransform;
@synthesize numberOfPanels, lastIndex, lastPosition, motionSpeed, coverPanelBuffer;
@synthesize touchedView, coverFlowViews, views, coverPanelQueue, coverPanelRange;

@synthesize directionOfMovementRight;

#pragma mark - Memory Management

- (void)dealloc {
    coverFlowDelegate = nil;
    [coverFlowDataSource release], coverFlowDataSource = nil;
    [touchedView release], touchedView = nil;
    [coverFlowViews release], coverFlowViews = nil;
    [views release], views = nil;
    [coverPanelQueue release], coverPanelQueue = nil;
    
    [super dealloc];
}

- (void)viewDidUnload {
    self.touchedView = nil;
}

#pragma mark - Init

- (id)initWithFrame:(CGRect)frame delegate:(id)incomingDelegate dataSource:(id)incomingDataSource {
    self = [self initWithFrame:frame];
    
    if (self) {
        /** Configure Delegate and DataSource */
        self.coverFlowDelegate   = incomingDelegate;
        self.coverFlowDataSource = incomingDataSource;
        
        /** Configure Defaults. */
        self.coverPanelSpace     = kXAICoverFlowPanelSpace;
        self.coverPanelAngle     = kXAICoverFlowPanelAngle;
        self.coverPanelSize      = CGSizeMake(kXAICoverFlowPanelSizeWidth, kXAICoverFlowPanelSizeHeight);
        self.numberOfPanels      = 0;
        self.lastIndex           = -1;
        
        /** UIScrollView Indicators */
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator   = NO;
        
        /** Configure Sublayer Transformation. */
        CATransform3D subLayerTranform = CATransform3DIdentity;
        
        subLayerTranform.m34 = -0.001;
        
        [self.layer setSublayerTransform:subLayerTranform];
        
        /** UIScrollView Delegate */
        self.delegate = self;
        
        /** Initialize the arrays. */
        self.coverFlowViews  = [NSMutableArray array];
        self.views           = [NSMutableArray array];
        self.coverPanelQueue = [NSMutableArray array];
        
        /** Set the default colors. */
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        // Initialization code
        self.contentSize = CGSizeMake(frame.size.width, frame.size.height);
    }
    
    return self;
}

- (void)didMoveToSuperview {
    [self configureTransformations];
    
    if (![self.coverFlowDataSource respondsToSelector:@selector(coverFlowNumberOfPanels)]) {
        return;
    }
    
    self.coverPanelRange  = NSMakeRange(0, 0);
    self.numberOfPanels   = [self.coverFlowDataSource coverFlowNumberOfPanels];
    
    self.contentSize      = ((self.numberOfPanels == 0) ? CGSizeZero : CGSizeMake(self.coverPanelSpace * (self.numberOfPanels - 1) + self.frame.size.width, self.frame.size.height));
    self.coverPanelBuffer = (NSUInteger) abs(((self.frame.size.width - self.coverPanelSize.width) / self.coverPanelSpace) + kXAICoverFlowPanelBufferPadding);

    for (NSUInteger i = 0; i < self.numberOfPanels; i++) {
        [self.coverFlowViews addObject:[NSNull null]];
    }
    
    [self configureCoverPanelRange];
}

- (void)layoutSubviews {
    if (self.lastIndex >= 0) {
        return;
    }

    self.lastIndex = 0;
    
    [self configureCoverPanelRange];
    
    [self moveToIndex:self.lastIndex animated:YES];
}

#pragma mark - NSRange

- (void)configureCoverPanelRange {
    NSUInteger destroyTo = 0, destroyFrom = 0, loadTo = 0, loadFrom = 0;
        
    NSInteger currentIndex     = (NSInteger) self.lastIndex;
    NSInteger currentBuffer    = (NSInteger) self.coverPanelBuffer;
    NSUInteger currentLocation = self.coverPanelRange.location;
    NSUInteger currentLength   = self.coverPanelRange.length;
    
    NSUInteger updatedLocation = (((NSInteger) self.lastIndex - (NSInteger) self.coverPanelBuffer) < 0) ? 0 : self.lastIndex - self.coverPanelBuffer;
    NSUInteger updatedLength   = ((currentIndex + currentBuffer) > self.numberOfPanels) ? (self.numberOfPanels - updatedLocation) : ((currentIndex + currentBuffer) - updatedLocation);

    if (currentLocation == updatedLocation && currentLength == updatedLength) {
        return;
    }
    
    if (self.isDirectionOfMovementRight) {
        destroyFrom = abs(currentLocation);
        destroyTo   = abs(MIN(updatedLocation, currentLocation + currentLength));
               
        loadFrom    = abs(MAX(currentLocation + currentLength, updatedLocation));
        loadTo      = abs(updatedLocation + updatedLength);
    } else {
        destroyFrom = abs(MAX(updatedLocation + updatedLength, currentLocation));
        destroyTo   = abs(currentLocation + currentLength);
        
        loadFrom    = abs(updatedLocation);
        loadTo      = abs(updatedLocation + updatedLength);
    }
        
    [self destroyCoverPanelsFrom:destroyFrom to:destroyTo];
    [self loadCoverPanelsFrom:loadFrom to:loadTo];
    
    NSRange updateRange = NSMakeRange(0, self.numberOfPanels);
    
    self.coverPanelRange = NSIntersectionRange(updateRange, NSMakeRange(updatedLocation, updatedLength));
}

#pragma mark - CATransform3D Configuration

- (void)configureTransformations {
    CGFloat coverPanelSpaceToFront = (self.coverPanelSize.width / kXAICoverFlowPanelSpaceSubdivide);
    
    CATransform3D leftSideA  = CATransform3DMakeRotation(self.coverPanelAngle, 0.0f, 1.0f, 0.0f);
    CATransform3D rightSideA = CATransform3DMakeRotation(-self.coverPanelAngle, 0.0f, 1.0f, 0.0f);
    
    CATransform3D leftSideB  = CATransform3DMakeTranslation(-coverPanelSpaceToFront, 0.0f, -300.f);
    CATransform3D rightSideB = CATransform3DMakeTranslation(coverPanelSpaceToFront, 0.0f, -300.f);
    
    self.leftSideTransform   = CATransform3DConcat(leftSideA, leftSideB);
    self.rightSideTransform  = CATransform3DConcat(rightSideA, rightSideB);
}

#pragma mark - UIScrollView Delegates

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat nextPosition = scrollView.contentOffset.x;
    
    self.motionSpeed  = (NSInteger) abs(self.lastPosition - nextPosition);
    self.directionOfMovementRight = ((nextPosition - self.lastPosition) > 0);
    self.lastPosition = nextPosition;
    
    CGFloat offset = (self.numberOfPanels * (self.lastPosition / (self.contentSize.width - self.frame.size.width)));
    CGFloat middle = (offset + ((1.0f - (offset / (self.numberOfPanels * 0.5f))) * 0.5f));
    
    NSInteger currentIndex = (NSInteger) floorf(middle);
    
    if (currentIndex < 0) {
        currentIndex = 0;
    }
    
    if ((self.numberOfPanels > 0) && (currentIndex == self.numberOfPanels)) {
        currentIndex = (self.numberOfPanels - 1);
    }
    
    if (currentIndex == self.lastIndex) {
        return;
    }
    
    self.lastIndex = currentIndex;
    
    [self configureCoverPanelRange];
    
    if ((self.motionSpeed < kXAICoverFlowMotionSpeedUpdateMaximum) || (self.lastIndex < kXAICoverFlowPanelEndCap) || (self.lastIndex > (self.numberOfPanels - kXAICoverFlowPanelEndCap))) {
        [self moveToIndex:currentIndex animated:YES];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!scrollView.decelerating && !decelerate) {
        [self jumpToCurrentCoverPanelAnimated:YES];
        [self updateAllCoverPanels];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (!scrollView.tracking && !scrollView.decelerating) {
        [self jumpToCurrentCoverPanelAnimated:YES];
        [self updateAllCoverPanels];
    }
}

#pragma mark - UITouch Events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    
    if (touch.view != self && [touch locationInView:touch.view].y < self.coverPanelSize.height) {
        self.touchedView = touch.view;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    
    if ([touch.view isEqual:self.touchedView]) {
        NSUInteger idx = (NSUInteger) abs(self.touchedView.tag - kXAICoverFlowPanelTagPrefix);
        
        if (touch.tapCount > 1 && self.lastIndex == idx) {
            if ([self.coverFlowDelegate respondsToSelector:@selector(coverPanel:wasDoubleTappedAtIndex:)]) {
                [self.coverFlowDelegate coverPanel:(XAICoverFlowPanel *)touch.view wasDoubleTappedAtIndex:idx];
            }
        } else {
            self.lastIndex = idx;
            
            [self jumpToCurrentCoverPanelAnimated:YES];
        }
    }
    
    self.touchedView = nil;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.touchedView != nil) {
        self.touchedView = nil;
    }
}

#pragma mark - UIViewAnimation Callback

- (void)coverFlowPanelAnimationDidEnd:(NSString *)panelAnimationId finished:(NSNumber *)finished context:(void *)context {
    if ([finished boolValue] == YES) {
        [self updateAllCoverPanels];
        
        NSString *animationId = [NSString stringWithFormat:kXAICoverFlowPanelAnimationIdFormat, self.lastIndex];
        
        if ([animationId isEqualToString:panelAnimationId]) {
            /** @todo Handle Delegate... */
        }
    }
}

#pragma mark - Update Content

- (void)moveToIndex:(NSUInteger)idx animated:(BOOL)animated {
    NSUInteger currentTag = (kXAICoverFlowPanelTagPrefix + idx);
    
    if (self.motionSpeed > kXAICoverFlowMotionSpeedUpdateMaximum) {
        animated = NO;
    }
    
    if (animated == YES) {
        NSString *animationId = [NSString stringWithFormat:kXAICoverFlowPanelAnimationIdFormat, idx];
        CGFloat durationSpeed = self.motionSpeed > floorf(kXAICoverFlowMotionSpeedUpdateMaximum * 0.5f) ? kXAICoverFlowPanelAnimationSpeedFast : kXAICoverFlowPanelAnimationSpeedSlow;
        
        [UIView beginAnimations:animationId context:nil];
        [UIView setAnimationDuration:durationSpeed];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(coverFlowPanelAnimationDidEnd:finished:context:)];
    }
    
    for (UIView *subView in self.views) {
        
        if (![subView isKindOfClass:[XAICoverFlowPanel class]]) {
            continue;
        }
        
        NSInteger viewTag = subView.tag;
        
        if (viewTag < currentTag) {
            subView.layer.transform = self.leftSideTransform;
        } else if (viewTag > currentTag) {
            subView.layer.transform = self.rightSideTransform;
        } else {
            subView.layer.transform = CATransform3DIdentity;
        }
    }
    
    if (animated == YES) {
        [UIView commitAnimations];
    }
}

- (void)jumpToCurrentCoverPanelAnimated:(BOOL)animated {
    CGPoint offsetPoint = CGPointZero;

    UIView *currentPanel = [self.coverFlowViews objectAtIndex:self.lastIndex];
    
    if (currentPanel == nil) {
        return;
    }
    
    if ([currentPanel isKindOfClass:[XAICoverFlowPanel class]]) {
        offsetPoint = CGPointMake(floorf(currentPanel.center.x - (self.frame.size.width * 0.5f)), 0.0f);
    } else {
        offsetPoint = CGPointMake(floorf(self.coverPanelSpace * self.lastIndex), 0.0f);
    }
    
    [self setContentOffset:offsetPoint animated:YES];
}

- (void)updateAllCoverPanels {
    for (UIView *panel in self.coverFlowViews) {
        if ([panel isKindOfClass:[XAICoverFlowPanel class]]) {
            NSUInteger currentIndex = (panel.tag - kXAICoverFlowPanelTagPrefix);
            
            if (self.lastIndex != currentIndex) {
                [self sendSubviewToBack:panel];
            } else {
                [self bringSubviewToFront:panel];
            }
        }
    }
}

- (void)destroyCoverPanelsFrom:(NSUInteger)from to:(NSUInteger)to {
    if (from > to) {
        return;
    }

    for (NSUInteger i = from; i < to; i++) {
        
        if (i >= [self.coverFlowViews count]) {
            break;
        }
        
        if ([self.coverFlowViews objectAtIndex:i] != [NSNull null]) {
            XAICoverFlowPanel *panel = [self.coverFlowViews objectAtIndex:i];
            
            [panel removeFromSuperview];
            
            [self.views removeObject:panel];
            [self.coverPanelQueue addObject:panel];
            [self.coverFlowViews replaceObjectAtIndex:i withObject:[NSNull null]];
        }
    }
}

- (void)loadCoverPanelsFrom:(NSUInteger)from to:(NSUInteger)to {
    if (from > to) {
        return;
    }
    
    for (NSUInteger i = from; i < to; i++) {
        if (i >= [self.coverFlowViews count]) {
            break;
        }
        
        if ([self.coverFlowViews objectAtIndex:i] == [NSNull null]) {
            XAICoverFlowPanel *panel = [self coverPanelAtIndex:i];
            
            [self.coverFlowViews replaceObjectAtIndex:i withObject:panel];
            [self addSubview:panel];
            
            if (i > self.lastIndex) {
                panel.layer.transform = rightSideTransform;
                
                [self sendSubviewToBack:panel];
            } else {
                panel.layer.transform = leftSideTransform;
            }
            
            [self.views addObject:panel];
        }
    }
}

#pragma mark - XAICoverFlowPanel View

- (XAICoverFlowPanel *)coverPanelAtIndex:(NSUInteger)idx {
    if ([[self.coverFlowViews objectAtIndex:idx] isKindOfClass:[XAICoverFlowPanel class]]) {
        return (XAICoverFlowPanel *) [self.coverFlowViews objectAtIndex:idx];
    }
    
    NSUInteger panelTag = kXAICoverFlowPanelTagPrefix + idx;
    
    CGFloat
        width   = self.coverPanelSize.width,
        height  = self.coverPanelSize.height,
        xOffset = floorf(((self.frame.size.width * 0.5f) - (width * 0.5f)) + (self.coverPanelSpace * idx)),
        yOffset = floorf((self.frame.size.height * 0.5f) - (height * 0.5f));
    
    XAICoverFlowPanel *panel = [[[XAICoverFlowPanel alloc] initWithFrame:CGRectMake(xOffset, yOffset, width, height)] autorelease];
    
    panel.tag = panelTag;
    
    if ([self.coverFlowDataSource respondsToSelector:@selector(urlForCoverFlowPanelAtIndex:)]) {
        NSString *imageURL = [self.coverFlowDataSource urlForCoverFlowPanelAtIndex:idx];
        
        [panel imageWithURL:imageURL size:self.coverPanelSize];
    } else if ([self.coverFlowDataSource respondsToSelector:@selector(imageNameForCoverFlowPanelAtIndex:)]) {
        NSString *imageName = [self.coverFlowDataSource urlForCoverFlowPanelAtIndex:idx];
        
        [panel processCachedImage:[UIImage imageNamed:imageName]];
    }
    
    return panel;
}

@end

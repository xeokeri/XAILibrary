//
//  XAICoverFlow.m
//  XAICoverFlow
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/29/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "XAICoverFlow.h"
#import "XAICoverFlowPanel.h"
#import "XAICoverFlowDefines.h"

/** XAICoverFlow Protocols */
#import "XAICoverFlowDelegate.h"
#import "XAICoverFlowDataSource.h"

/** XAIImageCache */
#import "XAIImageCacheQueue.h"
#import "UIScrollView+XAIImageCache.h"

@interface XAICoverFlow()

- (XAICoverFlowPanel *)coverPanelAtIndex:(NSUInteger)idx;

- (CGRect)frameForPanelAtIndex:(NSUInteger)idx;

- (void)updateAllCoverPanels;
- (void)configureTransformations;
- (void)configureCoverPanelRange;

- (void)destroyCoverPanelsFrom:(NSUInteger)from to:(NSUInteger)to;
- (void)loadCoverPanelsFrom:(NSUInteger)from to:(NSUInteger)to;

- (void)jumpToCurrentCoverPanelAnimated:(BOOL)animated;
- (void)moveToIndex:(NSUInteger)idx animated:(BOOL)animated;

@end

@implementation XAICoverFlow

@synthesize coverFlowDelegate   = __coverFlowDelegate;
@synthesize coverFlowDataSource = __coverFlowDataSource;

@synthesize coverPanelAngle, coverPanelSize, coverPanelSpace;
@synthesize leftSideTransform, rightSideTransform;
@synthesize numberOfPanels, lastIndex, lastPosition, motionSpeed, coverPanelBuffer;
@synthesize touchedView, panelPlaceholders, panelViews, panelQueue, coverPanelRange;

@synthesize directionOfMovementRight;

#pragma mark - Memory Management

- (void)dealloc {
    #if !__has_feature(objc_arc)
        [coverFlowDataSource release];
        [touchedView release];
        [panelPlaceholders release];
        [panelViews release];
        [panelQueue release];
    #endif
    
    coverFlowDelegate   = nil;
    coverFlowDataSource = nil;
    touchedView         = nil;
    panelPlaceholders   = nil;
    panelViews          = nil;
    panelQueue          = nil;
    
    #if !__has_feature(objc_arc)
        [super dealloc];
    #endif
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
        
        /** Initialize the arrays and sets. */
        self.panelPlaceholders = [NSMutableArray arrayWithCapacity:0];
        self.panelViews        = [NSMutableArray arrayWithCapacity:0];
        self.panelQueue        = [NSMutableSet setWithCapacity:0];
        
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
        [self.panelPlaceholders addObject:[NSNull null]];
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
    
    if ([touch.view isEqual:self.touchedView] && [touch.view isKindOfClass:[XAICoverFlowPanel class]]) {
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
    
    for (UIView *panel in self.panelViews) {
        if (![panel isKindOfClass:[XAICoverFlowPanel class]]) {
            continue;
        }
        
        NSInteger viewTag = panel.tag;
        
        if (viewTag < currentTag) {
            panel.layer.transform = self.leftSideTransform;
        } else if (viewTag > currentTag) {
            panel.layer.transform = self.rightSideTransform;
        } else {
            panel.layer.transform = CATransform3DIdentity;
        }
    }
    
    if (animated == YES) {
        [UIView commitAnimations];
    }
}

- (void)jumpToCurrentCoverPanelAnimated:(BOOL)animated {
    CGPoint offsetPoint = CGPointZero;

    UIView *currentPanel = [self.panelPlaceholders objectAtIndex:self.lastIndex];
    
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
    for (UIView *panel in self.panelPlaceholders) {
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
        if (i >= [self.panelPlaceholders count]) {
            break;
        }
        
        if ([self.panelPlaceholders objectAtIndex:i] != [NSNull null]) {
            XAICoverFlowPanel *panel = [self.panelPlaceholders objectAtIndex:i];
            
            if ([self.coverFlowDataSource respondsToSelector:@selector(urlForCoverFlowPanelAtIndex:)]) {
                NSString *urlForPanel = [self.coverFlowDataSource urlForCoverFlowPanelAtIndex:i];
                
                if (urlForPanel.length > 0) {
                    [[XAIImageCacheQueue sharedQueue] cancelOperationForURL:urlForPanel];
                }
            }
            
            [panel removeFromSuperview];
            
            [self.panelViews removeObject:panel];
            [self.panelQueue addObject:panel];
            [self.panelPlaceholders replaceObjectAtIndex:i withObject:[NSNull null]];
        }
    }
}

- (void)loadCoverPanelsFrom:(NSUInteger)from to:(NSUInteger)to {
    if (from > to) {
        return;
    }
    
    for (NSUInteger i = from; i < to; i++) {
        if (i >= [self.panelPlaceholders count]) {
            break;
        }
        
        if ([self.panelPlaceholders objectAtIndex:i] == [NSNull null]) {
            XAICoverFlowPanel *panel = [self coverPanelAtIndex:i];
            NSUInteger panelTag      = abs(kXAICoverFlowPanelTagPrefix + i);
            CGRect panelFrame        = [self frameForPanelAtIndex:i];
            
            [panel setFrame:panelFrame];
            [panel setTag:panelTag];
            
            [self.panelPlaceholders replaceObjectAtIndex:i withObject:panel];
            [self addSubview:panel];
            
            if ([self.coverFlowDataSource respondsToSelector:@selector(urlForCoverFlowPanelAtIndex:)]) {
                NSString *imageURL     = [self.coverFlowDataSource urlForCoverFlowPanelAtIndex:i];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                CGFloat cacheScale     = [[UIScreen mainScreen] scale];
                CGSize cacheSize       = self.coverPanelSize;
                
                if (cacheScale > 1.0f) {
                    cacheSize.width  = floorf(cacheSize.width * cacheScale);
                    cacheSize.height = floorf(cacheSize.height * cacheScale);
                }
                
                [self imageWithURL:imageURL atIndexPath:indexPath delegate:self size:cacheSize];
            } else if ([self.coverFlowDataSource respondsToSelector:@selector(imageNameForCoverFlowPanelAtIndex:)]) {
                NSString *imageName = [self.coverFlowDataSource urlForCoverFlowPanelAtIndex:i];
                UIImage *panelImage = [UIImage imageNamed:imageName];
                
                [panel processCachedImage:panelImage];
            }
            
            if (i > self.lastIndex) {
                panel.layer.transform = rightSideTransform;
                
                [self sendSubviewToBack:panel];
            } else {
                panel.layer.transform = leftSideTransform;
            }
            
            [self.panelViews addObject:panel];
        }
    }
}

#pragma mark - CGRect

- (CGRect)frameForPanelAtIndex:(NSUInteger)idx {
    CGFloat
        width   = self.coverPanelSize.width,
        height  = self.coverPanelSize.height,
        xOffset = floorf(((self.frame.size.width * 0.5f) - (width * 0.5f)) + fabsf(self.coverPanelSpace * idx)),
        yOffset = floorf((self.frame.size.height * 0.5f) - (height * 0.5f));
    
    return CGRectMake(xOffset, yOffset, width, height);
}

#pragma mark - XAICoverFlowPanel View

- (XAICoverFlowPanel *)coverPanelAtIndex:(NSUInteger)idx {
    if ([[self.panelPlaceholders objectAtIndex:idx] isKindOfClass:[XAICoverFlowPanel class]]) {
        return (XAICoverFlowPanel *) [self.panelPlaceholders objectAtIndex:idx];
    }
    
    XAICoverFlowPanel *panel = (XAICoverFlowPanel *) [self dequeueCoverFlowPanel];
    
    if (!panel) {
        CGRect panelFrame = [self frameForPanelAtIndex:idx];
        
        panel = [[XAICoverFlowPanel alloc] initWithFrame:panelFrame];
        
        #if !__has_feature(objc_arc)
            [panel autorelease];
        #endif
    }
    
    [panel setTransform:CGAffineTransformIdentity];
    
    return panel;
}

- (XAICoverFlowPanel *)dequeueCoverFlowPanel {
    XAICoverFlowPanel *panel = (XAICoverFlowPanel *) [self.panelQueue anyObject];
    
    if (panel) {
        #if !__has_feature(objc_arc)
            [[panel retain] autorelease];
        #endif
        
        [self.panelQueue removeObject:panel];
    }
    
    return panel;
}

#pragma mark - XAIImageCache Delegate

- (void)processCachedImage:(UIImage *)image atIndexPath:(NSIndexPath *)indexPath {
    NSUInteger panelTag = abs([indexPath row] + kXAICoverFlowPanelTagPrefix);
    
    XAICoverFlowPanel *panel = (XAICoverFlowPanel *) [self viewWithTag:panelTag];
    
    if (panel) {
        [panel processCachedImage:image];
    }
}

@end

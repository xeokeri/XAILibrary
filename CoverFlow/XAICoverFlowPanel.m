//
//  XAICoverFlowPanel.m
//  XAICoverFlow
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/29/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "XAICoverFlowPanel.h"

/** Quartz Framework */
#import <QuartzCore/QuartzCore.h>

/** XAIImageCache */
#import "UIScrollView+XAIImageCache.h"
#import "NSString+XAIImageCache.h"
#import "UIImage+XAIImageCache.h"

@implementation XAICoverFlowPanel

@synthesize panelImageView, reflectionImageView;
@synthesize reflectionGradient;
@synthesize loadingIndicator;

#pragma mark - Memory Management

- (void)dealloc {
    #if !__has_feature(objc_arc)
        [panelImageView release];
        [reflectionImageView release];
        [reflectionGradient release];
        [loadingIndicator release];
    #endif
    
    panelImageView = nil;
    reflectionImageView = nil;
    reflectionGradient = nil;
    loadingIndicator = nil;
    
    #if !__has_feature(objc_arc)
        [super dealloc];
    #endif
}

#pragma mark - Init

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        // Initialization code
        self.opaque            = NO;
        self.backgroundColor   = [UIColor clearColor];
        self.layer.anchorPoint = CGPointMake(0.5f, 0.5f);
        
        CGRect imageViewFrame  = CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height);
        CGRect reflectionFrame = CGRectMake(0.0f, self.frame.size.height, self.frame.size.width, self.frame.size.height);
        
        { /** Image */
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:imageViewFrame];
            
            imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            imageView.contentMode      = UIViewContentModeScaleAspectFit;
            imageView.backgroundColor  = [UIColor clearColor];
            
            self.panelImageView = imageView;
            
            [self addSubview:self.panelImageView];
            
            #if !__has_feature(objc_arc)
                [imageView release];
            #endif
        }
        
        { /** Activity Indicator */
            UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:imageViewFrame];
            
            indicatorView.hidesWhenStopped           = YES;
            indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
            indicatorView.color                      = [UIColor blackColor];
            
            [indicatorView startAnimating];
            
            self.loadingIndicator = indicatorView;
            
            #if !__has_feature(objc_arc)
                [indicatorView release];
            #endif
            
            [self addSubview:self.loadingIndicator];
        }
        
        { /** Reflection */
            UIImageView *reflection = [[UIImageView alloc] initWithFrame:reflectionFrame];
            
            reflection.transform        = CGAffineTransformScale(reflection.transform, 1.0f, -1.0f);
            reflection.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            reflection.contentMode      = UIViewContentModeScaleAspectFit;
            
            self.reflectionImageView = reflection;
            
            [self addSubview:self.reflectionImageView];
            
            #if !__has_feature(objc_arc)
                [reflection release];
            #endif
        }
       
        { /** Gradient */
            UIColor *gradientColorStart = [UIColor colorWithWhite:0.0f alpha:0.25f];
            UIColor *gradientColorEnd   = [UIColor colorWithWhite:0.0f alpha:0.75f];
            CAGradientLayer *gradient   = [CAGradientLayer layer];
            
            gradient.colors     = [NSArray arrayWithObjects:(id) gradientColorStart.CGColor, (id) gradientColorEnd.CGColor, nil];
            gradient.startPoint = CGPointMake(0.0f, 0.0f);
            gradient.endPoint   = CGPointMake(0.0f, 0.3f);
            gradient.frame      = CGRectMake(0.0f, self.frame.size.height, self.frame.size.width, self.frame.size.height);
            
            self.reflectionGradient = gradient;
            
            [self.layer addSublayer:self.reflectionGradient];
        }
    }
    
    return self;
}

#pragma mark - XAIImageCache Delegate

- (void)processCachedImage:(UIImage *)image {
    if (image == nil) {
        [self.loadingIndicator stopAnimating];
        
        return;
    }
    
    CGFloat
        baseline = self.bounds.size.height,
        width    = image.size.width,
        height   = image.size.height,
        scaling  = (self.bounds.size.width / (height > width ? height : width));
    
    height = scaling * height;
    width  = scaling * width;
    
    CGFloat yAxis = floorf((baseline - height > 0.0f) ? (baseline - height) : 0.0f);
    
    CGRect
        imageFrame   = CGRectMake(0.0f, yAxis, width, height),
        reflectFrame = CGRectMake(0.0f, yAxis + height, width, height);

    [UIView beginAnimations:@"LoadCachedImage" context:nil];
    [UIView setAnimationDuration:0.1f];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(coverFlowPanelAnimationDidEnd:finished:context:)];
    
    /** Update the cover panel UIImageView. */
    [self.panelImageView setFrame:imageFrame];
    [self.panelImageView setImage:image];
    
    /** Update the reflection UIImageView */
    [self.reflectionImageView setFrame:reflectFrame];
    [self.reflectionImageView setImage:image];
    
    /** Update the reflection gradient. */
    [self.reflectionGradient setFrame:reflectFrame];
    
    [UIView commitAnimations];
}

#pragma mark - UIViewAnimation Callback

- (void)coverFlowPanelAnimationDidEnd:(NSString *)panelAnimationId finished:(NSNumber *)finished context:(void *)context {
    if ([finished boolValue] == YES) {
        [self.loadingIndicator stopAnimating];
    }
}

@end

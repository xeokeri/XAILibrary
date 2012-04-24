//
//  XAICoverFlowPanel.m
//  CoverFlow
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/29/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "XAICoverFlowPanel.h"
#import <QuartzCore/QuartzCore.h>

#import "XAIImageCacheQueue.h"
#import "XAIImageCacheOperation.h"
#import "NSString+XAIImageCache.h"
#import "UIImage+XAIImageCache.h"

#import "NSException+Customized.h"

@implementation XAICoverFlowPanel

@synthesize panelImageView, reflectionImageView;
@synthesize reflectionGradient;
@synthesize loadingIndicator;
@synthesize cacheOperation;

#pragma mark - Memory Management

- (void)dealloc {
    [panelImageView release], panelImageView = nil;
    [reflectionImageView release], reflectionImageView = nil;
    [reflectionGradient release], reflectionGradient = nil;
    [loadingIndicator release], loadingIndicator = nil;
    
    [super dealloc];
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
            
            [imageView release];
        }
        
        { /** Activity Indicator */
            UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:imageViewFrame];
            
            indicatorView.hidesWhenStopped           = YES;
            indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
            indicatorView.color                      = [UIColor blackColor];
            
            [indicatorView startAnimating];
            
            self.loadingIndicator = indicatorView;
            
            [indicatorView release];
            
            [self addSubview:self.loadingIndicator];
        }
        
        { /** Reflection */
            UIImageView *reflection = [[UIImageView alloc] initWithFrame:reflectionFrame];
            
            reflection.transform        = CGAffineTransformScale(reflection.transform, 1.0f, -1.0f);
            reflection.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            reflection.contentMode      = UIViewContentModeScaleAspectFit;
            
            self.reflectionImageView = reflection;
            
            [self addSubview:self.reflectionImageView];
            
            [reflection release];
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

- (void)imageWithURL:(NSString *)url size:(CGSize)imageSize {
    [[XAIImageCacheQueue sharedQueue] cacheCleanup];
    
    /** UIImageView */
    self.panelImageView.image      = nil;
    self.reflectionImageView.image = nil;
    
    NSString *cacheURL = url;
    
    if (imageSize.width != CGSizeZero.width && imageSize.height != CGSizeZero.height) {
        cacheURL = [url cachedURLForImageSize:imageSize];
    }
    
    UIImage *cachedImage = [UIImage cachedImageForURL:cacheURL];
    
    if (cachedImage) {
        @try {
            [self processCachedImage:cachedImage];
        } @catch (NSException *exception) {
            [exception logDetailsFailedOnSelector:_cmd line:__LINE__];
        }
    } else {
        XAIImageCacheOperation *op = [[XAIImageCacheOperation alloc] initWithURL:url delegate:self size:imageSize];
        
        self.cacheOperation = op;
        
        [[XAIImageCacheQueue sharedQueue] addOperation:cacheOperation];
        
        [op release];
    }
}

- (void)removeFromSuperview {
    if (self.cacheOperation) {
        [self.cacheOperation setOperationExecuting:YES];
        [self.cacheOperation cancel];
    }
    
    [super removeFromSuperview];
}

#pragma mark - XAIImageCache Delegate

- (void)processCachedImage:(UIImage *)image {
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
    self.panelImageView.image = image;
    self.panelImageView.frame = imageFrame;
    
    /** Update the reflection UIImageView */
    self.reflectionImageView.frame = reflectFrame;
    self.reflectionImageView.image = image;
    
    /** Update the reflection gradient. */
    self.reflectionGradient.frame = reflectFrame;
    
    [UIView commitAnimations];
}

#pragma mark - UIViewAnimation Callback

- (void)coverFlowPanelAnimationDidEnd:(NSString *)panelAnimationId finished:(NSNumber *)finished context:(void *)context {
    if ([finished boolValue] == YES) {
        [self.loadingIndicator stopAnimating];
    }
}


@end

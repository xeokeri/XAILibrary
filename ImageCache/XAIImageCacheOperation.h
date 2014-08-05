//
//  XAIImageCacheOperation.h
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 2/24/12.
//  Copyright (c) 2011-2014 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CGGeometry.h>

/** XAIImageCache Protocols */
#import "XAIImageCacheDelegate.h"

/** XAIImageCacheOperationBlock */
typedef void (^XAIImageCacheOperationBlock)(UIImage *img, NSError *err);

/**
 * XAIImageCache Features:
 *
 * 1: Load UIImageView.image and UIButton.image.
 * 2: Check if image exists in the cache, if exists, use cached image.
 * 3: If the image isn't cached, pull image from the URL.
 * 4: Load image in CGSize cache.
 * 5: Support for image cache removable based on date length.
 *
 */
@interface XAIImageCacheOperation : NSOperation {
    @private
    id <XAIImageCacheDelegate> __weak  cacheDelegate;
    XAIImageCacheOperationBlock        operationBlock;
    
    NSString        *downloadURL;
    NSURLSession    *downloadSession;
    NSIndexPath     *containerIndexPath;
    
    CGSize containerSize;
    
    BOOL loadImageResized;
    
    @protected
    BOOL operationExecuting;
    BOOL operationFinished;
}

@property (nonatomic, weak) id <XAIImageCacheDelegate> cacheDelegate;
@property (nonatomic, copy) XAIImageCacheOperationBlock operationBlock;

@property (nonatomic, strong) NSString        *downloadURL;
@property (nonatomic, strong) NSURLSession    *downloadSession;
@property (nonatomic, strong) NSIndexPath     *containerIndexPath;

@property (nonatomic) CGSize containerSize;

@property (nonatomic, getter = isOperationExecuting) BOOL operationExecuting;
@property (nonatomic, getter = isOperationFinished) BOOL operationFinished;

@property (nonatomic, getter = shouldLoadImageResized) BOOL loadImageResized;

- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL usingBlock:(XAIImageCacheOperationBlock)callback;
- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL delegate:(id /** <XAIImageCacheDelegate> */)incomingDelegate size:(CGSize)imageSize;
- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL delegate:(id <XAIImageCacheDelegate>)incomingDelegate atIndexPath:(NSIndexPath *)indexPath size:(CGSize)imageSize;

@end

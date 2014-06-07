//
//  XAIImageCacheOperation.h
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 2/24/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

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

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>

/** XAIImageCache Protocols */
#import "XAIImageCacheDelegate.h"

typedef enum {
    kXAIImageCacheStatusTypeFinished  = 0,
    kXAIImageCacheStatusTypeExecuting = 1
} XAIImageCacheStatusType;

/** XAIImageCacheOperationBlock */
typedef void (^XAIImageCacheOperationBlock)(UIImage *img, NSError *err);

@interface XAIImageCacheOperation : NSOperation {
    @private
    id <XAIImageCacheDelegate> __weak delegateView;
    XAIImageCacheOperationBlock        operationBlock;
    
    NSMutableData   *receivedData;
    NSString        *downloadURL;
    NSPort          *downloadPort;
    NSURLConnection *downloadConnection;
    NSIndexPath     *containerIndexPath;
    
    CGSize containerSize;
    
    BOOL loadImageResized;
    
    @protected
    BOOL operationExecuting;
    BOOL operationFinished;
}

@property (nonatomic, weak) id <XAIImageCacheDelegate> delegateView;
@property (nonatomic, copy) XAIImageCacheOperationBlock operationBlock;

@property (nonatomic, strong) NSMutableData   *receivedData;
@property (nonatomic, strong) NSString        *downloadURL;
@property (nonatomic, strong) NSPort          *downloadPort;
@property (nonatomic, strong) NSURLConnection *downloadConnection;
@property (nonatomic, strong) NSIndexPath     *containerIndexPath;

@property (nonatomic) CGSize containerSize;

@property (nonatomic, getter = isOperationExecuting) BOOL operationExecuting;
@property (nonatomic, getter = isOperationFinished) BOOL operationFinished;

@property (nonatomic, getter = shouldLoadImageResized) BOOL loadImageResized;

- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL usingBlock:(XAIImageCacheOperationBlock)callback;
- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL delegate:(id)incomingDelegate;
- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL delegate:(id)incomingDelegate resize:(BOOL)imageResize;
- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL delegate:(id)incomingDelegate size:(CGSize)imageSize;
- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL delegate:(id)incomingDelegate atIndexPath:(NSIndexPath *)indexPath size:(CGSize)imageSize;

@end

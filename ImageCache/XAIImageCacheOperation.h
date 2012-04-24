//
//  XAIImageCacheOperation.h
//  XAIImageCache
//
//  Created by Xeon Xai on 2/24/12.
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

typedef enum {
    kXAIImageCacheStatusTypeFinished  = 0,
    kXAIImageCacheStatusTypeExecuting = 1
} XAIImageCacheStatusType;

@interface XAIImageCacheOperation : NSOperation <NSURLConnectionDataDelegate> {
    @protected
    BOOL operationExecuting;
    BOOL operationFinished;
    
    @private
    id delegateView;
    
    NSMutableData   *receivedData;
    NSString        *downloadURL;
    NSPort          *downloadPort;
    NSURLConnection *downloadConnection;
    NSIndexPath     *containerIndexPath;
    
    CGSize containerSize;
    
    BOOL loadImageResized;
}

@property (nonatomic, assign) id delegateView;

@property (nonatomic, retain) NSMutableData   *receivedData;
@property (nonatomic, retain) NSString        *downloadURL;
@property (nonatomic, retain) NSPort          *downloadPort;
@property (nonatomic, retain) NSURLConnection *downloadConnection;
@property (nonatomic, retain) NSIndexPath     *containerIndexPath;

@property (nonatomic) CGSize containerSize;

@property (nonatomic, getter = isOperationExecuting) BOOL operationExecuting;
@property (nonatomic, getter = isOperationFinished) BOOL operationFinished;

@property (nonatomic, getter = shouldLoadImageResized) BOOL loadImageResized;

- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL delegate:(id)incomingDelegate;
- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL delegate:(id)incomingDelegate resize:(BOOL)imageResize;
- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL delegate:(id)incomingDelegate size:(CGSize)imageSize;
- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL delegate:(id)incomingDelegate atIndexPath:(NSIndexPath *)indexPath size:(CGSize)imageSize;

@end

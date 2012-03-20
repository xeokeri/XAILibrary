//
//  XAIImageCacheOperation.h
//  XAIImageCache
//
//  Created by Xeon Xai on 2/24/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

/**
 * 1: Load UIImageView.image (done) and UIButton.image (pending) placeholder [with spinner (maybe)]. Fade in on successful image load.
 * 2: Pull image from URL. (done)
 * 3: Check if image exists in the cache. (done)
 * 4: If the image isn't cached, pull from the URL. (done)
 * 5: Load image in CGSize cache. (pending, upcoming feature... the reason for this code base.)
 * 6: Add in support for image cache removable based on date length. (done)
 * 7: Update for ARC support. (pending)
 * 8: Add in documentation. (pending)
 *
 */

#import <Foundation/Foundation.h>

@interface XAIImageCacheOperation : NSOperation <NSURLConnectionDataDelegate> {
    @private
    UIImageView     *delegateView;
    NSMutableData   *receivedData;
    NSString        *downloadURL;
    NSURLConnection *downloadConnection;
    
    BOOL operationExecuting;
    BOOL operationFinished;
}

@property (nonatomic, retain) UIImageView     *delegateView;
@property (nonatomic, retain) NSMutableData   *receivedData;
@property (nonatomic, retain) NSString        *downloadURL;
@property (nonatomic, retain) NSURLConnection *downloadConnection;

@property (nonatomic, getter = isOperationExecuting) BOOL operationExecuting;
@property (nonatomic, getter = isOperationFinished) BOOL operationFinished;

- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL withImageViewDelegate:(UIImageView *)imageViewDelegate;

@end

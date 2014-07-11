//
//  XAIImageCacheOperation.m
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 2/24/12.
//  Copyright (c) 2011-2014 Black Panther White Leopard. All rights reserved.
//

#import "XAIImageCacheOperation.h"
#import "XAIImageCacheQueue.h"
#import "XAIImageCacheStorage.h"
#import "XAIImageCacheDefines.h"

/** XAIUtilities Categories */
#import "UIImage+XAIUtilities.h"
#import "NSHTTPURLResponse+XAIUtilities.h"

/** XAIImageCache Categories */
#import "NSString+XAIImageCache.h"

/** XAILogging */
#import "NSError+XAILogging.h"
#import "NSException+XAILogging.h"

/** NSOperation Status Flags */
typedef NS_ENUM(NSUInteger, XAIImageCacheStatusType) {
    XAIImageCacheStatusTypeFinished  = 0,
    XAIImageCacheStatusTypeExecuting = 1
};

@interface XAIImageCacheOperation() <NSURLConnectionDataDelegate>

- (void)resetData;
- (void)checkOperationStatus;
- (void)changeStatus:(BOOL)status forType:(XAIImageCacheStatusType)type;
- (void)updateOperationStatus;
- (void)updateOperationStatusForBlock;
- (void)updateDelegateWithImage:(UIImage *)imageContent cache:(BOOL)cacheStore;
- (UIImage *)dataAsUIImage;

@end

@implementation XAIImageCacheOperation

@synthesize cacheDelegate  = _cacheDelegate;
@synthesize operationBlock = _operationBlock;

@synthesize receivedData, downloadURL, downloadConnection, downloadPort;
@synthesize operationFinished, operationExecuting;
@synthesize loadImageResized;
@synthesize containerSize, containerIndexPath;

#pragma mark - Init

- (id)init {
    self = [super init];
    
    if (self) {
        _cacheDelegate          = nil;
        self.operationBlock     = nil;
        self.containerIndexPath = nil;
        self.queuePriority      = NSOperationQueuePriorityVeryLow;
        self.containerSize      = CGSizeZero;
        self.downloadPort       = [[NSPort alloc] init];
        self.receivedData       = [[NSMutableData alloc] init];
    }
    
    return self;
}

#pragma mark - Init for Blocks.

- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL usingBlock:(XAIImageCacheOperationBlock)callback {
    self = [self init];
    
    if (self) {
        self.downloadURL    = imageURL;
        self.operationBlock = callback;
        self.queuePriority  = NSOperationQueuePriorityHigh;
    }
    
    return self;
}

#pragma mark - Init for UIImageView, UIButton, and UIView

- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL delegate:(id /** <XAIImageCacheDelegate> */)incomingDelegate size:(CGSize)imageSize {
    self = [self init];
    
    if (self) {
        _cacheDelegate        = ([incomingDelegate isKindOfClass:[UITableView class]]) ? nil : incomingDelegate;
        self.downloadURL      = imageURL;
        self.loadImageResized = YES;
        self.containerSize    = imageSize;
    }
    
    return self;  
}

#pragma mark - Init for UITableView, and UIScrollView

- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL delegate:(id <XAIImageCacheDelegate>)incomingDelegate atIndexPath:(NSIndexPath *)indexPath size:(CGSize)imageSize {
    self = [self init];
    
    if (self) {
        _cacheDelegate          = ([incomingDelegate isKindOfClass:[UITableView class]]) ? nil : incomingDelegate;
        self.downloadURL        = imageURL;
        self.loadImageResized   = (!CGSizeEqualToSize(CGSizeZero, imageSize));
        self.containerSize      = imageSize;
        self.containerIndexPath = indexPath;
    }
    
    return self;
}

#pragma mark - Memory Management

- (void)dealloc {
    #if !__has_feature(objc_arc)
        [receivedData release];
        [downloadURL release];
        [downloadConnection release];
        [downloadPort release];
    #endif
    
    operationBlock = nil;
    cacheDelegate  = nil;
    downloadPort   = nil;
    receivedData   = nil;
    
    #if !__has_feature(objc_arc)
        [super dealloc];
    #endif
}

#pragma mark - NSOperation Start

- (void)start {
    // Start the execution.
    [self changeStatus:YES forType:XAIImageCacheStatusTypeExecuting];
    
    // Clean up the cache if needed.
    [[XAIImageCacheStorage sharedStorage] cacheCleanup];
    
    // Check the state, to see if the file is cached or should be downloaded.
    BOOL shouldDownloadContent   = YES;
    
    // Check to see if the file is cached, and check the last modified date.
    NSDate *fileLastModifiedDate = [[XAIImageCacheStorage sharedStorage] lastModifiedDateForURL:self.downloadURL temporary:YES];
    
    // If the last modified date is valid, check to see if the host file is newer.
    if (fileLastModifiedDate != nil) {
        NSError *headRequestError        = nil;
        NSURLResponse *headResponse      = nil;
        NSMutableURLRequest *headRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.downloadURL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:XAIImageCacheTimeoutInterval];
        
        // Set to HEAD to fetch the headers.
        [headRequest setHTTPMethod:@"HEAD"];
        
        // Request the headers.
        [NSURLConnection sendSynchronousRequest:headRequest returningResponse:&headResponse error:&headRequestError];
        
        // Check to see if there were any errors.
        if (headRequestError != nil) {
            // Log any errors.
            [headRequestError logDetailsFailedOnSelector:_cmd line:__LINE__];
        } else {
            // Filter the response headers for the "Last-Modified" date.
            NSHTTPURLResponse *httpHeadResponse = (NSHTTPURLResponse *) headResponse;
            NSDate *httpHeadLastModifiedDate    = [httpHeadResponse lastModifiedDate];
            
            // Check to see if the file needs to be re-downloaded.
            if ((httpHeadLastModifiedDate != nil) && ([fileLastModifiedDate compare:httpHeadLastModifiedDate] == NSOrderedDescending)) {
                shouldDownloadContent = NO;
            }
        }
        
        #if !__has_feature(objc_arc)
            [headRequest release];
        #endif
    }
    
    // Check to see if the image should be loaded from cache without fetching the image from the server.
    if (!shouldDownloadContent) {
        // Check to see which URL to filter for in the cache.
        NSString *cacheURL   = (!CGSizeEqualToSize(CGSizeZero, self.containerSize)) ? [self.downloadURL cachedURLForImageSize:self.containerSize] : self.downloadURL;
        
        // Check to see if the image is already cached, before trying to request it.
        UIImage *cachedImage = [[XAIImageCacheStorage sharedStorage] cachedImageForURL:cacheURL];
        
        // Verify the cached image exists.
        if (cachedImage) {
            // Check to see if the block operation callback is set.
            if (self.operationBlock != nil) {
                // Process callback.
                self.operationBlock(cachedImage, nil);
                
                // Update the operation status to complete.
                [self updateOperationStatusForBlock];
            } else {
                /** Load the image and store in the cache. */
                [self updateDelegateWithImage:cachedImage cache:NO];
                [self updateOperationStatus];
            }
            
            // No need to proceed further.
            return;
        }
    }
    
    // Check for the callback block.
    if (self.operationBlock != nil) {
        /** Set the request and the connection. */
        NSURLRequest *request   = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.downloadURL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:XAIImageCacheTimeoutInterval];
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        
        /** Download the image asynchronously. */
        [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            @autoreleasepool {
                NSHTTPURLResponse
                    *httpResponse = (NSHTTPURLResponse *) response;
                
                NSString
                    *requestURL   = [[response URL] absoluteString];
                
                UIImage
                    *imageContent = nil;
                
                // Check for errors.
                if (connectionError != nil) {
                    // Log any errors.
                    [connectionError logDetailsFailedOnSelector:_cmd line:__LINE__];
                } else {
                    // Check for a valid HTTP status code.
                    if ([httpResponse statusCode] == 200) {
                        imageContent = [UIImage imageWithData:data scale:[[UIScreen mainScreen] scale]];
                    }
                }
                
                // Cache the image as needed.
                if (imageContent != nil) {
                    [[XAIImageCacheStorage sharedStorage] saveImage:imageContent forURL:requestURL temporary:YES];
                }
                
                // Check for the callback block.
                if (self.operationBlock != nil) {
                    // Process callback.
                    self.operationBlock(imageContent, connectionError);
                }
                
                // Update the operation status to complete.
                [self updateOperationStatusForBlock];
            }
        }];
        
        return;
    }
    
    if (self.isCancelled) {
        [self updateOperationStatus];
        
        return;
    }
    
    /** Configure the Container Size. */
    @try {
        id imageCacheDelegate = _cacheDelegate;
        
        if (imageCacheDelegate && [imageCacheDelegate respondsToSelector:@selector(isKindOfClass:)]) {
            if ([imageCacheDelegate isKindOfClass:[UIButton class]]) {
                self.containerSize = ((UIButton *) imageCacheDelegate).frame.size;
            } else if ([imageCacheDelegate isKindOfClass:[UIImageView class]]) {
                self.containerSize = ((UIImageView *) imageCacheDelegate).frame.size;
            } else {
                // Do nothing.
            }
        }
    } @catch (NSException *exception) {
        [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
    } @finally {
        if (self.shouldLoadImageResized && CGSizeEqualToSize(CGSizeZero, self.containerSize)) {
            [self updateOperationStatus];
            
            return;
        }
    }
    
    /** Set the request and the connection. */
    NSURLRequest *request   = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.downloadURL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:XAIImageCacheTimeoutInterval];
    NSURLConnection *conn   = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    
    /** Store the connection. */
    self.downloadConnection = conn;
    
    #if !__has_feature(objc_arc)
        [conn release];
        [request release];
    #endif
    
    /** Set the port for the NSRunLoop and start the download connection. */
    if (self.downloadConnection) {
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        
        [runLoop addPort:self.downloadPort forMode:NSDefaultRunLoopMode];
        
        [self.downloadConnection scheduleInRunLoop:runLoop forMode:NSRunLoopCommonModes];
        
        [self.downloadConnection start];
        
        [runLoop run];
    }
    
    [self checkOperationStatus];
}

#pragma mark - NSOperation Status

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isFinished {
    return self.isOperationFinished;
}

- (BOOL)isExecuting {
    return self.isOperationExecuting;
}

- (void)changeStatus:(BOOL)status forType:(XAIImageCacheStatusType)type {
    switch (type) {
        case XAIImageCacheStatusTypeFinished: {
            [self willChangeValueForKey:@"isFinished"];
            self.operationFinished = status;
            [self didChangeValueForKey:@"isFinished"];
        }
            
            break;
            
        case XAIImageCacheStatusTypeExecuting: {
            [self willChangeValueForKey:@"isExecuting"];
            self.operationExecuting = status;
            [self didChangeValueForKey:@"isExecuting"];
        }
            
            break;
            
        default:
            
            break;
    }
}

- (void)checkOperationStatus {
    if (self.isCancelled) {
        [self updateOperationStatus];
    }
}

- (void)updateOperationStatus {
    /** Reset the delegate. */
    _cacheDelegate = nil;
    
    /** Remove the port. */
    [[NSRunLoop currentRunLoop] removePort:self.downloadPort forMode:NSDefaultRunLoopMode];
    
    // Stop the download.
    if (self.downloadConnection != nil) {
        [self.downloadConnection cancel];
    }
    
    // Remove the URL from the queue.
    [[XAIImageCacheQueue sharedQueue] removeURL:self.downloadURL];
    
    [self changeStatus:YES forType:XAIImageCacheStatusTypeFinished];
    [self changeStatus:NO forType:XAIImageCacheStatusTypeExecuting];
}

- (void)updateOperationStatusForBlock {
    /** Clear out the operation callback. */
    _operationBlock = nil;
    
    // Remove the URL from the queue.
    [[XAIImageCacheQueue sharedQueue] removeURL:self.downloadURL];
    
    [self changeStatus:YES forType:XAIImageCacheStatusTypeFinished];
    [self changeStatus:NO forType:XAIImageCacheStatusTypeExecuting];
}

#pragma mark - NSData

- (void)resetData {
    @try {
        [self.receivedData setLength:0];
    } @catch (NSException *exception) {
        [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
    }
}

#pragma mark - UIImage

- (UIImage *)dataAsUIImage {
    return [[UIImage alloc] initWithData:self.receivedData];
}

#pragma mark - NSURLConnectionDataDelegate

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self resetData];
    [self checkOperationStatus];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (self.isCancelled) {
        [self updateOperationStatus];
    } else {
        [self.receivedData appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    UIImage *imageContent = [self dataAsUIImage];
    
    if (self.isCancelled) {
        _cacheDelegate   = nil;
        _operationBlock = nil;
    } else {
        /** Load the image and store in the cache. */
        [self updateDelegateWithImage:imageContent cache:YES];
    }
    
    [self resetData];
    [self checkOperationStatus];
    [self updateOperationStatus];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if (error != nil) {
        [error logDetailsFailedOnSelector:_cmd line:__LINE__];
    }
    
    if (self.isCancelled) {
        _cacheDelegate   = nil;
        _operationBlock = nil;
    } else {
        /** Make sure the image is cleared out. */
        [self updateDelegateWithImage:nil cache:NO];
    }
    
    [self resetData];
    [self updateOperationStatus];
}

#pragma mark - Delegate View Callback

- (void)updateDelegateWithImage:(UIImage *)imageContent cache:(BOOL)cacheStore {
    if (self.isCancelled) {
        [self updateOperationStatus];
        
        return;
    }
    
    UIImage *resizedImage = nil;
    id imageCacheDelegate = _cacheDelegate;
    
    // When image cache delegate or image content are nil, no further processing is needed.
    if (!imageCacheDelegate || !imageContent) {
        return;
    }
    
    // Check to see if the image should be cached.
    if (cacheStore == YES) {
        // Save the original file.
        [[XAIImageCacheStorage sharedStorage] saveImage:imageContent forURL:self.downloadURL];
        
        NSString *cachedURL = [self.downloadURL cachedURLForImageSize:self.containerSize];
        BOOL isEqualSize    = CGSizeEqualToSize(imageContent.size, self.containerSize);
        BOOL bothSidesDiff  = (imageContent.size.width != self.containerSize.width) && (imageContent.size.height != self.containerSize.height); // TODO: Migrate to a better function.
        
        // Check to see if the image should be resized.
        if (self.shouldLoadImageResized) {
            if (isEqualSize) {
                // Save the original image with the cache image size URL.
                [[XAIImageCacheStorage sharedStorage] saveImage:imageContent forURL:cachedURL temporary:YES];
                
                // Reset the image resize state.
                [self setLoadImageResized:NO];
            } else if (bothSidesDiff) {
                // Resize the image accordingly.
                resizedImage = [imageContent resizeToFillSize:self.containerSize];
                
                // Save the resized image to the cache.
                [[XAIImageCacheStorage sharedStorage] saveImage:resizedImage forURL:cachedURL temporary:YES];
            } else {
                // Do nothing...
            }
        }
    }
    
    if (self.shouldLoadImageResized && !CGSizeEqualToSize(CGSizeZero, self.containerSize)) {
        if (resizedImage == nil) {
            resizedImage = [imageContent resizeToFillSize:self.containerSize];
        }
        
        imageContent = resizedImage;
    }
    
    @try {
        if ([imageCacheDelegate respondsToSelector:@selector(processCachedImage:atIndexPath:)]) {
            [imageCacheDelegate processCachedImage:imageContent atIndexPath:self.containerIndexPath];
        } else {
            [UIView beginAnimations:@"XAIImageCacheLoadImageWithFade" context:nil];
            [UIView setAnimationDuration:XAIImageCacheFadeInDuration];
            
            if ([imageCacheDelegate respondsToSelector:@selector(setHidden:)]) {
                [imageCacheDelegate setHidden:NO];
            }
            
            if ([imageCacheDelegate respondsToSelector:@selector(processCachedImage:)]) {
                [imageCacheDelegate processCachedImage:imageContent];
            } else if ([imageCacheDelegate isKindOfClass:[UIButton class]]) {
                [(UIButton *)imageCacheDelegate setImage:imageContent forState:UIControlStateNormal];
            } else if ([imageCacheDelegate isKindOfClass:[UIImageView class]]) {
                [(UIImageView *)imageCacheDelegate setImage:imageContent];
            } else {
                // Do nothing.
            }
            
            if ([imageCacheDelegate respondsToSelector:@selector(setAlpha:)]) {
                [imageCacheDelegate setAlpha:1.0f];
            }
            
            [UIView commitAnimations];
        }
    } @catch (NSException *exception) {
        [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
    }
}

@end

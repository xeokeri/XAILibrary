//
//  XAIImageCacheOperation.m
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 2/24/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "XAIImageCacheOperation.h"
#import "XAIImageCacheQueue.h"
#import "XAIImageCacheStorage.h"
#import "XAIImageCacheDefines.h"

/** XAIUtilities Categories */
#import "UIImage+XAIUtilities.h"

/** XAIImageCache Categories */
#import "NSString+XAIImageCache.h"

/** XAILogging */
#import "NSError+XAILogging.h"
#import "NSException+XAILogging.h"

@interface XAIImageCacheOperation()

- (void)resetData;
- (void)checkOperationStatus;
- (void)changeStatus:(BOOL)status forType:(XAIImageCacheStatusType)type;
- (void)updateOperationStatus;
- (void)updateDelegateWithImage:(UIImage *)imageContent cache:(BOOL)cacheStore;
- (UIImage *)dataAsUIImage;

@end

@implementation XAIImageCacheOperation

@synthesize delegateView = __delegateView;

@synthesize receivedData, downloadURL, downloadConnection, downloadPort;
@synthesize operationFinished, operationExecuting;
@synthesize loadImageResized;
@synthesize containerSize, containerIndexPath;

#pragma mark - Init

- (id)init {
    self = [super init];
    
    if (self) {
        __delegateView          = nil;
        self.receivedData       = [NSMutableData data];
        self.operationExecuting = NO;
        self.operationFinished  = NO;
        self.queuePriority      = NSOperationQueuePriorityVeryLow;
        self.containerSize      = CGSizeZero;
        self.containerIndexPath = nil;
        self.downloadPort       = [NSPort port];
    }
    
    return self;
}

#pragma mark - Init for UIImageView and UIButton

- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL delegate:(id)incomingDelegate {
    return [self initWithURL:imageURL delegate:incomingDelegate resize:YES];
}

- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL delegate:(id)incomingDelegate resize:(BOOL)imageResize {
    self = [self init];
    
    if (self) {
        __delegateView        = ([incomingDelegate isKindOfClass:[UITableView class]]) ? nil : incomingDelegate;
        self.downloadURL      = imageURL;
        self.loadImageResized = imageResize;
    }
    
    return self;    
}

#pragma mark - Init for UIView

- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL delegate:(id)incomingDelegate size:(CGSize)imageSize {
    self = [self init];
    
    if (self) {
        __delegateView          = ([incomingDelegate isKindOfClass:[UITableView class]]) ? nil : incomingDelegate;
        self.downloadURL        = imageURL;
        self.loadImageResized   = YES;
        self.containerSize      = imageSize;
    }
    
    return self;  
}

#pragma mark - Init for UITableView and UIScrollView

- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL delegate:(id)incomingDelegate atIndexPath:(NSIndexPath *)indexPath size:(CGSize)imageSize {
    self = [self init];
    
    if (self) {
        __delegateView          = ([incomingDelegate isKindOfClass:[UITableView class]]) ? nil : incomingDelegate;
        self.downloadURL        = imageURL;
        self.loadImageResized   = (CGSizeZero.width == imageSize.width && CGSizeZero.height == imageSize.height) ? NO : YES;
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
    
    receivedData       = nil;
    downloadURL        = nil;
    downloadConnection = nil;
    downloadPort       = nil;
    __delegateView     = nil;
    
    #if !__has_feature(objc_arc)
        [super dealloc];
    #endif
}

#pragma mark - NSOperation Start

- (void)start {
    [self changeStatus:YES forType:kXAIImageCacheStatusTypeExecuting];
    
    if (self.isCancelled) {
        [self updateOperationStatus];
        return;
    }
    
    /** Configure the Container Size. */
    @try {
        if ([__delegateView respondsToSelector:@selector(isKindOfClass:)]) {
            if (__delegateView && [__delegateView isKindOfClass:[UIButton class]]) {
                self.containerSize = ((UIButton *) __delegateView).frame.size;
            } else if (__delegateView && [__delegateView isKindOfClass:[UIImageView class]]) {
                self.containerSize = ((UIImageView *) __delegateView).frame.size;
            } else {
                // Do nothing.
            }
        }
    } @catch (NSException *exception) {
        [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
    } @finally {
        if (self.shouldLoadImageResized) {
            if (self.containerSize.width == CGSizeZero.width && self.containerSize.height == CGSizeZero.height) {
                [self updateOperationStatus];
                
                return;
            }
        }
    }
    
    /** Set the request and the connection. */
    NSURLRequest *request   = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.downloadURL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:kXAIImageCacheTimeoutInterval];
    NSURLConnection *conn   = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
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
        case kXAIImageCacheStatusTypeFinished: {
            [self willChangeValueForKey:@"isFinished"];
            self.operationFinished = status;
            [self didChangeValueForKey:@"isFinished"];
        }
            
            break;
            
        case kXAIImageCacheStatusTypeExecuting: {
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
        [self.downloadConnection cancel];
        
        [self updateOperationStatus];
    }
}

- (void)updateOperationStatus {
    /** Reset the delegate. */
    __delegateView = nil;
    
    /** Remove the port. */
    [[NSRunLoop currentRunLoop] removePort:self.downloadPort forMode:NSDefaultRunLoopMode];
    
    [self.downloadConnection cancel];
    
    [[XAIImageCacheQueue sharedQueue] removeURL:self.downloadURL];
    
    [self changeStatus:YES forType:kXAIImageCacheStatusTypeFinished];
    [self changeStatus:NO forType:kXAIImageCacheStatusTypeExecuting];
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
    return [UIImage imageWithData:self.receivedData];
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
        __delegateView = nil;
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
        __delegateView = nil;
    } else {
        /** Make sure the image is cleared out. */
        [self updateDelegateWithImage:nil cache:NO];
    }
    
    [self resetData];
    [self updateOperationStatus];
}

#pragma mark - Delegate View Callback

- (void)updateDelegateWithImage:(UIImage *)imageContent cache:(BOOL)cacheStore {
    UIImage *resizedImage = nil;
    
    if (self.isCancelled) {
        [self updateOperationStatus];
        
        return;
    }
    
    if (cacheStore == YES && imageContent != nil) {
        [[XAIImageCacheStorage sharedStorage] saveImage:imageContent forURL:self.downloadURL];
        
        NSString *cachedURL = [self.downloadURL cachedURLForImageSize:self.containerSize];
        
        if (self.shouldLoadImageResized && imageContent.size.width == self.containerSize.width && imageContent.size.height == self.containerSize.height) {
            [[XAIImageCacheStorage sharedStorage] saveImage:imageContent forURL:cachedURL];
            
            [self setLoadImageResized:NO];
        }
        
        if (self.shouldLoadImageResized && imageContent.size.width != self.containerSize.width && imageContent.size.height != self.containerSize.height) {
            resizedImage = [imageContent resizeToFillSize:self.containerSize];
            
            [[XAIImageCacheStorage sharedStorage] saveImage:resizedImage forURL:cachedURL];
        }
    }
    
    if (self.isCancelled) {
        __delegateView = nil;
        
        return;
    }
    
    if (self.shouldLoadImageResized && imageContent != nil) {
        if (resizedImage == nil) {
            resizedImage = [imageContent resizeToFillSize:self.containerSize];
        }
        
        imageContent = resizedImage;
    }
    
    if (self.isCancelled) {
        __delegateView = nil;
        
        [self updateOperationStatus];
        
        return;
    }
    
    @try {
        if (self.isCancelled) {
            __delegateView = nil;
            
            [self updateOperationStatus];
            
            return;
        }
        
        if (__delegateView) {
            if (self.isCancelled) {
                [self updateOperationStatus];
                
                return;
            }
            
            if ([__delegateView respondsToSelector:@selector(processCachedImage:atIndexPath:)]) {
                [__delegateView processCachedImage:imageContent atIndexPath:self.containerIndexPath];
            } else {
                [UIView beginAnimations:@"LoadImageWithFade" context:nil];
                [UIView setAnimationDuration:kXAIImageCacheFadeInDuration];
                
                [__delegateView setHidden:NO];
                
                if ([__delegateView respondsToSelector:@selector(processCachedImage:)]) {
                    [__delegateView processCachedImage:imageContent];
                } else if ([__delegateView isKindOfClass:[UIButton class]]) {
                    [__delegateView setImage:imageContent forState:UIControlStateNormal];
                } else if ([__delegateView isKindOfClass:[UIImageView class]]) {
                    [__delegateView setImage:imageContent];
                } else {
                    // Do nothing.
                }
                
                [__delegateView setAlpha:1.0f];
                
                [UIView commitAnimations];
            }
        }
    } @catch (NSException *exception) {
        [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
    }
}

@end

//
//  XAIImageCacheOperation.m
//  XAIImageCache
//
//  Created by Xeon Xai on 2/24/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "XAIImageCacheOperation.h"
#import "XAIImageCacheDefines.h"

#import "UIImage+XAIImageCache.h"
#import "NSString+XAIImageCache.h"

#import "NSError+Customized.h"
#import "NSException+Customized.h"

@interface XAIImageCacheOperation()

- (void)resetData;
- (void)updateOperationStatus;
- (void)updateImageViewWithImage:(UIImage *)imageContent cache:(BOOL)cacheStore;
- (void)saveImage:(UIImage *)image forURL:(NSString *)imageURL;
- (UIImage *)dataAsUIImage;

@end

@implementation XAIImageCacheOperation

@synthesize receivedData, delegateView, downloadURL, downloadConnection;
@synthesize operationFinished, operationExecuting;

- (id)init {
    self = [super init];
    
    if (self) {
        self.receivedData       = [[NSMutableData alloc] init];
        self.operationExecuting = NO;
        self.operationFinished  = NO;
    }
    
    return self;
}

- (void)dealloc {
    [self.receivedData release];
    [self.downloadConnection release];
    
    [super dealloc];
}

- (void)start {
    [self willChangeValueForKey:@"isExecuting"];
    self.operationExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.downloadURL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:kXAIImageCacheTimeoutInterval];
    
    /** Set the connection. */
    self.downloadConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    
    [request release];
    
    if (self.downloadConnection) {
        NSPort *port       = [NSPort port];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        
        [runLoop addPort:port forMode:NSDefaultRunLoopMode];
        
        [self.downloadConnection scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
        [self.downloadConnection start];
        
        [runLoop run];
    }
}

- (XAIImageCacheOperation *)initWithURL:(NSString *)imageURL withImageViewDelegate:(UIImageView *)imageViewDelegate {
    self = [self init];
    
    if (self) {
        self.delegateView = imageViewDelegate;
        self.downloadURL  = imageURL;
    }
    
    return self;    
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isFinished {
    return self.isOperationFinished;
}

- (BOOL)isExecuting {
    return self.isOperationExecuting;
}

- (void)resetData {
    @try {
        [self.receivedData setLength:0];
    } @catch (NSException *exception) {
        [exception logDetailsFailedOnSelector:_cmd line:__LINE__];
    }
}

- (UIImage *)dataAsUIImage {
    return [UIImage imageWithData:self.receivedData];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    return request;
}

#pragma mark - NSURLConnection Delegates
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self resetData];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self.receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    UIImage *imageContent = [self dataAsUIImage];
    
    /** Load the image and store in the cache. */
    [self updateImageViewWithImage:imageContent cache:YES];
    
    [self resetData];
    [self updateOperationStatus];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [error logDetailsFailedOnSelector:_cmd line:__LINE__];
    
    /** Make sure the image is cleared out. */
    [self updateImageViewWithImage:nil cache:NO];
    
    [self resetData];
    [self updateOperationStatus];
}

- (void)saveImage:(UIImage *)image forURL:(NSString *)imageURL {
    /** Create the image cache folder. */
    NSError *error        = nil;
    NSArray *cachePaths   = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheFolder = [[cachePaths lastObject] stringByAppendingPathComponent:kXAIImageCacheDirectoryPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:cacheFolder]) {
        [fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:NO attributes:nil error:&error];
        
        if (error != nil) {
            [error logDetailsFailedOnSelector:_cmd line:__LINE__];
            
            return;
        }
    }
    
    NSData *imageData   = [NSData dataWithData:UIImagePNGRepresentation(image)];
    NSArray *cachePath  = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *imagePath = [[cachePath lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:kXAIImageCacheFileNamePath, kXAIImageCacheDirectoryPath, [imageURL md5HexEncode]]];
    
    [imageData writeToFile:imagePath atomically:YES];
}

- (void)updateImageViewWithImage:(UIImage *)imageContent cache:(BOOL)cacheStore {
    if (cacheStore == YES) {
        [self saveImage:imageContent forURL:self.downloadURL];
    }
    
    @try {
        [UIView beginAnimations:@"LoadImageWithFade" context:nil];
        [UIView setAnimationDuration:kXAIImageCacheFadeInDuration];
        
        self.delegateView.hidden = NO;
        self.delegateView.image  = imageContent;
        self.delegateView.alpha  = 1.0f;
        
        [UIView commitAnimations];
    } @catch (NSException *exception) {
        [exception logDetailsFailedOnSelector:_cmd line:__LINE__];
    }
}

- (void)updateOperationStatus {
    [self willChangeValueForKey:@"isExecuting"];
    self.operationExecuting = NO;
    [self didChangeValueForKey:@"isExecuting"];
    
    [self willChangeValueForKey:@"isFinished"];
    self.operationFinished = YES;
    [self didChangeValueForKey:@"isFinished"];
}

@end

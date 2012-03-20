//
//  UIImageView+XAIImageCache.h
//  XAIImageCache
//
//  Created by Xeon Xai on 2/24/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (XAIImageCache)

+ (UIImageView *)imageViewWithURL:(NSString *)url;

- (void)imageWithURL:(NSString *)url;

@end

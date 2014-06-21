//
//  UIImageView+XAIImageCache.h
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 2/24/12.
//  Copyright (c) 2011-2014 Black Panther White Leopard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (XAIImageCache)

+ (UIImageView *)imageViewWithURL:(NSString *)url;

- (void)imageWithURL:(NSString *)url;
- (void)imageWithURL:(NSString *)url resize:(BOOL)resizeImage;

@end

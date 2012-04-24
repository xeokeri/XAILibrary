//
//  XAIImageCacheDelegate.h
//  XAIImageCache
//
//  Created by Xeon Xai on 4/2/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol XAIImageCacheDelegate <NSObject>

@optional

/** UIImageView and UIButton */
- (void)processCachedImage:(UIImage *)image;

/** UITableView */
- (void)processCachedImage:(UIImage *)image atIndexPath:(NSIndexPath *)indexPath;

@end

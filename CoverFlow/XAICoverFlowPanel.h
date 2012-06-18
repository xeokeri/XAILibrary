//
//  XAICoverFlowPanel.h
//  XAICoverFlow
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/29/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

/** XAIImageCache Protocol */
#import "XAIImageCacheDelegate.h"

@interface XAICoverFlowPanel : UIView <XAIImageCacheDelegate> {
    @private
    UIImageView *panelImageView;
    UIImageView *reflectionImageView;
    CAGradientLayer *reflectionGradient;
    UIActivityIndicatorView *loadingIndicator;
}

@property (nonatomic, retain) IBOutlet UIImageView *panelImageView;
@property (nonatomic, retain) IBOutlet UIImageView *reflectionImageView;
@property (nonatomic, retain) CAGradientLayer *reflectionGradient;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *loadingIndicator;

@end

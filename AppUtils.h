//
//  AppUtils.h
//  NativoFullScreenVideoSkin
//
//  Copyright (c) 2019 Nativo, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface AppUtils : NSObject

+ (void)setLoadingState:(BOOL)isLoading onView:(UIView *)view style:(UIActivityIndicatorViewStyle)style;
+ (void)setViewAnchors:(UIView *)innerView equalToView:(UIView *)outerView;
+ (void)setViewAnchors:(UIView *)innerView equalToView:(UIView *)outerView withInsets:(UIEdgeInsets)insets;
+ (void)setViewCenterAnchors:(UIView *)innerView equalToView:(UIView *)outerView;
+ (void)removeViewConstraints:(UIView *)view;

@end

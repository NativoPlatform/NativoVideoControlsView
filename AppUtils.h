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

@end

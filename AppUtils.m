
#import "AppUtils.h"

@implementation AppUtils

+ (void)setLoadingState:(BOOL)isLoading onView:(UIView *)view style:(UIActivityIndicatorViewStyle)style {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Show / hide spinner
        static const NSInteger tag = 11007;
        UIActivityIndicatorView *spinner = [view viewWithTag:tag];
        if (!spinner) {
            spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
            spinner.tag = tag;
            spinner.hidesWhenStopped = YES;
            
            [view addSubview:spinner];
            if (view.translatesAutoresizingMaskIntoConstraints) {
                spinner.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
                spinner.center = view.center;
            } else {
                [AppUtils setViewCenterAnchors:spinner equalToView:view];
                [spinner.widthAnchor constraintEqualToConstant:spinner.frame.size.width].active = YES;
                [spinner.heightAnchor constraintEqualToConstant:spinner.frame.size.height].active = YES;
            }
        }
        if (isLoading) {
            [spinner startAnimating];
        }
        else {
            [spinner stopAnimating];
            [spinner removeFromSuperview];
            [view addSubview:spinner];
            if (!spinner.translatesAutoresizingMaskIntoConstraints) {
                [AppUtils removeViewConstraints:spinner];
                [AppUtils setViewCenterAnchors:spinner equalToView:view];
                [spinner.widthAnchor constraintEqualToConstant:spinner.frame.size.width].active = YES;
                [spinner.heightAnchor constraintEqualToConstant:spinner.frame.size.height].active = YES;
            }
        }
    });
}

+ (void)setViewAnchors:(UIView *)innerView equalToView:(UIView *)outerView {
    innerView.translatesAutoresizingMaskIntoConstraints = NO;
    [innerView.leftAnchor constraintEqualToAnchor:outerView.leftAnchor].active = YES;
    [innerView.rightAnchor constraintEqualToAnchor:outerView.rightAnchor].active = YES;
    [innerView.topAnchor constraintEqualToAnchor:outerView.topAnchor].active = YES;
    [innerView.bottomAnchor constraintEqualToAnchor:outerView.bottomAnchor].active = YES;
}

+ (void)setViewAnchors:(UIView *)innerView equalToView:(UIView *)outerView withInsets:(UIEdgeInsets)insets {
    innerView.translatesAutoresizingMaskIntoConstraints = NO;
    [innerView.leftAnchor constraintEqualToAnchor:outerView.leftAnchor constant:insets.left].active = YES;
    [innerView.rightAnchor constraintEqualToAnchor:outerView.rightAnchor constant:insets.right].active = YES;
    [innerView.topAnchor constraintEqualToAnchor:outerView.topAnchor constant:insets.top].active = YES;
    [innerView.bottomAnchor constraintEqualToAnchor:outerView.bottomAnchor constant:insets.bottom].active = YES;
}

+ (void)setViewCenterAnchors:(UIView *)innerView equalToView:(UIView *)outerView {
    innerView.translatesAutoresizingMaskIntoConstraints = NO;
    [innerView.centerXAnchor constraintEqualToAnchor:outerView.centerXAnchor].active = YES;
    [innerView.centerYAnchor constraintEqualToAnchor:outerView.centerYAnchor].active = YES;
}

+ (void)removeViewConstraints:(UIView *)view {
    @try {
        // Remove contraints to superview
        if (view.superview) {
            [view.superview.constraints enumerateObjectsUsingBlock:^(__kindof NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
                if (constraint.firstItem == view || constraint.secondItem == view) {
                    [view.superview removeConstraint:constraint];
                }
            }];
        }
        // Remove height & width constraints
        [view.constraints enumerateObjectsUsingBlock:^(__kindof NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
            if ((constraint.firstAttribute == NSLayoutAttributeWidth && constraint.secondAttribute == NSLayoutAttributeNotAnAttribute) || (constraint.firstAttribute == NSLayoutAttributeHeight && constraint.secondAttribute == NSLayoutAttributeNotAnAttribute)) {
                [view removeConstraint:constraint];
            }
        }];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
}

@end

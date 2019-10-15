
#import "AppUtils.h"
#import "Masonry.h"

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
                spinner.translatesAutoresizingMaskIntoConstraints = NO;
                [view insertSubview:spinner atIndex:0];
                [spinner mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.center.equalTo(view);
                    make.width.mas_equalTo(spinner.frame.size.width);
                    make.height.mas_equalTo(spinner.frame.size.height);
                }];
            }
        }

        if (isLoading) {
            [spinner startAnimating];
        }
        else {
            [spinner stopAnimating];
            
            // Spinner stays hidden unless we do this, not sure why
            [spinner removeFromSuperview];
            [view insertSubview:spinner atIndex:0];
            if (!spinner.translatesAutoresizingMaskIntoConstraints) {
                [spinner mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.center.equalTo(view);
                    make.width.mas_equalTo(spinner.frame.size.width);
                    make.height.mas_equalTo(spinner.frame.size.height);
                }];
            }
        }
    });
}

@end

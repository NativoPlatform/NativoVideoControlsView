//
//  NtvVideoSlider.m
//  NativoFullScreenVideoSkin
//
//  Copyright (c) 2019 Nativo, Inc. All rights reserved.
//

#import "NtvVideoSlider.h"

@interface NtvVideoSlider ()
@property (nonatomic) UIProgressView *bufferProgressView;
@property (nonatomic) CGRect trackFrame;
@end

@implementation NtvVideoSlider

- (instancetype)init {
    self = [super init];
    [self commonInit];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    [self commonInit];
    return self;
}

- (void)commonInit {
    self.maximumTrackTintColor = [UIColor clearColor];
    self.bufferProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.bufferProgressView.backgroundColor = [UIColor clearColor];
    self.bufferProgressView.userInteractionEnabled = NO;
    self.bufferProgressView.progress = 0.88f;
    self.bufferProgressView.progressTintColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.75f];
    self.bufferProgressView.trackTintColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.5f];
    [self addSubview:self.bufferProgressView];
    
    // Edit thumb and track
    UIImage *thumb = [UIImage imageNamed:@"sliderThumb" inBundle:nil compatibleWithTraitCollection:nil];
    [self setThumbImage:thumb forState:UIControlStateNormal];
    [self setThumbImage:thumb forState:UIControlStateHighlighted];
    [self setThumbImage:thumb forState:UIControlStateFocused];
    
    UIImage *track = [UIImage imageNamed:@"sliderTrack" inBundle:nil compatibleWithTraitCollection:nil];
    track = [track resizableImageWithCapInsets:UIEdgeInsetsZero];
    [self setMinimumTrackImage:track forState:UIControlStateNormal];
    [self setMinimumTrackImage:track forState:UIControlStateHighlighted];
    [self setMinimumTrackImage:track forState:UIControlStateFocused];
}


- (void)setBufferProgress:(float)progress {
    _bufferProgress = progress;
    self.bufferProgressView.progress = progress;
}

- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value {
    CGRect thumbRect = [super thumbRectForBounds:bounds trackRect:rect value:value];
    thumbRect.origin.y += 1.5f;

    return thumbRect;
}

- (CGRect)trackRectForBounds:(CGRect)bounds {
    CGRect newFrame = [super trackRectForBounds:bounds];
    
    // Getting exception due to setting frame and setting transform on object which is messing with its bounds.
    @try {
        if (!CGRectIsNull(newFrame) && !CGRectEqualToRect(newFrame, self.trackFrame)) {
            newFrame.size.height = 6.0f;
            self.trackFrame = newFrame;
            self.bufferProgressView.frame = CGRectOffset(newFrame, 0, 2);
            
            // Set progress view to desired height using transformScale
            self.bufferProgressView.transform = CGAffineTransformScale(self.bufferProgressView.transform, 1.0f, 3.0f);
        }
    } @catch (NSException *exception) {
        NSLog(@"NativoSDK - Exception setting frame on progress bar: %@", exception);
    }
    
    return newFrame;
}

@end

//
//  NtvVideoPlayerControls.h
//  NativoFullScreenVideoSkin
//
//  Copyright (c) 2019 Nativo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "NtvVideoSlider.h"

@import NativoSDK;

@interface NtvCustomVideoControlsView : UIView <NtvVideoFullScreenControlsDelegate>

// NtvVideoFullScreenControlsDelegate properties
@property (nonatomic, weak) AVPlayer *player;
@property (nonatomic, weak) AVPlayerLayer *playerLayer;
@property (weak, nonatomic) IBOutlet UIButton *learnMoreButton;
@property (weak, nonatomic) IBOutlet UIButton *socialShareButton;

// Other Labels & Controls
@property (weak, nonatomic) IBOutlet UIView *videoPlaceholderView;
@property (weak, nonatomic) IBOutlet UIButton *infoBtn;
@property (weak, nonatomic) IBOutlet UIButton *playPauseBtn;
@property (weak, nonatomic) IBOutlet UIButton *collapseBtn;
@property (nonatomic) IBInspectable UIColor *learnMoreBorderColor;
@property (weak, nonatomic) IBOutlet NtvVideoSlider *seekSlider;
@property (weak, nonatomic) IBOutlet UIView *botFaderView;
@property (weak, nonatomic) IBOutlet UIView *topFaderView;
@property (weak, nonatomic) IBOutlet UILabel *elapsedTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *remainingTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleInfoLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoDescriptionInfoLabel;
@property (weak, nonatomic) IBOutlet UIView *infoBackgroundView;
@property (weak, nonatomic) IBOutlet UILabel *timerSlashLabel;
@property (weak, nonatomic) IBOutlet UIView *socialShareView;
@property (weak, nonatomic) IBOutlet UILabel *authorNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *seekSliderBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *learnMoreBottomConstraint;

@end

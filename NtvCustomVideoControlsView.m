//
//  NtvCustomVideoPlayerControls.m
//  NativoFullScreenVideoSkin
//
//  Copyright (c) 2020 Nativo, Inc. All rights reserved.
//

#import "NtvCustomVideoControlsView.h"
#import "AppUtils.h"
#import "KVOController.h"

#define SHOW_CONTROLS_DURATION 4

@interface NtvCustomVideoControlsView ()
@property (nonatomic) UIButton *showControlsBtn;
@property (nonatomic) float playerRateBeforeSeek;
@property (nonatomic) id timeObserver;
@property (nonatomic) BOOL isControlsVisible;
@property (nonatomic) BOOL isInfoScreenActive;
@property (nonatomic) BOOL isVideoFinished;
@property (nonatomic) dispatch_block_t dispatchInteractionTimerBlock;
@property (nonatomic) id stalledToken;
@end

@implementation NtvCustomVideoControlsView


#pragma mark - Setup

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    return self;
}


- (void)drawRect:(CGRect)rect {
    // draw gradients
    CAGradientLayer *gradientTop = [CAGradientLayer layer];
    gradientTop.frame = self.topFaderView.bounds;
    gradientTop.colors = [NSArray arrayWithObjects:(id)[[UIColor blackColor] CGColor], (id)[[UIColor clearColor] CGColor], nil];
    self.topFaderView.layer.sublayers = @[];
    [self.topFaderView.layer insertSublayer:gradientTop atIndex:0];
    
    CAGradientLayer *gradientBot = [CAGradientLayer layer];
    gradientBot.frame = CGRectOffset(self.botFaderView.bounds, 0, 1);
    gradientBot.colors = [NSArray arrayWithObjects:(id)[[UIColor clearColor] CGColor], (id)[[UIColor blackColor] CGColor], nil];
    self.botFaderView.layer.sublayers = @[];
    [self.botFaderView.layer insertSublayer:gradientBot atIndex:0];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.learnMoreButton.layer.borderWidth = 2.0f;
    self.learnMoreButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.learnMoreButton.clipsToBounds = NO;
        
    // set button over view to show and hide controls
    if (!self.showControlsBtn) {
        self.showControlsBtn = [[UIButton alloc] init];
        [self.showControlsBtn addTarget:self action:@selector(videoPlayerClick) forControlEvents:UIControlEventTouchDown];
        [self.videoPlaceholderView insertSubview:self.showControlsBtn belowSubview:self.seekSlider];
    }
    self.showControlsBtn.frame = self.videoPlaceholderView.bounds;
    
    // Size top & bottom fader views
    NSArray *layers = [self.topFaderView.layer.sublayers arrayByAddingObjectsFromArray:self.botFaderView.layer.sublayers];
    for (CALayer *layer in layers) {
        layer.frame = CGRectMake(0, 1, self.frame.size.width, self.topFaderView.frame.size.height);
    }
}

- (void)updateConstraints {
    // Adjust for iPhoneX
    if (@available(iOS 11.0, *)) {
        self.learnMoreBottomConstraint.constant = self.window.safeAreaInsets.bottom + 10.0f;
    }
    [super updateConstraints];
}

- (void)dealloc {
    [self.player removeTimeObserver:self.timeObserver];
}


#pragma mark - NtvVideoFullScreenControlsDelegate

- (UIView *)videoContainer {
    return self.videoPlaceholderView;
}

- (void)willLoadNewPlayerItem {
    [self syncPlayState];
}

- (void)didLoadNewPlayerItem:(AVPlayerItem *)playerItem {
    @try {
        // Reset UI
        self.isVideoFinished = NO;
        if (!CMTIME_IS_VALID(playerItem.currentTime) || CMTimeCompare(playerItem.currentTime, kCMTimeZero) == 0 ) {
            [self updateTimeLabel:0];
            self.seekSlider.value = 0;
            self.seekSlider.bufferProgress = 0;
        } else {
            [self observeTime:playerItem.currentTime];
        }
        [self syncPlayState];
        
        // Reset time label
        Float64 duration = CMTimeGetSeconds(playerItem.duration);
        if (!isnan(duration) && duration > 0) {
            self.remainingTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (((int)duration)/60) % 60, ((int)duration) % 60];
        } else {
            self.remainingTimeLabel.text = @"--";
            self.elapsedTimeLabel.text = @"--";
        }
        
        // Observer player state
        [self observePlayerState:playerItem];
        
    } @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
}

- (void)unobservePreviousPlayer {
    if (self.player && self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
    }
    [self.KVOController unobserveAll];
    [[NSNotificationCenter defaultCenter] removeObserver:self.stalledToken];
}

- (void)observePlayerState:(AVPlayerItem *)playerItem {
    
    __weak NtvCustomVideoControlsView *weakSelf = self;
    UILabel *remainingTimeLabel = self.remainingTimeLabel;
    __block float playerRateBeforeSeek = self.playerRateBeforeSeek;
    
    [self.KVOController observe:playerItem keyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @try {
            AVPlayerStatus newStatus = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            AVPlayerStatus oldStatus = [[change objectForKey:NSKeyValueChangeOldKey] integerValue];
            
            if (newStatus != oldStatus)
            {
                switch (newStatus) {
                    case AVPlayerStatusReadyToPlay: {
                        Float64 duration = CMTimeGetSeconds(playerItem.duration);
                        if (!isnan(duration) && duration > 0) {
                            remainingTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (((int)duration)/60) % 60, ((int)duration) % 60];
                        }
                        break;
                    }
                    default:
                        break;
                }
            }
        } @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
    }];
    
    // Observe buffer rate
    __weak VideoSlider *videoSlider  = self.seekSlider;
    [self.KVOController observe:playerItem keyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionOld block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @try {
            Float64 maxBufferTime = 0;
            for (NSValue *val in playerItem.loadedTimeRanges) {
                CMTimeRange timeRange = [val CMTimeRangeValue];
                Float64 start = CMTimeGetSeconds(timeRange.start);
                Float64 duration = CMTimeGetSeconds(timeRange.duration);
                Float64 bufferTime = start + duration;
                if (bufferTime > maxBufferTime) {
                    maxBufferTime = bufferTime;
                }
            }
            videoSlider.bufferProgress = maxBufferTime / CMTimeGetSeconds(playerItem.duration);
        } @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
    }];
    
    // Observe play rate change (Show/hide info screen & sync play/pause button)
    [self.KVOController observe:self.player keyPath:@"rate" options:NSKeyValueObservingOptionOld block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        __strong NtvCustomVideoControlsView *strongSelf = weakSelf;
        @try {
            if (strongSelf) {
                float oldRate = [[change objectForKey:NSKeyValueChangeOldKey] floatValue];
                if (oldRate != strongSelf.player.rate) {
                    strongSelf.isVideoFinished = NO;
                    if (strongSelf.player.rate > 0 && strongSelf.isInfoScreenActive) {
                        [strongSelf hideInfoScreen];
                    } else if (strongSelf.player.rate == 0) {
                        if (strongSelf.seekSlider.value > 0.99f) {
                            strongSelf.isVideoFinished = YES;
                        }
                        [strongSelf showInfoScreen];
                    }
                    [strongSelf syncPlayState];
                }
            }
        } @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
    }];
    
    
    // Detect buffering state
    self.stalledToken = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemPlaybackStalledNotification object:playerItem queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        __strong NtvCustomVideoControlsView *strongSelf = weakSelf;
        if (strongSelf) {
            if ([strongSelf.player respondsToSelector:@selector(automaticallyWaitsToMinimizeStalling)]) {
                if (!strongSelf.player.automaticallyWaitsToMinimizeStalling) {
                    playerRateBeforeSeek = 1; // This will automatically trigger video play once buffer is ready
                }
            }
        }
    }];
    
    [self.KVOController observe:playerItem keyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @try {
            __strong NtvCustomVideoControlsView *strongSelf = weakSelf;
            if (strongSelf) {
                BOOL playbackBufferEmpty = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
                if (playbackBufferEmpty) {
                    playerRateBeforeSeek = strongSelf.player.rate;
                }
            }
        } @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
    }];
    
    [self.KVOController observe:playerItem keyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        __strong NtvCustomVideoControlsView *strongSelf = weakSelf;
        @try {
            if (strongSelf) {
                if (playerItem.playbackLikelyToKeepUp && playerRateBeforeSeek > 0) {
                    [strongSelf.player play];
                    playerRateBeforeSeek = 0;
                }
                [strongSelf syncPlayState];
            }
        } @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
    }];
}

- (void)setPlayer:(AVPlayer *)player {
    _player = player;

    // Add observer to update time labels
    __weak NtvCustomVideoControlsView *weakSelf = self;
    CMTime updateInterval = CMTimeMakeWithSeconds(1.0f, 10);
    self.timeObserver = [player addPeriodicTimeObserverForInterval:updateInterval queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [weakSelf observeTime:time];
    }];
}

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
    self.titleInfoLabel.text = title;
}

- (void)setContentText:(NSString *)content {
    self.contentTextView.text = content;
    self.videoDescriptionInfoLabel.text = content;
}

- (void)setAuthorName:(NSString *)author {
    self.authorNameLabel.text = author;
}


#pragma mark - Video Control Logic
     
 - (void)videoPlayerClick {
     [self playPauseClick:nil];
 }


- (void)showControls:(float)animationSpeed {
    self.isControlsVisible = YES;
    
    [UIView animateWithDuration:animationSpeed animations:^{
        self.topFaderView.alpha = 1;
        self.botFaderView.alpha = 1;
        self.playPauseBtn.alpha = 1;
        self.seekSlider.alpha = 1;
        self.collapseBtn.alpha = 1;
        self.contentTextView.alpha = 1;
        self.titleLabel.alpha = 1;
        self.authorNameLabel.alpha = 1;
        self.learnMoreButton.alpha = 1;
        self.elapsedTimeLabel.alpha = 1;
        self.remainingTimeLabel.alpha = 1;
        self.timerSlashLabel.alpha = 1;
        self.infoBtn.alpha = 1;
    } completion:^(BOOL finished) {
        [self resetHideControlsTimer];
    }];
}


- (void)hideControls:(float)animationSpeed {
    self.isControlsVisible = NO;
    [UIView animateWithDuration:animationSpeed animations:^{
        self.topFaderView.alpha = 0;
        self.botFaderView.alpha = 0;
        self.playPauseBtn.alpha = 0;
        self.seekSlider.alpha = 0;
        self.elapsedTimeLabel.alpha = 0;
        self.remainingTimeLabel.alpha = 0;
        self.timerSlashLabel.alpha = 0;
    }];
    
    // Landscape
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact
        || (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular && self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular)) {
        [UIView animateWithDuration:animationSpeed animations:^{
            self.collapseBtn.alpha = 0;
            self.titleLabel.alpha = 0;
            self.authorNameLabel.alpha = 0;
            self.learnMoreButton.alpha = 0;
            self.infoBtn.alpha = 0;
        }];
    } else {
        [UIView animateWithDuration:animationSpeed animations:^{
            self.collapseBtn.alpha = 1;
            self.titleLabel.alpha = 1;
            self.authorNameLabel.alpha = 1;
            self.learnMoreButton.alpha = 1;
        }];
    }
}


- (IBAction)infoButtonClick:(id)sender {
    
    if (self.isInfoScreenActive) {
        [self hideInfoScreen];
        if (self.playerRateBeforeSeek > 0) {
            [self.player play];
        }
    } else {
        self.playerRateBeforeSeek = self.player.rate;
        [self.player pause];
        [self showInfoScreen];
    }
}


- (void)showInfoScreen {
    // Show controls
    if (!self.isControlsVisible) {
        [self showControls:0.3f];
    }
    
    // prevent controls from hiding
    if (self.dispatchInteractionTimerBlock) {
        dispatch_block_cancel(self.dispatchInteractionTimerBlock);
    }
    
    // Landscape
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact
        || (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular && self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular)) {
        
        self.isInfoScreenActive = YES;
        
        [UIView animateWithDuration:0.33f animations:^{
            [self.titleLabel setAlpha:0];
            [self.titleInfoLabel setAlpha:1];
            [self.videoDescriptionInfoLabel setAlpha:1];
            [self.infoBackgroundView setAlpha:1];
            [self.socialShareButton setAlpha:0.9f];
        }];
    }
}


- (void)hideInfoScreen {
    self.isInfoScreenActive = NO;
    [UIView animateWithDuration:0.33f animations:^{
        if (self.isControlsVisible) {
            [self.titleLabel setAlpha:1];
        }
        [self.titleInfoLabel setAlpha:0];
        [self.videoDescriptionInfoLabel setAlpha:0];
        [self.infoBackgroundView setAlpha:0];
        [self.socialShareButton setAlpha:0];
    }];
    [self resetHideControlsTimer];
    
    // Portrait
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        [self.socialShareButton setAlpha:0.9f];
    }
}


- (void)resetHideControlsTimer {
    // this 'if' clause ensure we don't hide controls when video is finished or info screen is up
    if (!self.isInfoScreenActive && !self.isVideoFinished) {
        
        // Cancel previous touches
        if (self.dispatchInteractionTimerBlock) {
            dispatch_block_cancel(self.dispatchInteractionTimerBlock);
        }
        // Auto-hide controls after time SHOW_CONTROLS_DURATION
        __weak NtvCustomVideoControlsView *weakSelf = self;
        self.dispatchInteractionTimerBlock = dispatch_block_create(0, ^{
            [weakSelf hideControls:0.66f];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SHOW_CONTROLS_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), self.dispatchInteractionTimerBlock);
    }
}


- (IBAction)playPauseClick:(id)sender {
    // Replay
    if (self.isVideoFinished) {
        self.isVideoFinished = NO;
        [self.player seekToTime:CMTimeMakeWithSeconds(0, 100) completionHandler:^(BOOL finished) {}];
        [self.player play];
    } else if (self.player.rate > 0) {
        [self.player pause];
    } else {
        [self.player play];
    }
    [self resetHideControlsTimer];
}


- (IBAction)collapseClick:(id)sender {
    [self unobservePreviousPlayer];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ntvcollapse" object:nil];
}


- (void)syncPlayState {
    if (self.player && self.player.currentItem) {
        if (self.isVideoFinished) {
            // replay state
            UIImage *replayImg = [UIImage imageNamed:@"replay"];
            [self.playPauseBtn setImage:replayImg forState:UIControlStateNormal];
        }
        else if (self.player.rate > 0) {
            // play state
            UIImage *pauseImg = [UIImage imageNamed:@"pause"];
            [self.playPauseBtn setImage:pauseImg forState:UIControlStateNormal];
        }
        else if (self.player.rate == 0) {
            // pause state
            UIImage *playImg = [UIImage imageNamed:@"play"];
            [self.playPauseBtn setImage:playImg forState:UIControlStateNormal];
        }
    }
    
    // Buffering state
    [AppUtils setLoadingState:[self isBuffering] onView:self.videoPlaceholderView style:UIActivityIndicatorViewStyleWhiteLarge];
}

- (BOOL)isBuffering {
    BOOL isBuffering;
    if ([self.player respondsToSelector:@selector(automaticallyWaitsToMinimizeStalling)]) {
        isBuffering = (!self.player || !self.player.currentItem)
            || (!self.player.automaticallyWaitsToMinimizeStalling && self.player.rate == 0 && !self.player.currentItem.playbackLikelyToKeepUp)
            || (self.player.automaticallyWaitsToMinimizeStalling && !self.player.currentItem.playbackLikelyToKeepUp);
    } else {
        isBuffering = (!self.player || !self.player.currentItem)
            || (self.player.rate == 0 && !self.player.currentItem.playbackLikelyToKeepUp);
    }
    return isBuffering;
}


#pragma mark - Time Observing

- (void)observeTime:(CMTime)elapsedTime {
    float duration = CMTimeGetSeconds(self.player.currentItem.duration);
    if (isfinite(duration)) {
        float time = CMTimeGetSeconds(elapsedTime);
        [self updateTimeLabel:time];
        self.seekSlider.value = time / duration;
    }
}

- (void)updateTimeLabel:(float)elapsedTime {
    self.elapsedTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (((int)elapsedTime)/60) % 60, ((int)elapsedTime) % 60];
}



#pragma mark - Seeking

- (IBAction)seekValueChanged:(VideoSlider *)slider {
    float videoDuration = CMTimeGetSeconds(self.player.currentItem.duration);
    float elapsedTime = videoDuration * self.seekSlider.value;
    [self updateTimeLabel:elapsedTime];
}

- (IBAction)seekStart:(VideoSlider *)slider {
    [self resetHideControlsTimer];
    self.playerRateBeforeSeek = self.player.rate;
    [self.player pause];
}

- (IBAction)seekEnd:(VideoSlider *)slider {
    if (slider.value <= 0.99) {
        Float64 videoDuration = CMTimeGetSeconds(self.player.currentItem.duration);
        Float64 elapsedTime = videoDuration * slider.value;
        
        __weak NtvCustomVideoControlsView *weakSelf = self;
        [self.player seekToTime:CMTimeMakeWithSeconds(elapsedTime, 100) completionHandler:^(BOOL finished) {
            // resume playing
            if (weakSelf.playerRateBeforeSeek > 0) {
                [weakSelf.player play];
            }
            [weakSelf syncPlayState];
        }];
        
        [self updateTimeLabel:elapsedTime];
    } else {
        // End of video seek state
        [self.player pause];
        [self updateTimeLabel:CMTimeGetSeconds(self.player.currentItem.duration)];
        [self syncPlayState];
    }
    
    [self resetHideControlsTimer];
}



#pragma mark - Size Class Management

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    
    [super traitCollectionDidChange: previousTraitCollection];
    if ((self.traitCollection.verticalSizeClass != previousTraitCollection.verticalSizeClass) || (self.traitCollection.horizontalSizeClass != previousTraitCollection.horizontalSizeClass)) {
        
        // Reset controls UI (methods contain logic to set themselves up based on size classes)
        if (self.isControlsVisible) {
            [self showControls:0];
        } else {
            [self hideControls:0];
        }
        
        // Landscape (w:reg h:reg for ipad pro)
        if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact || (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular && self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular)) {
            self.authorNameLabel.textAlignment = NSTextAlignmentRight;
            // if paused show info screen & controls
            if (self.player.rate == 0) {
                [self showInfoScreen];
            } else {
                [self hideInfoScreen];
            }
            
            // Adjust for iPhoneX
            if (@available(iOS 11.0, *)) {
                self.seekSliderBottomConstraint.constant = self.window.safeAreaInsets.bottom;
                [self updateConstraints];
            }
            
        }
        
        // Portrait
        else {
            self.authorNameLabel.textAlignment = NSTextAlignmentLeft;
            if (!self.isVideoFinished) {
                [self hideInfoScreen];
            }
            
            // Adjust for iPhoneX
            if (@available(iOS 11.0, *)) {
                self.seekSliderBottomConstraint.constant = 9;
                [self updateConstraints];
            }
        }
    }
}

@end

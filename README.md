#  Nativo Full Screen Video Controls

The default full screen video controls used by the NativoSDK. You can use this as a starting point to customize the video player for your needs.

### Getting Started

Download the repo and import the code and resources into your project. Once you've finished making any customizations, simply register your custom video controls like this:

    NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"NtvCustomVideoControlsView" owner:nil options:nil];
    if (nibItems > 0) {
        NtvCustomVideoControlsView *customVideoSkin = nibItems[0];
        [NativoSDK setCustomFullScreenVideoControlsView:customVideoSkin];
    }


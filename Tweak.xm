#import "Tweak.h"

/**
 * Load Preferences
 */
BOOL noads;
BOOL canSaveVideo;
BOOL canSaveStory;
BOOL canSaveOnlyMeProfilePicture;
BOOL disableStorySeen;
BOOL hideNewsFeedComposer;
BOOL hideNewsFeedStories;

static void reloadPrefs() {
  NSDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH] ?: [@{} mutableCopy];

  noads = [[settings objectForKey:@"noads"] ?: @(YES) boolValue];
  canSaveVideo = [[settings objectForKey:@"canSaveVideo"] ?: @(YES) boolValue];
  canSaveStory = [[settings objectForKey:@"canSaveStory"] ?: @(YES) boolValue];
  canSaveOnlyMeProfilePicture = [[settings objectForKey:@"canSaveOnlyMeProfilePicture"] ?: @(YES) boolValue];
  disableStorySeen = [[settings objectForKey:@"disableStorySeen"] ?: @(YES) boolValue];
  hideNewsFeedComposer = [[settings objectForKey:@"hideNewsFeedComposer"] ?: @(NO) boolValue];
  hideNewsFeedStories = [[settings objectForKey:@"hideNewsFeedStories"] ?: @(NO) boolValue];
}

static void showDownloadVideoAlert(NSURL *HDPlaybackURL, NSURL *SDPlaybackURL, UIViewController *viewController) {
  UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:IS_iPAD ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
  [alert addAction:[UIAlertAction actionWithTitle:@"Download Video - HD" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    NSURL *videoURL = HDPlaybackURL;
    if (!videoURL) {
      [HCommon showAlertMessage:@"This video doesn't have HD quality, please select other quality" withTitle:@"No HD quality" viewController:viewController];
      return;
    }
    NSString *videoURLString = videoURL.absoluteString;
    [[[HDownloadMediaWithProgress alloc] init] checkPermissionToPhotosAndDownload:videoURLString appendExtension:nil mediaType:Video toAlbum:@"Facebook" viewController:viewController];
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Download Video - SD" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    NSURL *videoURL = SDPlaybackURL;
    if (!videoURL) {
      [HCommon showAlertMessage:@"This video doesn't have SD quality, please select other quality" withTitle:@"No SD quality" viewController:viewController];
      return;
    }
    NSString *videoURLString = videoURL.absoluteString;
    [[[HDownloadMediaWithProgress alloc] init] checkPermissionToPhotosAndDownload:videoURLString appendExtension:nil mediaType:Video toAlbum:@"Facebook" viewController:viewController];
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  [viewController presentViewController:alert animated:YES completion:nil];
}

%group NoAds
  %hook FBMemNewsFeedEdge
    - (id)initWithFBTree:(void *)arg1 {
      id orig = %orig;
      id category = [orig category];
      return category ? [category isEqualToString:@"ORGANIC"] ? orig : nil : orig;
    }
  %end

  %hook FBMemFeedStory
    - (id)initWithFBTree:(void *)arg1 {
      id orig = %orig;
      return [orig sponsoredData] == nil ? orig : nil;
    }
  %end

  %hook FBVideoChannelPlaylistItem
    - (id)Bi:(id)arg1 :(id)arg2 :(id)arg3 :(id)arg4 :(id)arg5 :(id)arg6 :(id)arg7 {
      id orig = %orig;
      return [orig isSponsored] ? nil : orig;
    }
  %end
%end

%group HideNewsFeedComposer
  %hook FBNewsFeedViewControllerConfiguration
    - (BOOL)shouldHideComposer {
      return TRUE;
    }
  %end
%end

%group HideNewsFeedChatRoomStories
  %hook FBComponentCollectionViewDataSource
    - (id)collectionView:(id)arg1 cellForItemAtIndexPath:(NSIndexPath *)arg2 {
      id orig = %orig;
      if (![arg1 isKindOfClass:%c(FBNewsFeedCollectionView)]) {
        return orig;
      }

      if ([self shouldHideSectionNumber:arg2.section]) {
        [orig setHidden: YES];
      } else {
        [orig setHidden: NO];
      }
      return orig;
    }

    - (CGSize)collectionView:(id)arg1 layout:(id)arg2 sizeForItemAtIndexPath:(NSIndexPath *)arg3 {
      CGSize orig = %orig;
      if (![arg1 isKindOfClass:%c(FBNewsFeedCollectionView)]) {
        return orig;
      }

      if ([self shouldHideSectionNumber:arg3.section]) {
        orig.height = 1;
        orig.width = 1;
      }
      return orig;
    }

    %new
    - (BOOL)shouldHideSectionNumber:(int)sectionNumber {
      if (hideNewsFeedComposer) {
        if (([self dataSourceState].sections.count == 3 && sectionNumber == 0) || ([self dataSourceState].sections.count == 4 && (sectionNumber == 0 || sectionNumber == 1))) {
          return TRUE;
        }
      } else {
        if (([self dataSourceState].sections.count == 4 && sectionNumber == 1) || ([self dataSourceState].sections.count == 5 && (sectionNumber == 1 || sectionNumber == 2))) {
          return TRUE;
        }
      }
      return FALSE;
    }
  %end
%end

%group CanSaveVideo
  %hook VideoContainerView
    - (id)syc:(CGRect)arg1:(id)arg2 {
      id orig = %orig;
      [orig addHandleLongPress];
      return orig;
    }

    - (id)nyc:(CGRect)arg1:(id)arg2 {
      id orig = %orig;
      [orig addHandleLongPress];
      return orig;
    }

    %new
    - (void)addHandleLongPress {
      UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
      longPress.minimumPressDuration = 0.5;
      [self addGestureRecognizer:longPress];
    }

    %new
    - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
      if (sender.state == UIGestureRecognizerStateBegan) {
        FBVideoPlaybackItem *videoPlaybackItem = [self.controller currentVideoPlaybackItem];
        if (!videoPlaybackItem) {
          [HCommon showAlertMessage:@"Can't find Video source, please report to developer" withTitle:@"Error" viewController:nil];
          return;
        }

        showDownloadVideoAlert(videoPlaybackItem.HDPlaybackURL, videoPlaybackItem.SDPlaybackURL, [self reactViewController]);
      }
    }
  %end

  %hook FBVideoOverlayPluginComponentBackgroundView
    - (id)initWithFrame:(struct CGRect)arg1 {
      id orig = %orig;
      [orig addHandleLongPress];
      return orig;
    }

    %new
    - (void)addHandleLongPress {
      UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
      longPress.minimumPressDuration = 0.5;
      [self addGestureRecognizer:longPress];
    }

    %new
    - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
      if (sender.state == UIGestureRecognizerStateBegan) {
        UIView *view = self.superview.superview.superview.superview;
        if (![view isKindOfClass:%c(VideoContainerView)]) {
          @try {
            view = self.superview.subviews[1].subviews[0].subviews[0];
          } @catch (NSException *exception) { }
        }
        if (![view isKindOfClass:%c(VideoContainerView)]) {
          @try {
            view = self.superview.subviews[2].subviews[0].subviews[0];
          } @catch (NSException *exception) { }
        }
        if (![view isKindOfClass:%c(VideoContainerView)]) {
          @try {
            view = self.superview.subviews[3].subviews[0].subviews[0];
          } @catch (NSException *exception) { }
        }
        if (![view isKindOfClass:%c(VideoContainerView)]) {
          [HCommon showAlertMessage:@"Can't find Video container, please report to developer" withTitle:@"Error" viewController:nil];
          return;
        }
        VideoContainerView *videoContainerView = (VideoContainerView *)view;
        FBVideoPlaybackItem *videoPlaybackItem = [videoContainerView.controller currentVideoPlaybackItem];
        if (!videoPlaybackItem) {
          [HCommon showAlertMessage:@"Can't find Video source, please report to developer" withTitle:@"Error" viewController:nil];
          return;
        }

        showDownloadVideoAlert(videoPlaybackItem.HDPlaybackURL, videoPlaybackItem.SDPlaybackURL, [self reactViewController]);
      }
    }
  %end
%end

%group CanSaveStory
  %hook FBSnacksMediaContainerView
    %property (nonatomic, retain) UIButton *hDownloadButton;
    - (id)initWithThread:(id)arg1 bucket:(id)arg2 mediaViewDelegate:(id)arg3 mediaViewGenerator:(id *)arg4 toolbox:(id)arg5 {
      self = %orig;

      self.hDownloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
      [self.hDownloadButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
      [self.hDownloadButton addTarget:self action:@selector(hDownloadButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
      [self.hDownloadButton setBackgroundImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/facebooknoads/download.png"] forState:UIControlStateNormal];
      self.hDownloadButton.frame = IS_iPAD ? CGRectMake([[UIApplication sharedApplication] keyWindow].frame.size.width / 2 + 60, [[UIApplication sharedApplication] keyWindow].frame.size.height - 140.0, 24.0, 24.0) : CGRectMake([[UIApplication sharedApplication] keyWindow].frame.size.width - 40, [[UIApplication sharedApplication] keyWindow].frame.size.height - ([HCommon isNotch] ? 190.0 : 90.0), 24.0, 24.0);
      [self addSubview:self.hDownloadButton];
      return self;
    }

    %new
    - (void)hDownloadButtonPressed:(UIButton *)sender {
      if ([self.mediaView isKindOfClass:%c(FBSnacksPhotoView)]) {
        @try {
          FBSnacksWebPhotoView *_snacksWebPhotoView = MSHookIvar<FBSnacksWebPhotoView *>(self.mediaView, "_photoView");
          FBWebPhotoView *_photoView = MSHookIvar<FBWebPhotoView *>(_snacksWebPhotoView, "_photoView");
          id imageSpecifier = _photoView.imageSpecifier;
          if ([imageSpecifier isKindOfClass:%c(FBWebImageNetworkSpecifier)]) {
            NSURL *url = ((FBWebImageNetworkSpecifier *)imageSpecifier).allInfoURLsSortedByDescImageFlag[0];
            [[[HDownloadMediaWithProgress alloc] init] checkPermissionToPhotosAndDownloadURL:url appendExtension:nil mediaType:Image toAlbum:@"Facebook" view:self];
          }
          else if ([imageSpecifier isKindOfClass:%c(FBWebImageMemorySpecifier)]) {
            UIImageWriteToSavedPhotosAlbum(((FBWebImageMemorySpecifier *)imageSpecifier).image, nil, nil, nil);
            [HCommon showToastMessage:@"" withTitle:@"Done!" timeout:0.5 viewController:nil];
          }
        } @catch(NSException *exception) {
          [HCommon showAlertMessage:exception.reason withTitle:@"Error" viewController:nil];
        }
      } else if ([self.mediaView isKindOfClass:%c(FBSnacksNewVideoView)]) {
        FBVideoPlaybackItem *videoPlaybackItem = [((FBSnacksNewVideoView *)self.mediaView).manager currentVideoPlaybackItem];
        showDownloadVideoAlert(videoPlaybackItem.HDPlaybackURL, videoPlaybackItem.SDPlaybackURL, [self reactViewController]);
      } else {
        [HCommon showAlertMessage:@"This story has no media to download. Seems like it's a bug. Please report to the developer" withTitle:@"Error" viewController:nil];
      }
    }
  %end
%end

%group CanSaveOnlyMeProfilePicture
  %hook FBPhotoViewController
    %property (nonatomic, retain) UIButton *hDownloadButton;
    - (void)viewDidAppear:(BOOL)arg1 {
      %orig;

      NSUInteger _actionSheetOptions = MSHookIvar<NSUInteger>(self, "_actionSheetOptions");
      if (_actionSheetOptions != 0 || (self.hDownloadButton && [self.hDownloadButton isDescendantOfView:self.view])) {
        return;
      }

      self.hDownloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
      [self.hDownloadButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
      [self.hDownloadButton addTarget:self action:@selector(hDownloadButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
      [self.hDownloadButton setBackgroundImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/facebooknoads/download.png"] forState:UIControlStateNormal];
      self.hDownloadButton.frame = CGRectMake([[UIApplication sharedApplication] keyWindow].frame.size.width - 40, [[UIApplication sharedApplication] keyWindow].frame.size.height - ([HCommon isNotch] ? 190.0 : 90.0), 24.0, 24.0);
      [self.view addSubview:self.hDownloadButton];
    }

    %new
    - (void)hDownloadButtonPressed:(UIButton *)sender {
      UIImageWriteToSavedPhotosAlbum(self.displayedImage, nil, nil, nil);
      [HCommon showToastMessage:@"" withTitle:@"Done!" timeout:0.5 viewController:nil];
    }
  %end
%end

%group DisableStorySeen
  %hook FBSnacksBucketsSeenStateManager
    - (void)_sendSeenThreadIDsWithBucket:(id)arg1 session:(id)arg2 {
    }
  %end
%end

%ctor {
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) reloadPrefs, CFSTR(PREF_CHANGED_NOTIF), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
  reloadPrefs();

  dlopen([[[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"Frameworks/FBSharedDynamicFramework.framework/FBSharedDynamicFramework"] UTF8String], RTLD_NOW);
  // dlopen([[[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"Frameworks/FBMessagingFramework.framework/FBMessagingFramework"] UTF8String], RTLD_NOW);

  if (noads) {
    %init(NoAds);
  }

  if (canSaveVideo) {
    %init(CanSaveVideo);
  }

  if (canSaveStory) {
    %init(CanSaveStory);
  }

  if (canSaveOnlyMeProfilePicture) {
    %init(CanSaveOnlyMeProfilePicture);
  }

  if (disableStorySeen) {
    %init(DisableStorySeen);
  }

  if (hideNewsFeedComposer) {
    %init(HideNewsFeedComposer);
  }

  if (hideNewsFeedStories) {
    %init(HideNewsFeedChatRoomStories);
  }
}


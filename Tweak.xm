#import "Tweak.h"

/**
 * Load Preferences
 */
BOOL noads;
BOOL canSaveVideo;
BOOL hideNewsFeedComposer;
BOOL hideNewsFeedStories;

static void reloadPrefs() {
  NSDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH] ?: [@{} mutableCopy];

  noads = [[settings objectForKey:@"noads"] ?: @(YES) boolValue];
  canSaveVideo = [[settings objectForKey:@"canSaveVideo"] ?: @(YES) boolValue];
  hideNewsFeedComposer = [[settings objectForKey:@"hideNewsFeedComposer"] ?: @(NO) boolValue];
  hideNewsFeedStories = [[settings objectForKey:@"hideNewsFeedStories"] ?: @(NO) boolValue];
}

static void showDownloadVideoAlert(FBVideoPlaybackItem *videoPlaybackItem, UIViewController *viewController) {
  UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
  [alert addAction:[UIAlertAction actionWithTitle:@"Download Video - HD" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    NSURL *videoURL = videoPlaybackItem.HDPlaybackURL;
    if (!videoURL) {
      [HCommon showAlertMessage:@"This video doesn't have HD quality, please select other quality" withTitle:@"No HD quality" viewController:viewController];
      return;
    }
    NSString *videoURLString = videoURL.absoluteString;
    [[[HDownloadMediaWithProgress alloc] init] checkPermissionToPhotosAndDownload:videoURLString appendExtension:nil mediaType:Video toAlbum:@"Facebook" viewController:viewController];
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Download Video - SD" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    NSURL *videoURL = videoPlaybackItem.SDPlaybackURL;
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
        if (([self dataSourceState].sections.count == 3 && sectionNumber == 0) || ([self dataSourceState].sections.count == 4 && sectionNumber == 1)) {
          return TRUE;
        }
      } else {
        if (([self dataSourceState].sections.count == 4 && sectionNumber == 1) || ([self dataSourceState].sections.count == 5 && sectionNumber == 2)) {
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

        showDownloadVideoAlert(videoPlaybackItem, [self reactViewController]);
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

        showDownloadVideoAlert(videoPlaybackItem, [self reactViewController]);
      }
    }
  %end
%end

%ctor {
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) reloadPrefs, CFSTR(PREF_CHANGED_NOTIF), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
  reloadPrefs();

  if (noads) {
    %init(NoAds);
  }

  if (canSaveVideo) {
    %init(CanSaveVideo);
  }

  if (hideNewsFeedComposer) {
    %init(HideNewsFeedComposer);
  }

  if (hideNewsFeedStories) {
    %init(HideNewsFeedChatRoomStories);
  }
}


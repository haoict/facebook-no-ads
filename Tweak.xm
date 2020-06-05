#import "Tweak.h"

/**
 * Load Preferences
 */
BOOL noads;
BOOL canSaveVideo;
BOOL hideNewsFeedComposer;
BOOL hideNewsFeedRoom;
BOOL hideNewsFeedStories;

static void reloadPrefs() {
  NSDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH] ?: [@{} mutableCopy];

  noads = [[settings objectForKey:@"noads"] ?: @(YES) boolValue];
  canSaveVideo = [[settings objectForKey:@"canSaveVideo"] ?: @(YES) boolValue];
  hideNewsFeedComposer = [[settings objectForKey:@"hideNewsFeedComposer"] ?: @(NO) boolValue];
  hideNewsFeedRoom = [[settings objectForKey:@"hideNewsFeedRoom"] ?: @(NO) boolValue];
  hideNewsFeedStories = [[settings objectForKey:@"hideNewsFeedStories"] ?: @(NO) boolValue];
}

%group NoAds
  %hook FBMemSponsoredData
    - (id)initWithFBTree:(void *)arg1 {
      return nil;
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
        if (sectionNumber == 0) {
          return TRUE;
        }
      } else {
        if (sectionNumber == 1) {
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
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:@"Download Video" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
          NSURL *videoURL = [self.controller currentVideoPlaybackItem].HDPlaybackURL;
          if (!videoURL) {
            videoURL = [self.controller currentVideoPlaybackItem].SDPlaybackURL;
          }
          NSString *videoURLString = videoURL.absoluteString;
          [HCommon showToastMessage:@"Downloading in background..." withTitle:@"Please wait" timeout:1.0 viewController:nil];
          [HDownloadMedia checkPermissionToPhotosAndDownload:videoURLString appendExtension:nil mediaType:Video toAlbum:@"Facebook"];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [[self reactViewController] presentViewController:alert animated:YES completion:nil];
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
          view = self.superview.subviews[1].subviews[0].subviews[0];
        }
        VideoContainerView *videoContainerView = (VideoContainerView *)view;

        UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:@"Download Video" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
          NSURL *videoURL = [videoContainerView.controller currentVideoPlaybackItem].HDPlaybackURL;
          if (!videoURL) {
            videoURL = [videoContainerView.controller currentVideoPlaybackItem].SDPlaybackURL;
          }
          NSString *videoURLString = videoURL.absoluteString;
          [HCommon showToastMessage:@"Downloading in background..." withTitle:@"Please wait" timeout:1.0 viewController:nil];
          [HDownloadMedia checkPermissionToPhotosAndDownload:videoURLString appendExtension:nil mediaType:Video toAlbum:@"Facebook"];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [[self reactViewController] presentViewController:alert animated:YES completion:nil];
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

  if (hideNewsFeedRoom || hideNewsFeedStories) {
    %init(HideNewsFeedChatRoomStories);
  }
}


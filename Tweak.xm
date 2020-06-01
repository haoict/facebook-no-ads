#import "Tweak.h"

/**
 * Load Preferences
 */
BOOL noads;

static void reloadPrefs() {
  NSDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH] ?: [@{} mutableCopy];

  noads = [[settings objectForKey:@"noads"] ?: @(YES) boolValue];
}

%group NoAds
  %hook FBMemNewsFeedEdge
  - (id)initWithFBTree:(void *)arg1 {
    id orig = %orig;
    id category = [orig category];
    return category ? [category isEqual:@"ORGANIC"] ? orig : nil : orig;
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

%ctor {
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) reloadPrefs, CFSTR(PREF_CHANGED_NOTIF), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
  reloadPrefs();

  if (noads) {
    %init(NoAds);
  }
}


#import <Foundation/Foundation.h>

#define PLIST_PATH "/var/mobile/Library/Preferences/com.haoict.facebooknoadspref.plist"
#define PREF_CHANGED_NOTIF "com.haoict.facebooknoadspref/PrefChanged"

@interface FBMemNewsFeedEdge
- (id)category;
@end;

@interface FBMemFeedStory
- (id)sponsoredData;
@end

@interface FBVideoChannelPlaylistItem
- (bool)isSponsored;
@end

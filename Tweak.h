#import <Foundation/Foundation.h>
#import <libhdev/HUtilities/HDownloadMedia.h>

#define PLIST_PATH "/var/mobile/Library/Preferences/com.haoict.facebooknoadspref.plist"
#define PREF_CHANGED_NOTIF "com.haoict.facebooknoadspref/PrefChanged"

@interface FBVideoPlaybackItem : NSObject
@property(readonly, copy, nonatomic) NSURL *sphericalPlaybackHDURL;
@property(readonly, copy, nonatomic) NSURL *sphericalPlaybackURL;
@property(readonly, copy, nonatomic) NSURL *HLSPlaybackURL;
@property(readonly, copy, nonatomic) NSURL *DashPlaybackURL;
@property(readonly, copy, nonatomic) NSURL *HDPlaybackURL;
@property(readonly, copy, nonatomic) NSURL *SDPlaybackURL;
@property(readonly, copy, nonatomic) NSArray *instreamVideoAdBreaks;
@end

@interface FBVideoPlaybackController : NSObject
- (FBVideoPlaybackItem *)currentVideoPlaybackItem;
@end

@interface VideoContainerView : UIView
@property(readonly, nonatomic) FBVideoPlaybackController *controller;
- (UIViewController *)reactViewController;
- (void)addHandleLongPress; // new
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender; // new
@end

@interface FBVideoOverlayPluginComponentBackgroundView : UIView
- (UIViewController *)reactViewController;
- (void)addHandleLongPress; // new
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender; // new
@end

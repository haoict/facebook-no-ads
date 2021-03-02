#include <dlfcn.h>
#import <Foundation/Foundation.h>
#import <libhdev/HUtilities/HDownloadMediaWithProgress.h>

#define PLIST_PATH "/var/mobile/Library/Preferences/com.haoict.facebooknoadspref.plist"
#define PREF_CHANGED_NOTIF "com.haoict.facebooknoadspref/PrefChanged"

@interface UIView (React)
- (UIViewController *)reactViewController;
@end

@interface FBMemNewsFeedEdge : NSObject
- (id)category;
@end;

@interface FBMemFeedStory : NSObject
- (id)sponsoredData;
@end

@interface FBVideoChannelPlaylistItem : NSObject
- (BOOL)isSponsored;
@end

@interface CKDataSourceState : NSObject
@property(readonly, copy, nonatomic) NSArray *sections;
@end

@interface FBComponentCollectionViewDataSource : NSObject
- (CKDataSourceState *)dataSourceState;
- (BOOL)shouldHideSectionNumber:(int)sectionNumber;
@end

@interface FBVideoPlaybackItem : NSObject
@property(readonly, copy, nonatomic) NSURL *HDPlaybackURL;
@property(readonly, copy, nonatomic) NSURL *SDPlaybackURL;
@end

@interface FBVideoPlaybackController : NSObject
- (FBVideoPlaybackItem *)currentVideoPlaybackItem;
@end

@interface VideoContainerView : UIView
@property(readonly, nonatomic) FBVideoPlaybackController *controller;
- (void)addHandleLongPress; // new
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender; // new
@end

@interface FBVideoOverlayPluginComponentBackgroundView : UIView
- (void)addHandleLongPress; // new
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender; // new
@end

/**
 * For download story
 */
@protocol FBSnacksMediaViewProtocol
@end

@protocol FBWebImageSpecifier
@end

@interface FBWebImageNetworkSpecifier : NSObject <FBWebImageSpecifier>
@property(readonly, copy, nonatomic) NSArray *allInfoURLsSortedByDescImageFlag;
@end

@interface FBWebImageMemorySpecifier : NSObject <FBWebImageSpecifier>
@property(readonly, nonatomic) UIImage *image;
@end

@interface FBWebImageView : UIView
@property(retain, nonatomic) id <FBWebImageSpecifier> imageSpecifier;
@end

@interface FBWebPhotoView : FBWebImageView
@end

@interface FBSnacksWebPhotoView : UIView {
  FBWebPhotoView *_photoView;
}
@end

@interface FBSnacksPhotoView : UIView <FBSnacksMediaViewProtocol> {
  FBSnacksWebPhotoView *_photoView;
}
@end

@interface FBSnacksVideoManager : NSObject
- (FBVideoPlaybackItem *)currentVideoPlaybackItem;
@end

@interface FBSnacksNewVideoView : UIView <FBSnacksMediaViewProtocol>
@property(readonly, nonatomic) FBSnacksVideoManager *manager; 
@end

@interface FBSnacksMediaContainerView : UIView
@property(readonly, nonatomic) UIView<FBSnacksMediaViewProtocol> *mediaView; 
@property(nonatomic, retain) UIButton *hDownloadButton; // new property
@end

/**
 * For download private profile picture
 */
@interface FBPhotoViewController : UIViewController {
  NSUInteger _actionSheetOptions;
}
@property(readonly, nonatomic) UIImage *displayedImage;
@property(nonatomic, retain) UIButton *hDownloadButton; // new property
@end
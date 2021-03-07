ARCHS = arm64 arm64e
TARGET = iphone:clang:14.4:12.0
INSTALL_TARGET_PROCESSES = Facebook Preferences

# https://gist.github.com/haoict/96710faf0524f0ec48c13e405b124222
PREFIX = "$(THEOS)/toolchain/XcodeDefault-11.5.xctoolchain/usr/bin/"

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = facebooknoads

facebooknoads_FILES = $(wildcard *.xm *.m)
facebooknoads_EXTRA_FRAMEWORKS = libhdev
facebooknoads_CFLAGS = -fobjc-arc -std=c++11

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += pref

include $(THEOS_MAKE_PATH)/aggregate.mk

clean::
	rm -rf .theos packages
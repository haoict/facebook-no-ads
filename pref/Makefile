ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = FNAPref
FNAPref_FILES = $(wildcard *.m)
FNAPref_INSTALL_PATH = /Library/PreferenceBundles
FNAPref_PRIVATE_FRAMEWORKS = Preferences
FNAPref_EXTRA_FRAMEWORKS = libhdev
FNAPref_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/FNAPref.plist$(ECHO_END)

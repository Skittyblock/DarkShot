ARCHS = arm64 arm64e
TARGET = iphone:clang::11.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = DarkShot
DarkShot_FILES = $(wildcard *.m)
DarkShot_INSTALL_PATH = /Library/PreferenceBundles
DarkShot_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/$(BUNDLE_NAME).plist$(ECHO_END)

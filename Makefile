INSTALL_TARGET_PROCESSES = ScreenshotServicesService
ARCHS = arm64 arm64e
TARGET = iphone:clang::13.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DarkShot

DarkShot_FILES = Tweak.xm
DarkShot_CFLAGS = -fobjc-arc -Iheaders
DarkShot_LDFLAGS = ./IOKit.tbd

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += prefs
include $(THEOS_MAKE_PATH)/aggregate.mk

TARGET := iphone:clang:latest:15.0

THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = 1

1_FILES = Tweak.x
1_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
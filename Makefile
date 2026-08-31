TARGET = iphone:clang:latest:16.0
ARCHS = arm64 arm64e

THEOS_PACKAGE_SCHEME = rootless

DEBUG = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SimpleCowbell

SimpleCowbell_FILES = Tweak.x
SimpleCowbell_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
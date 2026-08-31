TARGET := iphone:clang:16.5:16.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := SimpleCowbell

SimpleCowbell_FILES := Tweak.x
SimpleCowbell_CFLAGS := -fobjc-arc
SimpleCowbell_FRAMEWORKS := UIKit QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

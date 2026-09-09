export TARGET = iphone:clang:14.5:14.0
INSTALL_TARGET_PROCESSES = IPARanger

ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
    ARCHS = arm64 arm64e
    CFLAGS += -DTHEOS_PACKAGE_SCHEME_rootless
else
    ARCHS = arm64
endif

include $(THEOS)/makefiles/common.mk
GO_EASY_ON_ME = 1
APPLICATION_NAME = IPARanger
DEBUG = 1

SOURCES = $(shell find . -name 'IPAR*.m')

IPARanger_FILES = main.m $(SOURCES)
IPARanger_FRAMEWORKS = UIKit CoreGraphics
IPARanger_CFLAGS = -fobjc-arc
IPARanger_CODESIGN_FLAGS = -Sentitlements.plist

include $(THEOS_MAKE_PATH)/application.mk

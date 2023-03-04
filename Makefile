export TARGET = iphone:clang:14.4:14.4
INSTALL_TARGET_PROCESSES = IPARanger
ARCHS = arm64 arm64e
include $(THEOS)/makefiles/common.mk
GO_EASY_ON_ME = 1
APPLICATION_NAME = IPARanger

SOURCES = $(shell find . -name 'IPAR*.m')

IPARanger_FILES = main.m $(SOURCES)
IPARanger_FRAMEWORKS = UIKit CoreGraphics
IPARanger_CFLAGS = -fobjc-arc
IPARanger_CODESIGN_FLAGS = -Sentitlements.plist

include $(THEOS_MAKE_PATH)/application.mk

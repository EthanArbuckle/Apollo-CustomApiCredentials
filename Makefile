ARCHS = arm64

TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = Apollo
THEOS_LEAN_AND_MEAN = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ApolloCustomApiCredentials

ApolloCustomApiCredentials_FILES = Tweak.m fishhook.c
ApolloCustomApiCredentials_FRAMEWORKS = UIKit WebKit
ApolloCustomApiCredentials_CFLAGS = -fobjc-arc -Wno-unguarded-availability-new

include $(THEOS_MAKE_PATH)/tweak.mk

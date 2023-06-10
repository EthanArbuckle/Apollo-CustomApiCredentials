ARCHS = arm64
# Remove # if building for rootless
#THEOS_PACKAGE_SCHEME=rootless
TARGET := iphone:clang:13.7:15.0
INSTALL_TARGET_PROCESSES = Apollo
THEOS_LEAN_AND_MEAN = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ApolloCustomApiCredentials

ApolloCustomApiCredentials_FILES = Tweak.m
ApolloCustomApiCredentials_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

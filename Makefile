ARCHS = arm64

TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = Apollo
THEOS_LEAN_AND_MEAN = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ApolloCustomApiCredentials

ApolloCustomApiCredentials_FILES = Tweak.m RedditAPICredentialViewController.m fishhook.c
ApolloCustomApiCredentials_FRAMEWORKS = UIKit WebKit
ApolloCustomApiCredentials_GENERATOR = internal

# Add client-id at compile time by defining APOLLO_REDDIT_API_CLIENT_ID
ApolloCustomApiCredentials_CFLAGS = -fobjc-arc -Wno-unguarded-availability-new -DAPOLLO_REDDIT_API_CLIENT_ID="\"\""

include $(THEOS_MAKE_PATH)/tweak.mk

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "fishhook.h"
#import "RedditAPICredentialViewController.h"

static NSString * const kImgurClientID = @"IMGUR_CLIENT_ID_GOES_HERE";
static NSString * const kImgurRapidAPIKey = @"RAPID_API_KEY_GOES_HERE";

static NSDictionary *stripGroupAccessAttr(CFDictionaryRef attributes) {
    NSMutableDictionary *newAttributes = [[NSMutableDictionary alloc] initWithDictionary:(__bridge id)attributes];
    [newAttributes removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
    return newAttributes;
}

static void *SecItemAdd_orig;
static OSStatus SecItemAdd_replacement(CFDictionaryRef query, CFTypeRef *result) {
	NSDictionary *strippedQuery = stripGroupAccessAttr(query);
	return ((OSStatus (*)(CFDictionaryRef, CFTypeRef *))SecItemAdd_orig)((__bridge CFDictionaryRef)strippedQuery, result);
}

static void *SecItemCopyMatching_orig;
static OSStatus SecItemCopyMatching_replacement(CFDictionaryRef query, CFTypeRef *result) {
    NSDictionary *strippedQuery = stripGroupAccessAttr(query);
	return ((OSStatus (*)(CFDictionaryRef, CFTypeRef *))SecItemCopyMatching_orig)((__bridge CFDictionaryRef)strippedQuery, result);
}

static void *SecItemUpdate_orig;
static OSStatus SecItemUpdate_replacement(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) {
	NSDictionary *strippedQuery = stripGroupAccessAttr(query);
	return ((OSStatus (*)(CFDictionaryRef, CFDictionaryRef))SecItemUpdate_orig)((__bridge CFDictionaryRef)strippedQuery, attributesToUpdate);
}

__attribute__ ((constructor)) static void init(void) {

	rebind_symbols((struct rebinding[3]) {
		{"SecItemAdd", SecItemAdd_replacement, (void *)&SecItemAdd_orig},
		{"SecItemCopyMatching", SecItemCopyMatching_replacement, (void *)&SecItemCopyMatching_orig},
		{"SecItemUpdate", SecItemUpdate_replacement, (void *)&SecItemUpdate_orig}
	}, 3);

	if (![[NSUserDefaults standardUserDefaults] valueForKey:@"ApolloRedditAPIClientID"]) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

			UIWindow *mainWindow = ((UIWindowScene *)UIApplication.sharedApplication.connectedScenes.anyObject).windows.firstObject;

			UIWindow *window = [[UIWindow alloc] initWithFrame:mainWindow.frame];
			[window makeKeyAndVisible];
			[mainWindow addSubview:window];

			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:[[UIViewController alloc] init]];
			[window addSubview:navController.view];

			RedditAPICredentialViewController *viewController = [[RedditAPICredentialViewController alloc] init];
			[navController presentViewController:viewController animated:YES completion:nil];
		});
	}

	// Reddit API Credentials
	Class _RDKOAuthCredential = objc_getClass("RDKOAuthCredential");
	if (_RDKOAuthCredential) {

		Method clientIdMethod = class_getInstanceMethod(_RDKOAuthCredential, sel_registerName("clientIdentifier"));
		IMP replacementImp = imp_implementationWithBlock(^NSString *(id _self) {
			return [[NSUserDefaults standardUserDefaults] valueForKey:@"ApolloRedditAPIClientID"];
		});
	
		method_setImplementation(clientIdMethod, replacementImp);
	}

	// Randomize User-Agent
	Class _RDKClient = objc_getClass("RDKClient");
	if (_RDKClient) {

		Method userAgentMethod = class_getInstanceMethod(_RDKClient, sel_registerName("userAgent"));
		IMP userAgentReplacementImp = imp_implementationWithBlock(^NSString *(id _self) {
			static dispatch_once_t once;
			static NSString *newUserAgent;
			dispatch_once(&once, ^{
				newUserAgent = [NSString stringWithFormat:@"iOS: com.%@.%@ v%d.%d.%d (by /u/%@)", RANDSTRING, RANDSTRING, RANDINT, RANDINT, RANDINT, RANDSTRING];
			});

			return newUserAgent;
		});
	
		method_setImplementation(userAgentMethod, userAgentReplacementImp);
	}

	// Imgur API credentials
	Class _NSURLSessionConfiguration = objc_getClass("NSURLSessionConfiguration");
	Method setHeadersMethod = class_getInstanceMethod(_NSURLSessionConfiguration, sel_registerName("setHTTPAdditionalHeaders:"));
	IMP originalSetHeadersImp = method_getImplementation(setHeadersMethod);
	IMP replacementSetHeadersImp = imp_implementationWithBlock(^void (id _self, NSDictionary *headers) {

		if (headers && [headers valueForKey:@"Authorization"]) {
			if ([[headers valueForKey:@"Authorization"] isEqualToString:@"Client-ID 0b596f9aaeef0f4"]) {
				NSMutableDictionary *newHeaders = [headers mutableCopy];
				newHeaders[@"Authorization"] = [NSString stringWithFormat:@"Client-ID %@", kImgurClientID];
				headers = newHeaders;
			}
		}

		if (headers && [headers valueForKey:@"X-RapidAPI-Key"]) {
			NSMutableDictionary *newHeaders = [headers mutableCopy];
			newHeaders[@"X-RapidAPI-Key"] = kImgurRapidAPIKey;
			headers = newHeaders;
		}

		((void (*)(id, SEL, id))originalSetHeadersImp)(_self, sel_registerName("setHTTPAdditionalHeaders:"), headers);
	});

	method_setImplementation(setHeadersMethod, replacementSetHeadersImp);
}

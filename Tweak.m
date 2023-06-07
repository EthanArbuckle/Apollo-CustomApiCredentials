#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSString * const kRedditClientID = @"CLIENT_ID_GOES_HERE";


__attribute__ ((constructor)) static void init(void) {
	
	Class _RDKOAuthCredential = objc_getClass("RDKOAuthCredential");
	if (_RDKOAuthCredential) {

		Method clientIdMethod = class_getInstanceMethod(_RDKOAuthCredential, sel_registerName("clientIdentifier"));
		IMP replacementImp = imp_implementationWithBlock(^NSString *(id _self) {
			return kRedditClientID;
		});
		method_setImplementation(clientIdMethod, replacementImp);
	}
}

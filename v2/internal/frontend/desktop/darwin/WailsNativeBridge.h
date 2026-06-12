//
//  WailsNativeBridge.h
//

#import <Foundation/Foundation.h>

@class WailsContext;

typedef void (^WailsContextReadyCallback)(WailsContext *context);

@interface WailsNativeBridge : NSObject

+ (instancetype)sharedBridge;

- (void)setWailsContext:(WailsContext *)context;

- (void)onContextReady:(WailsContextReadyCallback)callback;

- (void)clearWailsContext:(WailsContext *)context;

@end
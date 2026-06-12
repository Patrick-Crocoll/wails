//
//  WailsNativeBridge.m
//

#import "WailsNativeBridge.h"
#import "WailsContext.h"

@interface WailsNativeBridge ()

@property(nonatomic, assign) WailsContext *context;
@property(nonatomic, retain) NSMutableArray *contextReadyCallbacks;

@end

@implementation WailsNativeBridge

@synthesize context;
@synthesize contextReadyCallbacks;

+ (instancetype)sharedBridge {
    static WailsNativeBridge *sharedBridge = nil;
    @synchronized(self) {
        if (sharedBridge == nil) {
            sharedBridge = [[WailsNativeBridge alloc] init];
        }
    }
    return sharedBridge;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self->context = nil;
        self->contextReadyCallbacks = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)setWailsContext:(WailsContext *)context {
    NSArray *callbacksToRun = nil;
    @synchronized(self) {
        self.context = context;
        callbacksToRun = [[NSArray alloc] initWithArray:self.contextReadyCallbacks];
        [self.contextReadyCallbacks removeAllObjects];
    }
    for (WailsContextReadyCallback callback in callbacksToRun) {
        callback(context);
    }
    [callbacksToRun release];
}

- (void)onContextReady:(WailsContextReadyCallback)callback {
    if (callback == nil) {
        return;
    }
    WailsContext *readyContext = nil;
    WailsContextReadyCallback callbackToRun = nil;
    @synchronized(self) {
        if (self.context != nil) {
            readyContext = self.context;
            callbackToRun = [callback copy];
        } else {
            [self.contextReadyCallbacks addObject:[[callback copy] autorelease]];
        }
    }
    if (readyContext != nil && callbackToRun != nil) {
        callbackToRun(readyContext);
        [callbackToRun release];
    }
}

- (void)clearWailsContext:(WailsContext *)context {
    @synchronized(self) {
        if (self.context == context) {
            self.context = nil;
            [self.contextReadyCallbacks removeAllObjects];
        }
    }
}

- (void)dealloc {
    [contextReadyCallbacks release];
    [super dealloc];
}

@end
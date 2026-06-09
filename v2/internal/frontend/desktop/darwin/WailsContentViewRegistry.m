//
//  WailsContentViewRegistry.m
//

#import "WailsContentViewRegistry.h"

@implementation WailsContentViewRegistration

- (instancetype)initWithMainViewFactory:(WailsContentViewFactory)mainViewFactory
                      dialogViewFactory:(WailsContentViewFactory)dialogViewFactory {
    self = [super init];
    if (self) {
        self.mainViewFactory = mainViewFactory;
        self.dialogViewFactory = dialogViewFactory;
    }
    return self;
}

- (void)dealloc {
    self.mainViewFactory = nil;
    self.dialogViewFactory = nil;
    [super dealloc];
}

@end

@interface WailsContentViewRegistry ()

@property(nonatomic, retain) NSMutableDictionary<NSString *, WailsContentViewRegistration *> *registrations;

@end

@implementation WailsContentViewRegistry

- (instancetype)init {
    self = [super init];
    if (self) {
        self.registrations = [NSMutableDictionary dictionary];
    }
    return self;
}

- (WailsContentViewFactory)dummyContentViewFactory {
    return [[^NSView *{
        return nil;
    } copy] autorelease];
}

- (void)registerContentViewForKey:(NSString *)key
                  mainViewFactory:(WailsContentViewFactory)mainViewFactory
                dialogViewFactory:(WailsContentViewFactory)dialogViewFactory {
    if (key == nil || [key length] == 0) {
        NSLog(@"Cannot register content view without key");
        return;
    }
    if ([self.registrations objectForKey:key] != nil) {
        NSLog(@"Cannot register content view for key '%@': key is already registered", key);
        return;
    }
    WailsContentViewRegistration *registration = [[[WailsContentViewRegistration alloc] initWithMainViewFactory:mainViewFactory
                                                                                              dialogViewFactory:dialogViewFactory]
                                                                                              autorelease];
    [self.registrations setObject:registration forKey:key];
}

- (void)registerContentViewForKey:(NSString *)key
                  mainViewFactory:(WailsContentViewFactory)mainViewFactory {
    [self registerContentViewForKey:key
                    mainViewFactory:mainViewFactory
                  dialogViewFactory:[self dummyContentViewFactory]];
}

- (void)registerContentViewForKey:(NSString *)key
                dialogViewFactory:(WailsContentViewFactory)dialogViewFactory {
    [self registerContentViewForKey:key
                    mainViewFactory:[self dummyContentViewFactory]
                  dialogViewFactory:dialogViewFactory];
}

- (WailsContentViewRegistration *)registrationForKey:(NSString *)key {
    if (key == nil || [key length] == 0) {
        return nil;
    }
    return [self.registrations objectForKey:key];
}

- (void)dealloc {
    self.registrations = nil;
    [super dealloc];
}

@end
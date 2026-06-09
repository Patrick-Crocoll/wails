//
//  WailsContentViewRegistry.h
//

#import <Cocoa/Cocoa.h>

// A view factory. May return nil, if creation of the view is not supported. May return a new view everytime it is
// called, or a pre-built view (singleton)
typedef NSView * _Nullable (^WailsContentViewFactory)(void);

@interface WailsContentViewRegistration : NSObject

// the factory for creating a view for the main content view.
// return nil if the view is only allowed in dialogs
@property(nonatomic, copy) WailsContentViewFactory mainViewFactory;
// the factory for creating a view for a dialog
// return nil if the view is not allowed in dialogs (because it is only allowed in the main view)
@property(nonatomic, copy) WailsContentViewFactory dialogViewFactory;

- (instancetype)initWithMainViewFactory:(WailsContentViewFactory)mainViewFactory
                      dialogViewFactory:(WailsContentViewFactory)dialogViewFactory;

@end

@interface WailsContentViewRegistry : NSObject

- (void)registerContentViewForKey:(NSString *)key
                  mainViewFactory:(WailsContentViewFactory)mainViewFactory
                dialogViewFactory:(WailsContentViewFactory)dialogViewFactory;

    - (void)registerContentViewForKey:(NSString *)key
                      mainViewFactory:(WailsContentViewFactory)mainViewFactory;

    - (void)registerContentViewForKey:(NSString *)key
                    dialogViewFactory:(WailsContentViewFactory)dialogViewFactory;

- (WailsContentViewRegistration *)registrationForKey:(NSString *)key;

@end
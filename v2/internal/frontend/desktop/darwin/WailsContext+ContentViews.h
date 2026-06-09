//
//  WailsContext+ContentViews.h
//

#import <Cocoa/Cocoa.h>
#import "WailsContext.h"
#import "WailsContentViewRegistry.h"

// Use this key to switch back to the default webView
extern NSString *const WailsDefaultContentViewKey;

@interface WailsContext (ContentViews)

// INIT

- (void)initContentViewSystem:(NSView *)contentView
                      webView:(NSView *)webView
            withNativeSidebar:(BOOL)withNativeSidebar
            withNativeToolbar:(BOOL)withNativeToolbar;

// REGISTER NEW VIEWS

- (void)registerContentViewForKey:(NSString *)key
                  mainViewFactory:(WailsContentViewFactory)mainViewFactory
                dialogViewFactory:(WailsContentViewFactory)dialogViewFactory;

- (void)registerContentViewForKey:(NSString *)key
                  mainViewFactory:(WailsContentViewFactory)mainViewFactory;

- (void)registerContentViewForKey:(NSString *)key
                dialogViewFactory:(WailsContentViewFactory)dialogViewFactory;

// SWITCH VIEW / SHOW DIALOGS

- (BOOL)switchToDefaultView;

- (BOOL)switchToView:(NSString *)key;

- (BOOL)openDialogForView:(NSString *)key
                    title:(NSString *)title
                    width:(CGFloat)width
                   height:(CGFloat)height
                    modal:(BOOL)modal
                 closable:(BOOL)closable
              minimizable:(BOOL)minimizable
           fullscreenable:(BOOL)fullscreenable;

- (void)closeDialog;

@end
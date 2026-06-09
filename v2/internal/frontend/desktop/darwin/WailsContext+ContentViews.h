//
//  WailsContext+ContentViews.h
//

#import <Cocoa/Cocoa.h>
#import "WailsContext.h"

@interface WailsContext (ContentViews)

- (void)initContentViewSystem:(NSView *)contentView
                      webView:(NSView *)webView
            withNativeSidebar:(BOOL)withNativeSidebar
            withNativeToolbar:(BOOL)withNativeToolbar;

- (NSView *)contentHostView;

@end
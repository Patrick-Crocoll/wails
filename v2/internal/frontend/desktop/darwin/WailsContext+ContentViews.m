//
//  WailsContext+ContentViews.m
//

#import "WailsContext+ContentViews.h"
#import <objc/runtime.h>

#import "WailsToolbarView.h"
#import "WailsSidebarView.h"

static char WailsContentHostViewKey;
static const CGFloat WailsToolbarHeight = 52.0;

@implementation WailsContext (ContentViews)

- (void)initContentViewSystem:(NSView *)contentView
                      webView:(NSView *)webView
            withNativeSidebar:(BOOL)withNativeSidebar
            withNativeToolbar:(BOOL)withNativeToolbar {
    // (1) initialize the content host view (this is where we will add the main content, e.g. the wails web view)
    NSRect contentViewBounds = [contentView bounds];
    NSView *contentHostView = [[[NSView alloc] initWithFrame:contentViewBounds] autorelease];
    [contentHostView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [self setContentHostView:contentHostView];
    // (2) for now we assume that there will be no toolbar/sidebar
    NSView *mainAppView = contentHostView;
    // (3) but if there actually should be a toolbar, we now add it
    if (withNativeToolbar) {
        mainAppView = [self withToolbar:contentHostView bounds:contentViewBounds];
    }
    // (4) Now we crate the rootView, which might be just the contentHostView or the contentHostView with a toolbar
    NSView *rootView = mainAppView;
    // (5) Maybe we also need a sidebar?
    if (withNativeSidebar) {
        rootView = [self withSidebar:mainAppView bounds:contentViewBounds];
    }
    // (6) then add the rootView, which is the contentHostView with or without sidebar/toolbar to the caller
    //     (contentView)
    [rootView setFrame:contentViewBounds];
    [rootView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [contentView addSubview:rootView];
    [self installInitialWebView:webView inContentHostView:contentHostView];
}

// Sets the wails web view into the content host view
- (void)installInitialWebView:(NSView *)webView
            inContentHostView:(NSView *)contentHostView {
    [webView setFrame:[contentHostView bounds]];
    [webView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [contentHostView addSubview:webView];
}

- (NSView *)withToolbar:(NSView *)contentHostView bounds:(NSRect)bounds {
    // (1) create the toolbar
    self.toolbar = [[WailsToolbarView alloc] initWithFrame:NSMakeRect(0,
                                                                      NSHeight(bounds) - WailsToolbarHeight,
                                                                      NSWidth(bounds),
                                                                      WailsToolbarHeight)];
    [self.toolbar setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin]; // +
    // (2) make the contentHostFrame a little bit smaller and position it below the toolbar
    NSRect contentHostFrame = NSMakeRect(0,
                                         0,
                                         NSWidth(bounds),
                                         NSHeight(bounds) - WailsToolbarHeight);
    [contentHostView setFrame:contentHostFrame];
    [contentHostView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    // (3) add the toolbar
    NSView *mainAppView = [[[NSView alloc] initWithFrame:bounds] autorelease];
    [mainAppView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [mainAppView addSubview:contentHostView];
    [mainAppView addSubview:self.toolbar];
    return mainAppView;
}

- (NSView *)withSidebar:(NSView *)mainAppView bounds:(NSRect)bounds {
    WailsSidebarView *sidebar = [[[WailsSidebarView alloc] initWithFrame:NSMakeRect(0, 0, 220, NSHeight(bounds))
                                                                   model:nil] autorelease];
    WailsSidebarViewContainer *sidebarContainer = [[WailsSidebarViewContainer alloc] initWithFrame:bounds
                                                                                           sidebar:sidebar
                                                                                          mainView:mainAppView];
    self.sidebarContainer = sidebarContainer;
    [sidebarContainer release];
    [self.sidebarContainer setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    return self.sidebarContainer;
}

- (void)setContentHostView:(NSView *)contentHostView {
    objc_setAssociatedObject(self,
                             &WailsContentHostViewKey,
                             contentHostView,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSView *)contentHostView {
    return objc_getAssociatedObject(self, &WailsContentHostViewKey);
}

@end
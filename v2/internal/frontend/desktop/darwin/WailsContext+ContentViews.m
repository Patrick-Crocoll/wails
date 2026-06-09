//
//  WailsContext+ContentViews.m
//

#import "WailsContext+ContentViews.h"
#import <objc/runtime.h>

#import "WailsToolbarView.h"
#import "WailsSidebarView.h"
#import "WailsContentDialogWindow.h"

NSString * const WailsDefaultContentViewKey = @"default:wails:webview";

static char WailsContentHostViewKey;
static char WailsContentViewRegistryKey;
static char WailsDialogWindowKey;
static const CGFloat WailsToolbarHeight = 52.0;

@interface WailsContext (ContentViewsPrivate)

- (void)setContentHostView:(NSView *)contentHostView;
- (NSView *)contentHostView;

- (WailsContentViewRegistry *)contentViewRegistry;

- (NSView *)withToolbar:(NSView *)contentHostView
                 bounds:(NSRect)bounds;

- (NSView *)withSidebar:(NSView *)mainAppView
                 bounds:(NSRect)bounds;

// Helpers for dialogs:

- (WailsContentDialogWindow *)dialogWindow;
- (void)setDialogWindow:(WailsContentDialogWindow *)dialogWindow;

- (NSWindowStyleMask)dialogStyleMaskClosable:(BOOL)closable
                                 minimizable:(BOOL)minimizable
                               fullscreenable:(BOOL)fullscreenable;

- (WailsContentDialogWindow *)createDialogWindowWithWidth:(CGFloat)width
                                                   height:(CGFloat)height
                                                styleMask:(NSWindowStyleMask)styleMask;

- (void)configureDialogWindow:(WailsContentDialogWindow *)dialogWindow
                        title:(NSString *)title
                        width:(CGFloat)width
                       height:(CGFloat)height
                    styleMask:(NSWindowStyleMask)styleMask
                fullscreenable:(BOOL)fullscreenable;

- (void)installDialogView:(NSView *)view
                 inWindow:(WailsContentDialogWindow *)window;

- (void)showDialogWindow:(WailsContentDialogWindow *)dialogWindow
                   modal:(BOOL)modal;

@end

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
    // (2) Register the factory for the default webView, so we can always switch to it later
    [self registerContentViewForKey:WailsDefaultContentViewKey
                        mainViewFactory:^NSView *{
                            return webView;
                        }];
    // (3) for now we assume that there will be no toolbar/sidebar
    NSView *mainAppView = contentHostView;
    // (4) but if there actually should be a toolbar, we now add it
    if (withNativeToolbar) {
        mainAppView = [self withToolbar:contentHostView bounds:contentViewBounds];
    }
    // (5) Now we crate the rootView, which might be just the contentHostView or the contentHostView with a toolbar
    NSView *rootView = mainAppView;
    // (6) Maybe we also need a sidebar?
    if (withNativeSidebar) {
        rootView = [self withSidebar:mainAppView bounds:contentViewBounds];
    }
    // (7) then add the rootView, which is the contentHostView with or without sidebar/toolbar to the caller
    //     (contentView)
    [rootView setFrame:contentViewBounds];
    [rootView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [contentView addSubview:rootView];
    [self switchToView:WailsDefaultContentViewKey];
}

- (WailsContentViewRegistry *)contentViewRegistry {
    WailsContentViewRegistry *registry = objc_getAssociatedObject(self, &WailsContentViewRegistryKey);
    if (registry == nil) {
        registry = [[[WailsContentViewRegistry alloc] init] autorelease];
        objc_setAssociatedObject(self,
                                 &WailsContentViewRegistryKey,
                                 registry,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return registry;
}

- (void)registerContentViewForKey:(NSString *)key
                  mainViewFactory:(WailsContentViewFactory)mainViewFactory
                dialogViewFactory:(WailsContentViewFactory)dialogViewFactory {
    [[self contentViewRegistry] registerContentViewForKey:key
                                          mainViewFactory:mainViewFactory
                                        dialogViewFactory:dialogViewFactory];
}

- (void)registerContentViewForKey:(NSString *)key
                  mainViewFactory:(WailsContentViewFactory)mainViewFactory {
    [[self contentViewRegistry] registerContentViewForKey:key
                                          mainViewFactory:mainViewFactory];
}

- (void)registerContentViewForKey:(NSString *)key
                dialogViewFactory:(WailsContentViewFactory)dialogViewFactory {
    [[self contentViewRegistry] registerContentViewForKey:key
                                        dialogViewFactory:dialogViewFactory];
}

- (BOOL)switchToDefaultView {
    return [self switchToView: WailsDefaultContentViewKey];
}

- (BOOL)switchToView:(NSString *)key {
    // (1) get the factory for the view
    if (key == nil || [key length] == 0) {
        NSLog(@"Cannot switch content view without key");
        return NO;
    }
    WailsContentViewRegistration *registration = [[self contentViewRegistry] registrationForKey:key];
    if (registration == nil) {
        NSLog(@"Cannot switch to content view '%@': key is not registered", key);
        return NO;
    }
    if (registration.mainViewFactory == nil) {
        NSLog(@"Cannot switch to content view '%@': main view factory is missing", key);
        return NO;
    }
    // (2) get the view from the factory
    NSView *view = registration.mainViewFactory();
    if (view == nil) {
        NSLog(@"Cannot switch to content view '%@': main view factory returned nil", key);
        return NO;
    }
    // (3) switch the view
    NSView *contentHostView = [self contentHostView];
    if (contentHostView == nil) {
        NSLog(@"Cannot switch to content view '%@': content host view is not initialized", key);
        return NO;
    }
    // (4) first remove the old view
    [contentHostView setSubviews:@[]];
    // (5) then prepare and set the new view in contentHostView
    [view setFrame:[contentHostView bounds]];
    [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [contentHostView addSubview:view];
    return YES;
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

/***** Dialogs ******/

- (BOOL)openDialogForView:(NSString *)key
                    title:(NSString *)title
                    width:(CGFloat)width
                   height:(CGFloat)height
                    modal:(BOOL)modal
                 closable:(BOOL)closable
              minimizable:(BOOL)minimizable
            fullscreenable:(BOOL)fullscreenable {
    // (1) get the view we want to show in the dialog
    if (key == nil || [key length] == 0) {
        NSLog(@"Cannot open content view dialog without key");
        return NO;
    }
    WailsContentViewRegistration *registration = [[self contentViewRegistry] registrationForKey:key];
    if (registration == nil) {
        NSLog(@"Cannot open content view dialog for '%@': key is not registered", key);
        return NO;
    }
    if (registration.dialogViewFactory == nil) {
        NSLog(@"Cannot open content view dialog for '%@': dialog view factory is missing", key);
        return NO;
    }
    NSView *view = registration.dialogViewFactory();
    if (view == nil) {
        NSLog(@"Cannot open content view dialog for '%@': dialog view factory returned nil", key);
        return NO;
    }
    if ([view superview] != nil) {
        NSLog(@"Cannot open content view dialog for '%@': view is already attached to another superview", key);
        return NO;
    }
    // (2) create the dialog
    CGFloat dialogWidth = width > 0 ? width : 600.0;
    CGFloat dialogHeight = height > 0 ? height : 400.0;
    NSWindowStyleMask styleMask = [self dialogStyleMaskClosable:closable
                                                    minimizable:minimizable
                                                  fullscreenable:fullscreenable];
    WailsContentDialogWindow *dialogWindow = [self dialogWindow];
    if (dialogWindow == nil) {
        // If the dialog singleton was not created yet, we do it now...
        WailsContentDialogWindow *newDialogWindow = [self createDialogWindowWithWidth:dialogWidth
                                                                              height:dialogHeight
                                                                           styleMask:styleMask];
        [self setDialogWindow:newDialogWindow];
        [newDialogWindow release];
        dialogWindow = [self dialogWindow];
    }
    if ([dialogWindow isVisible]) {
        [self closeDialog];
    }
    [self configureDialogWindow:dialogWindow
                          title:title
                          width:dialogWidth
                         height:dialogHeight
                      styleMask:styleMask
                 fullscreenable:fullscreenable];
    // (3) add the view to the dialog
    [self configureDialogView:view inWindow:dialogWindow];
    if (self.mainWindow != nil) {
        [self.mainWindow addChildWindow:dialogWindow ordered:NSWindowAbove];
    }
    // (4) show the dialog
    [self showDialogWindow:dialogWindow modal:modal];
    return YES;
}

- (void)closeDialog {
    WailsContentDialogWindow *dialogWindow = [self dialogWindow];
    if (dialogWindow == nil) {
        return;
    }
    if (self.mainWindow != nil) {
        [self.mainWindow removeChildWindow:dialogWindow];
    }
    [dialogWindow close];
}

- (WailsContentDialogWindow *)dialogWindow {
    return objc_getAssociatedObject(self, &WailsDialogWindowKey);
}

- (void)setDialogWindow:(WailsContentDialogWindow *)dialogWindow {
    objc_setAssociatedObject(self,
                             &WailsDialogWindowKey,
                             dialogWindow,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSWindowStyleMask)dialogStyleMaskClosable:(BOOL)closable
                                 minimizable:(BOOL)minimizable
                               fullscreenable:(BOOL)fullscreenable {
    NSWindowStyleMask styleMask = NSWindowStyleMaskTitled;
    if (closable) {
        styleMask |= NSWindowStyleMaskClosable;
    }
    if (minimizable) {
        styleMask |= NSWindowStyleMaskMiniaturizable;
    }
    if (fullscreenable) {
        styleMask |= NSWindowStyleMaskResizable;
    }
    return styleMask;
}

- (WailsContentDialogWindow *)createDialogWindowWithWidth:(CGFloat)width
                                                   height:(CGFloat)height
                                                styleMask:(NSWindowStyleMask)styleMask {
    WailsContentDialogWindow *dialogWindow = [[WailsContentDialogWindow alloc] initWithContentRect:NSMakeRect(0, 0, width, height)
                                                                                         styleMask:styleMask
                                                                                           backing:NSBackingStoreBuffered
                                                                                             defer:NO];
    [dialogWindow setReleasedWhenClosed:NO];
    return dialogWindow;
}

- (void)configureDialogWindow:(WailsContentDialogWindow *)dialogWindow
                        title:(NSString *)title
                        width:(CGFloat)width
                       height:(CGFloat)height
                    styleMask:(NSWindowStyleMask)styleMask
                fullscreenable:(BOOL)fullscreenable {
    [dialogWindow setTitle:title ?: @""];
    [dialogWindow setStyleMask:styleMask];
    [dialogWindow setContentSize:NSMakeSize(width, height)];
    [dialogWindow center];
    if (fullscreenable) {
        [dialogWindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    } else {
        [dialogWindow setCollectionBehavior:NSWindowCollectionBehaviorDefault];
    }
}

- (void)installDialogView:(NSView *)view
                 inWindow:(WailsContentDialogWindow *)window {
    NSView *contentView = [window contentView];
    [contentView setSubviews:@[]];
    [view setFrame:[contentView bounds]];
    [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [contentView addSubview:view];
}

- (void)showDialogWindow:(WailsContentDialogWindow *)dialogWindow
                   modal:(BOOL)modal {
    [dialogWindow makeKeyAndOrderFront:nil];
    if (modal) {
        dialogWindow.runningModal = YES;
        [NSApp runModalForWindow:dialogWindow];
        dialogWindow.runningModal = NO;
    }
}

@end
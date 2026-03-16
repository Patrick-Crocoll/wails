#ifndef WailsSidebarView_h
#define WailsSidebarView_h

#import <Cocoa/Cocoa.h>

@class WailsSidebarView;

typedef void (^WailsSidebarSelectionChangedHandler)(NSString *itemLabel);
typedef void (^WailsSidebarGroupToggledHandler)(NSString *groupLabel, BOOL expanded);

@protocol WailsSidebarViewModel <NSObject>
@required
- (NSInteger)numberOfGroupsInSidebarView:(WailsSidebarView *)sidebarView;
- (NSString *)sidebarView:(WailsSidebarView *)sidebarView titleForGroupAtIndex:(NSInteger)groupIndex;
- (NSInteger)sidebarView:(WailsSidebarView *)sidebarView numberOfItemsInGroupAtIndex:(NSInteger)groupIndex;
- (NSString *)sidebarView:(WailsSidebarView *)sidebarView labelForItemAtIndex:(NSInteger)itemIndex inGroupAtIndex:(NSInteger)groupIndex;
- (NSImage *)sidebarView:(WailsSidebarView *)sidebarView iconForItemAtIndex:(NSInteger)itemIndex inGroupAtIndex:(NSInteger)groupIndex;

@optional
- (BOOL)sidebarView:(WailsSidebarView *)sidebarView isGroupInitiallyExpandedAtIndex:(NSInteger)groupIndex;
@end

@interface WailsSidebarView : NSView <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (nonatomic, assign) id<WailsSidebarViewModel> model;
@property (nonatomic, copy) WailsSidebarSelectionChangedHandler onItemSelected;
@property (nonatomic, copy) WailsSidebarGroupToggledHandler onGroupToggled;

- (instancetype)initWithFrame:(NSRect)frameRect model:(id<WailsSidebarViewModel>)model;
- (void)reloadData;

@end

#endif /* WailsSidebarView_h */
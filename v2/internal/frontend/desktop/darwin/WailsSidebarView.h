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
- (NSInteger)numberOfUngroupedItemsInSidebarView:(WailsSidebarView *)sidebarView;
- (NSString *)sidebarView:(WailsSidebarView *)sidebarView labelForUngroupedItemAtIndex:(NSInteger)itemIndex;
- (NSImage *)sidebarView:(WailsSidebarView *)sidebarView iconForUngroupedItemAtIndex:(NSInteger)itemIndex;
@end

@interface WailsSidebarView : NSView <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (nonatomic, assign) id<WailsSidebarViewModel> model;
@property (nonatomic, copy) WailsSidebarSelectionChangedHandler onItemSelected;
@property (nonatomic, copy) WailsSidebarGroupToggledHandler onGroupToggled;

- (instancetype)initWithFrame:(NSRect)frameRect model:(id<WailsSidebarViewModel>)model;
- (void)reloadData;

@end

// A concrete implementation of WailsSidebarViewModel, used to bridge the objective-c code to the go code
@interface WailsSidebarModel : NSObject <WailsSidebarViewModel>

- (void)addUngroupedItemWithLabel:(NSString *)label iconName:(NSString *)iconName;
- (void)addGroupWithTitle:(NSString *)title initiallyExpanded:(BOOL)expanded;
- (void)addItemWithLabel:(NSString *)label iconName:(NSString *)iconName; // Adds to last group

@end

#endif /* WailsSidebarView_h */
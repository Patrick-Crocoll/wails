#ifndef WailsSidebarView_h
#define WailsSidebarView_h

#import <Cocoa/Cocoa.h>

// declaration of the callbacks
typedef void (^WailsSidebarSelectionChangedHandler)(int itemId);
typedef void (^WailsSidebarGroupToggledHandler)(int groupId, int state);

// declaration of a data source
@interface WailsSidebarDataSource : NSObject <NSOutlineViewDataSource>

- (void)addUngroupedItemWithLabel:(NSString *)label iconName:(NSString *)iconName itemId:(int)itemId;
- (void)addGroupWithTitle:(NSString *)title initiallyExpanded:(BOOL)expanded groupId:(int)groupId;
// Adds to the last group
- (void)addItemWithLabel:(NSString *)label iconName:(NSString *)iconName itemId:(int)itemId;

@end

// declaration of the sidebar view
@interface WailsSidebarView : NSView <NSOutlineViewDelegate>

@property (nonatomic, retain) WailsSidebarDataSource *model;
@property (nonatomic, copy) WailsSidebarSelectionChangedHandler onItemSelected;
@property (nonatomic, copy) WailsSidebarGroupToggledHandler onGroupToggled;

- (instancetype)initWithFrame:(NSRect)frameRect model:(WailsSidebarDataSource *)model;
- (void)reloadData;

@end

#endif /* WailsSidebarView_h */
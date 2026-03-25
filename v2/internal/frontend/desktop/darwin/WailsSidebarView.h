#ifndef WailsSidebarView_h
#define WailsSidebarView_h

#import <Cocoa/Cocoa.h>

// declaration of the callbacks
typedef void (^WailsSidebarSelectionChangedHandler)(NSString *itemLabel);
typedef void (^WailsSidebarGroupToggledHandler)(NSString *groupLabel, BOOL expanded);

// declaration of a data source
@interface WailsSidebarDataSource : NSObject <NSOutlineViewDataSource>

- (void)addUngroupedItemWithLabel:(NSString *)label iconName:(NSString *)iconName;
- (void)addGroupWithTitle:(NSString *)title initiallyExpanded:(BOOL)expanded;
// Adds to the last group
- (void)addItemWithLabel:(NSString *)label iconName:(NSString *)iconName;

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
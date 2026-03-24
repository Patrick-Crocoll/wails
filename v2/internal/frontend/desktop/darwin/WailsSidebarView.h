#ifndef WailsSidebarView_h
#define WailsSidebarView_h

#import <Cocoa/Cocoa.h>

// declaration of the callbacks
typedef void (^WailsSidebarSelectionChangedHandler)(NSString *itemLabel);
typedef void (^WailsSidebarGroupToggledHandler)(NSString *groupLabel, BOOL expanded);

// A sidebar node can be either a group or an item
@interface WailsSidebarNode : NSObject
@property (nonatomic, retain) NSString *title;
@end

// A sidebar group contains items and can be expanded or collapsed
@interface WailsSidebarGroupNode : WailsSidebarNode
@property (nonatomic, assign) BOOL isExpanded;
@property (nonatomic, retain) NSMutableArray *children;
@end

// A sidebar item is a leaf node
@interface WailsSidebarItemNode : WailsSidebarNode
@property (nonatomic, retain) NSImage *icon;
@end

// protocol of the sidebar model.
@protocol WailsSidebarViewModel <NSObject>

// groups
- (NSInteger)numberOfGroups;
- (WailsSidebarGroupNode *)groupAt:(NSInteger)groupIndex;

// items
- (NSInteger)numberOfUngroupedItems;
- (WailsSidebarItemNode *)ungroupedItemAt:(NSInteger)itemIndex;

@end

// FIXME: Rename to WailsSidebarDefaultModel
// declaration of a concrete implementation of WailsSidebarViewModel, used to bridge the objective-c code to the go code
@interface WailsSidebarModel : NSObject <WailsSidebarViewModel>

- (void)addUngroupedItemWithLabel:(NSString *)label iconName:(NSString *)iconName;
- (void)addGroupWithTitle:(NSString *)title initiallyExpanded:(BOOL)expanded;
// Adds to the last group
- (void)addItemWithLabel:(NSString *)label iconName:(NSString *)iconName;

@end

// declaration of the sidebar view
@interface WailsSidebarView : NSView <NSOutlineViewDelegate>

@property (nonatomic, assign) id<WailsSidebarViewModel> model;
@property (nonatomic, copy) WailsSidebarSelectionChangedHandler onItemSelected;
@property (nonatomic, copy) WailsSidebarGroupToggledHandler onGroupToggled;

- (instancetype)initWithFrame:(NSRect)frameRect model:(id<WailsSidebarViewModel>)model;
- (void)reloadData;

@end

#endif /* WailsSidebarView_h */
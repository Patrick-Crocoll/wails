#ifndef WailsSidebarView_h
#define WailsSidebarView_h

#import <Cocoa/Cocoa.h>

// declaration of the callbacks
typedef void (^WailsSidebarSelectionChangedHandler)(NSString *itemLabel);
typedef void (^WailsSidebarGroupToggledHandler)(NSString *groupLabel, BOOL expanded);

// protocol of the sidebar model.
@protocol WailsSidebarViewModel <NSObject>
@required
- (NSInteger)numberOfGroups;
- (NSString *)titleForGroupAtIndex:(NSInteger)groupIndex;
- (NSInteger)numberOfItemsInGroupAtIndex:(NSInteger)groupIndex;
- (NSString *)labelForItemAtIndex:(NSInteger)itemIndex inGroupAtIndex:(NSInteger)groupIndex;
- (NSImage *)iconForItemAtIndex:(NSInteger)itemIndex inGroupAtIndex:(NSInteger)groupIndex;

@optional
- (BOOL)isGroupInitiallyExpandedAtIndex:(NSInteger)groupIndex;
- (NSInteger)numberOfUngroupedItems;
- (NSString *)labelForUngroupedItemAtIndex:(NSInteger)itemIndex;
- (NSImage *)iconForUngroupedItemAtIndex:(NSInteger)itemIndex;
@end

// declaration of the sidebar view
@interface WailsSidebarView : NSView <NSOutlineViewDelegate>

@property (nonatomic, assign) id<WailsSidebarViewModel> model;
@property (nonatomic, copy) WailsSidebarSelectionChangedHandler onItemSelected;
@property (nonatomic, copy) WailsSidebarGroupToggledHandler onGroupToggled;

- (instancetype)initWithFrame:(NSRect)frameRect model:(id<WailsSidebarViewModel>)model;
- (void)reloadData;

@end

// declaration of a concrete implementation of WailsSidebarViewModel, used to bridge the objective-c code to the go code
@interface WailsSidebarModel : NSObject <WailsSidebarViewModel>

- (void)addUngroupedItemWithLabel:(NSString *)label iconName:(NSString *)iconName;
- (void)addGroupWithTitle:(NSString *)title initiallyExpanded:(BOOL)expanded;
- (void)addItemWithLabel:(NSString *)label iconName:(NSString *)iconName; // Adds to last group

@end

#endif /* WailsSidebarView_h */
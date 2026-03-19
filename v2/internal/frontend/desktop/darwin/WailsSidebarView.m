#import "WailsSidebarView.h"

// private class WailsSidebarNode: can be a group OR an item
@interface WailsSidebarNode : NSObject

@property (nonatomic, assign) BOOL isGroup;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSImage *icon;
@property (nonatomic, retain) NSMutableArray *children;

@end

@implementation WailsSidebarNode

@synthesize isGroup;
@synthesize title;
@synthesize icon;
@synthesize children;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self->isGroup = NO;
        self->title = nil;
        self->icon = nil;
        self->children = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [title release];
    [icon release];
    [children release];
    [super dealloc];
}

@end

// implementation for WailsSidebarModel. Used to bridge to go code
@interface WailsSidebarModel ()

@property (nonatomic, retain) NSMutableArray *ungroupedItems;
@property (nonatomic, retain) NSMutableArray *groups;

@end

@implementation WailsSidebarModel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.ungroupedItems = [[NSMutableArray alloc] init];
        self.groups = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self.ungroupedItems release];
    [self.groups release];
    [super dealloc];
}

- (void)addUngroupedItemWithLabel:(NSString *)label iconName:(NSString *)iconName {
    NSMutableDictionary *item = [NSMutableDictionary dictionary];
    if (label) [item setObject:label forKey:@"label"];
    if (iconName) [item setObject:iconName forKey:@"icon"];
    [self.ungroupedItems addObject:item];
}

- (void)addGroupWithTitle:(NSString *)title initiallyExpanded:(BOOL)expanded {
    NSMutableArray *items = [[NSMutableArray alloc] init];
    NSMutableDictionary *group = [NSMutableDictionary dictionary];
    if (title) [group setObject:title forKey:@"title"];
    [group setObject:@(expanded) forKey:@"expanded"];
    [group setObject:items forKey:@"items"];
    [self.groups addObject:group];
    [items release];
}

- (void)addItemWithLabel:(NSString *)label iconName:(NSString *)iconName {
    NSMutableDictionary *lastGroup = [self.groups lastObject];
    if (!lastGroup) return;
    NSMutableArray *items = [lastGroup objectForKey:@"items"];
    NSMutableDictionary *item = [NSMutableDictionary dictionary];
    if (label) [item setObject:label forKey:@"label"];
    if (iconName) [item setObject:iconName forKey:@"icon"];
    [items addObject:item];
}

- (NSInteger)numberOfUngroupedItems {
    return [self.ungroupedItems count];
}

- (NSString *)labelForUngroupedItemAtIndex:(NSInteger)itemIndex {
    return [[self.ungroupedItems objectAtIndex:itemIndex] objectForKey:@"label"];
}

- (NSImage *)iconForUngroupedItemAtIndex:(NSInteger)itemIndex {
    NSString *iconName = [[self.ungroupedItems objectAtIndex:itemIndex] objectForKey:@"icon"];
    return iconName ? [NSImage imageNamed:iconName] : nil;
}

- (NSInteger)numberOfGroups {
    return [self.groups count];
}

- (NSString *)titleForGroupAtIndex:(NSInteger)groupIndex {
    return [[self.groups objectAtIndex:groupIndex] objectForKey:@"title"];
}

- (NSInteger)numberOfItemsInGroupAtIndex:(NSInteger)groupIndex {
    return [[[self.groups objectAtIndex:groupIndex] objectForKey:@"items"] count];
}

- (NSString *)labelForItemAtIndex:(NSInteger)itemIndex inGroupAtIndex:(NSInteger)groupIndex {
    NSArray *items = [[self.groups objectAtIndex:groupIndex] objectForKey:@"items"];
    return [[items objectAtIndex:itemIndex] objectForKey:@"label"];
}

- (NSImage *)iconForItemAtIndex:(NSInteger)itemIndex inGroupAtIndex:(NSInteger)groupIndex {
    NSArray *items = [[self.groups objectAtIndex:groupIndex] objectForKey:@"items"];
    NSString *iconName = [[items objectAtIndex:itemIndex] objectForKey:@"icon"];
    return iconName ? [NSImage imageNamed:iconName] : nil;
}

- (BOOL)isGroupInitiallyExpandedAtIndex:(NSInteger)groupIndex {
    return [[[self.groups objectAtIndex:groupIndex] objectForKey:@"expanded"] boolValue];
}

@end

// WailsSidebarDataSource is a basic implementation of NSOutlineViewDataSource,
// using WailsSidebarViewModel as the source and creating WailsSidebarNode objects.
@interface WailsSidebarDataSource : NSObject <NSOutlineViewDataSource>

@property (nonatomic, assign) id<WailsSidebarViewModel> model;
@property (nonatomic, retain) NSMutableArray *rootNodes;

- (void)reloadData;
- (NSInteger)groupIndexForRootNode:(WailsSidebarNode *)rootNode;

@end

@implementation WailsSidebarDataSource

@synthesize model;
@synthesize rootNodes;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self->model = nil;
        self->rootNodes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [rootNodes release];
    [super dealloc];
}

- (WailsSidebarNode *)buildNodeWithTitle:(NSString *)title icon:(NSImage *)icon isGroup:(BOOL)isGroup
{
    WailsSidebarNode *node = [[WailsSidebarNode alloc] init];
    node.isGroup = isGroup;
    node.title = title;
    node.icon = icon;
    return node;
}

- (void)appendNodeToParent:(NSMutableArray *)parent node:(WailsSidebarNode *)node
{
    [parent addObject:node];
    [node release];
}

// We use a custom setter for the model because we want to call reloadData when the model changes.
- (void)setModel:(id<WailsSidebarViewModel>)newModel
{
    if (model != newModel) {
        model = newModel;
        [self reloadData];
    }
}

- (void)reloadData
{
    [self.rootNodes removeAllObjects];

    id<WailsSidebarViewModel> activeModel = self.model;
    if (activeModel == nil) {
        return;
    }

    NSInteger ungroupedCount = 0;
    if ([activeModel respondsToSelector:@selector(numberOfUngroupedItems)]) {
        ungroupedCount = [activeModel numberOfUngroupedItems];
    }

    for (NSInteger i = 0; i < ungroupedCount; i++) {
        WailsSidebarNode *node = [self
                                  buildNodeWithTitle:[activeModel labelForUngroupedItemAtIndex:i]
                                                icon:[activeModel iconForUngroupedItemAtIndex:i]
                                             isGroup:NO];
        [self appendNodeToParent:self.rootNodes node:node];
    }

    NSInteger groupCount = [activeModel numberOfGroups];
    for (NSInteger groupIndex = 0; groupIndex < groupCount; groupIndex++) {
        WailsSidebarNode *groupNode = [self
                                       buildNodeWithTitle:[activeModel titleForGroupAtIndex:groupIndex]
                                                     icon:nil
                                                  isGroup:YES];
        NSInteger itemCount = [activeModel numberOfItemsInGroupAtIndex:groupIndex];
        for (NSInteger itemIndex = 0; itemIndex < itemCount; itemIndex++) {
            WailsSidebarNode *itemNode = [self
                                          buildNodeWithTitle:[activeModel labelForItemAtIndex:itemIndex inGroupAtIndex:groupIndex]
                                                        icon:[activeModel iconForItemAtIndex:itemIndex inGroupAtIndex:groupIndex]
                                                     isGroup:NO];
            [self appendNodeToParent:groupNode.children node:itemNode];
        }

        [self appendNodeToParent:self.rootNodes node:groupNode];
    }
}

- (NSInteger)groupIndexForRootNode:(WailsSidebarNode *)rootNode
{
    NSInteger currentGroupIndex = 0;
    for (WailsSidebarNode *node in self.rootNodes) {
        if (!node.isGroup) {
            continue;
        }
        if (node == rootNode) {
            return currentGroupIndex;
        }
        currentGroupIndex++;
    }
    return NSNotFound;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil) {
        return [self.rootNodes count];
    }
    WailsSidebarNode *node = (WailsSidebarNode *)item;
    return [node.children count];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil) {
        return [self.rootNodes objectAtIndex:index];
    }
    WailsSidebarNode *node = (WailsSidebarNode *)item;
    return [node.children objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    WailsSidebarNode *node = (WailsSidebarNode *)item;
    return node.isGroup && [node.children count] > 0;
}

@end

// the private properties of WailsSidebarView
@interface WailsSidebarView ()

@property (nonatomic, retain) NSScrollView *scrollView;
@property (nonatomic, retain) NSOutlineView *outlineView;
@property (nonatomic, retain) WailsSidebarDataSource *dataSource;

@end

@implementation WailsSidebarView

// public properties
@synthesize model; // FIXME: Why keep this ???
@synthesize onItemSelected;
@synthesize onGroupToggled;
// private properties
@synthesize scrollView;
@synthesize outlineView;
@synthesize dataSource;

- (instancetype)initWithFrame:(NSRect)frameRect
{
    return [self initWithFrame:frameRect model:nil];
}

- (instancetype)initWithFrame:(NSRect)frameRect model:(id<WailsSidebarViewModel>)sidebarModel
{
    self = [super initWithFrame:frameRect];
    if (self) {
        self.model = sidebarModel;
        self->onItemSelected = nil;
        self->onGroupToggled = nil;
        self->dataSource = [[WailsSidebarDataSource alloc] init];

        [self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [self setWantsLayer:YES];
        [self.layer setBackgroundColor:[[NSColor windowBackgroundColor] CGColor]];

        NSScrollView *createdScrollView = [[NSScrollView alloc] initWithFrame:[self bounds]];
        [createdScrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [createdScrollView setBorderType:NSNoBorder];
        [createdScrollView setHasVerticalScroller:YES];
        [createdScrollView setHasHorizontalScroller:NO];
        [createdScrollView setDrawsBackground:NO];
        self.scrollView = createdScrollView;
        [createdScrollView release];

        NSOutlineView *createdOutlineView = [[NSOutlineView alloc] initWithFrame:[self bounds]];
        [createdOutlineView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [createdOutlineView setHeaderView:nil];
        [createdOutlineView setRowSizeStyle:NSTableViewRowSizeStyleDefault];
        [createdOutlineView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
        [createdOutlineView setFocusRingType:NSFocusRingTypeNone];
        [createdOutlineView setIndentationPerLevel:12.0];
        [createdOutlineView setGridStyleMask:NSTableViewGridNone];
        [createdOutlineView setIntercellSpacing:NSMakeSize(0.0, 0.0)];
        [createdOutlineView setFloatsGroupRows:NO];
        [createdOutlineView setDataSource:self.dataSource];
        [createdOutlineView setDelegate:self];

        NSTableColumn *column = [[[NSTableColumn alloc] initWithIdentifier:@"SidebarColumn"] autorelease];
        [column setWidth:[self bounds].size.width];
        [createdOutlineView addTableColumn:column];
        [createdOutlineView setOutlineTableColumn:column];

        self.outlineView = createdOutlineView;
        [createdOutlineView release];

        [self.scrollView setDocumentView:self.outlineView];
        [self addSubview:self.scrollView];

        [self reloadData];
    }
    return self;
}

- (void)dealloc
{
    [onItemSelected release];
    [onGroupToggled release];
    [scrollView release];
    [outlineView release];
    [dataSource release];
    [super dealloc];
}

- (void)setModel:(id<WailsSidebarViewModel>)newModel
{
    model = newModel;
    self.dataSource.model = newModel;
    [self reloadData];
}

- (void)setOnItemSelected:(WailsSidebarSelectionChangedHandler)newHandler
{
    if (onItemSelected != newHandler) {
        [onItemSelected release];
        onItemSelected = [newHandler copy];
    }
}

- (void)setOnGroupToggled:(WailsSidebarGroupToggledHandler)newHandler
{
    if (onGroupToggled != newHandler) {
        [onGroupToggled release];
        onGroupToggled = [newHandler copy];
    }
}

- (void)reloadData
{
    [self.outlineView reloadData];

    id<WailsSidebarViewModel> activeModel = self.model;
    if (activeModel == nil) {
        return;
    }

    NSInteger currentGroupIndex = 0;
    for (WailsSidebarNode *rootNode in self.dataSource.rootNodes) {
        if (!rootNode.isGroup) {
            continue;
        }

        BOOL shouldExpand = YES;
        if ([activeModel respondsToSelector:@selector(isGroupInitiallyExpandedAtIndex:)]) {
            shouldExpand = [activeModel isGroupInitiallyExpandedAtIndex:currentGroupIndex];
        }

        if (shouldExpand) {
            [self.outlineView expandItem:rootNode];
        } else {
            [self.outlineView collapseItem:rootNode];
        }

        currentGroupIndex++;
    }
}

#pragma mark - NSOutlineViewDelegate

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
    WailsSidebarNode *node = (WailsSidebarNode *)item;
    return node.isGroup;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    WailsSidebarNode *node = (WailsSidebarNode *)item;
    return !node.isGroup;
}

- (NSView *)outlineView:(NSOutlineView *)sidebarOutlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    WailsSidebarNode *node = (WailsSidebarNode *)item;

    if (node.isGroup) {
        NSTableCellView *groupCell = [[[NSTableCellView alloc] initWithFrame:NSMakeRect(0, 0, tableColumn.width, 20)] autorelease];

        NSTextField *textField = [[[NSTextField alloc] initWithFrame:NSMakeRect(8, 1, tableColumn.width - 16, 16)] autorelease];
        [textField setBezeled:NO];
        [textField setBordered:NO];
        [textField setDrawsBackground:NO];
        [textField setEditable:NO];
        [textField setSelectable:NO];
        [textField setStringValue:node.title != nil ? node.title : @""];
        [textField setTextColor:[NSColor secondaryLabelColor]];
        [textField setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize] weight:NSFontWeightSemibold]];

        [groupCell setTextField:textField];
        [groupCell addSubview:textField];
        return groupCell;
    }

    NSTableCellView *itemCell = [[[NSTableCellView alloc] initWithFrame:NSMakeRect(0, 0, tableColumn.width, 28)] autorelease];

    NSImageView *imageView = [[[NSImageView alloc] initWithFrame:NSMakeRect(6, 4, 16, 16)] autorelease];
    [imageView setImage:node.icon];
    [imageView setImageScaling:NSImageScaleProportionallyDown];

    NSTextField *textField = [[[NSTextField alloc] initWithFrame:NSMakeRect(28, 3, tableColumn.width - 34, 18)] autorelease];
    [textField setBezeled:NO];
    [textField setBordered:NO];
    [textField setDrawsBackground:NO];
    [textField setEditable:NO];
    [textField setSelectable:NO];
    [textField setStringValue:node.title != nil ? node.title : @""];
    [textField setFont:[NSFont systemFontOfSize:13.0]];
    [textField setTextColor:[NSColor labelColor]];

    [itemCell setImageView:imageView];
    [itemCell setTextField:textField];
    [itemCell addSubview:imageView];
    [itemCell addSubview:textField];

    return itemCell;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    WailsSidebarNode *node = (WailsSidebarNode *)item;
    return node.isGroup ? 20.0 : 28.0;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger selectedRow = [self.outlineView selectedRow];
    if (selectedRow < 0) {
        return;
    }

    id item = [self.outlineView itemAtRow:selectedRow];
    if (item == nil) {
        return;
    }

    WailsSidebarNode *node = (WailsSidebarNode *)item;
    if (node.isGroup) {
        return;
    }

    if (self.onItemSelected != nil) {
        self.onItemSelected(node.title);
    }
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
    id item = [[notification userInfo] objectForKey:@"NSObject"];
    if (item == nil) {
        return;
    }

    WailsSidebarNode *node = (WailsSidebarNode *)item;
    if (!node.isGroup) {
        return;
    }

    if (self.onGroupToggled != nil) {
        self.onGroupToggled(node.title, YES);
    }
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
    id item = [[notification userInfo] objectForKey:@"NSObject"];
    if (item == nil) {
        return;
    }

    WailsSidebarNode *node = (WailsSidebarNode *)item;
    if (!node.isGroup) {
        return;
    }

    if (self.onGroupToggled != nil) {
        self.onGroupToggled(node.title, NO);
    }
}

@end
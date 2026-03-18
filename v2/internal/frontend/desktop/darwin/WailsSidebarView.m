#import "WailsSidebarView.h"

@interface _WailsSidebarNode : NSObject
@property (nonatomic, assign) BOOL isGroup;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSImage *icon;
@property (nonatomic, retain) NSMutableArray *children;
@end

@implementation _WailsSidebarNode
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

// FIXME: EXAMPLE START: DELETE THIS!!!

@interface _WailsSidebarExampleModel : NSObject <WailsSidebarViewModel>
@end

@implementation _WailsSidebarExampleModel

- (NSInteger)numberOfGroupsInSidebarView:(WailsSidebarView *)sidebarView
{
    return 3;
}

- (NSString *)sidebarView:(WailsSidebarView *)sidebarView titleForGroupAtIndex:(NSInteger)groupIndex
{
    switch (groupIndex) {
        case 0: return @"Favorites";
        case 1: return @"Locations";
        case 2: return @"Tags";
        default: return @"";
    }
}

- (NSInteger)sidebarView:(WailsSidebarView *)sidebarView numberOfItemsInGroupAtIndex:(NSInteger)groupIndex
{
    switch (groupIndex) {
        case 0: return 3;
        case 1: return 2;
        case 2: return 3;
        default: return 0;
    }
}

- (NSString *)sidebarView:(WailsSidebarView *)sidebarView labelForItemAtIndex:(NSInteger)itemIndex inGroupAtIndex:(NSInteger)groupIndex
{
    switch (groupIndex) {
        case 0:
            switch (itemIndex) {
                case 0: return @"Recents";
                case 1: return @"Desktop";
                case 2: return @"Downloads";
            }
            break;
        case 1:
            switch (itemIndex) {
                case 0: return @"Applications";
                case 1: return @"Documents";
            }
            break;
        case 2:
            switch (itemIndex) {
                case 0: return @"Red";
                case 1: return @"Green";
                case 2: return @"Blue";
            }
            break;
    }
    return @"";
}

- (NSImage *)sidebarView:(WailsSidebarView *)sidebarView iconForItemAtIndex:(NSInteger)itemIndex inGroupAtIndex:(NSInteger)groupIndex
{
    if (groupIndex == 0) {
        switch (itemIndex) {
            case 0: return [NSImage imageNamed:NSImageNameMultipleDocuments];
            case 1: return [NSImage imageNamed:NSImageNameHomeTemplate];
            case 2: return [NSImage imageNamed:NSImageNameFolder];
        }
    }

    if (groupIndex == 1) {
        switch (itemIndex) {
            case 0: return [NSImage imageNamed:NSImageNameApplicationIcon];
            case 1: return [NSImage imageNamed:NSImageNameFolder];
        }
    }

    if (groupIndex == 2) {
        switch (itemIndex) {
            case 0: return [NSImage imageNamed:NSImageNameStatusUnavailable];
            case 1: return [NSImage imageNamed:NSImageNameStatusAvailable];
            case 2: return [NSImage imageNamed:NSImageNameStatusPartiallyAvailable];
        }
    }

    return [NSImage imageNamed:NSImageNameFolder];
}

- (BOOL)sidebarView:(WailsSidebarView *)sidebarView isGroupInitiallyExpandedAtIndex:(NSInteger)groupIndex
{
    return YES;
}

@end

// FIXME: EXAMPLE END

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

- (NSInteger)numberOfUngroupedItemsInSidebarView:(WailsSidebarView *)sidebarView {
    return [self.ungroupedItems count];
}

- (NSString *)sidebarView:(WailsSidebarView *)sidebarView labelForUngroupedItemAtIndex:(NSInteger)itemIndex {
    return [[self.ungroupedItems objectAtIndex:itemIndex] objectForKey:@"label"];
}

- (NSImage *)sidebarView:(WailsSidebarView *)sidebarView iconForUngroupedItemAtIndex:(NSInteger)itemIndex {
    NSString *iconName = [[self.ungroupedItems objectAtIndex:itemIndex] objectForKey:@"icon"];
    return iconName ? [NSImage imageNamed:iconName] : nil;
}

- (NSInteger)numberOfGroupsInSidebarView:(WailsSidebarView *)sidebarView {
    return [self.groups count];
}

- (NSString *)sidebarView:(WailsSidebarView *)sidebarView titleForGroupAtIndex:(NSInteger)groupIndex {
    return [[self.groups objectAtIndex:groupIndex] objectForKey:@"title"];
}

- (NSInteger)sidebarView:(WailsSidebarView *)sidebarView numberOfItemsInGroupAtIndex:(NSInteger)groupIndex {
    return [[[self.groups objectAtIndex:groupIndex] objectForKey:@"items"] count];
}

- (NSString *)sidebarView:(WailsSidebarView *)sidebarView labelForItemAtIndex:(NSInteger)itemIndex inGroupAtIndex:(NSInteger)groupIndex {
    NSArray *items = [[self.groups objectAtIndex:groupIndex] objectForKey:@"items"];
    return [[items objectAtIndex:itemIndex] objectForKey:@"label"];
}

- (NSImage *)sidebarView:(WailsSidebarView *)sidebarView iconForItemAtIndex:(NSInteger)itemIndex inGroupAtIndex:(NSInteger)groupIndex {
    NSArray *items = [[self.groups objectAtIndex:groupIndex] objectForKey:@"items"];
    NSString *iconName = [[items objectAtIndex:itemIndex] objectForKey:@"icon"];
    return iconName ? [NSImage imageNamed:iconName] : nil;
}

- (BOOL)sidebarView:(WailsSidebarView *)sidebarView isGroupInitiallyExpandedAtIndex:(NSInteger)groupIndex {
    return [[[self.groups objectAtIndex:groupIndex] objectForKey:@"expanded"] boolValue];
}

@end

@interface WailsSidebarView ()
@property (nonatomic, retain) NSScrollView *scrollView;
@property (nonatomic, retain) NSOutlineView *outlineView;
@property (nonatomic, retain) NSMutableArray *rootNodes;
@property (nonatomic, retain) id<WailsSidebarViewModel> fallbackModel;
@end

@implementation WailsSidebarView

@synthesize model;
@synthesize onItemSelected;
@synthesize onGroupToggled;
@synthesize scrollView;
@synthesize outlineView;
@synthesize rootNodes;
@synthesize fallbackModel;

- (instancetype)initWithFrame:(NSRect)frameRect
{
    return [self initWithFrame:frameRect model:nil];
}

- (instancetype)initWithFrame:(NSRect)frameRect model:(id<WailsSidebarViewModel>)sidebarModel
{
    self = [super initWithFrame:frameRect];
    if (self) {
        self->model = nil;
        self->onItemSelected = nil;
        self->onGroupToggled = nil;
        self->scrollView = nil;
        self->outlineView = nil;
        self->rootNodes = [[NSMutableArray alloc] init];
        self->fallbackModel = nil;

        if (sidebarModel != nil) {
            self.model = sidebarModel;
        } else {
            self.fallbackModel = [[_WailsSidebarExampleModel alloc] init];
            self.model = self.fallbackModel;
        }

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
        [createdOutlineView setDataSource:self];
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
    [rootNodes release];
    [fallbackModel release];
    [super dealloc];
}

- (void)setModel:(id<WailsSidebarViewModel>)newModel
{
    model = newModel;
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
    [self.rootNodes removeAllObjects];

    id<WailsSidebarViewModel> activeModel = self.model;
    if (activeModel == nil) {
        return;
    }

    // Compute ungroupedCount safely
    NSInteger ungroupedCount = 0;
    if ([activeModel respondsToSelector:@selector(numberOfUngroupedItemsInSidebarView:)]) {
        ungroupedCount = [activeModel numberOfUngroupedItemsInSidebarView:self];
    }

    // New code to add ungrouped items as top-level nodes
    for (NSInteger i = 0; i < ungroupedCount; i++) {
        _WailsSidebarNode *node = [[_WailsSidebarNode alloc] init];
        node.isGroup = NO;
        node.title = [activeModel sidebarView:self labelForUngroupedItemAtIndex:i];
        node.icon = [activeModel sidebarView:self iconForUngroupedItemAtIndex:i];
        [self.rootNodes addObject:node];
        [node release];
    }

    NSInteger groupCount = [activeModel numberOfGroupsInSidebarView:self];
    for (NSInteger groupIndex = 0; groupIndex < groupCount; groupIndex++) {
        _WailsSidebarNode *groupNode = [[_WailsSidebarNode alloc] init];
        groupNode.isGroup = YES;
        groupNode.title = [activeModel sidebarView:self titleForGroupAtIndex:groupIndex];

        NSInteger itemCount = [activeModel sidebarView:self numberOfItemsInGroupAtIndex:groupIndex];
        for (NSInteger itemIndex = 0; itemIndex < itemCount; itemIndex++) {
            _WailsSidebarNode *itemNode = [[_WailsSidebarNode alloc] init];
            itemNode.isGroup = NO;
            itemNode.title = [activeModel sidebarView:self labelForItemAtIndex:itemIndex inGroupAtIndex:groupIndex];
            itemNode.icon = [activeModel sidebarView:self iconForItemAtIndex:itemIndex inGroupAtIndex:groupIndex];
            [groupNode.children addObject:itemNode];
            [itemNode release];
        }

        [self.rootNodes addObject:groupNode];
        [groupNode release];
    }

    [self.outlineView reloadData];

    // Expand groups (skip ungrouped since they are not groups)
    NSInteger rootIndex = 0;
    NSInteger currentGroupIndex = 0;
    for (_WailsSidebarNode *rootNode in self.rootNodes) {
        if (!rootNode.isGroup) {
            rootIndex++;
            continue;
        }
        BOOL shouldExpand = YES;
        if ([activeModel respondsToSelector:@selector(sidebarView:isGroupInitiallyExpandedAtIndex:)]) {
            shouldExpand = [activeModel sidebarView:self isGroupInitiallyExpandedAtIndex:currentGroupIndex];
        }
        if (shouldExpand) {
            [self.outlineView expandItem:rootNode];
        } else {
            [self.outlineView collapseItem:rootNode];
        }
        rootIndex++;
        currentGroupIndex++;
    }
}

#pragma mark - NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil) {
        return [self.rootNodes count];
    }

    _WailsSidebarNode *node = (_WailsSidebarNode *)item;
    return [node.children count];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil) {
        return [self.rootNodes objectAtIndex:index];
    }

    _WailsSidebarNode *node = (_WailsSidebarNode *)item;
    return [node.children objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    _WailsSidebarNode *node = (_WailsSidebarNode *)item;
    return node.isGroup && [node.children count] > 0;
}

#pragma mark - NSOutlineViewDelegate

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
    _WailsSidebarNode *node = (_WailsSidebarNode *)item;
    return node.isGroup;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    _WailsSidebarNode *node = (_WailsSidebarNode *)item;
    return !node.isGroup;
}

- (NSView *)outlineView:(NSOutlineView *)sidebarOutlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    _WailsSidebarNode *node = (_WailsSidebarNode *)item;

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
    _WailsSidebarNode *node = (_WailsSidebarNode *)item;
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

    _WailsSidebarNode *node = (_WailsSidebarNode *)item;
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

    _WailsSidebarNode *node = (_WailsSidebarNode *)item;
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

    _WailsSidebarNode *node = (_WailsSidebarNode *)item;
    if (!node.isGroup) {
        return;
    }

    if (self.onGroupToggled != nil) {
        self.onGroupToggled(node.title, NO);
    }
}

@end
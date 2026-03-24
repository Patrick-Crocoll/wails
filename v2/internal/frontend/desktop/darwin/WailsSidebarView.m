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

- (NSImage *)systemSymbolImageNamed:(NSString *)symbolName
{
    Class imageClass = [NSImage class];
    SEL selector = NSSelectorFromString(@"imageWithSystemSymbolName:accessibilityDescription:");
    if ([imageClass respondsToSelector:selector]) {
        printf("=====> systemSymbolImageNamed (2) : %s\n", [symbolName UTF8String]);
        typedef NSImage *(*SymbolImageFunc)(id, SEL, NSString *, NSString *);
        SymbolImageFunc func = (SymbolImageFunc)[imageClass methodForSelector:selector];
        NSImage *image = func(imageClass, selector, symbolName, nil);
        [image setTemplate:YES];
        return image;
    }
    printf("=====> systemSymbolImageNamed (3) : %s\n", [symbolName UTF8String]);
    return [NSImage imageNamed:symbolName];
}

// FIXME: This is now a duplicate. Search for this in the View and remove it from there. But check the other version first, it might be better than this one!!!
- (NSImage *)imageForIconName:(NSString *)iconName
{
    if (iconName == nil || [iconName length] == 0) {
        return nil;
    }

    if ([iconName hasPrefix:@"System:"]) {
        NSString *symbolName = [[iconName substringFromIndex:[@"System:" length]]
                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        printf("=====> System icon: %s\n", [symbolName UTF8String]);

        if ([symbolName length] == 0) {
            return nil;
        }

        return [self systemSymbolImageNamed:symbolName];
    }

    if ([iconName hasPrefix:@"File:"]) {
        NSString *filePath = [[iconName substringFromIndex:[@"File:" length]]
                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        if ([filePath length] == 0) {
            return nil;
        }

        return [[[NSImage alloc] initWithContentsOfFile:filePath] autorelease];
    }

    return [NSImage imageNamed:iconName];
}

- (WailsSidebarNode *)createNodeWithTitle:(NSString *)title iconName:(NSString *)iconName isGroup:(BOOL)isGroup
{
    WailsSidebarNode *node = [[WailsSidebarNode alloc] init];
    node.isGroup = isGroup;
    node.title = title;
    printf("=====> Creating node: %s\n", [iconName UTF8String]);
    node.icon = [self imageForIconName:iconName];
    if (node.icon == nil) {
        printf("=====> Could not create icon for node: %s\n", [iconName UTF8String]);
        node.icon = [NSImage imageNamed:@"NSApplicationIcon"];
    } else {
        printf("=====> Created icon for node: %s\n", [iconName UTF8String]);
        [node.icon setTemplate:YES];
        printf("======> size: %f x %f\n", node.icon.size.width, node.icon.size.height);
    }
    return node;
}

- (void)addUngroupedItemWithLabel:(NSString *)label iconName:(NSString *)iconName
{
    WailsSidebarNode *node = [self createNodeWithTitle:label iconName:iconName isGroup:NO];
    [self.ungroupedItems addObject:node];
    [node release];
}

- (void)addGroupWithTitle:(NSString *)title initiallyExpanded:(BOOL)expanded
{
    WailsSidebarNode *groupNode = [self createNodeWithTitle:title iconName:nil isGroup:YES];
    // FIXME: We need initiallyExpanded in the node
    //groupNode.initiallyExpanded = expanded;
    [self.groups addObject:groupNode];
    [groupNode release];
}

- (void)addItemWithLabel:(NSString *)label iconName:(NSString *)iconName
{
    WailsSidebarNode *lastGroup = [self.groups lastObject];
    if (lastGroup == nil) {
        return;
    }
    WailsSidebarNode *itemNode = [self createNodeWithTitle:label iconName:iconName isGroup:NO];
    [lastGroup.children addObject:itemNode];
    [itemNode release];
}

- (NSInteger)numberOfUngroupedItems
{
    return [self.ungroupedItems count];
}

- (WailsSidebarNode *)ungroupedNodeAtIndex:(NSInteger)nodeIndex
{
    if (nodeIndex < 0 || nodeIndex >= [self.ungroupedItems count]) {
        return nil;
    }
    id node = [self.ungroupedItems objectAtIndex:nodeIndex];
    if (![node isKindOfClass:[WailsSidebarNode class]]) {
        return nil;
    }
    return (WailsSidebarNode *)node;
}

- (WailsSidebarNode *)groupNodeAtIndex:(NSInteger)groupIndex
{
    if (groupIndex < 0 || groupIndex >= [self.groups count]) {
        return nil;
    }
    id node = [self.groups objectAtIndex:groupIndex];
    if (![node isKindOfClass:[WailsSidebarNode class]]) {
        return nil;
    }
    return (WailsSidebarNode *)node;
}

- (WailsSidebarNode *)childNodeAtIndex:(NSInteger)itemIndex inGroupAtIndex:(NSInteger)groupIndex
{
    WailsSidebarNode *groupNode = [self groupNodeAtIndex:groupIndex];
    if (groupNode == nil) {
        return nil;
    }
    if (itemIndex < 0 || itemIndex >= [groupNode.children count]) {
        return nil;
    }
    id node = [groupNode.children objectAtIndex:itemIndex];
    if (![node isKindOfClass:[WailsSidebarNode class]]) {
        return nil;
    }
    return (WailsSidebarNode *)node;
}

- (NSString *)labelForUngroupedItemAtIndex:(NSInteger)itemIndex
{
    return [[self.ungroupedItems objectAtIndex:itemIndex] title];
}

- (NSImage *)iconForUngroupedItemAtIndex:(NSInteger)itemIndex
{
    return [[self.ungroupedItems objectAtIndex:itemIndex] icon];
}

- (NSInteger)numberOfGroups
{
    return [self.groups count];
}

- (NSString *)titleForGroupAtIndex:(NSInteger)groupIndex
{
    WailsSidebarNode *groupNode = [self groupNodeAtIndex:groupIndex];
    return groupNode != nil ? groupNode.title : nil;
}

- (NSInteger)numberOfItemsInGroupAtIndex:(NSInteger)groupIndex
{
    WailsSidebarNode *groupNode = [self groupNodeAtIndex:groupIndex];
    return groupNode != nil ? [groupNode.children count] : 0;
}

- (NSString *)labelForItemAtIndex:(NSInteger)itemIndex inGroupAtIndex:(NSInteger)groupIndex
{
    WailsSidebarNode *itemNode = [self childNodeAtIndex:itemIndex inGroupAtIndex:groupIndex];
    return itemNode != nil ? itemNode.title : nil;
}

- (NSImage *)iconForItemAtIndex:(NSInteger)itemIndex inGroupAtIndex:(NSInteger)groupIndex
{
    WailsSidebarNode *itemNode = [self childNodeAtIndex:itemIndex inGroupAtIndex:groupIndex];
    return itemNode != nil ? itemNode.icon : nil;
}

- (BOOL)isGroupInitiallyExpandedAtIndex:(NSInteger)groupIndex
{
    return YES;
    // FIXME: this
    //WailsSidebarNode *groupNode = [self groupNodeAtIndex:groupIndex];
    //return groupNode != nil ? groupNode.initiallyExpanded : NO;
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

- (NSArray<WailsSidebarNode *> *)nodesMatchingExpansionState:(BOOL)shouldBeExpanded
{
    NSMutableArray<WailsSidebarNode *> *nodes = [NSMutableArray array];
    if (self.model == nil || [self.rootNodes count] == 0) {
        return nodes;
    }
    NSInteger currentGroupIndex = 0;
    for (WailsSidebarNode *rootNode in self.rootNodes) {
        if (!rootNode.isGroup) {
            // only groups can be expanded/collapsed
            continue;
        }
        if ([self.model isGroupInitiallyExpandedAtIndex:currentGroupIndex] == shouldBeExpanded) {
            [nodes addObject:rootNode];
        }
        currentGroupIndex++;
    }
    return nodes;
}

- (NSArray<WailsSidebarNode *> *)expandedNodes
{
    return [self nodesMatchingExpansionState:YES];
}

- (NSArray<WailsSidebarNode *> *)collapsedNodes
{
    return [self nodesMatchingExpansionState:NO];
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
    // (1) add all ungrouped items
    NSInteger ungroupedCount = [activeModel numberOfUngroupedItems];
    for (NSInteger i = 0; i < ungroupedCount; i++) {
        WailsSidebarNode *node = [self
                                  buildNodeWithTitle:[activeModel labelForUngroupedItemAtIndex:i]
                                                icon:[activeModel iconForUngroupedItemAtIndex:i]
                                             isGroup:NO];
        [self appendNodeToParent:self.rootNodes node:node];
    }
    // (2) add all groups, and all items in each group
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
        if ([createdOutlineView respondsToSelector:@selector(setStyle:)]) {
            [createdOutlineView setStyle:NSTableViewStyleSourceList];
        } else {
            // This does not only change the selection highlight but makes the whole list look more macOS sidebar like...
            [createdOutlineView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
        }
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
    self.dataSource.model = newModel;
    [self.outlineView reloadData];
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
    [self expandNodes];
}

- (void)expandNodes
{
    for (WailsSidebarNode *rootNode in self.dataSource.expandedNodes) {
        [self.outlineView expandItem:rootNode];
    }
    for (WailsSidebarNode *rootNode in self.dataSource.collapsedNodes) {
        [self.outlineView collapseItem:rootNode];
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

- (NSTableCellView *)createBaseCellWithWidth:(CGFloat)width rowHeight:(CGFloat)height
{
    NSTableCellView *cell = [[[NSTableCellView alloc] initWithFrame:NSMakeRect(0, 0, width, height)] autorelease];
    return cell;
}

- (NSTextField *)createBaseTextFieldWithFrame:(NSRect)frame
{
    NSTextField *textField = [[[NSTextField alloc] initWithFrame:frame] autorelease];
    [textField setBezeled:NO];
    [textField setBordered:NO];
    [textField setDrawsBackground:NO];
    [textField setEditable:NO];
    [textField setSelectable:NO];
    return textField;
}

// Convert the WailsSidebarNode to a NSTableCellView, which is what NSOutlineView expects.
- (NSView *)outlineView:(NSOutlineView *)sidebarOutlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    WailsSidebarNode *node = (WailsSidebarNode *)item;

    if (node.isGroup) {
        NSTableCellView *groupCell = [self createBaseCellWithWidth:tableColumn.width rowHeight:20.0];
        NSTextField *textField = [self createBaseTextFieldWithFrame:NSMakeRect(8, 1, tableColumn.width - 16, 16)];
        [textField setStringValue:node.title != nil ? node.title : @""];
        [textField setTextColor:[NSColor secondaryLabelColor]];
        [textField setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize] weight:NSFontWeightSemibold]];
        [groupCell setTextField:textField];
        [groupCell addSubview:textField];
        return groupCell;
    }

    NSTableCellView *itemCell = [self createBaseCellWithWidth:tableColumn.width rowHeight:28.0];
    NSImageView *imageView = [[[NSImageView alloc] initWithFrame:NSMakeRect(6, 4, 16, 16)] autorelease];
    NSImage *resolvedImage = node.icon;
    printf("=======> resolvedImage: %p\n", resolvedImage);
    [resolvedImage setTemplate:YES];
    [imageView setImage:resolvedImage];
    [imageView setImageScaling:NSImageScaleProportionallyDown];
    NSTextField *textField = [self createBaseTextFieldWithFrame:NSMakeRect(28, 3, tableColumn.width - 34, 18)];
    [textField setStringValue:node.title != nil ? node.title : @""];
    [textField setFont:[NSFont systemFontOfSize:13.0]];
    [textField setTextColor:[NSColor labelColor]];
    [itemCell setImageView:imageView];
    [itemCell setTextField:textField];
    [itemCell addSubview:imageView];
    [itemCell addSubview:textField];

    return itemCell;
}

// Helper that loads an icon from a string.
- (NSImage *)imageForIconString:(NSString *)iconString
{
    if (iconString == nil || [iconString length] == 0) {
        return nil;
    }
    // We support system icons by checking for the prefix "System:"
    if ([iconString hasPrefix:@"System:"]) {
        NSString *symbolName = [iconString substringFromIndex:[@"System:" length]];
        symbolName = [symbolName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([symbolName length] == 0) {
            return nil;
        }
        if (@available(macOS 11.0, *)) {
            return [NSImage systemImageNamed:symbolName];
        }
        return [NSImage imageNamed:symbolName];
    }
    // It's just a file path, so we load it from the disk
    NSString *filePath = [iconString substringFromIndex:[@"File:" length]];
    filePath = [filePath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([filePath length] == 0) {
        return nil;
    }
    // FIXME: Now we are doing autorelease all of a sudden...
    return [[[NSImage alloc] initWithContentsOfFile:filePath] autorelease];
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
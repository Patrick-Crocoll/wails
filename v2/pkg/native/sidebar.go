package native

type ToolbarItem interface {
	isToolbarElement()
}

type ToolbarElement struct {
	Index int
	Text  string
}

type ToolbarButtonEvent struct {
	Btn *ToolbarButton
}

type ToolbarButtonClickHandler func(evt ToolbarButtonEvent)

type ToolbarButton struct {
	ToolbarElement
	Icon  string
	Click ToolbarButtonClickHandler
}

func (btn ToolbarButton) isToolbarElement() {}

type ToolbarStaticElement struct {
	ToolbarElement
	IsSpacer bool
}

func (tse ToolbarStaticElement) isToolbarElement() {}

type ToolbarButtonGroup struct {
	ToolbarElement
	Buttons []*ToolbarButton
}

func (grp ToolbarButtonGroup) isToolbarElement() {}

type SimpleMenuItemEvent struct {
	Item *SimpleMenuItem
}

type SimpleMenuItemClickHandler func(evt SimpleMenuItemEvent)

type SimpleMenuItem struct {
	Label       string
	IsSeparator bool
	Click       SimpleMenuItemClickHandler
}

type SimpleMenu struct {
	// TODO: See if we can use "menu.Menu" instead!
	Items []*SimpleMenuItem
}

type ToolbarMenuButton struct {
	ToolbarElement
	Icon string
	Menu *SimpleMenu
}

func (tse ToolbarMenuButton) isToolbarElement() {}

type ToolbarFieldTextEvent struct {
	Field *ToolbarField
	Text  string
}

type ToolbarFieldTextChangeHandler func(evt ToolbarFieldTextEvent)

type ToolbarField struct {
	ToolbarElement
	IsSearch    bool
	TextChanged ToolbarFieldTextChangeHandler
}

func (f ToolbarField) isToolbarElement() {}

type ToolbarControl interface {
	SetLabelText(element *ToolbarStaticElement, label string)
	SelectButton(group *ToolbarButtonGroup, button *ToolbarButton)
	DeSelectButton(group *ToolbarButtonGroup, button *ToolbarButton)
	SetText(field *ToolbarField, text string)
	Clear(field *ToolbarField, text string)
}

type ToolbarControlHandler func(ctrl ToolbarControl)

type Toolbar struct {
	Elements []ToolbarItem

	OnControlReady ToolbarControlHandler
}

// Sidebar

type SidebarElementValue interface {
	SidebarItem | SidebarGroup
}

type SidebarElement[T SidebarElementValue] struct {
	Index int
	Value T
}

type Sidebar struct {
	// description of the native sidebar

	ModelProvider SidebarModelProvider
	WidthPixels   int
	IsExpanded    bool

	// callbacks from the sidebar

	OnControlReady SidebarControlHandler
	OnItemSelected SidebarItemSelectedHandler
	OnGroupToggled SidebarGroupToggledHandler
	OnWidthChanged SidebarWidthChangedHandler
}

type SidebarModel struct {
	SidebarGroups []SidebarElement[SidebarGroup]
	SidebarItems  []SidebarElement[SidebarItem]
	SelectedItem  *SidebarItem // If given, this item will initially be selected
}

type SidebarModelProvider func() SidebarModel

type SidebarItemSelectEvent struct {
	Item  *SidebarItem
	Group *SidebarGroup
}

type SidebarGroupToggleEvent struct {
	Group      *SidebarGroup
	IsExpanded bool
}

type SidebarControlHandler func(ctrl SidebarControl)

type SidebarItemSelectedHandler func(evt SidebarItemSelectEvent)
type SidebarGroupToggledHandler func(evt SidebarGroupToggleEvent)
type SidebarWidthChangedHandler func(widthPixels int)

// TODO: Do we have to return errors?

type SidebarControl interface {
	Refresh()
	SetWidth(width int)
	Expand()
	Collapse()
}

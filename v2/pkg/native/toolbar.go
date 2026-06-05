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
	Icon       string
	IsSelected bool
	Click      ToolbarButtonClickHandler
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
	IsSelected  bool
	Click       SimpleMenuItemClickHandler
}

func (smi SimpleMenuItem) isToolbarElement() {}

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
	SelectMenuItem(menu *SimpleMenu, menuItem *SimpleMenuItem)
}

type ToolbarControlHandler func(ctrl ToolbarControl)

type Toolbar struct {
	Elements []ToolbarItem

	OnControlReady ToolbarControlHandler
}

//go:build darwin
// +build darwin

package darwin

import (
	"sync"
	"time"

	"github.com/wailsapp/wails/v2/pkg/native"
)

var (
	initSBCOnce          sync.Once
	sbModelRefreshLock   sync.Mutex
	sidebarItemIdCounter int
	sidebarInitialized   bool
	sbWidthLock          sync.Mutex
	initTBCOnce          sync.Once
	toolbarInitialized   bool
)

type SidebarGroupToggleState struct {
	groupId   int
	collapsed bool
}

type ToolbarTextChange struct {
	id  int
	txt string
}

var (
	sidebarItemSelectBuffer       = make(chan int, 10)
	sidebarGroupToggleStateBuffer = make(chan SidebarGroupToggleState, 10)
	sidebarWidthChangedBuffer     = make(chan int, 10)
	toolbarButtonClickedBuffer    = make(chan int, 10)
	toolbarTextChangedBuffer      = make(chan ToolbarTextChange, 10)
)

func (w *Window) SetNativeElements(ne *native.Native) {
	if ne == nil {
		return
	}
	w.setupSidebar(ne.Sidebar)
	w.setupToolbar(ne.Toolbar)
	// Code for more native support goes here ...
}

type ToolbarController struct {
	w         *Window
	items     map[int]native.ToolbarItem
	model     *ToolbarModel
	idCounter int
}

func (ctrl *ToolbarController) SetLabelText(element *native.ToolbarStaticElement, label string) {
	labelId := ctrl.idFor(element)
	if labelId > 0 {
		ctrl.model.setLabel(label, labelId)
	}
}

func (ctrl *ToolbarController) SelectButton(group *native.ToolbarButtonGroup, button *native.ToolbarButton) {
	groupId := ctrl.idFor(group)
	buttonId := ctrl.idFor(button)
	if groupId > 0 && buttonId > 0 {
		ctrl.model.selectButtonInGroup(groupId, buttonId)
	}
}

func (ctrl *ToolbarController) DeSelectButton(group *native.ToolbarButtonGroup, button *native.ToolbarButton) {
	groupId := ctrl.idFor(group)
	buttonId := ctrl.idFor(button)
	if groupId > 0 && buttonId > 0 {
		ctrl.model.deselectButtonInGroup(groupId, buttonId)
	}
}

func (ctrl *ToolbarController) SetText(field *native.ToolbarField, text string) {
	//TODO implement me
	panic("implement me")
}

func (ctrl *ToolbarController) Clear(field *native.ToolbarField, text string) {
	//TODO implement me
	panic("implement me")
}

func (ctrl *ToolbarController) SelectMenuItem(menu *native.SimpleMenu, menuItem *native.SimpleMenuItem) {
	itemId := ctrl.idFor(menuItem)
	if itemId > 0 {
		ctrl.model.selectMenuItem(itemId)
	}
}

func (ctrl *ToolbarController) idFor(item native.ToolbarItem) int {
	for id, existing := range ctrl.items {
		if existing == item {
			return id
		}
	}
	return -1
}

func (w *Window) setupToolbar(toolbar *native.Toolbar) {
	if toolbar == nil {
		return
	}
	ctrl := getToolbarController(w)
	addToolbarElements(ctrl, toolbar.Elements)
	setContextToolbarModel(w.context, ctrl.model)
	setToolbarCallbacks(w.context)
	if toolbar.OnControlReady != nil {
		toolbar.OnControlReady(ctrl)
	}
}

func getToolbarController(w *Window) (toolbarController *ToolbarController) {
	initTBCOnce.Do(
		func() {
			toolbarController = &ToolbarController{
				items: map[int]native.ToolbarItem{},
				model: newToolbarModel(),
			}
			go toolbarController.startToolbarButtonClickedProcessor()
			go toolbarController.startToolbarTextChangedProcessor()
			toolbarInitialized = true
		},
	)
	return
}

func (ctrl *ToolbarController) buttonClicked(buttonId int) {
	for id, element := range ctrl.items {
		if id != buttonId {
			continue
		}
		switch e := element.(type) {
		case *native.ToolbarButton:
			e.Click(
				native.ToolbarButtonEvent{
					Btn: e,
				},
			)
		case *native.SimpleMenuItem:
			e.Click(
				native.SimpleMenuItemEvent{
					Item: e,
				},
			)
		}
	}
}

func (ctrl *ToolbarController) textChanged(txt ToolbarTextChange) {
	for id, element := range ctrl.items {
		if id != txt.id {
			continue
		}
		switch e := element.(type) {
		case *native.ToolbarField:
			e.TextChanged(
				native.ToolbarFieldTextEvent{
					Field: e,
					Text:  txt.txt,
				},
			)
		}
	}
}

func addToolbarElements(ctrl *ToolbarController, elements []native.ToolbarItem) int {
	for _, element := range elements {
		switch e := element.(type) {
		case native.ToolbarButton:
			ctrl.addToolbarButton(&e)
		case *native.ToolbarButton:
			ctrl.addToolbarButton(e)
		case native.ToolbarStaticElement:
			ctrl.addToolbarStaticElement(&e)
		case *native.ToolbarStaticElement:
			ctrl.addToolbarStaticElement(e)
		case *native.ToolbarButtonGroup:
			ctrl.addToolbarButtonGroup(e)
		case native.ToolbarButtonGroup:
			ctrl.addToolbarButtonGroup(&e)
		case *native.ToolbarMenuButton:
			ctrl.addToolbarMenuButton(e)
		case native.ToolbarMenuButton:
			ctrl.addToolbarMenuButton(&e)
		case *native.ToolbarField:
			ctrl.addTextField(e)
		case native.ToolbarField:
			ctrl.addTextField(&e)
		}
	}
	return ctrl.idCounter
}

func (ctrl *ToolbarController) addToolbarButton(button *native.ToolbarButton) {
	if ctrl.model == nil || button == nil {
		return
	}
	ctrl.model.addButton(button.Text, button.Icon, button.IsSelected, ctrl.idCounter)
	ctrl.items[ctrl.idCounter] = button
	ctrl.idCounter++
}

func (ctrl *ToolbarController) addToolbarStaticElement(e *native.ToolbarStaticElement) {
	if e.IsSpacer {
		ctrl.model.addSpacer()
	} else {
		ctrl.model.addLabel(e.Text, ctrl.idCounter)
		ctrl.items[ctrl.idCounter] = e
		ctrl.idCounter++
	}
}

func (ctrl *ToolbarController) addToolbarButtonGroup(group *native.ToolbarButtonGroup) {
	if ctrl.model == nil || group == nil {
		return
	}
	ctrl.model.startButtonGroup(group.Text, ctrl.idCounter)
	defer ctrl.model.endButtonGroup()
	ctrl.idCounter++
	items := make([]native.ToolbarItem, len(group.Buttons))
	for i, b := range group.Buttons {
		items[i] = b
	}
	ctrl.idCounter = addToolbarElements(ctrl, items)
}

func (ctrl *ToolbarController) addToolbarMenuButton(btn *native.ToolbarMenuButton) {
	if ctrl.model == nil || btn == nil {
		return
	}
	ctrl.model.startButtonWithMenu(btn.Text, btn.Icon, ctrl.idCounter)
	defer ctrl.model.endButtonWithMenu()
	ctrl.idCounter++
	if btn.Menu == nil || btn.Menu.Items == nil {
		return
	}
	for _, item := range btn.Menu.Items {
		ctrl.model.addMenuItem(item.Label, item.IsSeparator, item.IsSelected, ctrl.idCounter)
		ctrl.items[ctrl.idCounter] = item
		ctrl.idCounter++
	}
}

func (ctrl *ToolbarController) addTextField(txtField *native.ToolbarField) {
	ctrl.model.addTextField(txtField.IsSearch, ctrl.idCounter)
	ctrl.items[ctrl.idCounter] = txtField
	ctrl.idCounter++
}

func (ctrl *ToolbarController) startToolbarButtonClickedProcessor() {
	for buttonId := range toolbarButtonClickedBuffer {
		ctrl.buttonClicked(buttonId)
	}
}

func (ctrl *ToolbarController) startToolbarTextChangedProcessor() {
	for txt := range toolbarTextChangedBuffer {
		ctrl.textChanged(txt)
	}
}

// sidebar

type SidebarController struct {
	w             *Window
	savedWidth    int
	currentWidth  int
	collapsed     bool
	selectedItem  int
	modelProvider native.SidebarModelProvider
	items         map[int]*native.SidebarItem
	groups        map[int]*native.SidebarGroup
	itemToGroup   map[int]int
}

func (s *SidebarController) Refresh() {
	if s.modelProvider != nil && s.w != nil {
		sbModelRefreshLock.Lock()
		defer sbModelRefreshLock.Unlock()
		clear(s.items)
		clear(s.groups)
		clear(s.itemToGroup)
		sidebarItemIdCounter = -1
		model := createSidebarModel(
			s.modelProvider(),
			func(item *native.SidebarItem, groupId int) int {
				sidebarItemIdCounter++
				s.items[sidebarItemIdCounter] = item
				if groupId >= 0 {
					s.itemToGroup[sidebarItemIdCounter] = groupId
				}
				return sidebarItemIdCounter
			},
			func(group *native.SidebarGroup) int {
				sidebarItemIdCounter++
				s.groups[sidebarItemIdCounter] = group
				return sidebarItemIdCounter
			},
		)
		setContextSidebarModel(s.w.context, model)
	}
}

func (s *SidebarController) SetWidth(width int) {
	if s.w != nil && s.w.context != nil {
		sbWidthLock.Lock()
		defer sbWidthLock.Unlock()
		setSidebarWidth(s.w.context, width)
		s.currentWidth = width
		s.savedWidth = width
	}
}

func (s *SidebarController) Expand() {
	if !s.collapsed {
		return
	}
	if s.w != nil && s.w.context != nil {
		s.collapsed = false
		width := s.savedWidth
		if width <= 1 {
			// In this case we set it to -1, which lets the underlying implementation decide a reasonable width
			width = -1
		}
		expandSidebar(s.w.context, width)
		s.currentWidth = width
	}
}

func (s *SidebarController) Collapse() {
	if s.collapsed {
		return
	}
	if s.w != nil && s.w.context != nil {
		s.collapsed = true
		collapseSidebar(s.w.context)
	}
}

func (s *SidebarController) itemSelected(itemId int) {
	if s.w == nil || s.w.nativeSidebar == nil || s.w.nativeSidebar.OnItemSelected == nil {
		return
	}
	if itemId == s.selectedItem {
		return
	}
	s.selectedItem = itemId
	if item, found := s.items[itemId]; found {
		var group *native.SidebarGroup
		if groupId, ok := s.itemToGroup[itemId]; ok {
			group = s.groups[groupId]
		}
		evt := native.SidebarItemSelectEvent{
			Item:  item,
			Group: group,
		}
		s.w.nativeSidebar.OnItemSelected(evt)
	}
}

func (s *SidebarController) groupToggled(groupState SidebarGroupToggleState) {
	if s.w == nil || s.w.nativeSidebar == nil || s.w.nativeSidebar.OnGroupToggled == nil {
		return
	}
	if group, found := s.groups[groupState.groupId]; found {
		evt := native.SidebarGroupToggleEvent{
			Group:      group,
			IsExpanded: !groupState.collapsed,
		}
		s.w.nativeSidebar.OnGroupToggled(evt)
	}
}

func (s *SidebarController) startSidebarItemSelectedProcessor() {
	for selectedItem := range sidebarItemSelectBuffer {
		s.itemSelected(selectedItem)
	}
}

func (s *SidebarController) startGroupToggledProcessor() {
	for groupState := range sidebarGroupToggleStateBuffer {
		s.groupToggled(groupState)
	}
}

func (s *SidebarController) startSidebarWidthChangedProcessor() {
	const timeout = 500 * time.Millisecond
	timer := time.NewTimer(timeout)
	defer timer.Stop()
	for {
		select {
		case <-timer.C:
			if s.w != nil && s.w.nativeSidebar != nil && s.w.nativeSidebar.OnWidthChanged != nil {
				if s.savedWidth != s.currentWidth {
					sbWidthLock.Lock()
					s.w.nativeSidebar.OnWidthChanged(s.currentWidth)
					if !s.collapsed {
						s.savedWidth = s.currentWidth
					}
					sbWidthLock.Unlock()
				}
			}
		case width := <-sidebarWidthChangedBuffer:
			s.currentWidth = width
			// This should be fine for go > 1.23. Might cause issues with older versions of go!
			timer.Reset(timeout)
		}
	}
}

func (w *Window) setupSidebar(sidebar *native.Sidebar) {
	if sidebar == nil || sidebar.ModelProvider == nil {
		return
	}
	w.nativeSidebar = sidebar
	sbc := getSidebarController(w)
	sbc.modelProvider = sidebar.ModelProvider
	sbc.Refresh()
	sbc.SetWidth(sidebar.WidthPixels)
	if sidebar.IsExpanded {
		sbc.Expand()
	} else {
		sbc.Collapse()
	}
	if sidebar.OnControlReady != nil {
		sidebar.OnControlReady(sbc)
	}
}

func getSidebarController(w *Window) (sidebarController *SidebarController) {
	initSBCOnce.Do(
		func() {
			sidebarController = &SidebarController{
				w:            w,
				savedWidth:   -1,
				selectedItem: -1,
			}
			sidebarController.items = make(map[int]*native.SidebarItem)
			sidebarController.groups = make(map[int]*native.SidebarGroup)
			sidebarController.itemToGroup = make(map[int]int)
			go sidebarController.startSidebarItemSelectedProcessor()
			go sidebarController.startSidebarWidthChangedProcessor()
			go sidebarController.startGroupToggledProcessor()
			setSidebarCallbacks(w.context)
			sidebarInitialized = true
		},
	)
	return sidebarController
}

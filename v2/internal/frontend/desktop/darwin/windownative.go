//go:build darwin
// +build darwin

package darwin

import (
	"sync"

	"github.com/wailsapp/wails/v2/pkg/native"
)

var (
	sidebarController    SidebarController
	initSBCOnce          sync.Once
	sbModelRefreshLock   sync.Mutex
	sidebarItemIdCounter int
)

type SidebarGroupToggleState struct {
	groupId   int
	collapsed bool
}

var (
	sidebarItemSelectBuffer       = make(chan int, 10)
	sidebarGroupToggleStateBuffer = make(chan SidebarGroupToggleState, 10)
	sidebarWidthChangedBuffer     = make(chan int, 10)
)

func (w *Window) SetNativeElements(ne *native.Native) {
	if ne == nil {
		return
	}
	w.setupSidebar(ne.Sidebar)
	// Code for more native support goes here ...
}

type SidebarController struct {
	w             *Window
	savedWidth    int
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
		model := CreateSidebarModel(
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
		SetContextSidebarModel(s.w.context, model)
	}
}

func (s *SidebarController) SetWidth(width int) {
	if s.w != nil && s.w.context != nil {
		SetSidebarWidth(s.w.context, width)
	}
}

func (s *SidebarController) Expand() {
	if s.w != nil && s.w.context != nil {
		ExpandSidebar(s.w.context, s.savedWidth)
	}
}

func (s *SidebarController) Collapse() {
	if s.w != nil && s.w.context != nil {
		CollapseSidebar(s.w.context)
	}
}

func (s *SidebarController) itemSelected(itemId int) {
	if s.w == nil || s.w.nativeSidebar == nil || s.w.nativeSidebar.OnItemSelected == nil {
		return
	}
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
	for width := range sidebarWidthChangedBuffer {
		if s.w == nil || s.w.nativeSidebar == nil || s.w.nativeSidebar.OnWidthChanged == nil {
			continue
		}
		s.w.nativeSidebar.OnWidthChanged(width)
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
	SetSidebarWidth(w.context, sidebar.WidthPixels)

	if sidebar.OnControlReady != nil {
		sidebar.OnControlReady(&sbc)
	}
}

func getSidebarController(w *Window) SidebarController {
	initSBCOnce.Do(
		func() {
			sidebarController = SidebarController{
				w:          w,
				savedWidth: -1,
			}
			sidebarController.items = make(map[int]*native.SidebarItem)
			sidebarController.groups = make(map[int]*native.SidebarGroup)
			sidebarController.itemToGroup = make(map[int]int)
			go sidebarController.startSidebarItemSelectedProcessor()
			SetSidebarCallbacks(w.context)
		},
	)
	return sidebarController
}

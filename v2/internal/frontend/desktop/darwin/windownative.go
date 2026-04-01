//go:build darwin
// +build darwin

package darwin

import (
	"log/slog"
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
		sbWidthLock.Lock()
		defer sbWidthLock.Unlock()
		SetSidebarWidth(s.w.context, width)
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
		ExpandSidebar(s.w.context, width)
	}
}

func (s *SidebarController) Collapse() {
	if s.collapsed {
		return
	}
	if s.w != nil && s.w.context != nil {
		slog.Debug("===================> collapse received. Collapsing now...")
		s.collapsed = true
		CollapseSidebar(s.w.context)
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
			SetSidebarCallbacks(w.context)
			sidebarInitialized = true
		},
	)
	return sidebarController
}

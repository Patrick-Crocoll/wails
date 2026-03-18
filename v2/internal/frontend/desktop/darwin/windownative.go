package darwin

import (
	"github.com/wailsapp/wails/v2/pkg/native"
)

func (w *Window) SetNativeElements(ne *native.Native) {
	if ne == nil {
		return
	}
	// (1) the native sidebar
	if ne.SidebarProvider != nil {

		return
	}
	// FIXME: Code for native support goes here
}

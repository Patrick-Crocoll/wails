//go:build darwin
// +build darwin

package darwin

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Foundation -framework Cocoa -framework WebKit
*/
import "C"

/*
 * These exports MUST be implemented in a separate file (not in sidebar.go),
 * because otherwise the linker will be very sad...
 */

//export GoSidebarItemSelected
func GoSidebarItemSelected(itemId C.int) {
	if !sidebarInitialized {
		return
	}
	select {
	case sidebarItemSelectBuffer <- int(itemId):
	default:
		// IMPORTANT: drop event if nobody is draining fast enough, otherwise the UI can lock up completely
	}
}

//export GoSidebarGroupToggled
func GoSidebarGroupToggled(groupId C.int, groupState C.int) {
	if !sidebarInitialized {
		return
	}
	select {
	case sidebarGroupToggleStateBuffer <- SidebarGroupToggleState{
		groupId:   int(groupId),
		collapsed: int(groupState) == 0,
	}:
	default:
		// IMPORTANT: drop event if nobody is draining fast enough, otherwise the UI can lock up completely
	}
}

//export GoSidebarWidthChanged
func GoSidebarWidthChanged(width C.int) {
	if !sidebarInitialized {
		return
	}
	select {
	case sidebarWidthChangedBuffer <- int(width):
	default:
		// IMPORTANT: drop event if nobody is draining fast enough, otherwise the UI can lock up completely
	}
}

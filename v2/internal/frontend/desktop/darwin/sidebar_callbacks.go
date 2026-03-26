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
	sidebarItemSelectBuffer <- int(itemId)
}

//export GoSidebarGroupToggled
func GoSidebarGroupToggled(groupId C.int, groupState C.int) {
	sidebarGroupToggleStateBuffer <- SidebarGroupToggleState{
		groupId:   int(groupId),
		collapsed: int(groupState) == 0,
	}
}

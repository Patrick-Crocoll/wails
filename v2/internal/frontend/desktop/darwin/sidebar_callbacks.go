package darwin

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Foundation -framework Cocoa -framework WebKit
*/
import "C"

import (
	"fmt"
)

/*
 * These exports MUST be implemented in a separate file (not in sidebar.go),
 * because otherwise the linker will be very sad...
 */

//export GoSidebarItemSelected
func GoSidebarItemSelected(itemLabel *C.char) {
	fmt.Println("Selected item:", C.GoString(itemLabel))
}

//export GoSidebarGroupToggled
func GoSidebarGroupToggled(groupLabel *C.char, expanded C.int) {
	fmt.Printf("Group toggled: %s expanded=%t\n", C.GoString(groupLabel), expanded != 0)
}

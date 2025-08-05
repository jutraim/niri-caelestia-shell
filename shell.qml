//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules"
import "modules/drawers"
import "modules/background"
import "modules/areapicker"
import "modules/lock"

// import "./modules/sidebarLeft/"
// import "./modules/sidebarRight/"

import Quickshell

ShellRoot {
    // property bool enableSidebarLeft: true
    // property bool enableSidebarRight: false
    Background {}
    Drawers {}
    AreaPicker {}
    Lock {}

    Shortcuts {}

    // LazyLoader { active: enableSidebarLeft; component: SidebarLeft {} }
    // LazyLoader { active: enableSidebarRight; component: SidebarRight {} }
}

pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Workspace management
    property var allWorkspaces: []
    property int focusedWorkspaceIndex: 0
    property string focusedWorkspaceId: ""
    property var currentOutputWorkspaces: []
    property string currentOutput: ""

    // Window management
    property var windows: []
    property int focusedWindowIndex: -1
    property string focusedWindowTitle: "(No active window)"
    property string focusedWindowClass: "(No active window)"
    property string focusedWindowId: ""

    property string focusedMonitorName: "eDP-2" //placeholder

    property var allKeyboardLayouts: []
    property string currentKeyboardLayout: ""

    // Overview state
    property bool inOverview: false

    signal windowOpenedOrChanged(var windowData)

    // Last focused window
    property var focusedWindow: root.windows[root.focusedWindowIndex]
    property var lastFocusedWindow: null
    // Monitor changes to focusedWindowId to update lastFocusedWindow
    onFocusedWindowIdChanged: {
        if (focusedWindow) {
            // Only update if a window is truly focused
            root.lastFocusedWindow = focusedWindow;
        }
    }

    property var workspaceHasWindows: ({})
    function updateWorkspaceHasWindows() {
        let newWorkspaceHasWindows = {};

        // Initialize all known workspaces to false
        for (const ws of root.allWorkspaces) {
            // Use allWorkspaces here
            newWorkspaceHasWindows[ws.idx] = false;
        }

        // Iterate through all windows and mark their workspace as having windows
        for (const window of root.windows) {
            if (window.workspace_id !== undefined && window.workspace_id !== null) {
                newWorkspaceHasWindows[getWorkspaceIdxById(window.workspace_id)] = true;
            }
        }
        // Only update if there's an actual change to avoid unnecessary property change signals
        if (JSON.stringify(root.workspaceHasWindows) !== JSON.stringify(newWorkspaceHasWindows)) {
            root.workspaceHasWindows = newWorkspaceHasWindows;
            console.log("NiriService: updateWorkspaceHasWindows() called. Current state:", JSON.stringify(root.workspaceHasWindows));
        }
    }

    function getWorkspaceIdxById(workspaceId) {
        const ws = allWorkspaces.find(w => w.id === workspaceId);
        return ws ? ws.idx : -1;
    }

    // Call updateWorkspaceHasWindows when relevant properties change
    onAllWorkspacesChanged: updateWorkspaceHasWindows() // Update if workspaces themselves change
    onWindowsChanged: updateWorkspaceHasWindows() // Explicitly update when the windows list changes

    // Feature availability
    property bool niriAvailable: false

    Component.onCompleted: {
        console.log("NiriService: Component.onCompleted - initializing service");
        checkNiriAvailability();
    }

    // Check if niri is available
    Process {
        id: niriCheck
        command: ["which", "niri"]

        onExited: exitCode => {
            root.niriAvailable = exitCode === 0;
            if (root.niriAvailable) {
                console.log("NiriService: niri found, starting event stream and loading initial data");
                eventStreamProcess.running = true;
                root.loadInitialWorkspaceData();
            } else {
                console.log("NiriService: niri not found, workspace features disabled");
            }
        }
    }

    function checkNiriAvailability() {
        niriCheck.running = true;
    }

    // Load initial workspace data
    Process {
        id: initialDataQuery
        command: ["niri", "msg", "-j", "workspaces"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) {
                    try {
                        console.log("NiriService: Loaded initial workspace data");
                        const workspaces = JSON.parse(text.trim());
                        // Initial query returns array directly, event stream wraps it in WorkspacesChanged
                        root.handleWorkspacesChanged({
                            workspaces: workspaces
                        });
                    } catch (e) {
                        console.warn("NiriService: Failed to parse initial workspace data:", e);
                    }
                }
            }
        }
    }

    // Load initial windows data
    Process {
        id: initialWindowsQuery
        command: ["niri", "msg", "-j", "windows"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) {
                    try {
                        const windowsData = JSON.parse(text.trim());
                        if (windowsData && windowsData.windows) {
                            root.handleWindowsChanged(windowsData);
                            console.log("NiriService: Loaded", windowsData.windows.length, "initial windows");
                        }
                    } catch (e) {
                        console.warn("NiriService: Failed to parse initial windows data:", e);
                    }
                }
            }
        }
    }

    // Load initial focused window data
    Process {
        id: initialFocusedWindowQuery
        command: ["niri", "msg", "-j", "focused-window"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) {
                    try {
                        const focusedData = JSON.parse(text.trim());
                        if (focusedData && focusedData.id) {
                            root.handleWindowFocusChanged({
                                id: focusedData.id
                            });
                            console.log("NiriService: Loaded initial focused window:", focusedData.id);
                        }
                    } catch (e) {
                        console.warn("NiriService: Failed to parse initial focused window data:", e);
                    }
                }
            }
        }
    }

    // Load initial keyboard layout data
    Process {
        id: initialKeyboardLayoutQuery
        command: ["niri", "msg", "-j", "keyboard-layouts"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) {
                    try {
                      const keyboardLayoutData = JSON.parse(text.trim());
                        if (keyboardLayoutData && keyboardLayoutData.names) {
                            root.allKeyboardLayouts = keyboardLayoutData.names;
                            root.handleKeyboardLayoutChanged({
                                idx: keyboardLayoutData.current_idx
                            });
                            console.log("NiriService: Loaded initial keyboard layouts:", keyboardLayoutData.names);
                        }
                    } catch (e) {
                        console.warn("NiriService: Failed to parse initial keyboard layouts data:", e);
                    }
                }
            }
        }
    }
    
    function loadInitialWorkspaceData() {
        console.log("NiriService: Loading initial workspace data...");
        initialKeyboardLayoutQuery.running = true;
        initialDataQuery.running = true;
        initialWindowsQuery.running = true;
        initialFocusedWindowQuery.running = true;
    }

    // Event stream for real-time updates
    Process {
        id: eventStreamProcess
        command: ["niri", "msg", "-j", "event-stream"]
        running: false // Will be enabled after niri check

        stdout: SplitParser {
            onRead: data => {
                try {
                    const event = JSON.parse(data.trim());
                    root.handleNiriEvent(event);
                } catch (e) {
                    console.warn("NiriService: Failed to parse event:", data, e);
                }
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0 && root.niriAvailable) {
                console.warn("NiriService: Event stream exited with code", exitCode, "restarting immediately");
                eventStreamProcess.running = true;
            }
        }
    }

    function handleNiriEvent(event) {
        if (event.WorkspacesChanged) {
            handleWorkspacesChanged(event.WorkspacesChanged);
        } else if (event.WorkspaceActivated) {
            handleWorkspaceActivated(event.WorkspaceActivated);
        } else if (event.WindowsChanged) {
            handleWindowsChanged(event.WindowsChanged);
        } else if (event.WindowClosed) {
            handleWindowClosed(event.WindowClosed);
        } else if (event.WindowFocusChanged) {
            handleWindowFocusChanged(event.WindowFocusChanged);
        } else if (event.WindowOpenedOrChanged) {
            handleWindowOpenedOrChanged(event.WindowOpenedOrChanged);
        } else if (event.OverviewOpenedOrClosed) {
            handleOverviewChanged(event.OverviewOpenedOrClosed);
        } else if (event.KeyboardLayoutSwitched) {
            handleKeyboardLayoutChanged(event.KeyboardLayoutSwitched);
        }
      }

    function handleKeyboardLayoutChanged(data) {
      currentKeyboardLayout = allKeyboardLayouts[data.idx].slice(0,2).toLowerCase();
    }

    function handleWorkspacesChanged(data) {
        allWorkspaces = [...data.workspaces].sort((a, b) => a.idx - b.idx);

        // Update focused workspace
        focusedWorkspaceIndex = allWorkspaces.findIndex(w => w.is_focused);
        if (focusedWorkspaceIndex >= 0) {
            var focusedWs = allWorkspaces[focusedWorkspaceIndex];
            focusedWorkspaceId = focusedWs.id;
            currentOutput = focusedWs.output || "";
        } else {
            focusedWorkspaceIndex = 0;
            focusedWorkspaceId = "";
        }

        updateCurrentOutputWorkspaces();
    }

    function handleWorkspaceActivated(data) {
        // Update focused workspace
        focusedWorkspaceId = data.id;
        focusedWorkspaceIndex = allWorkspaces.findIndex(w => w.id === data.id);

        if (focusedWorkspaceIndex >= 0) {
            var activatedWs = allWorkspaces[focusedWorkspaceIndex];

            // Update workspace states properly
            // First, deactivate all workspaces on this output
            for (var i = 0; i < allWorkspaces.length; i++) {
                if (allWorkspaces[i].output === activatedWs.output) {
                    allWorkspaces[i].is_active = false;
                    allWorkspaces[i].is_focused = false;
                }
            }

            // Then activate the new workspace
            allWorkspaces[focusedWorkspaceIndex].is_active = true;
            allWorkspaces[focusedWorkspaceIndex].is_focused = data.focused || false;

            currentOutput = activatedWs.output || "";

            updateCurrentOutputWorkspaces();

            // Force property change notifications
            allWorkspacesChanged();
        } else {
            focusedWorkspaceIndex = 0;
        }
    }

    function handleWindowsChanged(data) {
        windows = [...data.windows].sort((a, b) => a.id - b.id);
        updateFocusedWindow();
    }

    function handleWindowClosed(data) {
        windows = windows.filter(w => w.id !== data.id);
        updateFocusedWindow();
    }

    function handleWindowFocusChanged(data) {
        if (data.id) {
            focusedWindowId = data.id;
            focusedWindowIndex = windows.findIndex(w => w.id === data.id);
        } else {
            focusedWindowId = "";
            focusedWindowIndex = -1;
        }
        updateFocusedWindow();
    }

    function handleWindowOpenedOrChanged(data) {
        if (!data.window)
            return;

        const window = data.window;
        const existingIndex = windows.findIndex(w => w.id === window.id);

        if (existingIndex >= 0) {
            // Update existing window - create new array to trigger property change
            let updatedWindows = [...windows];
            updatedWindows[existingIndex] = window;
            windows = updatedWindows.sort((a, b) => a.id - b.id);
        } else {
            // Add new window
            windows = [...windows, window].sort((a, b) => a.id - b.id);
        }

        // Update focused window if this window is focused
        if (window.is_focused) {
            focusedWindowId = window.id;
            focusedWindowIndex = windows.findIndex(w => w.id === window.id);
        }

        updateFocusedWindow();

        // Emit signal for other services to listen to
        windowOpenedOrChanged(window);
    }

    function handleOverviewChanged(data) {
        inOverview = data.is_open;
    }

    function updateCurrentOutputWorkspaces() {
        if (!currentOutput) {
            currentOutputWorkspaces = allWorkspaces;
            return;
        }

        // Filter workspaces for current output
        var outputWs = allWorkspaces.filter(w => w.output === currentOutput);
        currentOutputWorkspaces = outputWs;
    }

    function updateFocusedWindow() {
        if (focusedWindowIndex >= 0 && focusedWindowIndex < windows.length) {
            var focusedWin = windows[focusedWindowIndex];
            focusedWindowTitle = focusedWin.title || "(Unnamed window)";
            focusedWindowClass = focusedWin.app_id || "";
        } else {
            focusedWindowTitle = "";
            focusedWindowClass = "Desktop";
        }
    }

    // Public API functions
    function switchToWorkspace(workspaceId) {
        if (!niriAvailable)
            return false;

        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", workspaceId.toString()]);
        return true;
    }

    function switchToWorkspaceUpDown(string) {
        if (!niriAvailable)
            return false;

        Quickshell.execDetached(["niri", "msg", "action", `focus-workspace-${string}`]);
        return true;
    }

    function toggleWindowFloating() {
        if (!niriAvailable)
            return false;

        Quickshell.execDetached(["niri", "msg", "action", `toggle-window-floating`]);
        return true;
    }

    function focusWindow(windowID) {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `focus-window`, `--id`, windowID.toString()]);
        return true;
    }

    function closeFocusedWindow() {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `close-window`]);
        return true;
    }

    function toggleWindowOpacity() {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `toggle-window-rule-opacity`]);
        return true;
    }
    function expandColumnToAvailable() {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `expand-column-to-available-width`]);
        return true;
    }
    function centerWindow() {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `center-window`]);
        return true;
    }
    function screenshotWindow() {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `screenshot-window`]);
        return true;
    }
    function keyboardShortcutsInhibitWindow() {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `toggle-keyboard-shortcuts-inhibit`]);
        return true;
    }
    function toggleWindowedFullscreen() {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `toggle-windowed-fullscreen`]);
        return true;
    }
    function toggleFullscreen() {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `fullscreen-window`]);
        return true;
    }
    function toggleMaximize() {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `maximize-column`]);
        return true;
    }

    function moveWindowToWorkspace(workspaceId) {
        if (!niriAvailable)
            return false;

        Quickshell.execDetached(["niri", "msg", "action", `move-window-to-workspace`, workspaceId.toString()]);
        return true;
    }

    function switchToWorkspaceByIndex(index) {
        if (!niriAvailable || index < 0 || index >= allWorkspaces.length)
            return false;

        var workspace = allWorkspaces[index];
        return switchToWorkspace(workspace.id);
    }

    function switchToWorkspaceByNumber(number, output) {
        if (!niriAvailable)
            return false;

        var targetOutput = output || currentOutput;
        if (!targetOutput) {
            console.warn("NiriService: No output specified for workspace switching");
            return false;
        }

        // Get workspaces for the target output, sorted by idx
        var outputWorkspaces = allWorkspaces.filter(w => w.output === targetOutput).sort((a, b) => a.idx - b.idx);

        // Use sequential index (number is 1-based, array is 0-based)
        if (number >= 1 && number <= outputWorkspaces.length) {
            var workspace = outputWorkspaces[number - 1];
            return switchToWorkspace(workspace.id);
        }

        console.warn("NiriService: No workspace", number, "found on output", targetOutput);
        return false;
    }

    function getWorkspaceByIndex(index) {
        if (index >= 0 && index < allWorkspaces.length) {
            return allWorkspaces[index];
        }
        return null;
    }

    function getWorkspaceCount() {
        return allWorkspaces.length;
    }

    function getCurrentOutputWorkspaceNumbers() {
        return currentOutputWorkspaces.map(w => w.idx + 1); // niri uses 0-based, UI shows 1-based
    }

    function getCurrentWorkspaceNumber() {
        if (focusedWorkspaceIndex >= 0 && focusedWorkspaceIndex < allWorkspaces.length) {
            return allWorkspaces[focusedWorkspaceIndex].idx + 1;
        }
        return 1;
    }
}

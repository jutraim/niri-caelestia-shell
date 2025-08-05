pragma ComponentBehavior: Bound

import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

IconImage {
    id: root

    property string colorOverride: ""
    property real brightnessOverride: 0.5
    property real contrastOverride: 1

    smooth: true
    asynchronous: true
    layer.enabled: colorOverride !== ""

    Process {
        running: true
        command: ["sh", "-c", ". /etc/os-release && echo $LOGO"]

        stdout: StdioCollector {
            onStreamFinished: () => {
                root.source = Quickshell.iconPath(this.text.trim());
            }
        }
    }

    layer.effect: MultiEffect {
        colorization: 1
        colorizationColor: root.colorOverride
        brightness: root.brightnessOverride
        contrast: root.contrastOverride
    }
}

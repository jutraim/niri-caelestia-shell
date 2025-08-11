import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property var lock
    property real centerScale

    anchors.fill: parent
    anchors.margins: Appearance.padding.large

    spacing: Appearance.spacing.large

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Appearance.rounding.small
            color: Colours.tPalette.m3surfaceContainer

            // WeatherInfo {}
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Appearance.rounding.small
            color: Colours.tPalette.m3surfaceContainer
        }
    }

    Center {
        Layout.leftMargin: -(1 - scale) * implicitWidth / 2
        Layout.rightMargin: -(1 - scale) * implicitWidth / 2
        scale: root.centerScale
        lock: root.lock
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Appearance.rounding.small
            color: Colours.tPalette.m3surfaceContainer
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Appearance.rounding.small
            color: Colours.tPalette.m3surfaceContainer
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}

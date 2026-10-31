import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

/**
 * ZyraxonOS app rail — a frosted glass box on the left edge of the screen
 * holding every installed application in a smooth, kinetic vertical scroller.
 *
 * It stays hidden until the pointer reaches the left edge (or it is pinned),
 * so it never gets in the way of windows. Clicking an icon launches the app.
 */
Scope {
    id: root

    property bool pinned: Config.options?.appRail?.pinnedOnStartup ?? false
    property int railWidth: Config.options?.appRail?.width ?? 62
    property int revealStrip: Config.options?.appRail?.hoverRegionWidth ?? 12

    readonly property var appList: Array.from(DesktopEntries.applications.values)
        .filter(app => app && !app.noDisplay)
        .sort((a, b) => (a.name || "").localeCompare(b.name || ""))

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: railRoot
            required property var modelData
            screen: modelData
            visible: !GlobalStates.screenLocked
            color: "transparent"
            WlrLayershell.namespace: "quickshell:appRail"

            anchors {
                top: true
                bottom: true
                left: true
            }

            // never reserve space: the rail floats over the wallpaper
            exclusiveZone: 0
            implicitWidth: railWidth + Appearance.sizes.elevationMargin * 2

            property bool revealed: root.pinned || railMouseArea.containsMouse || listView.hovered

            MouseArea {
                id: railMouseArea
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }
                width: railRoot.revealed ? parent.width : root.revealStrip
                hoverEnabled: true
                onClicked: root.pinned = !root.pinned
            }

            Item {
                id: railBackground
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                    leftMargin: Appearance.sizes.elevationMargin
                    topMargin: Appearance.sizes.elevationMargin
                    bottomMargin: Appearance.sizes.elevationMargin
                }
                implicitWidth: root.railWidth
                // slide out from the left edge when revealed
                x: railRoot.revealed ? 0 : -(root.railWidth + Appearance.sizes.elevationMargin)

                Behavior on x {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                StyledRectangularShadow {
                    target: railGlass
                }

                Rectangle {
                    id: railGlass
                    anchors.fill: parent
                    radius: Appearance.rounding.large
                    color: Appearance.colors.colLayer0
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                }

                StyledListView {
                    id: listView
                    anchors.fill: parent
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 4
                    orientation: ListView.Vertical
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 2500
                    maximumFlickVelocity: 6000

                    model: ScriptModel {
                        values: root.appList
                    }

                    delegate: Item {
                        id: appItem
                        required property var modelData
                        required property int index
                        width: ListView.view.width
                        height: 46

                        Rectangle {
                            id: iconChip
                            anchors.centerIn: parent
                            width: 40
                            height: 40
                            radius: Appearance.rounding.normal
                            color: appMouseArea.containsMouse
                                ? Appearance.colors.colLayer1Hover
                                : "transparent"

                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }

                            AppIcon {
                                anchors.centerIn: parent
                                implicitSize: 26
                                source: appItem.modelData.icon
                            }

                            ToolTip.visible: appMouseArea.containsMouse
                            ToolTip.text: appItem.modelData.name
                            ToolTip.delay: 400
                        }

                        MouseArea {
                            id: appMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (appItem.modelData && appItem.modelData.execute)
                                    appItem.modelData.execute();
                            }
                        }
                    }
                }
            }
        }
    }
}

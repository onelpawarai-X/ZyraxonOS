import QtQuick
import QtQuick.Effects

Item {
    id: root
    required property Item target
    property real radius: 0
    property real blur: 0
    property real spread: 0
    property vector2d offset: Qt.vector2d(0, 0)
    property color color: "black"
    property bool cached: true

    anchors.fill: target
    visible: target.visible
    z: -1

    Rectangle {
        id: src
        anchors.fill: parent
        anchors.leftMargin: -root.spread + root.offset.x
        anchors.topMargin: -root.spread + root.offset.y
        anchors.rightMargin: -root.spread - root.offset.x
        anchors.bottomMargin: -root.spread - root.offset.y
        radius: root.radius
        color: root.color
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        source: src
        anchors.fill: src
        shadowEnabled: true
        shadowColor: root.color
        shadowOpacity: 1.0
        shadowBlur: 0.6
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        blurMax: Math.max(16, root.blur * 4)
        opacity: 0.7
    }
}

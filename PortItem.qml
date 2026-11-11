import QtQuick 2.0

Item {
    id: itemPort
    property int portIndex: -1
    property bool portOut: true
    property bool positionLeft: false
    property bool connected: true
    property string namePort: "test"
    readonly property real portRadius: 8
    readonly property alias portArea: port
    Rectangle {
        id: port
        anchors.verticalCenter: parent.verticalCenter
        x: itemPort.positionLeft ? -(width / 2) : itemPort.width - (width / 2)
        width:  parent.height / 2
        height: width
        radius: 6
        border.color: "#16162a"
        border.width: 1.5
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    Text {
        id: lblPort
        text: namePort
        color: "#00ff88"
        font.pixelSize: 15
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: itemPort.positionLeft ? undefined : port.left
        anchors.left: itemPort.positionLeft ? port.right : undefined
        anchors.margins: 5

    }
}

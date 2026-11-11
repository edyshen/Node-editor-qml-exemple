import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Shapes 1.12

ApplicationWindow {
    id: window
    visible: true
    width: 1280
    height: 800
    title: "Node Editor"
    color: "#1e1e2e"

    readonly property real nodeWidth:  200
    readonly property real nodeHeader: 32
    readonly property real portRow:    26
    readonly property real portTop:    10
    readonly property real portSize:   30
    readonly property real portRadius: 6

    ListModel { id: nodesModel }
    ListModel { id: connectionsModel }

    property int revision: 0

    property bool  connecting: false
    property bool  isLeft: false
    property int   connSrcNode: -1
    property bool  connSrcIsOutput: false
    property int   connSrcPort: -1
    property point p1start: Qt.point(0, 0)
    property point connCur: Qt.point(0, 0)

    // Функция для определения высоты окна, в зависимости от колличество портов
    function nodeHeight(maxPort) {
        return nodeHeader + portTop * 2 + maxPort * portRow
    }
    // центровка порта по вертикали
    function portCenterY(portIndex) {
        return nodeHeader + portTop + portIndex * portRow + portRow / 2
    }

    function portPos(nodeId, leftSide, portIndex, _rev) {
        var node = nodesModel.get(nodeId)
        if (!node) return Qt.point(0, 0)
        var x = leftSide ? node.nx : node.nx + nodeWidth
        var y = node.ny + portCenterY(portIndex)
        return Qt.point(x, y)
    }

    function findPortAt(x, y) {
        var t = 16
        for (var i = 0; i < nodesModel.count; i++) {
            var node = nodesModel.get(i)
            console.log("count ports in  node ->", node.arrayPorts.count)
            for (var p = 0; p < node.arrayPorts.count; p++) {
                var prt = node.arrayPorts.get(p)
                var pp = portPos(i, prt.pleft, prt.order)
                if (Math.abs(pp.x - x) < t && Math.abs(pp.y - y) < t)
                {
                    return { nodeId: i, isOutput: prt.out, portIndex: prt.order, isLeft: prt.pleft}
                }
            }
        }
        console.log("Нихуя не нашёл!")
        return null
    }
    function addNode(x, y, t, prts, heightNode) {
        nodesModel.append({
                              nx: x, ny: y, title: t, arrayPorts: prts, maxRowPort: heightNode
                          })
    }
    /*
      расчитываю построить рхитектуру создания нодов
      указать координаты где создаются
      указать название нода
      перечислить порты входа и выхода после сторону где они будут распологаться
*/

    function startConnection(nodeId, isOutput, isLeftPort, portIndex, sx, sy) {
        connecting = true           // Статус, соединения началось или нет
        connSrcNode = nodeId        // id нода
        connSrcIsOutput = isOutput  // Входящий или исходящий порт
        connSrcPort = portIndex     // Индекс порта
        isLeft =    isLeftPort      // какая сторона
        connCur = Qt.point(sx, sy)  // Координаты порта
    }

    function updateConnection(sx, sy) {
        if (!connecting) return
        connCur = Qt.point(sx, sy)
    }

    function finishConnection(sx, sy, indx) {
        if (!connecting) return
        var target = findPortAt(sx, sy)
        if(target)
        {
            console.log(indx, "   ----   " ,target.nodeId )
            if(indx === target.nodeId){     // Запрещаю связывать порты внутри своего нода (только между нодами)
                connecting = false
                return
            }
        }
        if (target && target.isOutput !== connSrcIsOutput) {
            var sN, sP, dN, dP, sLeft, dLeft
//            console.log("----------START PORT----------")
//            console.log("start-left ->" , isLeft, "start-order->", connSrcPort)
//            console.log("start-prt.out " ,connSrcIsOutput)
//            console.log("----------Finder PORT----------")
//            console.log("target-left ->" , target.isLeft, " target-order->", target.portIndex)
//            console.log("target-prt.out " ,target.isOutput)
//            console.log("-------------------------------")
            if (connSrcIsOutput) {
//            if (!isLeft) {
                sN = connSrcNode; sP = connSrcPort ; sLeft = isLeft
                dN = target.nodeId; dP = target.portIndex ; dLeft = target.isLeft
            } else {
                sN = target.nodeId; sP = target.portIndex ; sLeft = target.isLeft
                dN = connSrcNode; dP = connSrcPort ; dLeft = isLeft
            }
            var exists = false
            for (var i = 0; i < connectionsModel.count; i++) {
                var c = connectionsModel.get(i)
                if (c.srcNode === sN && c.srcPort === sP &&
                        c.dstNode === dN && c.dstPort === dP) { exists = true; break }
            }
            if (!exists) {
                connectionsModel.append({
                                            srcNode: sN, srcPort: sP, srcLeft: sLeft,
                                            dstNode: dN, dstPort: dP, dstLeft: dLeft
                                        })
                //                revision++
            }
        }
        connecting = false
        connSrcNode = -1
    }

    function removeConnectionAt(i) {
        connectionsModel.remove(i)
        //        revision++
    }

    function isPortConnected(nodeId, isOutput, portIndex, _rev) {
        for (var i = 0; i < connectionsModel.count; i++) {
            var c = connectionsModel.get(i)
            if (isOutput) {
                if (c.srcNode === nodeId && c.srcPort === portIndex) return true
            } else {
                if (c.dstNode === nodeId && c.dstPort === portIndex) return true
            }
        }
        return false
    }


    Canvas {
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.fillStyle = "#999999"
            ctx.fillRect(0, 0, width, height)
            ctx.strokeStyle = "#26263a"
            ctx.lineWidth = 1
            for (var x = 0; x < width;  x += 50) {
                ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke()
            }
            for (var y = 0; y < height; y += 50) {
                ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
            }
        }
    }
    Item {      // Запихаю в итем что бы можно было перемещать
        id: world
        x: 0
        y: 0

        // ==== Связи ====
        Repeater {
            model: connectionsModel

            delegate: Item {
                id: connItem

                readonly property int   cIndex:     index
                readonly property int   cSrcNode:   srcNode
                readonly property int   cSrcPort:   srcPort
                readonly property bool  cSrcLeft :  srcLeft
                readonly property int   cDstNode:   dstNode
                readonly property int   cDstPort:   dstPort
                readonly property bool  cDstLeft :  dstLeft

                anchors.fill: parent
                z: 5

                property point p1: portPos(cSrcNode, cSrcLeft, cSrcPort, revision)
                property point p2: portPos(cDstNode, cDstLeft, cDstPort, revision)
                property real  cdx: Math.max(50, Math.abs(p2.x - p1.x) * 0.4)

                Shape {
                    anchors.fill: parent
                    antialiasing: true
                    ShapePath {
                        strokeColor: connMouse.containsMouse ? "#ff8080" : "#5aa9e6"
                        strokeWidth: connMouse.containsMouse ? 4 : 3
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap

                        startX: connItem.p1.x
                        startY: connItem.p1.y

                        PathCubic {
                            x: connItem.p2.x
                            y: connItem.p2.y
                            control1X: connItem.p1.x - (cSrcLeft? connItem.cdx : -connItem.cdx)
                            control1Y: connItem.p1.y
                            control2X: connItem.p2.x + (cDstLeft? -connItem.cdx : connItem.cdx)
                            control2Y: connItem.p2.y
                        }
                    }
                }

                MouseArea {
                    id: connMouse
                    anchors.fill: closeX
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }

                Rectangle {
                anchors.fill: closeX
                color: "#55ff6b6b"
                radius: closeX.radius
                }

                Rectangle {
                    id: closeX
                    visible: connMouse.containsMouse
                    x: (connItem.p1.x + connItem.p2.x) / 2 - 10
                    y: (connItem.p1.y + connItem.p2.y) / 2 - 10
                    width: 20; height: 20; radius: 10
                    color: "#ff6b6b"
                    border.color: "#661111"
                    z: 100

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: "white"
                        font.pixelSize: 14
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: closeX
                        cursorShape: Qt.PointingHandCursor
                        onClicked: removeConnectionAt(connItem.cIndex)
                    }
                }
            }
        }

        // ==== Резинка ====
        Item {
            id: pendingLayer
            z: 10
            visible: connecting
            property point p1: connecting
                               ? portPos(connSrcNode, isLeft, connSrcPort, revision)
                               : Qt.point(0, 0)
            property point p2: connCur

            Shape {
                anchors.fill: parent
                antialiasing: true
                // тоже без layer.*

                ShapePath {
                    strokeColor: "#88ff9c"
                    strokeWidth: 2.5
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    strokeStyle: ShapePath.DashLine
                    dashPattern: [6, 4]

                    startX: pendingLayer.p1.x
                    startY: pendingLayer.p1.y

                    PathCubic {
                        x: pendingLayer.p2.x
                        y: pendingLayer.p2.y
                        control1X: pendingLayer.p1.x + (!isLeft ?  60 : -60)
                        control1Y: pendingLayer.p1.y
                        control2X: pendingLayer.p2.x
                        control2Y: pendingLayer.p2.y
                    }
                }
            }
        }

        // ==== Узлы ====
        Repeater {
            model: nodesModel

            delegate: Item {
                id: nodeItem

                readonly property int    nodeId:      index
                readonly property real   nodeX:       nx
                readonly property real   nodeY:       ny
                readonly property string nodeTitle:   title
                readonly property var ports: arrayPorts
                opacity: headerDrag.drag.active ? 0.7 : 1
//                opacity: 0.3

                Component.onCompleted: {
                    console.log("NODE", index, "title:", title)
                    console.log("  arrayPorts:", arrayPorts)
                    console.log("  ports:", ports)
                    console.log("  ports.length:", ports ? ports.length : "n/a")
                    console.log("  maxRowPort:", maxRowPort)
                    console.log("  height:", height)
                    for(var i = 0; i < ports.count ; i++)
                    {
                    console.log(ports.get(i).out,ports.get(i).pleft,ports.get(i).portName)
                    }
                }

                x: nodeX
                y: nodeY
                width:  nodeWidth
                height: nodeHeight(maxRowPort)
                z: headerDrag.drag.active ? 100 : 20     // ← drag.active

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: "#708090"
                    border.color: "#4a4a6e"
                    border.width: 1

                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.margins: -3
                        radius: parent.radius + 3
                        color: "#00000060"
                    }
                }

                Rectangle {
                    id: headerRect
                    width:  parent.width
                    height: nodeHeader
                    radius: 8
                    color: headerDrag.drag.active ? "#4d4d7e" : "#3d3d5e"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 10
                        color: parent.color
                    }

                    Text {
                        anchors.centerIn: parent
                        text: nodeItem.nodeTitle
                        color: "#9ACD32"
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                // ============ DRAG (новое) ============
                MouseArea {
                    id: headerDrag
                    width:  parent.width
                    height: nodeHeader
                    cursorShape: Qt.OpenHandCursor
                    //                preventStealing: true

                    drag.target: nodeItem
                    drag.axis: Drag.XAndYAxis
//                    drag.minimumX: 0
//                    drag.minimumY: 0

                    onPositionChanged: {
                        if (drag.active) {
                            nodesModel.setProperty(nodeItem.nodeId, "nx", nodeItem.x)
                            nodesModel.setProperty(nodeItem.nodeId, "ny", nodeItem.y)
                            //                        revision++    // обязательно для обновления шнуров
                        }
                    }
                }
                // ---- Порты ----

                Repeater {
                    model: nodeItem.ports ? nodeItem.ports.count : 0
                    delegate: PortItem {
                        readonly property var portData: nodeItem.ports.get(index)
                        portIndex: index
                        portOut: portData.out
                        positionLeft: portData.pleft
                        connected: isPortConnected(nodeItem.nodeId, portOut, portData.order, revision)
                        portArea.color: portMAin.containsMouse ? "#88ddff" : (connected ? "#4a9eec" : "#666680")
                        width:  window.nodeWidth / 2
                        height: portSize
                        y: portCenterY(portData.order) - portSize / 2
                        anchors.left: positionLeft ? parent.left : undefined
                        anchors.right: positionLeft ? undefined : parent.right
                        namePort: portData.portName
                        z: 50

                        Component.onCompleted: {
                            console.log("    PORT", index, "node:", nodeItem.nodeId)
                            console.log("    portData:", nodeItem.ports ? nodeItem.ports[index] : "n/a")
                            console.log("    geom:", x, y, width, height)
                            console.log("    positionLeft:", positionLeft)
                            console.log("    name:", namePort)
                        }
                        MouseArea {
                            id: portMAin
                            anchors.fill: portArea
                            hoverEnabled: true
                            cursorShape: Qt.CrossCursor
                            preventStealing: true

                            onPressed: (mouse) => {
                                           var p = mapToItem(world, portArea.width / 2, portArea.height / 2)
                                           startConnection(nodeItem.nodeId, portOut, positionLeft, portData.order, p.x, p.y)
                                           console.log(portData.order)
                                       }
                            onPositionChanged: (mouse) => {
                                                   if (!pressed) return
                                                   var p = mapToItem(world, mouse.x, mouse.y)
                                                   updateConnection(p.x, p.y)
                                               }
                            onReleased: (mouse) => {
                                            var p = mapToItem(world, mouse.x, mouse.y)
                                            finishConnection(p.x, p.y, nodeItem.nodeId)
                                        }
                        }
                    }
                }
            }
        }
    }
    // isOut - какой порт , вход или выход
    // isLeft - Расположение порта, слева или справа
    // namePort - Имя порта
    function creatPort(isOut, isLeft, namePort) {
        return {
            out: isOut,
            pleft: isLeft,
            portName: namePort
        }
    }
    function creatNode(nameNode, ports){
        var countLeft=0
        var countRight = 0
        // пересоздам массив для распределения порядка портов на сторонах
        // (потребуется что бы через один репитер расположить по высоте порты)
        var tmpPorts = []
        for(var i = 0; i < ports.length; i++)   // подсчитаем колличество портов на сторонах
        {
            if(ports[i].pleft){
                tmpPorts.push({
                                  out: ports[i].out,
                                  pleft: ports[i].pleft,
                                  portName: ports[i].portName,
                                  order: countLeft
                              })
                countLeft++
            }else{
                tmpPorts.push({
                                  out: ports[i].out,
                                  pleft: ports[i].pleft,
                                  portName: ports[i].portName,
                                  order: countRight
                              })
                countRight++
            }
        }
        addNode(100,100,nameNode,tmpPorts, Math.max(countRight,countLeft))

        console.log(countLeft, "  -  " , countRight )
    }
    function devArinc(){
        var ports = []
        ports.push(creatPort(false,false,"ch1"))
        ports.push(creatPort(false,false,"ch2"))
        ports.push(creatPort(false,false,"ch3"))
        ports.push(creatPort(false,false,"ch4"))
        ports.push(creatPort(true,true,"usb1"))
        ports.push(creatPort(true,true,"usb2"))
        ports.push(creatPort(true,true,"usb3"))
        ports.push(creatPort(false,true,"usbIN"))
        creatNode("Arinc",ports)
    }
    MouseArea {
        id: panArea
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton        // только средняя кнопка
        cursorShape: Qt.ArrowCursor
        z: -1
        hoverEnabled: true
        drag.target: world                       // тащим «мир»
        drag.axis: Drag.XAndYAxis
        drag.threshold: 0                        // реагировать сразу
        onWheel: (wheel) => {
                     var factor = wheel.angleDelta.y > 0 ? 1.15 : 1/1.15
                     // Что бы при скалировании итем world увеличивался относительно курсора
                     world.x = mouseX - (mouseX - world.x) * factor
                     world.y = mouseY - (mouseY - world.y) * factor
                     // Ну и наконец скалируем сам итем world
                     world.scale *= factor
                 }

    }
    MouseArea {
        id: panAreas
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: {devArinc()}

    }

    Component.onCompleted: {
//        addNode(100, 100, "ARINC",    4, 1)
//        addNode(500, 150, "Transform", 2, 1)
        devArinc()
//        addNode(950, 300, "Sink",      1, 0)

//        connectionsModel.append({ srcNode: 0, srcPort: 0, dstNode: 1, dstPort: 0 })
//        connectionsModel.append({ srcNode: 1, srcPort: 0, dstNode: 2, dstPort: 0 })
        //        revision++
    }
}

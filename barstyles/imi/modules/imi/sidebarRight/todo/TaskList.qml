import "../../../common"
import "../../../common/widgets"
import "../../../../services"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    required property var taskList
    property string emptyPlaceholderIcon
    property string emptyPlaceholderText
    property int todoListItemSpacing: Appearance.spacing.space50
    property int todoListItemPadding: Appearance.spacing.space100
    property int listBottomPadding: 80

    StyledListView {
        id: listView
        anchors.fill: parent
        spacing: root.todoListItemSpacing
        model: ScriptModel {
            values: root.taskList
        }
        delegate: Item {
            id: todoItem
            required property var modelData
            property bool pendingDoneToggle: false
            property bool pendingDelete: false
            property bool enableHeightAnimation: false

            function resolveIndex(): int {
                const md = todoItem.modelData;
                const idx = Todo.list.indexOf(md);
                if (idx !== -1)
                    return idx;
                return Todo.list.findIndex(task =>
                    task.content === md.content && task.done === md.done);
            }

            implicitHeight: todoItemRectangle.implicitHeight
            width: ListView.view.width
            clip: true

            Behavior on implicitHeight {
                enabled: enableHeightAnimation
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }

            Rectangle {
                id: todoItemRectangle
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                implicitHeight: todoContentRowLayout.implicitHeight
                color: Appearance.colors.colLayer2
                radius: Appearance.rounding.small

                ColumnLayout {
                    id: todoContentRowLayout
                    anchors.left: parent.left
                    anchors.right: parent.right

                    StyledText {
                        id: todoContentText
                        Layout.fillWidth: true
                        Layout.leftMargin: Appearance.spacing.space150
                        Layout.rightMargin: Appearance.spacing.space150
                        Layout.topMargin: todoListItemPadding
                        text: todoItem.modelData.content
                        wrapMode: Text.Wrap
                    }
                    RowLayout {
                        Layout.leftMargin: Appearance.spacing.space150
                        Layout.rightMargin: Appearance.spacing.space150
                        Layout.bottomMargin: todoListItemPadding
                        Item {
                            Layout.fillWidth: true
                        }
                        TodoItemActionButton {
                            Layout.fillWidth: false
                            onClicked: {
                                const index = todoItem.resolveIndex();
                                if (index === -1)
                                    return;
                                if (!todoItem.modelData.done)
                                    Todo.markDone(index);
                                else
                                    Todo.markUnfinished(index);
                            }
                            contentItem: MaterialSymbol {
                                verticalAlignment: Text.AlignVCenter
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: todoItem.modelData.done ? "remove_done" : "check"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                        TodoItemActionButton {
                            Layout.fillWidth: false
                            onClicked: {
                                const index = todoItem.resolveIndex();
                                if (index !== -1)
                                    Todo.deleteItem(index);
                            }
                            contentItem: MaterialSymbol {
                                verticalAlignment: Text.AlignVCenter
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: "delete_forever"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }
            }
        }
    }

    PagePlaceholder {
        dropIconWhenCramped: true
        shown: root.taskList.length === 0
        icon: root.emptyPlaceholderIcon
        shape: MaterialShape.Shape.Ghostish
        title: root.emptyPlaceholderText
    }
}

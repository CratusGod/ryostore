import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import shell.services as RyokuServices
import "calendar_layout.js" as CalendarLayout
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property int monthShift: 0
    property int entranceTrigger: -1
    property int _entranceKey: 0
    property bool _entranceArmed: false
    Component.onCompleted: Qt.callLater(() => root._entranceArmed = true)
    onEntranceTriggerChanged: {
        if (root._entranceArmed)
            root._entranceKey++;
    }
    onMonthShiftChanged: _entranceKey++
    readonly property int dayCellSize: 36
    readonly property int firstDayOfWeek: Config.options.calendar.firstDayOfWeek
    property var viewingDate: CalendarLayout.getDateInXMonthsTime(monthShift)
    property var calendarLayout: CalendarLayout.getCalendarLayout(viewingDate, monthShift === 0, firstDayOfWeek)
    readonly property int viewingYear: viewingDate.getFullYear()
    readonly property int viewingMonth: viewingDate.getMonth() + 1
    function hasEventOn(day: int): bool {
        return RyokuServices.Events.hasEvents(
            root.viewingYear + "-" + root._pad2(root.viewingMonth) + "-" + root._pad2(day));
    }
    function _pad2(n: int): string {
        return (n < 10 ? "0" : "") + n;
    }
    readonly property int contentPadding: Appearance.spacing.space150

    width: calendarColumn.width
    implicitHeight: calendarColumn.height + contentPadding * 2

    Keys.onPressed: (event) => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp)
            && event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageDown) {
                monthShift++;
            } else if (event.key === Qt.Key_PageUp) {
                monthShift--;
            }
            event.accepted = true;
        }
    }
    MouseArea {
        anchors.fill: parent
        onWheel: (event) => {
            if (event.angleDelta.y > 0) {
                monthShift--;
            } else if (event.angleDelta.y < 0) {
                monthShift++;
            }
        }
    }

    ColumnLayout {
        id: calendarColumn
        anchors.top: parent.top
        anchors.topMargin: root.contentPadding
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Appearance.spacing.space75

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.space100
            CalendarHeaderButton {
                id: monthButton
                clip: true
                Layout.leftMargin: -labelInset
                buttonText: `${monthShift != 0 ? "• " : ""}${viewingDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")}`
                tooltipText: (monthShift === 0) ? "" : Translation.tr("Jump to current month")
                downAction: () => {
                    monthShift = 0;
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: false
            }
            CalendarHeaderButton {
                forceCircle: true
                downAction: () => {
                    monthShift--;
                }
                contentItem: MaterialSymbol {
                    verticalAlignment: Text.AlignVCenter
                    text: "chevron_left"
                    iconSize: Appearance.font.pixelSize.larger
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer1
                }
            }
            CalendarHeaderButton {
                forceCircle: true
                downAction: () => {
                    monthShift++;
                }
                contentItem: MaterialSymbol {
                    verticalAlignment: Text.AlignVCenter
                    text: "chevron_right"
                    iconSize: Appearance.font.pixelSize.larger
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        RowLayout {
            id: weekDaysRow
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: false
            spacing: Appearance.spacing.space75
            Repeater {
                model: CalendarLayout.getWeekDays(root.firstDayOfWeek)
                delegate: CalendarDayButton {
                    implicitWidth: root.dayCellSize
                    implicitHeight: root.dayCellSize
                    day: Translation.tr(modelData.day)
                    isToday: modelData.today
                    bold: true
                    enabled: false
                }
            }
        }

        Repeater {
            id: calendarRows
            model: 6
            delegate: RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: false
                spacing: Appearance.spacing.space75
                Repeater {
                    model: Array(7).fill(modelData)
                    delegate: CalendarDayButton {
                        implicitWidth: root.dayCellSize
                        implicitHeight: root.dayCellSize
                        gridRow: modelData
                        gridCol: index
                        entranceKey: root._entranceKey
                        day: calendarLayout[modelData][index].day
                        isToday: calendarLayout[modelData][index].today
                        hasEvent: calendarLayout[modelData][index].today !== -1
                            && root.hasEventOn(calendarLayout[modelData][index].day)
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../common"
import "../../common/widgets"
import "../../common/functions/weatherHourly.js" as WeatherHourly
import "../../common/functions/weatherForecast.js" as WeatherForecast

Rectangle {
    id: root
    objectName: "hourlyChart"

    required property bool charted

    readonly property real nowMs: {
        DateTime.minutes;
        return Date.now();
    }
    readonly property var slots: WeatherHourly.upcoming(Weather.hourly, root.nowMs, WeatherHourly.SLOT_COUNT)
    readonly property var range: WeatherHourly.chartRange(root.slots)
    readonly property bool twelveHour: WeatherHourly.usesTwelveHourClock(Config.options.time.format)

    visible: WeatherHourly.isRenderable(root.slots)
    Layout.fillWidth: true
    implicitHeight: contentRow.implicitHeight + Appearance.spacing.space100 * 2

    radius: Appearance.rounding.small
    color: Appearance.colors.colSurfaceContainerHigh

    RowLayout {
        id: contentRow
        anchors {
            fill: parent
            margins: Appearance.spacing.space100
        }
        spacing: Appearance.spacing.space50
        uniformCellSizes: true

        Repeater {
            model: root.slots

            ColumnLayout {
                id: slotColumn
                required property var modelData
                Layout.fillWidth: true
                spacing: Appearance.spacing.space25

                readonly property var fraction: WeatherHourly.barFraction(slotColumn.modelData.temp,
                                                                         root.range.low, root.range.high)

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: slotColumn.modelData.temp === null
                        ? "–" : `${Math.round(slotColumn.modelData.temp)}°`
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnSurfaceVariant
                }

                Item {
                    id: track
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36

                    Rectangle {
                        id: bar
                        objectName: "hourlyBar"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: Math.min(12, track.width)
                        radius: Appearance.rounding.verysmall
                        color: Appearance.colors.colPrimary
                        height: (root.charted && slotColumn.fraction !== null)
                            ? slotColumn.fraction * track.height : 0

                        Behavior on height {
                            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                        }
                    }
                }

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: Icons.getProviderWeatherIcon(Weather.provider, slotColumn.modelData.wCode,
                                                       Icons.isNightAt(slotColumn.modelData.hour))
                    iconSize: Appearance.font.pixelSize.smaller
                    fill: 0
                    color: Appearance.colors.colOnSurfaceVariant
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: slotColumn.modelData.dayBreak
                        ? WeatherForecast.shortDayName(slotColumn.modelData.date, Qt.locale())
                        : WeatherHourly.hourLabel(slotColumn.modelData.hour, root.twelveHour)
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colOnSurfaceVariant
                    opacity: 0.7
                }
            }
        }
    }
}

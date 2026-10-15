import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import "../../../.."
import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import "../../../common/functions"

ContentPage {
    id: root
    forceWidth: true
    bottomContentPadding: 35

    property string appVersion: "dev"
    FileView {
        id: versionFile
        path: Qt.resolvedUrl(Quickshell.shellPath("VERSION"))
        onLoaded: {
            const v = (versionFile.text() || "").trim();
            if (v.length > 0) root.appVersion = v;
        }
    }

    property string changelogText: ""
    property bool changelogExpanded: false
    readonly property var changelogParsed: {
        if (!root.changelogText) return { title: "", body: "" };
        const lines = root.changelogText.split("\n");
        const starts = [];
        for (let i = 0; i < lines.length; i++)
            if (lines[i].startsWith("## ")) starts.push(i);
        if (starts.length === 0) return { title: "", body: "" };
        const end = starts.length > 2 ? starts[2] : lines.length;
        return {
            title: lines[starts[0]].replace(/^## /, "").replace(/[\[\]]/g, ""),
            body: lines.slice(starts[0] + 1, end).join("\n").trim()
        };
    }
    FileView {
        id: changelogFile
        path: `${Directories.suiteSrc}/CHANGELOG.md`
        onLoaded: root.changelogText = changelogFile.text() || ""
    }

    function runSystemUpdate() {
        Quickshell.execDetached([
            "kitty", "--hold",
            "fish", "-i", "-l", "-c",
            "yay -Syu --combinedupgrade=false"
        ])
        Qt.callLater(() => GlobalStates.settingsOpen = false)
    }

    function runUpdateDots() {
        Quickshell.execDetached([
            "kitty", "--hold",
            "fish", "-i", "-l", "-c",
            "ryoku update"
        ])
        Qt.callLater(() => GlobalStates.settingsOpen = false)
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 156 
        Layout.topMargin: Appearance.spacing.space450
        Layout.leftMargin: Appearance.spacing.space200
        Layout.rightMargin: Appearance.spacing.space200

        radius: 24
        color: Appearance.colors.colLayer1

        RowLayout {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Appearance.spacing.space300
            spacing: Appearance.spacing.space300

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 110
                implicitHeight: 110
                radius: 20
                color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.9)

                IconImage {
                    anchors.centerIn: parent
                    implicitWidth: 72
                    implicitHeight: 72
                    source: Qt.resolvedUrl("../../../../assets/icons/ryoku-symbolic.svg")
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Appearance.spacing.space50

                StyledText {
                    Layout.fillWidth: true
                    text: SystemInfo.distroName
                    font.pixelSize: Appearance.font.pixelSize.hugeass
                    font.weight: Font.ExtraBold
                    color: Appearance.colors.colOnSurface
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: "Kernel " + (SystemInfo.kernelVersion || "Loading...")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: "Imi"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: "XephyLon | By dodo986"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }

                Row {
                    id: colorRow
                    spacing: -Appearance.spacing.space100

                    Repeater {
                        model: [
                            Appearance.m3colors.m3primary,
                            Appearance.m3colors.m3secondary,
                            Appearance.m3colors.m3tertiary,
                            Appearance.m3colors.m3error,
                            Appearance.m3colors.m3primaryContainer,
                            Appearance.m3colors.m3secondaryContainer,
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: 28
                            height: 28
                            radius: width / 2
                            color: modelData
                            z: index
                            border.width: Appearance.borderWidth.emphasis
                            border.color: Appearance.colors.colLayer1
                        }
                    }
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                spacing: Appearance.spacing.space100
                DialogButton {
                    buttonText: Translation.tr("Update Dots")
                    colBackground: Appearance.colors.colPrimaryContainer
                    colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                    colRipple: Appearance.colors.colPrimaryContainerActive
                    colText: Appearance.colors.colOnPrimaryContainer
                    Layout.preferredHeight: 44
                    downAction: () => runUpdateDots()
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.space100

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.space100

            AboutCard {
                icon: "planner_review"
                iconShape: MaterialShape.Shape.Pentagon
                label: "CPU"
                value: SystemInfo.cpu || "Loading..."
                Layout.fillWidth: true
            }

            AboutCard {
                icon: "monitor"
                iconShape: MaterialShape.Shape.ClamShell
                label: "GPU"
                value: SystemInfo.gpu || "N/A"
                Layout.fillWidth: true
            }
        }

        GridLayout {
            columns: 2
            Layout.fillWidth: true
            rowSpacing: Appearance.spacing.space100
            columnSpacing: Appearance.spacing.space100

            AboutCard {
                icon: "memory"
                label: "Memory"
                value: SystemInfo.memory || "Loading..."
                Layout.fillWidth: true
            }

            AboutCard {
                icon: "storage"
                iconShape: MaterialShape.Shape.Cookie6Sided
                label: "Disk"
                value: SystemInfo.disk || "Loading..."
                Layout.fillWidth: true
            }

            AboutCard {
                icon: "terminal"
                label: "Shell"
                iconShape: MaterialShape.Shape.Gem
                value: SystemInfo.shell || "Loading..."
                Layout.fillWidth: true
            }

            AboutCard {
                icon: "package_2"
                label: "Packages"
                iconShape: MaterialShape.Shape.Sunny
                value: SystemInfo.packages || "Loading..."
                Layout.fillWidth: true
            }

            AboutCard {
                icon: "update"
                label: "Updates"
                iconShape: MaterialShape.Shape.Cookie9Sided
                value: Updates.checking ? "Checking..." : (Updates.count === 0 ? "Up to date" : `${Updates.count}`)
                Layout.fillWidth: true
                clickAction: () => {
                    runSystemUpdate()
                }
            }

            AboutCard {
                icon: "timelapse"
                label: "Uptime"
                iconShape: MaterialShape.Shape.Cookie12Sided
                value: DateTime.uptime || "Loading..."
                Layout.fillWidth: true
            }
        }
    }

    Rectangle {
        visible: root.changelogParsed.body !== ""
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing.space200
        Layout.leftMargin: Appearance.spacing.space200
        Layout.rightMargin: Appearance.spacing.space200
        Layout.preferredHeight: whatsNewColumn.implicitHeight + Appearance.spacing.space300 * 2

        radius: 24
        color: Appearance.colors.colLayer1

        ColumnLayout {
            id: whatsNewColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: Appearance.spacing.space300
            }
            spacing: Appearance.spacing.space200

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.space200

                MaterialSymbol {
                    text: "new_releases"
                    iconSize: Appearance.font.pixelSize.huge
                    color: Appearance.colors.colPrimary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    StyledText {
                        text: Translation.tr("What's new")
                        font.pixelSize: Appearance.font.pixelSize.larger
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnSurface
                    }
                    StyledText {
                        text: root.changelogParsed.title
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }

                DialogButton {
                    buttonText: Translation.tr("Full changelog")
                    colBackground: Appearance.colors.colLayer2
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colRipple: Appearance.colors.colLayer2Active
                    colText: Appearance.colors.colOnLayer2
                    onClicked: Qt.openUrlExternally("https://github.com/ryoku-dev/ryostore/tree/main/barstyles/imi")
                }

                IconButton {
                    buttonSize: 36
                    buttonIcon: "expand_more"
                    colText: Appearance.colors.colOnLayer2
                    colBackground: Appearance.colors.colLayer2
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colRipple: Appearance.colors.colLayer2Active
                    rotation: root.changelogExpanded ? 180 : 0
                    Behavior on rotation {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    onClicked: root.changelogExpanded = !root.changelogExpanded
                }
            }

            StyledText {
                visible: root.changelogExpanded
                Layout.fillWidth: true
                text: root.changelogParsed.body
                textFormat: Text.MarkdownText
                wrapMode: Text.WordWrap
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
                onLinkActivated: link => Qt.openUrlExternally(link)
                PointingHandLinkHover {}
            }
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import "phone_cards.js" as PhoneCards

ColumnLayout {
    id: root

    readonly property string mode: {
        if (!PhoneDeps.ready)
            return "";
        if (!PhoneDeps.adbPresent)
            return "absent";
        if (PhoneDeps.adbRunError.length > 0)
            return "broken";
        if (!PhoneDeps.adbDevice)
            return "noDevice";
        return "";
    }

    readonly property bool shown: root.mode.length > 0

    readonly property var adbDependency: PhoneDeps.dependency("android-tools")
    readonly property string adbInstallCommand:
        PhoneCards.firstCommand(PhoneCards.commandFor(root.adbDependency,
                                                      PhoneCards.initialDistro(PhoneDeps.distro)))

    readonly property string knownHost: PhoneDeps.preferredWirelessHost()

    property string pairSuggested: ""
    property string connectSuggested: ""

    function offerPairAddress(next: string): void {
        if (next.length === 0)
            return;
        if (pairAddressField.text.length > 0 && pairAddressField.text !== root.pairSuggested)
            return;
        pairAddressField.text = next;
        root.pairSuggested = next;
    }

    function offerConnectAddress(next: string): void {
        if (next.length === 0)
            return;
        if (connectAddressField.text.length > 0 && connectAddressField.text !== root.connectSuggested)
            return;
        connectAddressField.text = next;
        root.connectSuggested = next;
    }

    function offerEverythingKnown(): void {
        root.offerPairAddress(PhoneDeps.mdnsPairingAddress.length > 0
                              ? PhoneDeps.mdnsPairingAddress : root.knownHost);
        root.offerConnectAddress(PhoneDeps.mdnsConnectAddress.length > 0
                                 ? PhoneDeps.mdnsConnectAddress : root.knownHost);
    }

    Component.onCompleted: root.offerEverythingKnown()
    onKnownHostChanged: root.offerEverythingKnown()

    Connections {
        target: PhoneDeps

        function onMdnsPairingAddressChanged(): void {
            root.offerPairAddress(PhoneDeps.mdnsPairingAddress);
        }

        function onMdnsConnectAddressChanged(): void {
            root.offerConnectAddress(PhoneDeps.mdnsConnectAddress);
        }
    }

    Layout.fillWidth: true
    Layout.fillHeight: false
    spacing: Appearance.spacing.space100

    NoticeBox {
        id: diagnosis

        Layout.fillWidth: true
        colBackground: Appearance.colors.colErrorContainer
        colOnBackground: Appearance.colors.colOnErrorContainer
        materialIcon: root.mode === "broken" ? "warning" : "usb_off"
        text: {
            if (root.mode === "absent")
                return Translation.tr("App Mode starts each app over ADB, and adb is not installed on this machine.");
            if (root.mode === "broken")
                return Translation.tr("adb is installed and cannot start: the dynamic loader cannot find %1. The package was built against an older library than this system ships, so it needs rebuilding or reinstalling.").arg(PhoneDeps.adbRunError);
            return Translation.tr("App Mode starts each app over ADB, and no phone is on ADB. Pairing in KDE Connect does not do it: that link carries notifications and files, not debugging.");
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            spacing: Appearance.spacing.space75

            StyledText {
                id: installCommandLabel
                Layout.fillWidth: true
                visible: (root.mode === "absent" || root.mode === "broken")
                    && root.adbInstallCommand.length > 0
                textFormat: Text.PlainText
                text: root.adbInstallCommand
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnErrorContainer
                wrapMode: Text.WrapAnywhere
            }

            StyledText {
                id: usbRouteTitle
                Layout.fillWidth: true
                visible: root.mode === "noDevice"
                text: Translation.tr("Over a USB cable")
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnErrorContainer
                wrapMode: Text.WordWrap
            }

            StyledText {
                id: usbRouteBody
                Layout.fillWidth: true
                visible: root.mode === "noDevice"
                text: Translation.tr("Settings → System → Developer options → USB debugging. Plug the cable in and accept the fingerprint the phone asks about.")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnErrorContainer
                wrapMode: Text.WordWrap
            }
        }
    }

    ContentSubsection {
        id: wirelessSection

        visible: root.mode === "noDevice"
        title: Translation.tr("Pair over Wi-Fi")
        icon: "wifi_tethering"

        StyledText {
            id: wirelessIntro
            Layout.fillWidth: true
            text: Translation.tr("On the phone: Developer options → Wireless debugging → Pair device with pairing code. That screen shows an address and a six-digit code; the main Wireless debugging screen shows a different port for the second step. Android picks new ports every time the switch is turned off and on.")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
        }

        Rectangle {
            id: formCard

            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.space50
            implicitHeight: formColumn.implicitHeight + Appearance.spacing.space150 * 2
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2

            ColumnLayout {
                id: formColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: Appearance.spacing.space150
                }
                spacing: Appearance.spacing.space75

                StyledText {
                    id: pairStepLabel
                    Layout.fillWidth: true
                    text: Translation.tr("1 · Pairing address and code")
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    spacing: Appearance.spacing.space75

                    ToolbarTextField {
                        id: pairAddressField
                        Layout.fillWidth: true
                        enabled: PhoneDeps.pairState !== "busy"
                        placeholderText: Translation.tr("192.168.1.42:37129")
                    }

                    ToolbarTextField {
                        id: pairCodeField
                        Layout.fillWidth: false
                        Layout.preferredWidth: Appearance.font.pixelSize.huge * 5
                        enabled: PhoneDeps.pairState !== "busy"
                        maximumLength: 6
                        inputMethodHints: Qt.ImhDigitsOnly
                        placeholderText: Translation.tr("123456")
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    spacing: Appearance.spacing.space75

                    RippleButtonWithIcon {
                        id: pairButton
                        enabled: PhoneDeps.pairState !== "busy"
                            && PhoneDeps.pairInputsReady(pairAddressField.text, pairCodeField.text)
                        materialIcon: "link"
                        materialIconFill: false
                        colBackground: Appearance.colors.colLayer3
                        colBackgroundHover: Appearance.colors.colLayer3Hover
                        colRipple: Appearance.colors.colLayer3Active
                        mainText: PhoneDeps.pairState === "busy"
                            ? Translation.tr("Pairing…") : Translation.tr("Pair")
                        onClicked: PhoneDeps.pairWireless(pairAddressField.text, pairCodeField.text)
                    }

                    RippleButtonWithIcon {
                        id: discoverButton
                        visible: PhoneDeps.avahiBrowse
                        enabled: PhoneDeps.mdnsState !== "searching"
                        materialIcon: "wifi_find"
                        materialIconFill: false
                        colBackground: Appearance.colors.colLayer3
                        colBackgroundHover: Appearance.colors.colLayer3Hover
                        colRipple: Appearance.colors.colLayer3Active
                        mainText: PhoneDeps.mdnsState === "searching"
                            ? Translation.tr("Looking…") : Translation.tr("Find the ports")
                        onClicked: PhoneDeps.discoverWirelessPorts()

                        StyledToolTip {
                            text: Translation.tr("Ask the network which ports the phone is advertising")
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                StatusLine {
                    id: discoveryStatus
                    shownWhen: PhoneDeps.avahiBrowse && PhoneDeps.mdnsState !== "idle"
                    glyph: PhoneDeps.mdnsState === "searching" ? "search"
                        : (PhoneDeps.mdnsPairingAddress.length > 0
                           || PhoneDeps.mdnsConnectAddress.length > 0) ? "check_circle" : "info"
                    message: {
                        if (PhoneDeps.mdnsState === "searching")
                            return Translation.tr("Asking the network…");
                        if (PhoneDeps.mdnsPairingAddress.length === 0
                            && PhoneDeps.mdnsConnectAddress.length === 0)
                            return Translation.tr("Nothing is advertising wireless debugging. The pairing screen only advertises while it is open, so leave it on the phone and try again.");
                        if (PhoneDeps.mdnsPairingAddress.length === 0)
                            return Translation.tr("Found the connect port. The pairing one is only advertised while the pairing screen is open on the phone.");
                        return Translation.tr("Found both ports.");
                    }
                }

                StatusLine {
                    id: pairStatus
                    shownWhen: PhoneDeps.pairState === "ok" || PhoneDeps.pairState === "failed"
                    glyph: PhoneDeps.pairState === "ok" ? "check_circle" : "error"
                    message: PhoneDeps.pairMessage
                }

                StyledText {
                    id: connectStepLabel
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.space50
                    text: Translation.tr("2 · Connect address, from the Wireless debugging screen")
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    spacing: Appearance.spacing.space75

                    ToolbarTextField {
                        id: connectAddressField
                        Layout.fillWidth: true
                        enabled: PhoneDeps.connectState !== "busy"
                        placeholderText: Translation.tr("192.168.1.42:41235")
                    }

                    RippleButtonWithIcon {
                        id: connectButton
                        enabled: PhoneDeps.connectState !== "busy"
                            && PhoneDeps.connectInputReady(connectAddressField.text)
                        materialIcon: "power"
                        materialIconFill: false
                        colBackground: Appearance.colors.colLayer3
                        colBackgroundHover: Appearance.colors.colLayer3Hover
                        colRipple: Appearance.colors.colLayer3Active
                        mainText: PhoneDeps.connectState === "busy"
                            ? Translation.tr("Connecting…") : Translation.tr("Connect")
                        onClicked: PhoneDeps.connectWireless(connectAddressField.text)
                    }
                }

                StatusLine {
                    id: connectStatus
                    shownWhen: PhoneDeps.connectState === "ok" || PhoneDeps.connectState === "failed"
                    glyph: PhoneDeps.connectState === "ok" ? "check_circle" : "error"
                    message: PhoneDeps.connectMessage
                }

                StyledText {
                    id: closingNote
                    Layout.fillWidth: true
                    text: Translation.tr("The tab keeps asking while it is open. As soon as a device answers, this goes and the app list is fetched on its own.")
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    component StatusLine: RowLayout {
        id: statusLine

        property bool shownWhen: false
        property string glyph: "info"
        property string message: ""

        Layout.fillWidth: true
        Layout.fillHeight: false
        visible: statusLine.shownWhen && statusLine.message.length > 0
        spacing: Appearance.spacing.space50

        MaterialSymbol {
            Layout.alignment: Qt.AlignTop
            text: statusLine.glyph
            iconSize: Appearance.font.pixelSize.normal
            color: statusLine.glyph === "error"
                ? Appearance.colors.colError : Appearance.colors.colSubtext
        }

        StyledText {
            Layout.fillWidth: true
            textFormat: Text.PlainText
            text: statusLine.message
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: statusLine.glyph === "error"
                ? Appearance.colors.colError : Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
        }
    }
}

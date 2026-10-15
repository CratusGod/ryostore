pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import "../../phone"
import "phone_cards.js" as PhoneCards

Item {
    id: root

    signal openPage(string id)

    implicitHeight: stack.implicitHeight

    readonly property bool showCards: Config.options.phone?.showPeripheralCards ?? true
    readonly property var activeDevice: PhoneConnect.activeDevice
    readonly property bool deviceReachable: PhoneConnect.activeDevice?.reachable === true
    readonly property var adbDevice: PhoneDeps.ready ? PhoneDeps.adbDevice : undefined

    property real nowMs: Date.now()
    readonly property bool anyActive: PhoneScrcpy.mirrorRunning || PhoneCamera.active || PhoneMic.active

    Timer {
        interval: 1000
        repeat: true
        running: root.anyActive && root.visible
        onTriggered: root.nowMs = Date.now()
    }

    onAnyActiveChanged: root.nowMs = Date.now()

    Timer {
        interval: 5000
        repeat: true
        running: root.visible && PhoneDeps.adb && !PhoneDeps.adbDevice
        onTriggered: PhoneDeps.refreshAdbDevices()
    }

    readonly property real mirrorStartedAtMs: {
        const count = PhoneScrcpy.sessionCount;
        if (count === 0)
            return 0;
        const index = PhoneScrcpy.sessionIndex("mirror");
        return index >= 0 ? Number(PhoneScrcpy.sessions.get(index).startedAt) : 0;
    }

    function openInstallGuide(feature: string, title: string): void {
        installGuide.feature = feature;
        installGuide.headerTitle = title;
        installGuide.shown = true;
    }

    ColumnLayout {
        id: stack
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        spacing: Appearance.spacing.space100

        PhoneFeatureCard {
            id: mirrorCard
            Layout.fillWidth: true
            visible: root.showCards

            readonly property var flags: ({
                available: PhoneScrcpy.available,
                reachable: root.deviceReachable,
                running: PhoneScrcpy.mirrorRunning,
                launching: PhoneScrcpy.mirrorLaunching,
                adbDevice: root.adbDevice,
                error: PhoneScrcpy.mirrorError
            })

            iconName: "smart_display"
            iconShape: MaterialShape.Shape.Cookie9Sided
            cardState: PhoneCards.mirrorState(mirrorCard.flags)
            title: {
                switch (PhoneCards.mirrorTitleKey(mirrorCard.flags)) {
                case "install":
                    return Translation.tr("Install scrcpy");
                case "running":
                    return Translation.tr("scrcpy Mirror");
                case "connecting":
                    return Translation.tr("Connecting scrcpy…");
                default:
                    return Translation.tr("Open scrcpy Mirror");
                }
            }
            subtitle: {
                switch (PhoneCards.mirrorSubtitleKey(mirrorCard.flags)) {
                case "install":
                    return Translation.tr("Click to see missing dependencies and install guide");
                case "offline":
                    return Translation.tr("Pair a reachable device to mirror its screen");
                case "noDevice":
                    return Translation.tr("No device over ADB · turn on USB or wireless debugging");
                case "error":
                    return PhoneCards.errorHeadline(PhoneScrcpy.mirrorError);
                case "running":
                    return Translation.tr("Mirror is running · click to focus its window");
                case "launching":
                    return Translation.tr("Launching scrcpy…");
                default:
                    return Translation.tr("Opens a floating window for the active phone");
                }
            }
            detailLine: PhoneScrcpy.mirrorRunning && root.mirrorStartedAtMs > 0
                ? Translation.tr("Active for %1").arg(PhoneCards.formatElapsed(root.nowMs - root.mirrorStartedAtMs))
                : ""
            lastError: ""
            inlineActions: [
                {
                    icon: "center_focus_strong",
                    label: Translation.tr("Focus the mirror window"),
                    action: () => PhoneScrcpy.focusMirror()
                }
            ]
            dropEnabled: root.deviceReachable && PhoneConnect.canShare
            onFilesDropped: urls => PhoneConnect.shareUrls(root.activeDevice, urls)

            onClicked: {
                if (!PhoneScrcpy.available) {
                    root.openInstallGuide("mirror", Translation.tr("scrcpy Mirror — missing dependencies"));
                    return;
                }
                if (PhoneScrcpy.mirrorLaunching)
                    return;
                PhoneScrcpy.launchMirror();
            }
            onStopClicked: PhoneScrcpy.stopMirror()
        }

        PhoneFeatureCard {
            id: webcamCard
            Layout.fillWidth: true
            visible: root.showCards

            readonly property var flags: ({
                available: PhoneCamera.available,
                reachable: root.deviceReachable,
                connecting: PhoneCamera.connecting,
                active: PhoneCamera.active,
                device: PhoneCamera.device,
                error: PhoneCamera.lastError
            })

            iconName: "videocam"
            iconShape: MaterialShape.Shape.Cookie7Sided
            hasSettings: true
            cardState: PhoneCamera.state
            title: PhoneCards.webcamTitleKey(PhoneCamera.available) === "install"
                ? Translation.tr("Install DroidCam")
                : Translation.tr("Phone Webcam")
            subtitle: {
                switch (PhoneCards.webcamSubtitleKey(webcamCard.flags)) {
                case "install":
                    return Translation.tr("Click to see missing dependencies and install guide");
                case "offline":
                    return Translation.tr("Pair a reachable device to use its camera");
                case "connecting":
                    return Translation.tr("Connecting to the phone's camera…");
                case "device":
                    return PhoneCamera.device;
                case "running":
                    return Translation.tr("Streaming from the phone's camera");
                case "error":
                    return PhoneCards.errorHeadline(PhoneCamera.lastError);
                default:
                    return Translation.tr("Tap to start · settings to configure");
                }
            }
            detailLine: {
                if (!PhoneCamera.active)
                    return "";
                const elapsed = PhoneCards.formatElapsed(PhoneCards.elapsedMs(PhoneCamera.startedAt, root.nowMs));
                const target = (PhoneCamera.activeIp || Translation.tr("usb")) + ":" + PhoneCamera.activePort;
                return Translation.tr("Active for %1 · %2 · %3")
                    .arg(elapsed).arg(target).arg(PhoneCamera.device || "—");
            }
            lastError: PhoneCamera.lastError
            inlineActions: [
                {
                    icon: "preview",
                    label: Translation.tr("Open a preview window"),
                    action: () => PhoneCamera.openPreview()
                },
                {
                    icon: "cameraswitch",
                    label: Translation.tr("Switch the camera the app uses"),
                    action: () => PhoneCamera.flip()
                }
            ]

            onClicked: {
                if (!PhoneCamera.available) {
                    root.openInstallGuide("webcam", Translation.tr("Phone Webcam — missing dependencies"));
                    return;
                }
                PhoneCamera.toggle();
            }
            onSettingsClicked: root.openPage("webcam")
            onStopClicked: PhoneCamera.stop()
        }

        PhoneFeatureCard {
            id: micCard
            Layout.fillWidth: true
            visible: root.showCards

            readonly property var flags: ({
                available: PhoneMic.available,
                reachable: root.deviceReachable,
                connecting: PhoneMic.connecting,
                active: PhoneMic.active,
                muted: PhoneMic.muted,
                needsAdbDevice: PhoneMic.preferredBackend === "scrcpy",
                adbDevice: root.adbDevice,
                error: PhoneMic.lastError
            })

            iconName: "mic"
            iconShape: MaterialShape.Shape.Sunny
            hasSettings: true
            cardState: PhoneCards.micState(micCard.flags)
            title: PhoneCards.micTitleKey(PhoneMic.available) === "install"
                ? Translation.tr("Install scrcpy or DroidCam")
                : Translation.tr("Phone Microphone")
            subtitle: {
                switch (PhoneCards.micSubtitleKey(micCard.flags)) {
                case "install":
                    return Translation.tr("Click to see missing dependencies and install guide");
                case "offline":
                    return Translation.tr("Pair a reachable device to use its microphone");
                case "connecting":
                    return Translation.tr("Setting up audio routing…");
                case "muted":
                    return Translation.tr("Muted · click to unmute");
                case "active":
                    return Translation.tr("Active · click to mute");
                case "noDevice":
                    return Translation.tr("No device over ADB · turn on USB or wireless debugging");
                case "error":
                    return PhoneCards.errorHeadline(PhoneMic.lastError);
                default:
                    return Translation.tr("Tap to start · uses scrcpy or DroidCam");
                }
            }
            detailLine: {
                if (!PhoneMic.active)
                    return "";
                const elapsed = PhoneCards.formatElapsed(PhoneCards.elapsedMs(PhoneMic.startedAt, root.nowMs));
                const suffix = PhoneMic.isDefaultInput ? Translation.tr("default input") : PhoneMic.backend;
                return Translation.tr("Active for %1 · %2% · %3")
                    .arg(elapsed).arg(PhoneMic.gain).arg(suffix);
            }
            lastError: PhoneMic.lastError
            inlineActions: [
                {
                    icon: PhoneMic.muted ? "mic_off" : "mic",
                    label: PhoneMic.muted ? Translation.tr("Unmute") : Translation.tr("Mute"),
                    action: () => PhoneMic.toggleMute()
                },
                {
                    icon: "tune",
                    label: Translation.tr("Gain: %1%").arg(PhoneMic.gain),
                    action: () => {
                        const gain = PhoneMic.gain;
                        PhoneMic.setGain(gain < 100 ? 100 : gain < 150 ? 150 : gain < 200 ? 200 : 50);
                    }
                },
                {
                    icon: PhoneMic.isDefaultInput ? "star" : "star_border",
                    label: PhoneMic.isDefaultInput
                        ? Translation.tr("Restore the previous default input")
                        : Translation.tr("Set as the default input"),
                    action: () => {
                        if (PhoneMic.isDefaultInput)
                            PhoneMic.restoreDefaultInput();
                        else
                            PhoneMic.setAsDefaultInput();
                    }
                }
            ]

            onClicked: {
                if (!PhoneMic.available) {
                    root.openInstallGuide("microphone", Translation.tr("Phone Microphone — missing dependencies"));
                    return;
                }
                if (PhoneMic.active) {
                    PhoneMic.toggleMute();
                    return;
                }
                PhoneMic.toggle();
            }
            onSettingsClicked: root.openPage("mic")
            onStopClicked: PhoneMic.stop()
        }

    }

    InstallGuidePopup {
        id: installGuide
        property bool shown: false
        property string feature: ""

        parent: root.Window.contentItem ?? root
        anchors.fill: parent
        visible: installGuide.shown
        z: 9999
        dependencies: installGuide.feature.length > 0
            ? PhoneDeps.missingFor(installGuide.feature)
            : []
        detectedDistro: PhoneDeps.distro
        onCloseRequested: installGuide.shown = false
        onRecheckRequested: PhoneDeps.recheck()
    }
}

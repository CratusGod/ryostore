pragma Singleton

import QtQuick
import Quickshell
import "functions"

Singleton {
    id: root

    property string home: FileUtils.trimFileProtocol(Quickshell.env("HOME") || "/home")
    property string config: FileUtils.trimFileProtocol(Quickshell.env("XDG_CONFIG_HOME") || `${FileUtils.trimFileProtocol(Directories.home)}/.config`)
    property string state: FileUtils.trimFileProtocol(Quickshell.env("XDG_STATE_HOME") || `${FileUtils.trimFileProtocol(Directories.home)}/.local/state`)
    property string cache: FileUtils.trimFileProtocol(Quickshell.env("XDG_CACHE_HOME") || `${FileUtils.trimFileProtocol(Directories.home)}/.cache`)
    property string data: FileUtils.trimFileProtocol(Quickshell.env("XDG_DATA_HOME") || `${FileUtils.trimFileProtocol(Directories.home)}/.local/share`)
    property string downloads: `${Directories.home}/Downloads`
    property string pictures: `${Directories.home}/Pictures`
    property string music: `${Directories.home}/Music`
    property string videos: `${Directories.home}/Videos`
    property string scriptPath: Quickshell.shellPath("scripts")
    property string recordScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/videos/record.sh`)
    property string shellConfig: FileUtils.trimFileProtocol(`${Directories.config}/immaterial-impulse`)
    property string shellConfigName: "config.json"
    property string shellConfigPath: `${Directories.shellConfig}/${Directories.shellConfigName}`
    property string notificationsPath: FileUtils.trimFileProtocol(`${Directories.cache}/notifications/notifications.json`)
    property string todoPath: FileUtils.trimFileProtocol(`${Directories.state}/user/todo.json`)
    property string generatedMaterialThemePath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/colors.json`)
    property string desktopNotesPath: FileUtils.trimFileProtocol(`${Directories.state}/user/desktopnotes.txt`)
    property string coverArt: FileUtils.trimFileProtocol(`${Directories.cache}/media/coverart`)
    property string booruPreviews: FileUtils.trimFileProtocol(`${Directories.cache}/media/boorus`)
    property string booruDownloads: FileUtils.trimFileProtocol(`${Directories.pictures}/homework`)
    property string booruDownloadsNsfw: FileUtils.trimFileProtocol(`${Directories.pictures}/homework/🌶️`)
    property string latexOutput: FileUtils.trimFileProtocol(`${Directories.cache}/media/latex`)

    property bool configDirReady: true
}

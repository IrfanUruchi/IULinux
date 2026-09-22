import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import QtQuick.Window

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.title: "IULinux Performance"
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    property int cpuPercent: -1
    property int ramPercent: -1
    property real ramUsedGiB: -1
    property string gpuText: "--"
    property string graphicsModeText: "Unknown"
    property string powerText: "Unknown"
    property bool supportsSaver: false
    property bool supportsBalanced: false
    property bool supportsPerformance: false

    readonly property int densityMode:
        Screen.width >= 1800 ? 2 :
        Screen.width >= 1200 ? 1 :
                               0

    // Keep the island visually consistent across display sizes.
    implicitWidth:
        Math.min(
            densityMode === 2 ? 380 :
            densityMode === 1 ? 330 :
                                290,
            Math.max(240, Screen.width * 0.32)
        )

    implicitHeight: Kirigami.Units.gridUnit * 2

    Layout.minimumWidth: implicitWidth
    Layout.preferredWidth: implicitWidth
    Layout.maximumWidth: implicitWidth
    Layout.fillWidth: false

    preferredRepresentation: compactRepresentation

    function applyTelemetry(obj) {
        if (obj.cpu_percent !== null)
            cpuPercent = obj.cpu_percent

        if (obj.ram_percent !== null)
            ramPercent = obj.ram_percent

        if (obj.ram_used_gib !== null)
            ramUsedGiB = obj.ram_used_gib

        if (obj.gpu)
            gpuText = obj.gpu

        if (obj.power)
            powerText = obj.power

        if (obj.power_profiles !== undefined) {
            supportsSaver =
                obj.power_profiles.indexOf("power-saver") !== -1

            supportsBalanced =
                obj.power_profiles.indexOf("balanced") !== -1

            supportsPerformance =
                obj.power_profiles.indexOf("performance") !== -1
        }
}

    function applyGraphics(obj) {
        if (obj.current_mode)
            graphicsModeText = obj.current_mode
        else
            graphicsModeText = "Unknown"
    }

    function requestPowerProfile(profile) {
        powerControl.command =
            "powerprofilesctl set " + profile

        powerControl.connectSource(
            powerControl.command
        )
    }

    Plasma5Support.DataSource {
        id: telemetry

        engine: "executable"
        connectedSources: []

        property bool busy: false
        readonly property string command:
            "/usr/lib/iulinux/iulinux-performance-status"

        function refresh() {
            if (busy)
                return

            busy = true
            connectSource(command)
        }

        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            busy = false

            if (data["exit code"] !== 0)
                return

            try {
                root.applyTelemetry(
                    JSON.parse(data["stdout"].trim())
                )
            } catch (error) {
                console.warn(
                    "IULinux Performance telemetry parse failed:",
                    error
                )
            }
        }
    }

    Plasma5Support.DataSource {
        id: graphicsTelemetry

        engine: "executable"
        connectedSources: []

        property bool busy: false
        readonly property string command:
            "/usr/lib/iulinux/iulinux-graphics-status"

        function refresh() {
            if (busy)
                return

            busy = true
            connectSource(command)
        }

        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            busy = false

            if (data["exit code"] !== 0)
                return

            try {
                root.applyGraphics(
                    JSON.parse(data["stdout"].trim())
                )
            } catch (error) {
                console.warn(
                    "IULinux graphics telemetry parse failed:",
                    error
                )
            }
        }
    }

    Plasma5Support.DataSource {
        id: powerControl

        engine: "executable"
        connectedSources: []

        property string command: ""

        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)

            // Immediately refresh the displayed state.
            telemetry.refresh()
        }
    }

    Timer {
        interval: 1500
        repeat: true
        running: true

        onTriggered: telemetry.refresh()
    }

    Timer {
        interval: 5000
        repeat: true
        running: true

        onTriggered: graphicsTelemetry.refresh()
    }

    Component.onCompleted: {
        telemetry.refresh()
        graphicsTelemetry.refresh()
    }

    compactRepresentation: Item {
        implicitWidth: root.implicitWidth
        implicitHeight: root.implicitHeight

        RowLayout {
            anchors.centerIn: parent

            spacing:
                root.densityMode === 2
                    ? Kirigami.Units.largeSpacing
                    : Kirigami.Units.mediumSpacing

            Text {
                text:
                    "CPU " +
                    (root.cpuPercent >= 0
                        ? root.cpuPercent + "%"
                        : "--")

                color: Kirigami.Theme.textColor
            }

            Text {
                text:
                    root.densityMode === 0
                        ? "RAM " +
                          (root.ramPercent >= 0
                              ? root.ramPercent + "%"
                              : "--")
                        : "RAM " +
                          (root.ramUsedGiB >= 0
                              ? root.ramUsedGiB.toFixed(1) + "G"
                              : "--")

                color: Kirigami.Theme.textColor
            }

            Text {
                text: "GPU " + root.gpuText
                color: Kirigami.Theme.textColor
            }

            Text {
                text:
                    root.densityMode === 2
                        ? "⚡ " + root.powerText
                        : "⚡"

                color: Kirigami.Theme.textColor
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            onClicked:
                root.expanded =
                    !root.expanded
        }
    }

    fullRepresentation: Item {
        // Responsive, but deliberately bounded so the popup
        // keeps the same character on laptop and workstation displays.
        implicitWidth: Math.min(
            420,
            Math.max(
                320,
                Screen.width * 0.34
            )
        )

        implicitHeight: Math.min(
            420,
            Math.max(
                300,
                Screen.height * 0.42
            )
        )

        Controls.ScrollView {
            anchors.fill: parent
            clip: true

            contentWidth: availableWidth

            ColumnLayout {
                width: parent.width

                anchors.margins:
                    root.densityMode === 0
                        ? Kirigami.Units.mediumSpacing
                        : Kirigami.Units.largeSpacing

                spacing:
                    root.densityMode === 0
                        ? Kirigami.Units.mediumSpacing
                        : Kirigami.Units.largeSpacing

            Kirigami.Heading {
                text: "Performance"
                level: 2
            }

            GridLayout {
                columns: 2
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.mediumSpacing

                Controls.Label {
                    text: "CPU"
                    opacity: 0.7
                }

                Controls.Label {
                    text:
                        root.cpuPercent >= 0
                            ? root.cpuPercent + "%"
                            : "Unavailable"
                }

                Controls.Label {
                    text: "Memory"
                    opacity: 0.7
                }

                Controls.Label {
                    text:
                        root.ramUsedGiB >= 0
                            ? root.ramUsedGiB.toFixed(1) +
                              " GiB (" +
                              root.ramPercent +
                              "%)"
                            : "Unavailable"
                }

                Controls.Label {
                    text: "Graphics"
                    opacity: 0.7
                }

                Controls.Label {
                    text: root.gpuText
                }

                Controls.Label {
                    text: "Power mode"
                    opacity: 0.7
                }

                Controls.Label {
                    text: root.powerText
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
            }

            Controls.Label {
                text: "Power Mode"
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true

                Controls.Button {
                    Layout.fillWidth: true
                    text: "Saver"
                    checkable: true
                    enabled: root.supportsSaver
                    checked:
                        root.powerText === "Saver"

                    onClicked:
                        root.requestPowerProfile(
                            "power-saver"
                        )
                }

                Controls.Button {
                    Layout.fillWidth: true
                    text: "Balanced"
                    checkable: true
                    enabled: root.supportsBalanced
                    checked:
                        root.powerText === "Balanced"

                    onClicked:
                        root.requestPowerProfile(
                            "balanced"
                        )
                }

                Controls.Button {
                    Layout.fillWidth: true
                    text: "Performance"
                    checkable: true
                    enabled: root.supportsPerformance
                    checked:
                        root.powerText === "Performance"

                    onClicked:
                        root.requestPowerProfile(
                            "performance"
                        )
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
            }

            Controls.Label {
                text: "Graphics"
                font.bold: true
            }

            Controls.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap

                text:
                    "Current mode: " +
                    root.graphicsModeText +
                    "\n\nAdvanced GPU switching and power limits " +
                    "will appear here only when the hardware backend " +
                    "reports that they are safely supported."

                opacity: 0.8
            }

            Item {
                Layout.fillHeight: true
            }
        }
        }
    }
}

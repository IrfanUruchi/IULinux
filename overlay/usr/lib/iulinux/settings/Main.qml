import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: root

    width: 1040
    height: 680
    minimumWidth: 760
    minimumHeight: 520

    title: "IULinux Settings"

    property int currentPage: 0

    readonly property var sections: [
        ["Overview", "computer"],
        ["Performance & Graphics", "speedometer"],
        ["Display", "video-display"],
        ["Power & Battery", "battery"],
        ["Network & Bluetooth", "network-wireless"],
        ["Audio", "audio-volume-high"],
        ["Appearance & Desktop", "preferences-desktop-theme"],
        ["Input", "input-keyboard"],
        ["Storage", "drive-harddisk"],
        ["Apps & Updates", "system-software-update"],
        ["Developer & Profiles", "applications-development"],
        ["Security", "security-high"],
        ["About", "help-about"]
    ]

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth:
                root.width >= 900 ? 240 : 190

            Layout.fillHeight: true

            color: Kirigami.Theme.alternateBackgroundColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin:
                        Kirigami.Units.largeSpacing

                    Kirigami.Icon {
                        source: "preferences-system"
                        implicitWidth:
                            Kirigami.Units.iconSizes.medium
                        implicitHeight:
                            Kirigami.Units.iconSizes.medium
                    }

                    Kirigami.Heading {
                        text: "IULinux"
                        level: 2
                    }
                }

                ListView {
                    id: navigation

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    clip: true
                    spacing: 2

                    model: root.sections

                    delegate: Controls.ItemDelegate {
                        required property var modelData
                        required property int index

                        width: ListView.view.width

                        text: modelData[0]
                        icon.name: modelData[1]

                        highlighted:
                            root.currentPage === index

                        onClicked:
                            root.currentPage = index
                    }
                }
            }
        }

        Rectangle {
            width: 1
            Layout.fillHeight: true
            color: Kirigami.Theme.disabledTextColor
            opacity: 0.25
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            currentIndex: root.currentPage

            Item {
                Flickable {
                    anchors.fill: parent
                    contentHeight: overview.height
                    clip: true

                    ColumnLayout {
                        id: overview

                        width: parent.width
                        spacing: Kirigami.Units.largeSpacing

                        anchors.margins:
                            Kirigami.Units.gridUnit * 2

                        Kirigami.Heading {
                            text: "Overview"
                            level: 1
                        }

                        Controls.Label {
                            text:
                                "Your IULinux workstation at a glance."
                            opacity: 0.7
                        }

                        Kirigami.Card {
                            Layout.fillWidth: true

                            contentItem: GridLayout {
                                columns: 2
                                rowSpacing:
                                    Kirigami.Units.largeSpacing
                                columnSpacing:
                                    Kirigami.Units.gridUnit * 2

                                Controls.Label {
                                    text: "System"
                                    opacity: 0.65
                                }

                                Controls.Label {
                                    text:
                                        systemBackend.iulinuxVersion
                                }

                                Controls.Label {
                                    text: "Hostname"
                                    opacity: 0.65
                                }

                                Controls.Label {
                                    text:
                                        systemBackend.hostname
                                }

                                Controls.Label {
                                    text: "Kernel"
                                    opacity: 0.65
                                }

                                Controls.Label {
                                    text:
                                        systemBackend.kernel
                                }

                                Controls.Label {
                                    text: "Architecture"
                                    opacity: 0.65
                                }

                                Controls.Label {
                                    text:
                                        systemBackend.architecture
                                }
                            }
                        }

                        Kirigami.Card {
                            Layout.fillWidth: true

                            contentItem: RowLayout {
                                spacing:
                                    Kirigami.Units.gridUnit * 2

                                ColumnLayout {
                                    Layout.fillWidth: true

                                    Controls.Label {
                                        text: "CPU"
                                        opacity: 0.65
                                    }

                                    Kirigami.Heading {
                                        text:
                                            systemBackend.cpuPercent >= 0
                                            ? systemBackend.cpuPercent + "%"
                                            : "—"

                                        level: 2
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true

                                    Controls.Label {
                                        text: "Memory"
                                        opacity: 0.65
                                    }

                                    Kirigami.Heading {
                                        text:
                                            systemBackend.ramUsedGiB >= 0
                                            ? systemBackend.ramUsedGiB.toFixed(1) + " GiB"
                                            : "—"

                                        level: 2
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true

                                    Controls.Label {
                                        text: "Graphics"
                                        opacity: 0.65
                                    }

                                    Kirigami.Heading {
                                        text:
                                            systemBackend.gpuText
                                        level: 2
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true

                                    Controls.Label {
                                        text: "Power"
                                        opacity: 0.65
                                    }

                                    Kirigami.Heading {
                                        text:
                                            systemBackend.powerMode
                                        level: 2
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Flickable {
                    anchors.fill: parent
                    contentHeight: performance.height
                    clip: true

                    ColumnLayout {
                        id: performance

                        width: parent.width

                        anchors.margins:
                            Kirigami.Units.gridUnit * 2

                        spacing:
                            Kirigami.Units.largeSpacing

                        Kirigami.Heading {
                            text: "Performance & Graphics"
                            level: 1
                        }

                        Controls.Label {
                            text:
                                "Performance, graphics and hardware power controls in one place."

                            opacity: 0.7
                        }

                        Kirigami.Card {
                            Layout.fillWidth: true

                            contentItem: GridLayout {
                                columns: 2
                                rowSpacing:
                                    Kirigami.Units.largeSpacing

                                Controls.Label {
                                    text: "CPU usage"
                                    opacity: 0.65
                                }

                                Controls.Label {
                                    text:
                                        systemBackend.cpuPercent >= 0
                                        ? systemBackend.cpuPercent + "%"
                                        : "Unavailable"
                                }

                                Controls.Label {
                                    text: "Memory"
                                    opacity: 0.65
                                }

                                Controls.Label {
                                    text:
                                        systemBackend.ramUsedGiB >= 0
                                        ? systemBackend.ramUsedGiB.toFixed(1)
                                          + " GiB · "
                                          + systemBackend.ramPercent
                                          + "%"
                                        : "Unavailable"
                                }

                                Controls.Label {
                                    text: "Graphics"
                                    opacity: 0.65
                                }

                                Controls.Label {
                                    text:
                                        systemBackend.gpuText
                                }
                            }
                        }

                        Kirigami.Card {
                            Layout.fillWidth: true

                            contentItem: ColumnLayout {
                                spacing:
                                    Kirigami.Units.largeSpacing

                                Kirigami.Heading {
                                    text: "Power Mode"
                                    level: 3
                                }

                                Controls.Label {
                                    text:
                                        "Choose how aggressively the system balances performance and energy use."

                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                    opacity: 0.7
                                }

                                RowLayout {
                                    Layout.fillWidth: true

                                    Controls.Button {
                                        Layout.fillWidth: true
                                        text: "Saver"
                                        checkable: true
                                        enabled: systemBackend.supportsSaver

                                        checked:
                                            systemBackend.powerMode === "Saver"

                                        onClicked:
                                            systemBackend.setPowerMode(
                                                "Saver"
                                            )
                                    }

                                    Controls.Button {
                                        Layout.fillWidth: true
                                        text: "Balanced"
                                        checkable: true
                                        enabled: systemBackend.supportsBalanced

                                        checked:
                                            systemBackend.powerMode === "Balanced"

                                        onClicked:
                                            systemBackend.setPowerMode(
                                                "Balanced"
                                            )
                                    }

                                    Controls.Button {
                                        Layout.fillWidth: true
                                        text: "Performance"
                                        checkable: true
                                        enabled: systemBackend.supportsPerformance

                                        checked:
                                            systemBackend.powerMode === "Performance"

                                        onClicked:
                                            systemBackend.setPowerMode(
                                                "Performance"
                                            )
                                    }
                                }

                                Controls.Label {
                                    visible:
                                        systemBackend.actionError.length > 0

                                    text:
                                        systemBackend.actionError

                                    color:
                                        Kirigami.Theme.negativeTextColor

                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        Kirigami.Card {
                            Layout.fillWidth: true

                            contentItem: ColumnLayout {
                                spacing:
                                    Kirigami.Units.largeSpacing

                                Kirigami.Heading {
                                    text: "Graphics Mode"
                                    level: 3
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 2

                                    rowSpacing:
                                        Kirigami.Units.smallSpacing

                                    columnSpacing:
                                        Kirigami.Units.gridUnit * 2

                                    Controls.Label {
                                        text: "Current mode"
                                        opacity: 0.65
                                    }

                                    Controls.Label {
                                        text: systemBackend.graphicsMode
                                    }

                                    Controls.Label {
                                        text: "Configured mode"
                                        opacity: 0.65
                                    }

                                    Controls.Label {
                                        text:
                                            systemBackend.graphicsConfiguredMode
                                    }

                                    Controls.Label {
                                        visible:
                                            systemBackend.graphicsTransitionPending
                                        text: "Requested mode"
                                        opacity: 0.65
                                    }

                                    Controls.Label {
                                        visible:
                                            systemBackend.graphicsTransitionPending
                                        text:
                                            systemBackend.graphicsRequestedMode
                                    }

                                    Controls.Label {
                                        text: "Detected GPUs"
                                        opacity: 0.65
                                    }

                                    Controls.Label {
                                        Layout.fillWidth: true
                                        text: systemBackend.graphicsDevices
                                        wrapMode: Text.WordWrap
                                    }

                                    Controls.Label {
                                        text: "Detection backend"
                                        opacity: 0.65
                                    }

                                    Controls.Label {
                                        text: systemBackend.graphicsProvider
                                    }

                                    Controls.Label {
                                        text: "Render offload"
                                        opacity: 0.65
                                    }

                                    Controls.Label {
                                        text:
                                            systemBackend.graphicsOffloadAvailable
                                            ? "Available"
                                            : "Unavailable"
                                    }

                                    Controls.Label {
                                        text: "Mode switching"
                                        opacity: 0.65
                                    }

                                    Controls.Label {
                                        Layout.fillWidth: true
                                        text:
                                            systemBackend.graphicsSwitchProvider.length > 0
                                            ? systemBackend.graphicsSwitchProvider
                                            : "No verified provider"
                                        wrapMode: Text.WordWrap
                                    }

                                    Controls.Label {
                                        text: "Reboot required"
                                        opacity: 0.65
                                    }

                                    Controls.Label {
                                        text:
                                            systemBackend.graphicsRebootRequired
                                            ? "Yes"
                                            : "No"
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true

                                    Controls.Button {
                                        Layout.fillWidth: true
                                        text: "Integrated"
                                        checkable: true

                                        checked:
                                            systemBackend.graphicsMode
                                            === "Integrated"

                                        enabled:
                                            systemBackend.supportsIntegratedGraphics

                                        onClicked:
                                            systemBackend.setGraphicsMode(
                                                "Integrated"
                                            )
                                    }

                                    Controls.Button {
                                        Layout.fillWidth: true
                                        text: "Hybrid"
                                        checkable: true

                                        checked:
                                            systemBackend.graphicsMode
                                            === "Hybrid"

                                        enabled:
                                            systemBackend.supportsHybridGraphics

                                        onClicked:
                                            systemBackend.setGraphicsMode(
                                                "Hybrid"
                                            )
                                    }

                                    Controls.Button {
                                        Layout.fillWidth: true
                                        text: "Discrete"
                                        checkable: true

                                        checked:
                                            systemBackend.graphicsMode
                                            === "Discrete"

                                        enabled:
                                            systemBackend.supportsDiscreteGraphics

                                        onClicked:
                                            systemBackend.setGraphicsMode(
                                                "Discrete"
                                            )
                                    }
                                }

                                Controls.Label {
                                    Layout.fillWidth: true
                                    visible:
                                        systemBackend.graphicsTransitionPending
                                    text:
                                        systemBackend.graphicsTransitionStatus
                                    wrapMode: Text.WordWrap
                                    opacity: 0.8
                                }

                                Controls.Label {
                                    Layout.fillWidth: true

                                    visible:
                                        !systemBackend.supportsIntegratedGraphics
                                        && !systemBackend.supportsHybridGraphics
                                        && !systemBackend.supportsDiscreteGraphics

                                    text:
                                        "System-wide switching stays locked until IULinux detects a verified safe hardware provider."

                                    wrapMode: Text.WordWrap
                                    opacity: 0.7
                                }
                            }
                        }

                        Kirigami.Card {
                            Layout.fillWidth: true

                            contentItem: ColumnLayout {
                                Kirigami.Heading {
                                    text: "GPU Power"
                                    level: 3
                                }

                                Controls.Label {
                                    text:
                                        "Managed by the hardware backend"

                                    opacity: 0.7
                                }

                                Controls.Label {
                                    text:
                                        "Power-limit and TGP controls will only be exposed on hardware where the vendor or kernel interface has been verified."

                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                    opacity: 0.7
                                }
                            }
                        }
                    }
                }
            }

            Repeater {
                model: root.sections.length - 2

                Item {
                    ColumnLayout {
                        anchors.centerIn: parent
                        width:
                            Math.min(
                                parent.width - 80,
                                520
                            )

                        spacing:
                            Kirigami.Units.largeSpacing

                        Kirigami.Icon {
                            Layout.alignment:
                                Qt.AlignHCenter

                            source:
                                root.sections[index + 2][1]

                            implicitWidth:
                                Kirigami.Units.iconSizes.huge

                            implicitHeight:
                                Kirigami.Units.iconSizes.huge
                        }

                        Kirigami.Heading {
                            Layout.alignment:
                                Qt.AlignHCenter

                            text:
                                root.sections[index + 2][0]

                            level: 2
                        }

                        Controls.Label {
                            Layout.fillWidth: true
                            horizontalAlignment:
                                Text.AlignHCenter

                            wrapMode:
                                Text.WordWrap

                            text:
                                "This section is part of the IULinux Settings roadmap and will gain curated controls in upcoming Alpha updates."

                            opacity: 0.7
                        }
                    }
                }
            }
        }
    }
}

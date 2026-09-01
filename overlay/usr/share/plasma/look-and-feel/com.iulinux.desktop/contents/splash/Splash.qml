/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: root
    color: "#0b0f14"

    property int stage

    onStageChanged: {
        if (stage == 2) {
            introAnimation.running = true;
        } else if (stage == 5) {
            outroAnimation.running = true;
        }
    }

    Item {
        id: backgroundLayer
        anchors.fill: parent

        Rectangle {
            width: parent.width * 0.9
            height: parent.height * 0.9
            anchors.centerIn: parent
            radius: width / 2
            color: "#0f1d34"
            opacity: 0.20
        }

        Rectangle {
            width: parent.width * 0.55
            height: parent.width * 0.55
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -Kirigami.Units.gridUnit
            radius: width / 2
            color: "#165dff"
            opacity: 0.10
        }

        Rectangle {
            width: parent.width * 0.35
            height: parent.width * 0.35
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -Kirigami.Units.gridUnit
            radius: width / 2
            color: "#3c8dff"
            opacity: 0.08
        }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        Column {
            id: brandBlock
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -Kirigami.Units.gridUnit
            spacing: Kirigami.Units.largeSpacing

            Image {
                id: logo
                anchors.horizontalCenter: parent.horizontalCenter
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                source: "images/iulinux-logo.png"
                sourceSize.width: Kirigami.Units.gridUnit * 18
                sourceSize.height: Kirigami.Units.gridUnit * 18
                width: Kirigami.Units.gridUnit * 18
                height: Kirigami.Units.gridUnit * 6
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Premium developer workstation"
                color: "#cfd6e4"
                opacity: 0.88
                font.pixelSize: Kirigami.Units.gridUnit
                font.weight: Font.Medium
            }
        }

        Image {
            id: busyIndicator
            anchors.top: brandBlock.bottom
            anchors.topMargin: Kirigami.Units.gridUnit * 2
            anchors.horizontalCenter: parent.horizontalCenter
            asynchronous: true
            source: "images/busywidget.svgz"
            sourceSize.height: Kirigami.Units.gridUnit * 2
            sourceSize.width: Kirigami.Units.gridUnit * 2

            RotationAnimator on rotation {
                id: rotationAnimator
                from: 0
                to: 360
                duration: 2200
                loops: Animation.Infinite
                running: Kirigami.Units.longDuration > 1
            }
        }

        Text {
            anchors.top: busyIndicator.bottom
            anchors.topMargin: Kirigami.Units.smallSpacing
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Loading workspace..."
            color: "#8f9bb0"
            font.pixelSize: Kirigami.Units.smallSpacing * 2
        }
    }

    OpacityAnimator {
        id: introAnimation
        target: content
        from: 0
        to: 1
        duration: Kirigami.Units.veryLongDuration * 2
        easing.type: Easing.InOutQuad
    }

    OpacityAnimator {
        id: outroAnimation
        target: content
        from: 1
        to: 0
        duration: Kirigami.Units.longDuration
        easing.type: Easing.InOutQuad
    }
}

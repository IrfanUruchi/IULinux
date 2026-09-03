import org.kde.breeze.components

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

SessionManagementScreen {
    id: root
    property Item mainPasswordBox: passwordBox

    property bool showUsernamePrompt: !showUserList

    property string lastUserName
    property bool loginScreenUiVisible: false

    //the y position that should be ensured visible when the on screen keyboard is visible
    property int visibleBoundary: mapFromItem(loginButton, 0, 0).y
    onHeightChanged: visibleBoundary = mapFromItem(loginButton, 0, 0).y + loginButton.height + Kirigami.Units.smallSpacing

    property real fontSize: Kirigami.Theme.defaultFont.pointSize

    signal loginRequest(string username, string password)

    onShowUsernamePromptChanged: {
        if (!showUsernamePrompt) {
            lastUserName = ""
        }
    }

    onUserSelected: {
        // Don't startLogin() here, because the signal is connected to the
        // Escape key as well, for which it wouldn't make sense to trigger
        // login.
        passwordBox.clear()
        focusFirstVisibleFormControl();
    }

    QQC2.StackView.onActivating: {
        // Controls are not visible yet.
        Qt.callLater(focusFirstVisibleFormControl);
    }

    function focusFirstVisibleFormControl() {
        const nextControl = (userNameInput.visible
            ? userNameInput
            : (passwordBox.visible
                ? passwordBox
                : loginButton));
        // Using TabFocusReason, so that the loginButton gets the visual highlight.
        nextControl.forceActiveFocus(Qt.TabFocusReason);
    }

    /*
     * Login has been requested with the following username and password
     * If username field is visible, it will be taken from that, otherwise from the "name" property of the currentIndex
     */
    function startLogin() {
        const username = showUsernamePrompt ? userNameInput.text : userList.selectedUser
        const password = passwordBox.text

        footer.enabled = false
        mainStack.enabled = false
        userListComponent.userList.opacity = 0.75

        // This is partly because it looks nicer, but more importantly it
        // works round a Qt bug that can trigger if the app is closed with a
        // TextField focused.
        //
        // See https://bugreports.qt.io/browse/QTBUG-55460
        loginButton.forceActiveFocus();
        loginRequest(username, password);
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: loginForm.implicitHeight + Kirigami.Units.gridUnit * 2

        radius: 18
        color: "#D91B2028"
        border.width: 1
        border.color: "#55677A96"

        ColumnLayout {
            id: loginForm
            anchors.fill: parent
            anchors.margins: Kirigami.Units.gridUnit
            spacing: Kirigami.Units.smallSpacing * 2

            PlasmaComponents3.TextField {
                id: userNameInput
        font.pointSize: fontSize + 1
        Layout.fillWidth: true

        text: lastUserName
        visible: showUsernamePrompt
        focus: showUsernamePrompt && !lastUserName //if there's a username prompt it gets focus first, otherwise password does
        placeholderText: i18ndc("plasma-desktop-sddm-theme", "@info:placeholder in textfield", "Username")

        onAccepted: {
            if (root.loginScreenUiVisible) {
                passwordBox.forceActiveFocus()
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true

        PlasmaExtras.PasswordField {
            id: passwordBox
            font.pointSize: fontSize + 1
            Layout.fillWidth: true

            placeholderText: i18ndc("plasma-desktop-sddm-theme",  "@info:placeholder in textfield", "Password")
            focus: !showUsernamePrompt || lastUserName

            background: Rectangle {
                implicitWidth: Kirigami.Units.gridUnit * 12
                implicitHeight: Kirigami.Units.gridUnit * 2.2

                radius: 10
                color: "#141922"

                border.width: 1
                border.color: passwordBox.activeFocus
                    ? "#3D8DFF"
                    : "#55677A96"

                property var margins: ({
                    left: 12,
                    right: 12,
                    top: 8,
                    bottom: 8
                })
            }

            palette.base: "#141922"
            palette.text: "#EEF2F7"
            palette.placeholderText: "#8F9AAA"
            palette.highlight: "#3D8DFF"
            palette.highlightedText: "#FFFFFF"

            // Disable reveal password action because SDDM does not have the breeze icon set loaded
            rightActions: []

            onAccepted: {
                if (root.loginScreenUiVisible) {
                    startLogin();
                }
            }

            visible: root.showUsernamePrompt || userList.currentItem.needsPassword

            Keys.onEscapePressed: {
                mainStack.currentItem.forceActiveFocus();
            }

            //if empty and left or right is pressed change selection in user switch
            //this cannot be in keys.onLeftPressed as then it doesn't reach the password box
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Left && !text) {
                    userList.decrementCurrentIndex();
                    event.accepted = true
                }
                if (event.key === Qt.Key_Right && !text) {
                    userList.incrementCurrentIndex();
                    event.accepted = true
                }
            }

            Connections {
                target: sddm
                function onLoginFailed() {
                    passwordBox.selectAll()
                    passwordBox.forceActiveFocus()
                }
            }
        }

        PlasmaComponents3.Button {
            id: loginButton
            Accessible.name: i18ndc("plasma-desktop-sddm-theme", "@action:button Accessible name", "Log in")
            Layout.preferredHeight: passwordBox.implicitHeight
            Layout.preferredWidth: loginButton.text.length === 0
                ? loginButton.Layout.preferredHeight
                : -1

            topPadding: 8
            bottomPadding: 8
            leftPadding: loginButton.text.length === 0 ? 10 : 16
            rightPadding: loginButton.text.length === 0 ? 10 : 16

            font.pointSize: fontSize + 1

            icon.name: loginButton.text.length === 0
                ? (root.LayoutMirroring.enabled ? "go-previous" : "go-next")
                : ""
            icon.width: Kirigami.Units.iconSizes.sizeForLabels
            icon.height: Kirigami.Units.iconSizes.sizeForLabels

            palette.buttonText: "#EEF2F7"
            palette.highlight: "#3D8DFF"
            palette.highlightedText: "#FFFFFF"

            background: Rectangle {
                implicitWidth: loginButton.text.length === 0
                    ? Kirigami.Units.gridUnit * 2.2
                    : Kirigami.Units.gridUnit * 5.5
                implicitHeight: Kirigami.Units.gridUnit * 2.2

                radius: 10
                color: !loginButton.enabled
                    ? "#1B212B"
                    : loginButton.down
                        ? "#1E2630"
                        : loginButton.hovered
                            ? "#2C3542"
                            : "#252C36"

                border.width: 1
                border.color: (loginButton.activeFocus || loginButton.visualFocus)
                    ? "#3D8DFF"
                    : loginButton.hovered
                        ? "#6B7A8A"
                        : "#4A5664"
            }

            text: root.showUsernamePrompt || userList.currentItem.needsPassword
                ? ""
                : i18nc("@action:button", "Log In")
            onClicked: startLogin()
            Keys.onEnterPressed: clicked()
            Keys.onReturnPressed: clicked()
        }
            }
        }
    }
}

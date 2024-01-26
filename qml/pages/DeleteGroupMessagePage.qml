/*
    Copyright (C) 2020 Sebastian J. Wolf and other contributors

    This file is part of Fernschreiber.

    Fernschreiber is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Fernschreiber is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Fernschreiber. If not, see <http://www.gnu.org/licenses/>.
*/
import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"
import "../js/functions.js" as Functions
import "../js/twemoji.js" as Emoji
// TODO REFACTOR
// - could be delete message OR remove user!
// - we need the user & group & message
// - if no message: other ui!

Dialog {
    id: deleteGroupMessagePage

    allowedOrientations: Orientation.All
    property var chatInformation
    property var chatPhoto
    // todo perhaps load new like ChatInformationPage
    property var message

    property bool doReportMessage: reportMessage.checked
    property bool doBanUser: banUser.checked
    property int doUnbanUserAfter: 0
    property bool doDeleteAllUserMessagesInChat: deleteAllMessagesOnBan.checked

    function unbanValueIsNever(timestamp) {
        /*
            Point in time (Unix timestamp) when restrictions will be lifted from the user;
            0 if never. If the user is restricted for more than 366 days or for less than
            30 seconds from the current time, the user is considered to be restricted forever.
        */
        var settingDate = new Date(timestamp);
        var currentDate = new Date();
        // we'll set it to 365 to be sure ;)
        var smallestSpecificDate = new Date(currentDate.getTime() + (30000))
        var biggestSpecificDate = new Date(currentDate.getTime() + (365 * 24 * 3600000))

        return settingDate <= smallestSpecificDate || settingDate > biggestSpecificDate;
    }
    function getUnbanValueText(value) {
        if(unbanValueIsNever(value)) {
            return  qsTr("never", "Unban user… never")
        }
        return Qt.formatDate(date);
    }

    function getDoUnbanUserAfterUnix(){
        return doUnbanUserAfter / 1000
    }

    DialogHeader {
        id: header
        dialog: deleteGroupMessagePage
//        title: qsTr("Delete Message", "Dialog Header")
    }

    SilicaFlickable {
        id: contentFlickable
        clip: true
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        contentHeight: contentColumn.height

        Column {
            id: contentColumn
            width: parent.width
//            topPadding: Theme.paddingLarge
            bottomPadding: Theme.paddingLarge

            DetailItem {
                    label: qsTr("Delete Message from", "Before group name: Delete Message from [Group Name]")
                    value: deleteGroupMessagePage.chatInformation.title !== "" ? Emoji.emojify(deleteGroupMessagePage.chatInformation.title, Theme.fontSizeLarge) : qsTr("Unknown")
                }

//            SectionHeader {
//                text: qsTr("Message", "Section Header: Short view of Message to be deleted")
//            }

            Column {
                id: deleteMessageViewColumn
                spacing: Theme.paddingSmall
                width: parent.width - Theme.horizontalPageMargin * 2
                x: Theme.horizontalPageMargin

                Label {
                    id: deleteMessageViewUserText
                    width: parent.width
                    font.pixelSize: Theme.fontSizeExtraSmall
                    font.weight: Font.ExtraBold
                    maximumLineCount: 1
                    truncationMode: TruncationMode.Fade
                    textFormat: Text.StyledText
                    horizontalAlignment: Text.AlignLeft
                    text: Emoji.emojify(Functions.getUserName(tdLibWrapper.getUserInformation(deleteGroupMessagePage.message.sender_id.user_id)), deleteMessageViewUserText.font.pixelSize)
                }
                Label {
                    id: deleteMessageViewMessageText
                    font.pixelSize: Theme.fontSizeExtraSmall
                    width: parent.width
                    textFormat: Text.StyledText
                    truncationMode: TruncationMode.Fade
                    maximumLineCount: 1
                    linkColor: Theme.highlightColor
                    onLinkActivated: {}
                    text: Emoji.emojify(Functions.getMessageText(deleteGroupMessagePage.message, true, '', false), deleteMessageViewMessageText.font.pixelSize)
                }
            }

            SectionHeader {
                text: qsTr("Deletion options", "Section Header: options like banning the user")
            }

            TextSwitch {
                id: reportMessage
                text: qsTr("Report message as spam")
                visible: chatInformation.chatType === "chatTypeSupergroup"
            }

            TextSwitch {
                id: banUser
                text: qsTr("Ban user")
            }

            ValueButton {
                enabled: banUser.checked
                opacity: enabled ? 1 : 0.5


                label: qsTr("Unban user", "")
                value: deleteGroupMessagePage.unbanValueIsNever(deleteGroupMessagePage.doUnbanUserAfter) ?
                           qsTr("never", "Unban user… never")
                         : Functions.getDateTimeTimepoint(getDoUnbanUserAfterUnix())

                onClicked: {
                    var dialog = pageStack.push("Sailfish.Silica.DatePickerDialog")

                    dialog.accepted.connect(function() {
                        var date = dialog.date;
                        if(deleteGroupMessagePage.unbanValueIsNever(date)) {
                            date = 0;
                        }
                        deleteGroupMessagePage.doUnbanUserAfter = date;

                    })
                }

                Behavior on opacity { NumberAnimation {} }
            }

            TextSwitch {
                id: deleteAllMessagesOnBan
                enabled: banUser.checked
                opacity: enabled ? 1 : 0.5
                text: qsTr("Delete all messages from user")

                Behavior on opacity { NumberAnimation {} }
            }

        }
    }


    Component {
        id: datePickerDialog
        DatePickerDialog {
            dateText: Qt.formatDate(date)

            onDone: {
                if (result == DialogResult.Accepted) {
                    dateText = getUnbanValueText(date);
                    if(unbanValueIsNever(date)) {
                        deleteGroupMessagePage.doUnbanUserAfter = 0;
                    } else {
                        deleteGroupMessagePage.doUnbanUserAfter = date;
                    }

                }
            }
        }
    }
}

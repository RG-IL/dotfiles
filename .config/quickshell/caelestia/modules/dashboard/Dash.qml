import "dash"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.components.filedialog
import qs.services

GridLayout {
    id: root

    required property ScreenState screenState
    required property FileDialog facePicker

    rowSpacing: Tokens.spacing.medium
    columnSpacing: Tokens.spacing.medium

    Rect {
        Layout.column: 2
        Layout.columnSpan: 3
        Layout.preferredWidth: Tokens.sizes.dashboard.userWidth
        Layout.fillHeight: true

        radius: Tokens.rounding.extraLarge

        User {
            id: user

            screenState: root.screenState
            facePicker: root.facePicker
        }
    }

    RaycastCard {
        Layout.row: 0
        Layout.columnSpan: 2
        Layout.preferredWidth: Tokens.sizes.dashboard.weatherWidth

        radius: Tokens.rounding.extraLarge * 1.5
    }

    Rect {
        Layout.row: 1
        Layout.preferredWidth: dateTime.implicitWidth
        Layout.fillHeight: true

        radius: Tokens.rounding.large

        DateTime {
            id: dateTime
        }
    }

    Rect {
        Layout.row: 1
        Layout.column: 1
        Layout.columnSpan: 3
        Layout.fillWidth: true
        Layout.preferredHeight: calendar.implicitHeight

        radius: Tokens.rounding.extraLarge

        Calendar {
            id: calendar

            screenState: root.screenState
        }
    }

    Rect {
        Layout.row: 1
        Layout.column: 4
        Layout.preferredWidth: resources.implicitWidth
        Layout.fillHeight: true

        radius: Tokens.rounding.large

        Resources {
            id: resources
        }
    }

    Rect {
        Layout.row: 0
        Layout.column: 5
        Layout.rowSpan: 2
        Layout.preferredWidth: media.implicitWidth
        Layout.fillHeight: true

        radius: Tokens.rounding.extraLarge * 2

        Media {
            id: media
        }
    }

    component RaycastCard: StyledRect {
        id: card

        color: Colours.tPalette.m3surfaceContainer
        implicitHeight: content.implicitHeight + Tokens.padding.largeIncreased * 2

        property int installs: -1

        function reload(): void {
            const xhr = new XMLHttpRequest();
            xhr.open("GET", "https://backend.raycast.com/api/v1/extensions/RG-IL/neovim");
            xhr.onreadystatechange = () => {
                if (xhr.readyState !== XMLHttpRequest.DONE)
                    return;
                if (xhr.status === 200) {
                    try {
                        card.installs = JSON.parse(xhr.responseText)?.download_count ?? -1;
                    } catch (e) {
                        console.warn("RaycastCard: failed to parse installs:", e);
                    }
                } else {
                    console.warn("RaycastCard: fetch failed with status", xhr.status);
                }
            };
            xhr.send();
        }

        Timer {
            interval: 15 * 60 * 1000
            running: true
            repeat: true
            onTriggered: card.reload()
        }

        Component.onCompleted: card.reload()

        StateLayer {
            onClicked: Qt.openUrlExternally("https://www.raycast.com/RG-IL/neovim")
        }

        RowLayout {
            id: content

            anchors.left: parent.left
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spacing.largeIncreased

            ColouredIcon {
                id: icon

                source: Qt.resolvedUrl("./assets/neovim.svg")
                implicitSize: Math.round(Tokens.font.icon.extraLarge.pointSize * 1.6)
                colour: Colours.palette.m3secondary
            }

            StyledText {
                text: "•••"
                color: Colours.palette.m3primary
                font: Tokens.font.clock.size(28 * 0.9).build()
                rotation: 90
                Layout.leftMargin: Tokens.spacing.extraSmall
            }

            ColumnLayout {
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    animate: true
                    text: "Neovim"
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    animate: true
                    text: card.installs < 0 ? "…" : qsTr("%1 install%2").arg(card.installs).arg(card.installs === 1 ? "" : "s")
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }

    component Rect: StyledRect {
        color: Colours.tPalette.m3surfaceContainer
    }
}

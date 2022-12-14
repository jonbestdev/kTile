import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.12
import QtQuick.LocalStorage 2.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents

PlasmaComponents.Button {
  property int id
  property double boxWidth
  property double boxHeight
  property double boxX
  property double boxY
  property double boxGap: 10
  
  width: 200
  height: 120

  function tileWindow(window) {
    if (!window.normalWindow) return;

    let screen = workspace.clientArea(KWin.MaximizeArea, workspace.activeScreen, window.desktop);
    
    let newWidth = ((boxWidth / 100) * (screen.width - boxGap)) - boxGap
    let newHeight = ((boxHeight / 100) * (screen.height - boxGap)) - boxGap
    let newX = ((boxX / 100) * (screen.width - boxGap)) + boxGap
    let newY = ((boxY / 100) * (screen.height - boxGap)) + boxGap

    window.setMaximize(false, false);
    window.geometry = Qt.rect(newX, newY, newWidth, newHeight);
  }

  MouseArea {
    property double pad: ((2 / 100) * parent.width) // 2% of parent.width
    property bool isHovered: false
    onEntered: isHovered = true
    onExited: isHovered = false
    anchors.margins: pad
    anchors.fill: parent
    hoverEnabled: true

    onClicked: {
      tileWindow(workspace.activeClient);
      mainDialog.visible = false
    }

    PlasmaComponents.Button {
      width: ((boxWidth / 100) * parent.width)
      height: ((boxHeight / 100) * parent.height)
      x: ((boxX / 100) * parent.width)
      y: ((boxY / 100) * parent.height)
      visible: !parent.isHovered
    }

    // fake the button hover state
    PlasmaComponents.Button {
      width: ((boxWidth / 100) * parent.width)
      height: ((boxHeight / 100) * parent.height)
      x: ((boxX / 100) * parent.width)
      y: ((boxY / 100) * parent.height)
      visible: parent.isHovered
      signal hovered()

      MouseArea {
        anchors.fill: parent

        onClicked: {
          tileWindow(workspace.activeClient);
          mainDialog.visible = false
        }
      }
    }

    RowLayout {
      anchors.top: parent.top
      anchors.right: parent.right
      visible: parent.isHovered

      PlasmaComponents.Button {
        icon.name: "edit-entry"
        onClicked: {
          var component = Qt.createComponent("edit.qml")
          component.createObject(tableBackground, {id: id});
        }
      }

      PlasmaComponents.Button {
        icon.name: "edit-delete-symbolic"
        onClicked: {

          this.parent.parent.parent.destroy()

          var db = LocalStorage.openDatabaseSync("QDeclarativeExampleDB", "1.0", "The Example QML SQL!", 1000000);

          db.transaction(
            function(tx) {
              tx.executeSql('DELETE FROM spaces WHERE rowid = ' + id);
            }
          )
        }
      }
    }
  }

  Text {
    text: id
    font.pointSize: 38
    anchors.centerIn: parent
    opacity: 0.2
    visible: showNumbers
  }
}

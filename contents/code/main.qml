import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kwin 2.0
import QtQuick.LocalStorage 2.15

PlasmaCore.Dialog {
  id: mainDialog

  location: PlasmaCore.Types.Floating
  flags: Qt.X11BypassWindowManagerHint | Qt.FramelessWindowHint
  visible: false

  property bool editMode: false
  property bool restartButtonVisible: true
  property bool showNumbers: false

  function loadConfig(){
    // columns = KWin.readConfig("columns", 6);
    // rows = KWin.readConfig("rows", 4);
  }

  function show() {
    var screen = workspace.clientArea(KWin.FullScreenArea, workspace.activeScreen, workspace.currentDesktop);
    mainDialog.visible = true;

    mainDialog.x = screen.x + screen.width/2 - mainDialog.width/2;
    mainDialog.y = screen.y + screen.height/2 - mainDialog.height/2;
  }

  function tileWindow(window, pos) {
    if (!window.normalWindow) return;
    let screen = workspace.clientArea(KWin.MaximizeArea, workspace.activeScreen, window.desktop);
    let db = LocalStorage.openDatabaseSync("QDeclarativeExampleDB", "1.0", "The Example QML SQL!", 1000000);

    db.transaction(
      function(tx) {
        const rs = tx.executeSql('SELECT rowid, * FROM spaces WHERE rowid = ' + pos);

        const tmpGap = 10

        let newWidth = ((rs.rows[0].width / 100) * (screen.width - tmpGap)) - tmpGap
        let newHeight = ((rs.rows[0].height / 100) * (screen.height - tmpGap)) - tmpGap
        let newX = ((rs.rows[0].x / 100) * (screen.width - tmpGap)) + tmpGap
        let newY = ((rs.rows[0].y / 100) * (screen.height - tmpGap)) + tmpGap

        window.setMaximize(false, false);
        window.geometry = Qt.rect(newX, newY, newWidth, newHeight);
      }
    )
  }

  ColumnLayout {
    id: mainColumnLayout

    RowLayout {
      id: headerRowLayout

      PlasmaComponents.Label {
        text: "kTile"
        Layout.fillWidth: true
      }

      PlasmaComponents.Button {
        icon.name: showNumbers ? "password-show-on" : "password-show-off"
        onClicked: {
          showNumbers = !showNumbers
        }
      }
      
      PlasmaComponents.Button {
        icon.name: "list-add-symbolic"
        visible: restartButtonVisible
        onClicked: {

          var db = LocalStorage.openDatabaseSync("QDeclarativeExampleDB", "1.0", "The Example QML SQL!", 1000000);

          db.transaction(
            function(tx) {

              // tx.executeSql('DROP TABLE spaces');

              tx.executeSql('CREATE TABLE IF NOT EXISTS spaces(width INTEGER, height INTEGER, x INTEGER, y INTEGER)');
              
              var insert = tx.executeSql('INSERT INTO spaces VALUES(?, ?, ?, ?) RETURNING rowid', [ 50, 50, 0, 0 ]);

              var component = Qt.createComponent("block.qml")
              var object = component.createObject(flowLayout, {
                id: insert.rows[0].rowid,
                boxWidth: 50,
                boxHeight: 50,
                boxX: 0,
                boxY: 0
              });
            }
          )
        }
      }
      
      PlasmaComponents.Button {
        icon.name: "dialog-close"
        onClicked: {
          mainDialog.visible = false;
        }
      }
    }

    Rectangle {
      id: tableBackground
      width: 850
      height: 400
      color: "transparent"

      ScrollView {
        id: scrollview1
        anchors.fill: parent
        anchors.margins: 10
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        
        ColumnLayout {
          width: parent.width

          Flow {
            property int rowCount: parent.width / (200 + spacing)
            property int rowWidth: rowCount * 200 + (rowCount - 1) * spacing
            property int mar: (parent.width - rowWidth) / 2

            id: flowLayout
            width: parent.parent.width
            spacing: 10

            Component.onCompleted: {
              
              var component = Qt.createComponent("block.qml")

              var db = LocalStorage.openDatabaseSync("QDeclarativeExampleDB", "1.0", "The Example QML SQL!", 1000000);

              db.transaction(
                function(tx) {
                  var rs = tx.executeSql('SELECT rowid, * FROM spaces');
                  for (var i = 0; i < rs.rows.length; i++) {
                    var object = component.createObject(flowLayout, {
                      id: rs.rows.item(i).rowid,
                      boxWidth: rs.rows.item(i).width,
                      boxHeight: rs.rows.item(i).height,
                      boxX: rs.rows.item(i).x,
                      boxY: rs.rows.item(i).y
                    });
                  }
                }
              )
            }
          }
        }
      }
    }
  }

  Component.onCompleted: {

    KWin.registerWindow(mainDialog);

    KWin.registerShortcut(
      "kTile",
      "kTile",
      "Ctrl+.",
      function() {
        if (mainDialog.visible) {
          mainDialog.visible = false;
        } else {
          mainDialog.loadConfig();
          mainDialog.show();
        }
      }
    );

    for (var i = 1; i <= 12; i++) {
      let count = i
      KWin.registerShortcut(
        "kTile Position " + count,
        "kTile Position " + count,
        "",
        function() {
          tileWindow(workspace.activeClient, count);
        }
      );
    }

    // KWin.registerShortcut(
    //   "kTile Close",
    //   "kTile Close",
    //   "Escape",
    //   function() {
    //     mainDialog.visible = false;
    //   }
    // );

    mainDialog.loadConfig();
  }
}

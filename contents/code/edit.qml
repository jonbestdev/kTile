import QtQuick 2.0
import QtQuick.Controls 2.12
import QtQuick.LocalStorage 2.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents

Rectangle {
  property int id
  property var dragging: false
  property int cols: 6
  property int rows: 6
  property double editGap: 0
  property double cellWidth: parent.width / cols
  property double cellHeight: parent.height / rows
  property double storeX: 0
  property double storeY: 0
  property double previewWidth: 0
  property double previewHeight: 0
  property double previewX: 0
  property double previewY: 0

  id: edit
  color: "#EDEDEE"
  width: parent.width
  height: parent.height
  x: 0
  y: 0

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    preventStealing: true
    onPositionChanged: {

      var getGridX = Math.floor(mouse.x / cellWidth);
      var getGridY = Math.floor(mouse.y / cellHeight);

      // keep MouseArea values in bounds
      // there's some weirdness with mouse position being tracked while dragging outside component
      if(
        mouse.x >= 0 &&
        mouse.x <= parent.width &&
        mouse.y >= 0 &&
        mouse.y <= parent.height &&
        getGridX < cols &&
        getGridY < rows
      ) {
        if(!dragging) {

          // mouse hover
          hoverBox.width = (cellWidth - editGap)
          hoverBox.height = (cellHeight - editGap)
          hoverBox.x = ((cellWidth * getGridX) + (editGap / 2))
          hoverBox.y = ((cellHeight * getGridY) + (editGap / 2))
          
        } else {

          // mouse drag
          var dirextionX = getGridX - storeX
          var dirextionY = getGridY - storeY

          var cellCountX = (dirextionX < 0 ? dirextionX * -1 : dirextionX) + 1
          var cellCountY = (dirextionY < 0 ? dirextionY * -1 : dirextionY) + 1

          if(dirextionX < 1) {
            hoverBox.x = ((cellWidth * getGridX) + (editGap / 2))
            previewX = (cellWidth * getGridX) + (editGap / 2)
          }

          if(dirextionY < 1) {
            hoverBox.y = ((cellHeight * getGridY) + (editGap / 2))
            previewY = (cellHeight * getGridY) + (editGap / 2)
          }

          hoverBox.width = ((cellWidth * cellCountX) - editGap)
          hoverBox.height = ((cellHeight * cellCountY) - editGap)

          previewWidth = ((cellWidth * cellCountX) - editGap)
          previewHeight = ((cellHeight * cellCountY) - editGap)

        }
      }
    }
    onClicked: {
      print('onClicked')
    }
    onPressed: {
      dragging = true

      storeX = Math.floor(mouse.x / (parent.width / cols))
      storeY = Math.floor(mouse.y / (parent.height / rows))
    }
    onReleased: {
      dragging = false

      var preview = flowLayout.children[(id - 1)]

      preview.boxWidth = (100 * previewWidth) / parent.width
      preview.boxHeight = (100 * previewHeight) / parent.height
      preview.boxX = (100 * previewX) / parent.width
      preview.boxY = (100 * previewY) / parent.height

      // shapePreview.width = (100 * previewWidth) / parent.width
      // shapePreview.height = (100 * previewHeight) / parent.height

      var db = LocalStorage.openDatabaseSync("QDeclarativeExampleDB", "1.0", "The Example QML SQL!", 1000000);

      db.transaction(
        function(tx) {
          tx.executeSql('UPDATE spaces SET width = '+ preview.boxWidth +', height = '+ preview.boxHeight +', x = '+ preview.boxX +', y = '+ preview.boxY +' WHERE rowid = ' + id);
        }
      )
    }
  }

  Rectangle {
    id: hoverBox
    width: 0
    height: 0
    color: "red"
  }

  Rectangle {
    id: shapePreview
    width: 0
    height: 0
    color: "blue"
  }

  Canvas {
    anchors.fill : parent
    visible: true
    onPaint: {

      var ctx = getContext("2d")
      ctx.lineWidth = 1
      ctx.strokeStyle = "black"
      ctx.beginPath()

      var nrows = parent.height/cellHeight;
      for(var i=0; i < nrows+1; i++){
        ctx.moveTo(0, cellHeight*i);
        ctx.lineTo(parent.width, cellHeight*i);
      }

      var ncols = parent.width/cellWidth
      for(var j=0; j < ncols+1; j++){
        ctx.moveTo(cellWidth*j, 0);
        ctx.lineTo(cellWidth*j, parent.height);
      }

      ctx.closePath()
      ctx.stroke()
    }
  }

  PlasmaComponents.Button {
    icon.name: "dialog-close"
    anchors.top: parent.top
    anchors.right: parent.right
    onClicked: {
      print(id);
      this.parent.destroy()
    }
  }
}

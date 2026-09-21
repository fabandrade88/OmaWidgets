pragma Singleton
import QtQuick
import qs.Commons
import "../model/TodoList.js" as TodoList

// The one place in this plugin with colours of its own.
//
// Everything else is themed, and deliberately so. But "how close is this
// deadline" is information, and information that changed meaning with the
// wallpaper would be worse than useless — a red that means calm in one theme is
// a trap. So these four hues are fixed, and only these four. Overdue borrows the
// theme's own urgent colour, so the sharpest state still matches every other
// alarm in the plugin.
QtObject {
  id: root

  readonly property color calm: "#4b8bf5"
  readonly property color soon: "#e8912d"
  readonly property color urgent: "#e0533d"
  readonly property color done: "#3fae62"

  function forUrgency(level) {
    if (level === TodoList.OVERDUE) return Color.urgent
    if (level === TodoList.URGENT) return root.urgent
    if (level === TodoList.SOON) return root.soon
    if (level === TodoList.DONE) return root.done
    if (level === TodoList.CALM) return root.calm
    return Qt.darker(Color.popups.text, 1.45)
  }

  function label(level) {
    if (level === TodoList.OVERDUE) return "overdue"
    if (level === TodoList.URGENT) return "due now"
    if (level === TodoList.SOON) return "due soon"
    if (level === TodoList.DONE) return "done"
    return ""
  }
}

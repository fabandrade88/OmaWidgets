// Every Nerd Font glyph in the source, checked against the font the bar uses.
//
// Two failure modes, and the second is why this test exists. A codepoint the
// font does not carry renders as tofu. And a malformed surrogate pair — two high
// surrogates, say — is not one character at all, which looks like a styling
// problem rather than the typo it is. Neither is visible in a diff.
var fs = require("fs")
var path = require("path")
var t = require("./harness.js")

var FONT = process.env.OMAWIDGETS_FONT
  || "/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf"

// Enough of the TrueType cmap to answer "does this font carry this codepoint",
// without adding a dependency to a repo that otherwise has none.
function cmapCodepoints(file) {
  var d = fs.readFileSync(file)
  var tables = {}
  var count = d.readUInt16BE(4)
  for (var i = 0; i < count; i++) {
    var off = 12 + 16 * i
    tables[d.toString("latin1", off, off + 4)] = d.readUInt32BE(off + 8)
  }
  var codes = {}
  var cmap = tables.cmap
  var subtables = d.readUInt16BE(cmap + 2)
  for (var s = 0; s < subtables; s++) {
    var sub = cmap + d.readUInt32BE(cmap + 4 + 8 * s + 4)
    var format = d.readUInt16BE(sub)
    if (format === 4) {
      var segX2 = d.readUInt16BE(sub + 6)
      for (var seg = 0; seg < segX2 / 2; seg++) {
        var end = d.readUInt16BE(sub + 14 + seg * 2)
        var start = d.readUInt16BE(sub + 16 + segX2 + seg * 2)
        if (start === 0xFFFF) continue
        for (var c = start; c <= end; c++) codes[c] = true
      }
    } else if (format === 12) {
      var groups = d.readUInt32BE(sub + 12)
      for (var g = 0; g < groups; g++) {
        var q = sub + 16 + 12 * g
        var gs = d.readUInt32BE(q)
        var ge = d.readUInt32BE(q + 4)
        if (ge - gs > 0x20000) continue
        for (var cp = gs; cp <= ge; cp++) codes[cp] = true
      }
    }
  }
  return codes
}

function sources(dir) {
  var out = []
  fs.readdirSync(dir).forEach(function (name) {
    if (name === "tests" || name === ".git" || name === "docs") return
    var full = path.join(dir, name)
    if (fs.statSync(full).isDirectory()) { out = out.concat(sources(full)); return }
    if (/[.](qml|js)$/.test(name)) out.push(full)
  })
  return out
}

if (!fs.existsSync(FONT)) {
  console.log("skip glyphs — " + FONT + " not installed")
  process.exit(0)
}

var codes = cmapCodepoints(FONT)
var root = path.join(__dirname, "..")
var ESCAPE = /\\u([0-9a-fA-F]{4})/g

// Glyphs live in the source as literal characters, so the check walks the text.
// Anything at or above U+E000 is private use, which in this codebase means a
// Nerd Font icon.
function checkCharacters(line, where) {
  for (var i = 0; i < line.length; i++) {
    var unit = line.charCodeAt(i)
    // Surrogates come first: a code unit in D800..DFFF is numerically BELOW
    // 0xE000, so testing the private-use floor first would skip every glyph
    // above the basic plane — which is all of them.
    if (unit >= 0xD800 && unit <= 0xDBFF) {
      var low = line.charCodeAt(i + 1)
      if (!(low >= 0xDC00 && low <= 0xDFFF)) {
        t.ok(false, where + ": an unpaired high surrogate at column " + (i + 1))
        continue
      }
      i++
      var cp = 0x10000 + ((unit - 0xD800) << 10) + (low - 0xDC00)
      t.ok(codes[cp] === true,
        where + ": U+" + cp.toString(16).toUpperCase() + " is not in " + path.basename(FONT))
      continue
    }
    if (unit >= 0xDC00 && unit <= 0xDFFF) {
      t.ok(false, where + ": an unpaired low surrogate at column " + (i + 1))
      continue
    }
    if (unit < 0xE000) continue
    t.ok(codes[unit] === true,
      where + ": U+" + unit.toString(16).toUpperCase() + " is not in " + path.basename(FONT))
  }
}

// Escapes are checked separately: a JS engine turns a bad pair into two lone
// surrogates silently, and by the time the file is a string the text walk above
// cannot tell it apart from a deliberate one.
function checkEscapes(line, where) {
  var units = []
  var match
  ESCAPE.lastIndex = 0
  while ((match = ESCAPE.exec(line)) !== null) units.push(parseInt(match[1], 16))

  for (var i = 0; i < units.length; i++) {
    var unit = units[i]
    if (unit >= 0xDC00 && unit <= 0xDFFF) {
      t.ok(false, where + ": a low surrogate escape with no high surrogate before it")
      continue
    }
    if (unit < 0xD800 || unit > 0xDBFF) continue
    var low = units[i + 1]
    if (!(low >= 0xDC00 && low <= 0xDFFF)) {
      t.ok(false, where + ": a high surrogate escape not followed by a low one,"
        + " which is not one character")
      continue
    }
    i++
    var cp = 0x10000 + ((unit - 0xD800) << 10) + (low - 0xDC00)
    t.ok(codes[cp] === true,
      where + ": escaped U+" + cp.toString(16).toUpperCase() + " is not in " + path.basename(FONT))
  }
}

var files = sources(root)
t.ok(files.length > 10, "the scan found the source files (" + files.length + ")")

files.forEach(function (file) {
  var label = path.relative(root, file)
  fs.readFileSync(file, "utf8").split("\n").forEach(function (line, index) {
    var where = label + ":" + (index + 1)
    checkCharacters(line, where)
    checkEscapes(line, where)
  })
})

process.exit(t.report("glyphs"))

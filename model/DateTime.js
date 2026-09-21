// Reading and writing dates the way the user writes them.
//
// Parsing is done here rather than handed to Qt's locale parser so that what a
// deadline field accepts is decided by the setting rather than by whatever
// locale the session happens to have, and so it can be tested without one.
//
// The default is day-first and 24-hour, which is what most of the world writes.
var DAY_FIRST_DASH = "dd-MM-yyyy"
var DAY_FIRST_SLASH = "dd/MM/yyyy"
var ISO = "yyyy-MM-dd"
var MONTH_FIRST = "MM/dd/yyyy"

var HOUR_24 = "24h"
var HOUR_12 = "12h"

var DATE_FORMATS = [DAY_FIRST_DASH, DAY_FIRST_SLASH, ISO, MONTH_FIRST]
var TIME_FORMATS = [HOUR_24, HOUR_12]

var DATE_LABELS = {}
DATE_LABELS[DAY_FIRST_DASH] = "DD-MM-YYYY"
DATE_LABELS[DAY_FIRST_SLASH] = "DD/MM/YYYY"
DATE_LABELS[ISO] = "YYYY-MM-DD"
DATE_LABELS[MONTH_FIRST] = "MM/DD/YYYY"

var MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
var WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

function dateFormat(value) {
  return DATE_FORMATS.indexOf(String(value || "")) !== -1 ? String(value) : DAY_FIRST_DASH
}

function timeFormat(value) {
  return TIME_FORMATS.indexOf(String(value || "")) !== -1 ? String(value) : HOUR_24
}

function dateLabel(format) {
  return DATE_LABELS[dateFormat(format)]
}

function pad(n) {
  return (n < 10 ? "0" : "") + n
}

// Separators are accepted interchangeably, because someone typing a date in a
// hurry should not have to remember which one the setting asked for.
function parseDate(text, format) {
  var parts = String(text || "").trim().split(/[-/.\s]+/)
  if (parts.length !== 3) return null
  var numbers = []
  for (var i = 0; i < 3; i++) {
    if (!/^\d{1,4}$/.test(parts[i])) return null
    numbers.push(parseInt(parts[i], 10))
  }

  var chosen = dateFormat(format)
  var year, month, day
  if (chosen === ISO) {
    year = numbers[0]; month = numbers[1]; day = numbers[2]
  } else if (chosen === MONTH_FIRST) {
    month = numbers[0]; day = numbers[1]; year = numbers[2]
  } else {
    day = numbers[0]; month = numbers[1]; year = numbers[2]
  }

  // A two-digit year means this century. Anyone entering a deadline in 1998 can
  // write it out.
  if (year < 100) year += 2000
  if (year < 1970 || year > 9999) return null
  if (month < 1 || month > 12) return null
  if (day < 1 || day > 31) return null

  // Rejects the 31st of a thirty-day month rather than rolling into the next.
  var probe = new Date(year, month - 1, day)
  if (probe.getFullYear() !== year || probe.getMonth() !== month - 1 || probe.getDate() !== day)
    return null
  return { year: year, month: month, day: day }
}

// Accepts "18:00", "1800", "6pm", "6:30 PM". An empty time means the end of the
// day, so a date on its own is a deadline rather than midnight that morning.
function parseTime(text, format) {
  var body = String(text || "").trim().toLowerCase()
  if (body === "") return { hour: 23, minute: 59 }

  var suffix = ""
  var meridiem = body.match(/(am|pm)\s*$/)
  if (meridiem) {
    suffix = meridiem[1]
    body = body.replace(/(am|pm)\s*$/, "").trim()
  }

  var hour, minute
  var colon = body.match(/^(\d{1,2})[:.h](\d{2})$/)
  var bare = body.match(/^(\d{1,2})$/)
  var packed = body.match(/^(\d{2})(\d{2})$/)
  if (colon) { hour = parseInt(colon[1], 10); minute = parseInt(colon[2], 10) }
  else if (packed) { hour = parseInt(packed[1], 10); minute = parseInt(packed[2], 10) }
  else if (bare) { hour = parseInt(bare[1], 10); minute = 0 }
  else return null

  if (suffix === "pm" && hour < 12) hour += 12
  if (suffix === "am" && hour === 12) hour = 0
  // A twelve-hour setting without am or pm is ambiguous, not invalid: whichever
  // hour was typed is taken at face value.
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null
  return { hour: hour, minute: minute }
}

function toTimestamp(dateParts, timeParts) {
  if (!dateParts) return 0
  var t = timeParts || { hour: 23, minute: 59 }
  return new Date(dateParts.year, dateParts.month - 1, dateParts.day, t.hour, t.minute, 0, 0).getTime()
}

function formatTime(date, format) {
  if (!date) return ""
  var hour = date.getHours()
  var minute = date.getMinutes()
  if (timeFormat(format) === HOUR_12) {
    var suffix = hour >= 12 ? "pm" : "am"
    var shown = hour % 12
    if (shown === 0) shown = 12
    return shown + ":" + pad(minute) + " " + suffix
  }
  return pad(hour) + ":" + pad(minute)
}

function formatDate(date, format) {
  if (!date) return ""
  var d = pad(date.getDate())
  var m = pad(date.getMonth() + 1)
  var y = date.getFullYear()
  var chosen = dateFormat(format)
  if (chosen === ISO) return y + "-" + m + "-" + d
  if (chosen === MONTH_FIRST) return m + "/" + d + "/" + y
  if (chosen === DAY_FIRST_SLASH) return d + "/" + m + "/" + y
  return d + "-" + m + "-" + y
}

// The deadline said the way a person would: a time today, a weekday this week,
// and the full date beyond that.
function deadlineLabel(at, now, dateFmt, timeFmt) {
  if (!(at > 0) || !isFinite(at)) return ""
  var when = new Date(at)
  // A timestamp beyond what Date can represent yields an Invalid Date, whose
  // every accessor is NaN — which would render as "NaN:NaN" rather than as
  // nothing.
  if (isNaN(when.getTime())) return ""
  var today = new Date(typeof now === "number" && now > 0 ? now : Date.now())
  var time = formatTime(when, timeFmt)
  if (when.toDateString() === today.toDateString()) return time
  var days = Math.round((when - today) / 86400000)
  if (days >= 0 && days < 7) return WEEKDAYS[when.getDay()] + " " + time
  if (when.getFullYear() === today.getFullYear())
    return when.getDate() + " " + MONTHS[when.getMonth()] + " " + time
  return formatDate(when, dateFmt) + " " + time
}

// What the composer's fields should show when empty.
function datePlaceholder(format) {
  var sample = new Date(2026, 8, 30)
  return formatDate(sample, format)
}

function timePlaceholder(format) {
  return timeFormat(format) === HOUR_12 ? "6:00 pm" : "18:00"
}

if (typeof module !== "undefined") {
  module.exports = {
    DAY_FIRST_DASH: DAY_FIRST_DASH, DAY_FIRST_SLASH: DAY_FIRST_SLASH,
    ISO: ISO, MONTH_FIRST: MONTH_FIRST,
    HOUR_24: HOUR_24, HOUR_12: HOUR_12,
    DATE_FORMATS: DATE_FORMATS, TIME_FORMATS: TIME_FORMATS,
    dateFormat: dateFormat, timeFormat: timeFormat, dateLabel: dateLabel,
    parseDate: parseDate, parseTime: parseTime, toTimestamp: toTimestamp,
    formatTime: formatTime, formatDate: formatDate,
    deadlineLabel: deadlineLabel,
    datePlaceholder: datePlaceholder, timePlaceholder: timePlaceholder
  }
}

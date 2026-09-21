// Reading and writing deadlines the way the user writes them.
var t = require("./harness.js")
var D = require("../model/DateTime.js")

// --------------------------------------------------------------- parsing

// Day-first and 24-hour by default, which is what most of the world writes.
t.eq(D.dateFormat(undefined), D.DAY_FIRST_DASH, "the default date format is day first")
t.eq(D.timeFormat(undefined), D.HOUR_24, "and the default clock is 24 hour")
t.eq(D.dateFormat("nonsense"), D.DAY_FIRST_DASH, "an unknown format falls back")
t.eq(D.dateLabel(D.MONTH_FIRST), "MM/DD/YYYY", "each format has a label to show in settings")

function parsed(text, fmt) {
  var p = D.parseDate(text, fmt)
  return p ? p.day + "/" + p.month + "/" + p.year : null
}

t.eq(parsed("30-09-2026", D.DAY_FIRST_DASH), "30/9/2026", "day first reads day first")
t.eq(parsed("09-30-2026", D.MONTH_FIRST), "30/9/2026", "month first reads month first")
t.eq(parsed("2026-09-30", D.ISO), "30/9/2026", "ISO reads year first")
t.eq(parsed("30/09/2026", D.DAY_FIRST_SLASH), "30/9/2026", "slashes are a format of their own")

// Someone typing a date in a hurry should not have to remember which separator
// the setting asked for.
t.eq(parsed("30/09/2026", D.DAY_FIRST_DASH), "30/9/2026", "a slash is accepted in a dash format")
t.eq(parsed("30.09.2026", D.DAY_FIRST_DASH), "30/9/2026", "as is a dot")
t.eq(parsed("30 09 2026", D.DAY_FIRST_DASH), "30/9/2026", "and a space")
t.eq(parsed("1-9-2026", D.DAY_FIRST_DASH), "1/9/2026", "single digits need no padding")
t.eq(parsed("30-09-26", D.DAY_FIRST_DASH), "30/9/2026", "a two-digit year means this century")

// A date that does not exist must be refused rather than rolled forward, which
// is what Date() does with it by default.
t.eq(D.parseDate("31-09-2026", D.DAY_FIRST_DASH), null, "the 31st of September is not a date")
t.eq(D.parseDate("29-02-2025", D.DAY_FIRST_DASH), null, "nor is the 29th of a common February")
t.eq(parsed("29-02-2024", D.DAY_FIRST_DASH), "29/2/2024", "but a leap year has one")
t.eq(D.parseDate("30-13-2026", D.DAY_FIRST_DASH), null, "there is no thirteenth month")
t.eq(D.parseDate("", D.DAY_FIRST_DASH), null, "an empty date is no date")
t.eq(D.parseDate("tomorrow", D.DAY_FIRST_DASH), null, "and neither is a word")
t.eq(D.parseDate("30-09", D.DAY_FIRST_DASH), null, "a date needs all three parts")

function time(text, fmt) {
  var p = D.parseTime(text, fmt)
  return p ? p.hour + ":" + p.minute : null
}

t.eq(time("18:00"), "18:0", "a 24-hour time reads as written")
t.eq(time("18.30"), "18:30", "a dot separates as well as a colon")
t.eq(time("1830"), "18:30", "four digits need no separator at all")
t.eq(time("9"), "9:0", "a bare hour is on the hour")
t.eq(time("6pm"), "18:0", "pm shifts the afternoon")
t.eq(time("6:30 PM"), "18:30", "in either case, with or without a space")
t.eq(time("12am"), "0:0", "midnight is zero, not twelve")
t.eq(time("12pm"), "12:0", "and noon is twelve")
// A date on its own is a deadline for that day, not midnight that morning.
t.eq(time(""), "23:59", "no time means the end of the day")
t.eq(D.parseTime("25:00"), null, "there is no twenty-fifth hour")
t.eq(D.parseTime("18:70"), null, "nor a seventieth minute")
t.eq(D.parseTime("noon"), null, "and a word is not a time")

// ------------------------------------------------------------- formatting

var sample = new Date(2026, 8, 30, 18, 5)
t.eq(D.formatDate(sample, D.DAY_FIRST_DASH), "30-09-2026", "day first writes day first")
t.eq(D.formatDate(sample, D.ISO), "2026-09-30", "ISO writes year first")
t.eq(D.formatDate(sample, D.MONTH_FIRST), "09/30/2026", "month first writes month first")
t.eq(D.formatTime(sample, D.HOUR_24), "18:05", "a 24-hour clock pads the hour")
t.eq(D.formatTime(sample, D.HOUR_12), "6:05 pm", "a 12-hour clock does not, and says which half")
t.eq(D.formatTime(new Date(2026, 8, 30, 0, 5), D.HOUR_12), "12:05 am", "midnight reads as twelve")
t.eq(D.formatTime(new Date(2026, 8, 30, 12, 0), D.HOUR_12), "12:00 pm", "so does noon")

// What the composer shows when empty has to match what it will accept.
t.eq(D.datePlaceholder(D.DAY_FIRST_DASH), "30-09-2026", "the placeholder is in the chosen format")
t.eq(D.datePlaceholder(D.ISO), "2026-09-30", "whichever one that is")
t.eq(D.timePlaceholder(D.HOUR_12), "6:00 pm", "and so is the time placeholder")
t.eq(D.parseDate(D.datePlaceholder(D.MONTH_FIRST), D.MONTH_FIRST) !== null, true,
  "so the placeholder itself always parses")

// --------------------------------------------------------------- labels

var now = new Date(2026, 8, 30, 9, 0).getTime()
t.eq(D.deadlineLabel(new Date(2026, 8, 30, 18, 0).getTime(), now, D.DAY_FIRST_DASH, D.HOUR_24),
  "18:00", "later today is just a time")
t.eq(D.deadlineLabel(new Date(2026, 9, 2, 18, 0).getTime(), now, D.DAY_FIRST_DASH, D.HOUR_24),
  "Fri 18:00", "later this week is a weekday")
t.eq(D.deadlineLabel(new Date(2026, 10, 20, 18, 0).getTime(), now, D.DAY_FIRST_DASH, D.HOUR_24),
  "20 Nov 18:00", "later this year is a day and a month")
t.eq(D.deadlineLabel(new Date(2027, 1, 3, 18, 0).getTime(), now, D.DAY_FIRST_DASH, D.HOUR_24),
  "03-02-2027 18:00", "and beyond that the full date, in the chosen format")
t.eq(D.deadlineLabel(new Date(2027, 1, 3, 18, 0).getTime(), now, D.MONTH_FIRST, D.HOUR_12),
  "02/03/2027 6:00 pm", "both settings apply to it")
t.eq(D.deadlineLabel(0, now, D.DAY_FIRST_DASH, D.HOUR_24), "", "no deadline, no label")

// ------------------------------------------------------------ round trip

var stamp = D.toTimestamp(D.parseDate("30-09-2026", D.DAY_FIRST_DASH), D.parseTime("18:00"))
t.eq(new Date(stamp).getHours(), 18, "a parsed deadline keeps its hour")
t.eq(new Date(stamp).getDate(), 30, "and its day")
t.eq(D.toTimestamp(null, { hour: 9, minute: 0 }), 0, "no date means no deadline, whatever the time")
t.eq(new Date(D.toTimestamp(D.parseDate("30-09-2026", D.DAY_FIRST_DASH), null)).getHours(), 23,
  "a date with no time is due at the end of it")

process.exit(t.report("datetime"))

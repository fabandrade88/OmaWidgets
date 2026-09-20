// GPU readings, normalised across the three driver families that expose
// completely different things.
//
//   amdgpu   gpu_busy_percent, hwmon temp, mem_info_vram_used/total
//   nvidia   nothing in sysfs; nvidia-smi reports all four
//   i915/xe  clock and (sometimes) temperature, and no busy counter at all
//
// The Intel case is why `busy` can be UNKNOWN. intel_gpu_top can produce a real
// utilisation figure, but only with CAP_PERFMON or a relaxed
// perf_event_paranoid — a privilege no shell plugin should ask a user to grant.
// So an Intel card reports the clock it is actually running at and leaves
// utilisation blank, rather than showing a number that was guessed.
var UNKNOWN = -1

var AMD = "amd"
var NVIDIA = "nvidia"
var INTEL = "intel"
var OTHER = "other"

function num(raw, fallback) {
  if (typeof raw === "number") return isFinite(raw) ? raw : fallback
  var text = String(raw === undefined || raw === null ? "" : raw).trim()
  if (text === "") return fallback
  var n = Number(text)
  return isFinite(n) ? n : fallback
}

function vendorFromDriver(driver) {
  var name = String(driver || "").trim().toLowerCase()
  if (name === "amdgpu" || name === "radeon") return AMD
  if (name === "nvidia" || name === "nouveau") return NVIDIA
  if (name === "i915" || name === "xe") return INTEL
  return OTHER
}

function empty() {
  return {
    present: false,
    vendor: OTHER,
    driver: "",
    name: "",
    busy: UNKNOWN,
    temperature: UNKNOWN,
    temperatureIsShared: false,
    frequency: UNKNOWN,
    maxFrequency: UNKNOWN,
    memoryUsedMib: UNKNOWN,
    memoryTotalMib: UNKNOWN,
    memoryFraction: UNKNOWN,
    power: UNKNOWN
  }
}

// nvidia-smi --query-gpu=name,utilization.gpu,temperature.gpu,clocks.current.graphics,
//   clocks.max.graphics,memory.used,memory.total,power.draw --format=csv,noheader,nounits
// Fields are positional, and any of them can be "[N/A]" on a laptop GPU that is
// powered down, which num() turns back into UNKNOWN.
function parseNvidiaSmi(text) {
  var line = String(text || "").trim().split("\n")[0] || ""
  if (line === "") return empty()
  var f = line.split(",")
  if (f.length < 7) return empty()
  var used = num(f[5], UNKNOWN)
  var total = num(f[6], UNKNOWN)
  var gpu = empty()
  gpu.present = true
  gpu.vendor = NVIDIA
  gpu.driver = "nvidia"
  gpu.name = String(f[0] || "").trim()
  gpu.busy = clampPercent(num(f[1], UNKNOWN))
  gpu.temperature = toMilli(num(f[2], UNKNOWN))
  gpu.frequency = num(f[3], UNKNOWN)
  gpu.maxFrequency = num(f[4], UNKNOWN)
  gpu.memoryUsedMib = used
  gpu.memoryTotalMib = total
  gpu.memoryFraction = total > 0 && used >= 0 ? Math.max(0, Math.min(1, used / total)) : UNKNOWN
  gpu.power = num(f[7], UNKNOWN)
  return gpu
}

function clampPercent(value) {
  if (!(value >= 0)) return UNKNOWN
  return Math.max(0, Math.min(1, value / 100))
}

function toMilli(celsius) {
  return celsius > UNKNOWN ? celsius * 1000 : UNKNOWN
}

// Builds the reading from raw sysfs node contents. `fields` keys mirror the
// probe's output names, so a node the machine does not have is simply absent.
function fromSysfs(descriptor, fields) {
  var source = fields || {}
  var gpu = empty()
  gpu.present = true
  gpu.driver = String(descriptor && descriptor.driver || "")
  gpu.vendor = vendorFromDriver(gpu.driver)
  gpu.name = String(descriptor && descriptor.name || "")

  gpu.busy = clampPercent(num(source.busy, UNKNOWN))
  gpu.temperature = clampTemperature(num(source.temperature, UNKNOWN))
  gpu.temperatureIsShared = descriptor ? descriptor.temperatureIsShared === true : false
  // amdgpu's hwmon reports hertz where i915 and xe report megahertz, so the
  // probe records which unit this driver speaks and the scale is applied once,
  // here, rather than in each card.
  var scale = String(descriptor && descriptor.frequencyUnit || "mhz") === "hz" ? 1 / 1000000 : 1
  gpu.frequency = positive(num(source.frequency, UNKNOWN) * scale)
  // xe and i915 report 0 MHz for a GT that has been powered down. That is a
  // real state, not a missing reading, so it stays 0 and the card shows "idle".
  if (gpu.frequency === UNKNOWN && String(source.frequency || "").trim() === "0") gpu.frequency = 0
  gpu.maxFrequency = positive(num(source.maxFrequency, UNKNOWN) * scale)

  var usedBytes = num(source.memoryUsed, UNKNOWN)
  var totalBytes = num(source.memoryTotal, UNKNOWN)
  if (usedBytes >= 0 && totalBytes > 0) {
    gpu.memoryUsedMib = usedBytes / 1048576
    gpu.memoryTotalMib = totalBytes / 1048576
    gpu.memoryFraction = Math.max(0, Math.min(1, usedBytes / totalBytes))
  }
  var microwatts = num(source.power, UNKNOWN)
  if (microwatts > 0) gpu.power = microwatts / 1000000
  return gpu
}

function clampTemperature(milli) {
  if (!(milli > UNKNOWN)) return UNKNOWN
  if (milli < -40000 || milli > 150000) return UNKNOWN
  return milli
}

function positive(value) {
  return value > 0 ? value : UNKNOWN
}

// What the card shows as its headline. A vendor with no busy counter leads with
// the clock instead, so the biggest number on the card is always a measurement.
function headline(gpu) {
  if (!gpu || !gpu.present) return { kind: "absent", value: UNKNOWN }
  if (gpu.busy > UNKNOWN) return { kind: "busy", value: gpu.busy }
  if (gpu.maxFrequency > 0 && gpu.frequency > UNKNOWN)
    return { kind: "clock", value: Math.max(0, Math.min(1, gpu.frequency / gpu.maxFrequency)) }
  return { kind: "idle", value: UNKNOWN }
}

if (typeof module !== "undefined") {
  module.exports = {
    UNKNOWN: UNKNOWN,
    AMD: AMD, NVIDIA: NVIDIA, INTEL: INTEL, OTHER: OTHER,
    vendorFromDriver: vendorFromDriver,
    empty: empty,
    parseNvidiaSmi: parseNvidiaSmi,
    fromSysfs: fromSysfs,
    headline: headline
  }
}

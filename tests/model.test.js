var t = require("./harness.js")
var Format = require("../model/Format.js")
var Sysfs = require("../model/Sysfs.js")
var Gpu = require("../model/Gpu.js")
var Series = require("../model/Series.js")

// --------------------------------------------------------------------- Format

t.eq(Format.toNumber("42", 0), 42, "toNumber parses digits")
t.eq(Format.toNumber("", 7), 7, "toNumber falls back on empty")
t.eq(Format.toNumber("[N/A]", -1), -1, "toNumber falls back on nvidia-smi N/A")
t.eq(Format.toNumber(undefined, -1), -1, "toNumber falls back on undefined")
t.eq(Format.toNumber(NaN, -1), -1, "toNumber rejects NaN")
t.eq(Format.percent(0.3256), "33%", "percent rounds")
t.eq(Format.percent(1.5), "100%", "percent clamps above one")
t.eq(Format.percent(-4), "0%", "percent clamps below zero")
t.eq(Format.fromKib(15929712), "15 GB", "fromKib reports whole gigabytes above ten")
t.eq(Format.fromKib(2621440), "2.5 GB", "fromKib keeps one decimal below ten")
t.eq(Format.fromKib(524288), "512 MB", "fromKib stays in megabytes under a gigabyte")
t.eq(Format.celsius(45050), "45°", "celsius rounds millidegrees")
t.eq(Format.celsius(""), "", "celsius yields nothing for an empty sensor")
t.eq(Format.megahertz(2400), "2.4 GHz", "megahertz promotes to gigahertz")
t.eq(Format.megahertz(0), "", "megahertz treats zero as no reading")
t.eq(Format.duration(8040), "2h 14m", "duration splits hours and minutes")
t.eq(Format.duration(2820), "47m", "duration stays in minutes under an hour")
t.eq(Format.duration(0), "", "duration yields nothing for no estimate")
t.eq(Format.duration(3599), "1h", "duration rolls 60 rounded minutes into an hour")
t.eq(Format.joinMeta(["a", "", null, "b"]), "a · b", "joinMeta drops empty parts")
t.eq(Format.joinMeta([]), "", "joinMeta of nothing is empty")

// ---------------------------------------------------------------------- Sysfs

var STAT_A = "cpu  100 0 100 800 0 0 0 0 0 0\ncpu0 50 0 50 400 0 0 0\ncpu1 50 0 50 400 0 0 0\nintr 1 2 3\n"
var STAT_B = "cpu  200 0 200 1600 0 0 0 0 0 0\ncpu0 150 0 150 700 0 0 0\ncpu1 50 0 50 900 0 0 0\nintr 9\n"

var a = Sysfs.parseCpuStat(STAT_A)
var b = Sysfs.parseCpuStat(STAT_B)
t.eq(a.cores.length, 2, "parseCpuStat finds both cores")
t.eq(a.overall.total, 1000, "parseCpuStat totals every field")
t.eq(a.overall.idle, 800, "parseCpuStat counts idle and iowait as not busy")
t.eq(Sysfs.cpuLoad(a, b).overall, 0.2, "cpuLoad diffs two samples")
t.eq(Sysfs.cpuLoad(a, b).cores[0], 0.4, "cpuLoad diffs per core")
t.eq(Sysfs.cpuLoad(null, b).overall, Sysfs.UNKNOWN, "cpuLoad of one sample is unknown")
t.eq(Sysfs.cpuLoad(a, a).overall, Sysfs.UNKNOWN, "an unmoved counter carries no load")
t.eq(Sysfs.parseCpuStat("").overall, null, "parseCpuStat of nothing yields nothing")

var mem = Sysfs.parseMeminfo("MemTotal: 1000 kB\nMemFree: 100 kB\nMemAvailable: 400 kB\n"
  + "Cached: 250 kB\nBuffers: 50 kB\nSwapTotal: 2000 kB\nSwapFree: 1500 kB\n")
t.eq(mem.totalKib, 1000, "parseMeminfo reads the total")
t.eq(mem.usedKib, 600, "used is total minus available, not total minus free")
t.eq(mem.fraction, 0.6, "memory fraction follows MemAvailable")
t.eq(mem.swapFraction, 0.25, "swap fraction follows SwapFree")
var legacy = Sysfs.parseMeminfo("MemTotal: 1000 kB\nMemFree: 100 kB\nCached: 250 kB\nBuffers: 50 kB\n")
t.eq(legacy.availableKib, 400, "a kernel without MemAvailable falls back to free plus caches")
t.eq(Sysfs.parseMeminfo("").fraction, Sysfs.UNKNOWN, "no meminfo means no fraction")

t.eq(Sysfs.parseTemperature("45000"), 45000, "parseTemperature keeps millidegrees")
t.eq(Sysfs.parseTemperature(""), Sysfs.UNKNOWN, "an empty sensor is not zero degrees")
t.eq(Sysfs.parseTemperature("900000"), Sysfs.UNKNOWN, "an impossible temperature is rejected")
t.eq(Sysfs.parseCpuFrequency("2400000"), 2400, "cpu frequency converts kHz to MHz")
t.eq(Sysfs.parseCpuFrequency("0"), Sysfs.UNKNOWN, "a zero clock is no reading")
t.eq(Sysfs.parseLoadAvg("0.52 0.58 0.59 2/1234 5678").one, 0.52, "parseLoadAvg reads the one-minute average")

// ------------------------------------------------------------------------ Gpu

var nvidia = Gpu.parseNvidiaSmi("NVIDIA GeForce RTX 4070, 61, 68, 1900, 2610, 3480, 8188, 74.21")
t.eq(nvidia.vendor, Gpu.NVIDIA, "nvidia-smi output is an nvidia card")
t.eq(nvidia.busy, 0.61, "nvidia utilisation becomes a fraction")
t.eq(nvidia.temperature, 68000, "nvidia temperature becomes millidegrees")
t.eq(Math.round(nvidia.memoryFraction * 100), 43, "nvidia VRAM fraction")
t.eq(Gpu.parseNvidiaSmi("GPU, [N/A], [N/A], [N/A], [N/A], [N/A], [N/A], [N/A]").busy, Gpu.UNKNOWN,
  "a powered-down nvidia card reports no utilisation rather than zero")
t.eq(Gpu.parseNvidiaSmi("").present, false, "no nvidia-smi output means no card")

var intel = Gpu.fromSysfs({ driver: "xe", name: "Intel Graphics", frequencyUnit: "mhz",
  temperatureIsShared: true }, { frequency: "450", maxFrequency: "1800", temperature: "46000" })
t.eq(intel.vendor, Gpu.INTEL, "xe is an intel card")
t.eq(intel.busy, Gpu.UNKNOWN, "intel reports no busy counter")
t.eq(intel.frequency, 450, "intel frequency is already in megahertz")
t.eq(intel.temperatureIsShared, true, "a shared package sensor is marked as shared")
t.eq(Gpu.headline(intel).kind, "clock", "an intel card leads with its clock")
t.eq(Gpu.headline(intel).value, 0.25, "the clock headline is a fraction of the maximum")
t.eq(Gpu.fromSysfs({ driver: "xe" }, { frequency: "0" }).frequency, 0,
  "a powered-down GT reports zero megahertz, which is a real state")

var amd = Gpu.fromSysfs({ driver: "amdgpu", frequencyUnit: "hz" },
  { busy: "37", frequency: "1200000000", temperature: "52000",
    memoryUsed: "1288490188", memoryTotal: "8589934592", power: "45000000" })
t.eq(amd.busy, 0.37, "amdgpu busy percent becomes a fraction")
t.eq(amd.frequency, 1200, "amdgpu hertz are scaled to megahertz")
t.eq(Math.round(amd.memoryTotalMib), 8192, "amdgpu VRAM total in mebibytes")
t.eq(amd.power, 45, "amdgpu microwatts become watts")
t.eq(Gpu.headline(amd).kind, "busy", "an amd card leads with utilisation")
t.eq(Gpu.headline(Gpu.empty()).kind, "absent", "no card, no headline")

// --------------------------------------------------------------------- Series

t.eq(Series.create(8).length, 8, "a new series is prefilled to its cap")
t.eq(Series.create(8)[0], Series.UNKNOWN, "a new series holds no readings")
var s = Series.create(4)
for (var i = 0; i < 20; i++) s = Series.push(s, i / 20, 4)
t.eq(s.length, 4, "push never grows past the cap")
t.eq(s[3], 19 / 20, "the newest sample is last")
t.eq(Series.push(s, 5, 4)[3], 1, "a sample above one is clamped")
t.eq(Series.push(s, -3, 4)[3], Series.UNKNOWN, "a negative sample is unknown, not zero")
t.eq(Series.latest(Series.create(4)), Series.UNKNOWN, "an empty series has no latest reading")
t.eq(Series.capacity(100000), 240, "capacity is bounded so a fast timer cannot grow it without limit")

process.exit(t.report("model"))

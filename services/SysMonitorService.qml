pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root
    property int refCount: 0
    property int updateInterval: refCount > 0 ? 2000 : 30000
    property int maxProcesses: 100
    property bool isUpdating: false

    property var processes: []
    property string sortBy: "cpu"
    property bool sortDescending: true

    property real cpuUsage: 0
    property real totalCpuUsage: 0
    property int cpuCores: 1
    property int cpuCount: 1
    property string cpuModel: ""
    property real cpuFrequency: 0
    property real cpuTemperature: 0
    property var perCoreCpuUsage: []
    property var perCoreCpuUsagePrev: []

    property var lastCpuStats: null
    property var lastPerCoreStats: null

    property real memoryUsage: 0
    property real totalMemoryMB: 0
    property real usedMemoryMB: 0
    property real freeMemoryMB: 0
    property real availableMemoryMB: 0
    property int totalMemoryKB: 0
    property int usedMemoryKB: 0
    property int totalSwapKB: 0
    property int usedSwapKB: 0

    property real networkRxRate: 0
    property real networkTxRate: 0
    property var lastNetworkStats: null

    property real diskReadRate: 0
    property real diskWriteRate: 0
    property var lastDiskStats: null
    property var diskMounts: []

    property int historySize: 60
    property var cpuHistory: []
    property var memoryHistory: []
    property var networkHistory: ({
            "rx": [],
            "tx": []
        })
    property var diskHistory: ({
            "read": [],
            "write": []
        })

    property string kernelVersion: ""
    property string distribution: ""
    property string hostname: ""
    property string architecture: ""
    property string loadAverage: ""
    property int processCount: 0
    property int threadCount: 0
    property string bootTime: ""
    property string motherboard: ""
    property string biosVersion: ""

    // GPU Monitoring Properties

    property var gpus: [] // Array of GPU objects: {vendor, name, usage, temperature, memoryUsed, memoryTotal, card, busId}
    property var _gpuDetectCallback: null

    property string gpuDetectScript: "
for card in /sys/class/drm/card[0-9]*; do
    [ -d \"$card/device\" ] || continue
    case \"$card\" in
        *-*) continue ;;
    esac
    driver=\$(cat \"$card/device/uevent\" 2>/dev/null | grep ^DRIVER= | cut -d= -f2)
    vendor=\$(cat \"$card/device/vendor\" 2>/dev/null)
    device=\$(cat \"$card/device/device\" 2>/dev/null)
    name=\$(cat \"$card/device/uevent\" 2>/dev/null | grep ^DRIVER= | cut -d= -f2)
    busid=\$(basename \"$card\")
    pciid=\$(basename \$(readlink -f \"$card/device\") 2>/dev/null)
    if [ \"\$driver\" = \"nvidia\" ]; then
        type=\"NVIDIA\"
    elif [ -f \"$card/device/gpu_busy_percent\" ]; then
        type=\"GENERIC\"
    else
        type=\"UNKNOWN\"
    fi
    echo \"\$busid|\$type|\$vendor|\$device|\$name|\$pciid\"
done | awk -F'|' '!seen[\$6]++ {print \$0}'
"

    Process {
        id: gpuDetectProcess
        property var _callback: null
        command: ["sh", "-c", root.gpuDetectScript]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (typeof gpuDetectProcess._callback === "function") {
                    gpuDetectProcess._callback(text);
                }
            }
        }
    }

    Process {
        id: nvidiaStatsProcess
        property var _callback: null
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (typeof nvidiaStatsProcess._callback === "function") {
                    nvidiaStatsProcess._callback(text);
                }
            }
        }
    }

    // Helper: Find first matching file for a glob pattern (for hwmon)
    function findFirstMatchingFile(pattern) {
        try {
            let files = Quickshell.ls(pattern);
            if (files && files.length > 0)
                return files[0];
        } catch (e) {}
        return "";
    }

    function detectGpus(callback) {
        gpuDetectProcess._callback = function (output) {
            let lines = output.trim().split("\n");
            let detected = [];
            for (let line of lines) {
                let [card, type, vendor, device, name, pciid] = line.split("|");
                detected.push({
                    card,
                    type,
                    vendor,
                    device,
                    name,
                    pciid
                });
            }
            callback(detected);
        };
        gpuDetectProcess.running = true;
    }

    function updateGpuStats() {
        detectGpus(function (gpuList) {
            let pending = gpuList.length;
            let results = [];
            if (pending === 0) {
                gpus = [];
                return;
            }
            for (let i = 0; i < gpuList.length; i++) {
                let gpu = gpuList[i];
                if (gpu.type === "NVIDIA") {
                    nvidiaStatsProcess._callback = function (text) {
                        let parts = text.trim().split(",");
                        if (parts.length >= 5) {
                            results.push({
                                vendor: "NVIDIA",
                                name: parts[2].trim(),
                                usage: parseFloat(parts[0]),
                                temperature: parseInt(parts[1], 10),
                                memoryUsed: parseInt(parts[3], 10),
                                memoryTotal: parseInt(parts[4], 10),
                                card: gpu.card
                            });
                        } else {
                            results.push({
                                vendor: "NVIDIA",
                                name: "NVIDIA GPU",
                                usage: null,
                                temperature: null,
                                memoryUsed: null,
                                memoryTotal: null,
                                card: gpu.card
                            });
                        }
                        pending--;
                        if (pending === 0) {
                            gpus = results;
                        }
                    };
                    nvidiaStatsProcess.command = ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu,name,memory.used,memory.total", "--format=csv,noheader,nounits", "-i", String(i)];
                    nvidiaStatsProcess.running = true;
                    // } else if ((gpu.type === "GENERIC" || gpu.type === "UNKNOWN") && gpu.vendor && gpu.vendor.replace(/^0x/i, "").toLowerCase() === "8086") {
                    //     // Intel GPU detected, use intel_gpu_top
                    //     console.log("INTEL DETECTED:", JSON.stringify(gpu));
                    //     intelGpuTopProcess._callback = function (text) {
                    //         console.log("[intelGpuTopProcess._callback] called. Text:", text && text.length ? text.slice(0, 200) : "<empty>");
                    //         let parsed = parseIntelGpuTop(text);
                    //         if (parsed.length > 0) {
                    //             parsed[0].card = gpu.card;
                    //             parsed[0].busId = gpu.pciid || null;
                    //             results.push(parsed[0]);
                    //         }
                    //         pending--;
                    //         if (pending === 0) {
                    //             gpus = results;
                    //         }
                    //     };
                    //     console.log("Starting intel_gpu_top process...");
                    //     intelGpuTopProcess.running = true;
                    //     intelGpuTopKillTimer.start();
                } else if (gpu.type === "GENERIC") {
                    let usage = null;
                    let temp = null;
                    try {
                        usage = parseInt(Quickshell.readFile("/sys/class/drm/" + gpu.card + "/device/gpu_busy_percent").trim(), 10);
                    } catch (e) {}
                    let hwmonGlob = "/sys/class/drm/" + gpu.card + "/device/hwmon/hwmon*/temp1_input";
                    let tempPath = findFirstMatchingFile(hwmonGlob);
                    try {
                        if (tempPath)
                            temp = parseInt(Quickshell.readFile(tempPath).trim(), 10) / 1000;
                    } catch (e) {}
                    results.push({
                        vendor: "GENERIC",
                        name: gpu.name || "Generic GPU",
                        usage: usage,
                        temperature: temp,
                        memoryUsed: null,
                        memoryTotal: null,
                        card: gpu.card
                    });
                    pending--;
                    if (pending === 0) {
                        gpus = results;
                    }
                } else {
                    results.push({
                        vendor: "UNKNOWN",
                        name: gpu.name || "Unknown GPU",
                        usage: null,
                        temperature: null,
                        memoryUsed: null,
                        memoryTotal: null,
                        card: gpu.card
                    });
                    pending--;
                    if (pending === 0) {
                        gpus = results;
                    }
                }
            }
        });
    }

    // END GPU STUFF

    function addRef() {
        refCount++;
        if (refCount === 1) {
            updateAllStats();
        }
    }

    function removeRef() {
        refCount = Math.max(0, refCount - 1);
    }

    function updateAllStats() {
        if (refCount > 0) {
            isUpdating = true;
            unifiedStatsProcess.running = true;
            updateGpuStats();
        }
    }

    function setSortBy(newSortBy) {
        if (newSortBy !== sortBy) {
            sortBy = newSortBy;
            sortProcessesInPlace();
        }
    }

    function toggleSortOrder() {
        sortDescending = !sortDescending;
        sortProcessesInPlace();
    }

    function sortProcessesInPlace() {
        if (processes.length === 0)
            return;

        const sortedProcesses = [...processes];

        sortedProcesses.sort((a, b) => {
            let aVal, bVal;

            switch (sortBy) {
            case "cpu":
                aVal = parseFloat(a.cpu) || 0;
                bVal = parseFloat(b.cpu) || 0;
                break;
            case "memory":
                aVal = parseFloat(a.memoryPercent) || 0;
                bVal = parseFloat(b.memoryPercent) || 0;
                break;
            case "name":
                aVal = a.command || "";
                bVal = b.command || "";
                break;
            case "pid":
                aVal = parseInt(a.pid) || 0;
                bVal = parseInt(b.pid) || 0;
                break;
            default:
                aVal = parseFloat(a.cpu) || 0;
                bVal = parseFloat(b.cpu) || 0;
            }

            if (typeof aVal === "string") {
                return sortDescending ? bVal.localeCompare(aVal) : aVal.localeCompare(bVal);
            } else {
                return sortDescending ? bVal - aVal : aVal - bVal;
            }
        });

        processes = sortedProcesses;
    }

    function killProcess(pid) {
        if (pid > 0) {
            Quickshell.execDetached("kill", [pid.toString()]);
        }
    }

    function addToHistory(array, value) {
        array.push(value);
        if (array.length > historySize)
            array.shift();
    }

    function calculateCpuUsage(currentStats, lastStats) {
        if (!lastStats || !currentStats || currentStats.length < 4) {
            return 0;
        }

        const currentTotal = currentStats.reduce((sum, val) => sum + val, 0);
        const lastTotal = lastStats.reduce((sum, val) => sum + val, 0);

        const totalDiff = currentTotal - lastTotal;
        if (totalDiff <= 0)
            return 0;

        const currentIdle = currentStats[3];
        const lastIdle = lastStats[3];
        const idleDiff = currentIdle - lastIdle;

        const usedDiff = totalDiff - idleDiff;
        return Math.max(0, Math.min(100, (usedDiff / totalDiff) * 100));
    }

    function parseUnifiedStats(text) {
        function num(x) {
            return (typeof x === "number" && !isNaN(x)) ? x : 0;
        }

        let data;
        try {
            data = JSON.parse(text);
        } catch (error) {
            console.error("SysMonitorService: Failed to parse JSON:", error, "Raw text:", text.slice(0, 300));
            isUpdating = false;
            return;
        }

        if (data.memory) {
            const m = data.memory;
            totalMemoryKB = num(m.total);
            const free = num(m.free);
            const buf = num(m.buffers);
            const cached = num(m.cached);
            const shared = num(m.shared);
            usedMemoryKB = totalMemoryKB - free - buf - cached;
            totalSwapKB = num(m.swaptotal);
            usedSwapKB = num(m.swaptotal) - num(m.swapfree);
            totalMemoryMB = totalMemoryKB / 1024;
            usedMemoryMB = usedMemoryKB / 1024;
            freeMemoryMB = (totalMemoryKB - usedMemoryKB) / 1024;
            availableMemoryMB = num(m.available) ? num(m.available) / 1024 : (free + buf + cached) / 1024;
            memoryUsage = totalMemoryKB > 0 ? (usedMemoryKB / totalMemoryKB) * 100 : 0;
        }

        if (data.cpu) {
            cpuCores = data.cpu.count || 1;
            cpuCount = data.cpu.count || 1;
            cpuModel = data.cpu.model || "";
            cpuFrequency = data.cpu.frequency || 0;
            cpuTemperature = data.cpu.temperature || 0;

            if (data.cpu.total && data.cpu.total.length >= 8) {
                const currentStats = data.cpu.total;
                const usage = calculateCpuUsage(currentStats, lastCpuStats);
                cpuUsage = usage;
                totalCpuUsage = usage;
                lastCpuStats = [...currentStats];
            }

            if (data.cpu.cores) {
                const coreUsages = [];
                for (let i = 0; i < data.cpu.cores.length; i++) {
                    const currentCoreStats = data.cpu.cores[i];
                    if (currentCoreStats && currentCoreStats.length >= 8) {
                        let lastCoreStats = null;
                        if (lastPerCoreStats && lastPerCoreStats[i]) {
                            lastCoreStats = lastPerCoreStats[i];
                        }

                        const usage = calculateCpuUsage(currentCoreStats, lastCoreStats);
                        coreUsages.push(usage);
                    }
                }

                if (JSON.stringify(perCoreCpuUsage) !== JSON.stringify(coreUsages)) {
                    // Store previous values before updating current ones
                    perCoreCpuUsagePrev = [...perCoreCpuUsage];
                    perCoreCpuUsage = coreUsages;
                }

                lastPerCoreStats = data.cpu.cores.map(core => [...core]);
            }
        }

        if (data.network) {
            let totalRx = 0;
            let totalTx = 0;
            for (const iface of data.network) {
                totalRx += iface.rx;
                totalTx += iface.tx;
            }
            if (lastNetworkStats) {
                const timeDiff = updateInterval / 1000;
                const rxDiff = totalRx - lastNetworkStats.rx;
                const txDiff = totalTx - lastNetworkStats.tx;
                networkRxRate = Math.max(0, rxDiff / timeDiff);
                networkTxRate = Math.max(0, txDiff / timeDiff);
                addToHistory(networkHistory.rx, networkRxRate / 1024);
                addToHistory(networkHistory.tx, networkTxRate / 1024);
            }
            lastNetworkStats = {
                "rx": totalRx,
                "tx": totalTx
            };
        }

        if (data.disk) {
            let totalRead = 0;
            let totalWrite = 0;
            for (const disk of data.disk) {
                totalRead += disk.read * 512;
                totalWrite += disk.write * 512;
            }
            if (lastDiskStats) {
                const timeDiff = updateInterval / 1000;
                const readDiff = totalRead - lastDiskStats.read;
                const writeDiff = totalWrite - lastDiskStats.write;
                diskReadRate = Math.max(0, readDiff / timeDiff);
                diskWriteRate = Math.max(0, writeDiff / timeDiff);
                addToHistory(diskHistory.read, diskReadRate / (1024 * 1024));
                addToHistory(diskHistory.write, diskWriteRate / (1024 * 1024));
            }
            lastDiskStats = {
                "read": totalRead,
                "write": totalWrite
            };
        }

        if (data.processes) {
            const newProcesses = [];
            for (const proc of data.processes) {
                newProcesses.push({
                    "pid": proc.pid,
                    "ppid": proc.ppid,
                    "cpu": proc.cpu,
                    "memoryPercent": proc.memoryPercent,
                    "memoryKB": proc.memoryKB,
                    "command": proc.command,
                    "fullCommand": proc.fullCommand,
                    "displayName": proc.command.length > 15 ? proc.command.substring(0, 15) + "..." : proc.command
                });
            }
            processes = newProcesses;
            sortProcessesInPlace();
        }

        if (data.system) {
            kernelVersion = data.system.kernel || "";
            distribution = data.system.distro || "";
            hostname = data.system.hostname || "";
            architecture = data.system.arch || "";
            loadAverage = data.system.loadavg || "";
            processCount = data.system.processes || 0;
            threadCount = data.system.threads || 0;
            bootTime = data.system.boottime || "";
            motherboard = data.system.motherboard || "";
            biosVersion = data.system.bios || "";
        }

        if (data.diskmounts) {
            diskMounts = data.diskmounts;
        }

        addToHistory(cpuHistory, cpuUsage);
        addToHistory(memoryHistory, memoryUsage);

        isUpdating = false;
    }

    function getProcessIcon(command) {
        const cmd = command.toLowerCase();
        if (cmd.includes("firefox") || cmd.includes("chrome") || cmd.includes("browser"))
            return "web";
        if (cmd.includes("code") || cmd.includes("editor") || cmd.includes("vim"))
            return "code";
        if (cmd.includes("terminal") || cmd.includes("bash") || cmd.includes("zsh"))
            return "terminal";
        if (cmd.includes("music") || cmd.includes("audio") || cmd.includes("spotify"))
            return "music_note";
        if (cmd.includes("video") || cmd.includes("vlc") || cmd.includes("mpv"))
            return "play_circle";
        if (cmd.includes("systemd") || cmd.includes("kernel") || cmd.includes("kthread"))
            return "settings";
        return "memory";
    }

    function formatCpuUsage(cpu) {
        return (cpu || 0).toFixed(1) + "%";
    }

    function formatMemoryUsage(memoryKB) {
        const mem = memoryKB || 0;
        if (mem < 1024)
            return mem.toFixed(0) + " KB";
        else if (mem < 1024 * 1024)
            return (mem / 1024).toFixed(1) + " MB";
        else
            return (mem / (1024 * 1024)).toFixed(1) + " GB";
    }

    function formatSystemMemory(memoryKB) {
        const mem = memoryKB || 0;
        if (mem < 1024 * 1024)
            return (mem / 1024).toFixed(0) + " MB";
        else
            return (mem / (1024 * 1024)).toFixed(1) + " GB";
    }

    Timer {
        id: updateTimer
        interval: root.updateInterval
        running: root.refCount > 0 && !IdleService.isIdle
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateAllStats()
    }

    Connections {
        target: IdleService
        function onIdleChanged(idle) {
            if (idle) {
                console.log("SysMonitorService: System idle, pausing monitoring");
            } else {
                console.log("SysMonitorService: System active, resuming monitoring");
                if (root.refCount > 0) {
                    root.updateAllStats();
                }
            }
        }
    }

    readonly property string scriptBody: `set -Eeuo pipefail
trap 'echo "ERR at line $LINENO: $BASH_COMMAND (exit $?)" >&2' ERR

sort_key=\${1:-cpu}
max_procs=\${2:-20}

json_escape() { sed -e 's/\\\\/\\\\\\\\/g' -e 's/"/\\\\"/g' -e ':a;N;$!ba;s/\\n/\\\\n/g'; }

printf "{"

mem_line="$(awk '/^MemTotal:/{t=$2}
                 /^MemFree:/{f=$2}
                 /^MemAvailable:/{a=$2}
                 /^Buffers:/{b=$2}
                 /^Cached:/{c=$2}
                 /^Shmem:/{s=$2}
                 /^SwapTotal:/{st=$2}
                 /^SwapFree:/{sf=$2}
                 END{printf "%d %d %d %d %d %d %d %d",t,f,a,b,c,s,st,sf}' /proc/meminfo)"
read -r MT MF MA BU CA SH ST SF <<< "$mem_line"
printf '"memory":{"total":%d,"free":%d,"available":%d,"buffers":%d,"cached":%d,"shared":%d,"swaptotal":%d,"swapfree":%d},' \\
       "$MT" "$MF" "$MA" "$BU" "$CA" "$SH" "$ST" "$SF"

cpu_count=$(nproc)
cpu_model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//' | json_escape || echo 'Unknown')
cpu_freq=$(awk -F: '/cpu MHz/{gsub(/ /,"",$2);print $2;exit}' /proc/cpuinfo || echo 0)
cpu_temp=$(if [ -r /sys/class/thermal/thermal_zone0/temp ]; then
             awk '{printf "%.1f",$1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0
           else echo 0; fi)

printf '"cpu":{"count":%d,"model":"%s","frequency":%s,"temperature":%s,' \\
       "$cpu_count" "$cpu_model" "$cpu_freq" "$cpu_temp"

printf '"total":'
awk 'NR==1 {printf "[%d,%d,%d,%d,%d,%d,%d,%d]", $2,$3,$4,$5,$6,$7,$8,$9; exit}' /proc/stat

printf ',"cores":['
cpu_cores=$(nproc)
awk -v n="$cpu_cores" 'BEGIN{c=0}
     /^cpu[0-9]+/ {
       if(c>0) printf ",";
       printf "[%d,%d,%d,%d,%d,%d,%d,%d]", $2,$3,$4,$5,$6,$7,$8,$9;
       c++;
       if(c==n) exit
     }' /proc/stat
printf ']},'

printf '"network":['
tmp_net=$(mktemp)
grep -E '(wlan|eth|enp|wlp|ens|eno)' /proc/net/dev > "$tmp_net" || true
nfirst=1
while IFS= read -r line; do
    [ -z "$line" ] && continue
    iface=$(echo "$line" | awk '{print $1}' | sed 's/://')
    rx_bytes=$(echo "$line" | awk '{print $2}')
    tx_bytes=$(echo "$line" | awk '{print $10}')
    [ $nfirst -eq 1 ] || printf ","
    printf '{"name":"%s","rx":%d,"tx":%d}' "$iface" "$rx_bytes" "$tx_bytes"
    nfirst=0
done < "$tmp_net"
rm -f "$tmp_net"
printf '],'

printf '"disk":['
tmp_disk=$(mktemp)
grep -E ' (sd[a-z]+|nvme[0-9]+n[0-9]+|vd[a-z]+|dm-[0-9]+|mmcblk[0-9]+) ' /proc/diskstats > "$tmp_disk" || true
dfirst=1
while IFS= read -r line; do
    [ -z "$line" ] && continue
    name=$(echo "$line" | awk '{print $3}')
    read_sectors=$(echo "$line" | awk '{print $6}')
    write_sectors=$(echo "$line" | awk '{print $10}')
    [ $dfirst -eq 1 ] || printf ","
    printf '{"name":"%s","read":%d,"write":%d}' "$name" "$read_sectors" "$write_sectors"
    dfirst=0
done < "$tmp_disk"
rm -f "$tmp_disk"
printf '],'

printf '"processes":['
case "$sort_key" in
    cpu)    SORT_OPT="--sort=-pcpu" ;;
    memory) SORT_OPT="--sort=-pmem" ;;
    name)   SORT_OPT="--sort=+comm" ;;
    pid)    SORT_OPT="--sort=+pid" ;;
    *)      SORT_OPT="--sort=-pcpu" ;;
esac

tmp_ps=$(mktemp)
ps -eo pid,ppid,pcpu,pmem,rss,comm,cmd --no-headers $SORT_OPT | head -n "$max_procs" > "$tmp_ps" || true
pfirst=1
while IFS=' ' read -r pid ppid cpu memp memk comm rest; do
    [ -z "$pid" ] && continue
    cmd=$(printf "%s" "$rest" | json_escape)
    [ $pfirst -eq 1 ] || printf ","
    printf '{"pid":%s,"ppid":%s,"cpu":%s,"memoryPercent":%s,"memoryKB":%s,"command":"%s","fullCommand":"%s"}' \\
           "$pid" "$ppid" "$cpu" "$memp" "$memk" "$comm" "$cmd"
    pfirst=0
done < "$tmp_ps"
rm -f "$tmp_ps"
printf '],'

dmip="/sys/class/dmi/id"
[ -d "$dmip" ] || dmip="/sys/devices/virtual/dmi/id"
mb_vendor=$([ -r "$dmip/board_vendor" ] && cat "$dmip/board_vendor" | json_escape || echo "Unknown")
mb_name=$([ -r "$dmip/board_name" ] && cat "$dmip/board_name" | json_escape || echo "")
bios_ver=$([ -r "$dmip/bios_version" ] && cat "$dmip/bios_version" | json_escape || echo "Unknown")
bios_date=$([ -r "$dmip/bios_date" ] && cat "$dmip/bios_date" | json_escape || echo "")

kern_ver=$(uname -r | json_escape)
distro=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"' | json_escape || echo 'Unknown')
host_name=$(hostname | json_escape)
arch_name=$(uname -m)
load_avg=$(cut -d' ' -f1-3 /proc/loadavg)
proc_count=$(( $(ps aux | wc -l) - 1 ))
thread_count=$(ps -eL | wc -l)
boot_time=$(who -b 2>/dev/null | awk '{print $3, $4}' | json_escape || echo 'Unknown')

printf '"system":{"kernel":"%s","distro":"%s","hostname":"%s","arch":"%s","loadavg":"%s","processes":%d,"threads":%d,"boottime":"%s","motherboard":"%s %s","bios":"%s %s"},' \\
    "$kern_ver" "$distro" "$host_name" "$arch_name" "$load_avg" "$proc_count" "$thread_count" "$boot_time" "$mb_vendor" "$mb_name" "$bios_ver" "$bios_date"

printf '"diskmounts":['
tmp_mounts=$(mktemp)
df -h --output=source,target,fstype,size,used,avail,pcent | tail -n +2 | grep -vE '^(tmpfs|devtmpfs)' | head -n 10 > "$tmp_mounts" || true
mfirst=1
while IFS= read -r line; do
    [ -z "$line" ] && continue
    device=$(echo "$line" | awk '{print $1}' | json_escape)
    mount=$(echo "$line" | awk '{print $2}' | json_escape)
    fstype=$(echo "$line" | awk '{print $3}')
    size=$(echo "$line" | awk '{print $4}')
    used=$(echo "$line" | awk '{print $5}')
    avail=$(echo "$line" | awk '{print $6}')
    percent=$(echo "$line" | awk '{print $7}')
    [ $mfirst -eq 1 ] || printf ","
    printf '{"device":"%s","mount":"%s","fstype":"%s","size":"%s","used":"%s","avail":"%s","percent":"%s"}' \\
           "$device" "$mount" "$fstype" "$size" "$used" "$avail" "$percent"
    mfirst=0
done < "$tmp_mounts"
rm -f "$tmp_mounts"
printf ']'

printf "}\\n"`

    Process {
        id: unifiedStatsProcess
        command: ["bash", "-c", "bash -s \"$1\" \"$2\" <<'QS_EOF'\\n" + root.scriptBody + "\\nQS_EOF\\n", "qsmon", root.sortBy, root.maxProcesses]
        running: false
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn("Unified stats process failed with exit code:", exitCode);
                isUpdating = false;
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    const fullText = text.trim();
                    const lastBraceIndex = fullText.lastIndexOf('}');
                    if (lastBraceIndex === -1) {
                        console.error("SysMonitorService: No JSON object found in output.", fullText);
                        isUpdating = false;
                        return;
                    }
                    const jsonText = fullText.substring(0, lastBraceIndex + 1);

                    try {
                        const data = JSON.parse(jsonText);
                        parseUnifiedStats(jsonText);
                    } catch (e) {
                        isUpdating = false;
                        return;
                    }
                }
            }
        }
    }

    function debug() {
        SysMonitorService.addRef();
        SysMonitorService.updateAllStats();
        console.log("GPUS:", JSON.stringify(SysMonitorService.gpus));
    }

    // Component.onCompleted: {
    // Qt.callLater(debug)
    // }

}

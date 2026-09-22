#!/usr/bin/python3

import json
import platform
import subprocess
import sys
from pathlib import Path

from PySide6.QtCore import (
    QObject,
    Property,
    QTimer,
    Signal,
    Slot,
    QUrl,
)
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine


class SystemBackend(QObject):
    telemetryChanged = Signal()
    actionErrorChanged = Signal()
    powerProfilesChanged = Signal()
    graphicsChanged = Signal()

    def __init__(self):
        super().__init__()

        self._cpu = -1
        self._ram_percent = -1
        self._ram_used = -1.0
        self._gpu = "Unknown"
        self._power = "Unknown"
        self._action_error = ""
        self._supported_power_profiles = set()

        self._graphics_mode = "Unknown"
        self._graphics_provider = "Unknown"
        self._graphics_devices = "No GPUs detected"
        self._graphics_offload = False
        self._graphics_switch_provider = ""
        self._graphics_reboot_required = False
        self._supports_integrated_graphics = False
        self._supports_hybrid_graphics = False
        self._supports_discrete_graphics = False

        self.refreshPowerProfiles()
        self.refreshGraphics()

        self._timer = QTimer(self)
        self._timer.setInterval(1500)
        self._timer.timeout.connect(self.refresh)
        self._timer.start()

        self._graphics_timer = QTimer(self)
        self._graphics_timer.setInterval(5000)
        self._graphics_timer.timeout.connect(self.refreshGraphics)
        self._graphics_timer.start()

        self.refresh()

    @Property(int, notify=telemetryChanged)
    def cpuPercent(self):
        return self._cpu

    @Property(int, notify=telemetryChanged)
    def ramPercent(self):
        return self._ram_percent

    @Property(float, notify=telemetryChanged)
    def ramUsedGiB(self):
        return self._ram_used

    @Property(str, notify=telemetryChanged)
    def gpuText(self):
        return self._gpu

    @Property(str, notify=telemetryChanged)
    def powerMode(self):
        return self._power

    @Property(str, constant=True)
    def hostname(self):
        return platform.node()

    @Property(str, constant=True)
    def kernel(self):
        return platform.release()

    @Property(str, constant=True)
    def architecture(self):
        return platform.machine()

    @Property(str, constant=True)
    def iulinuxVersion(self):
        try:
            values = {}

            for line in Path("/etc/os-release").read_text().splitlines():
                if "=" not in line:
                    continue

                key, value = line.split("=", 1)
                values[key] = value.strip().strip('"')

            return values.get(
                "PRETTY_NAME",
                values.get("NAME", "IULinux"),
            )
        except Exception:
            return "IULinux"

    @Property(str, notify=actionErrorChanged)
    def actionError(self):
        return self._action_error

    @Property(bool, notify=powerProfilesChanged)
    def supportsSaver(self):
        return "power-saver" in self._supported_power_profiles

    @Property(bool, notify=powerProfilesChanged)
    def supportsBalanced(self):
        return "balanced" in self._supported_power_profiles

    @Property(bool, notify=powerProfilesChanged)
    def supportsPerformance(self):
        return "performance" in self._supported_power_profiles

    @Property(str, notify=graphicsChanged)
    def graphicsMode(self):
        return self._graphics_mode

    @Property(str, notify=graphicsChanged)
    def graphicsProvider(self):
        return self._graphics_provider

    @Property(str, notify=graphicsChanged)
    def graphicsDevices(self):
        return self._graphics_devices

    @Property(bool, notify=graphicsChanged)
    def graphicsOffloadAvailable(self):
        return self._graphics_offload

    @Property(str, notify=graphicsChanged)
    def graphicsSwitchProvider(self):
        return self._graphics_switch_provider

    @Property(bool, notify=graphicsChanged)
    def graphicsRebootRequired(self):
        return self._graphics_reboot_required

    @Property(bool, notify=graphicsChanged)
    def supportsIntegratedGraphics(self):
        return self._supports_integrated_graphics

    @Property(bool, notify=graphicsChanged)
    def supportsHybridGraphics(self):
        return self._supports_hybrid_graphics

    @Property(bool, notify=graphicsChanged)
    def supportsDiscreteGraphics(self):
        return self._supports_discrete_graphics

    @Slot()
    def refreshPowerProfiles(self):
        supported = set()

        try:
            result = subprocess.run(
                ["powerprofilesctl", "list"],
                capture_output=True,
                text=True,
                timeout=2.0,
                check=False,
            )

            if result.returncode == 0:
                for raw_line in result.stdout.splitlines():
                    line = raw_line.strip()

                    if line.startswith("*"):
                        line = line[1:].strip()

                    if not line.endswith(":"):
                        continue

                    profile = line[:-1]

                    if profile in {
                        "power-saver",
                        "balanced",
                        "performance",
                    }:
                        supported.add(profile)

        except Exception:
            pass

        if supported != self._supported_power_profiles:
            self._supported_power_profiles = supported
            self.powerProfilesChanged.emit()

    def _set_error(self, text):
        if self._action_error == text:
            return

        self._action_error = text
        self.actionErrorChanged.emit()

    @Slot()
    def refresh(self):
        try:
            result = subprocess.run(
                ["/usr/lib/iulinux/iulinux-performance-status"],
                capture_output=True,
                text=True,
                timeout=1.0,
                check=False,
            )

            if result.returncode != 0:
                return

            data = json.loads(result.stdout)

            self._cpu = data.get("cpu_percent", -1)
            self._ram_percent = data.get("ram_percent", -1)
            self._ram_used = data.get("ram_used_gib", -1.0)
            self._gpu = data.get("gpu", "Unknown")
            self._power = data.get("power", "Unknown")

            self.telemetryChanged.emit()

        except Exception:
            pass

    @Slot()
    def refreshGraphics(self):
        try:
            result = subprocess.run(
                ["/usr/lib/iulinux/iulinux-graphics-status"],
                capture_output=True,
                text=True,
                timeout=2.0,
                check=False,
            )

            if result.returncode != 0:
                return

            data = json.loads(result.stdout)

            switcheroo = data.get("switcheroo", {})
            switcheroo_gpus = switcheroo.get("gpus", [])

            device_names = []

            for gpu in switcheroo_gpus:
                name = str(gpu.get("name", "")).strip()

                if name and name not in device_names:
                    device_names.append(name)

            if not device_names:
                for gpu in data.get("drm_devices", []):
                    vendor = str(gpu.get("vendor", "GPU"))
                    driver = str(gpu.get("driver", "")).strip()

                    label = vendor

                    if driver:
                        label += " (" + driver + ")"

                    if label not in device_names:
                        device_names.append(label)

            switching = data.get("mode_switching", {})

            new_values = (
                str(data.get("current_mode", "Unknown")),
                str(data.get("provider", "Unknown")),
                "\n".join(device_names) or "No GPUs detected",
                bool(data.get("offload_available", False)),
                str(switching.get("provider") or ""),
                bool(switching.get("reboot_required", False)),
                bool(switching.get("integrated", False)),
                bool(switching.get("hybrid", False)),
                bool(switching.get("discrete", False)),
            )

            old_values = (
                self._graphics_mode,
                self._graphics_provider,
                self._graphics_devices,
                self._graphics_offload,
                self._graphics_switch_provider,
                self._graphics_reboot_required,
                self._supports_integrated_graphics,
                self._supports_hybrid_graphics,
                self._supports_discrete_graphics,
            )

            if new_values == old_values:
                return

            (
                self._graphics_mode,
                self._graphics_provider,
                self._graphics_devices,
                self._graphics_offload,
                self._graphics_switch_provider,
                self._graphics_reboot_required,
                self._supports_integrated_graphics,
                self._supports_hybrid_graphics,
                self._supports_discrete_graphics,
            ) = new_values

            self.graphicsChanged.emit()

        except Exception:
            pass

    @Slot(str)
    def setGraphicsMode(self, mode):
        allowed = {
            "Integrated": self._supports_integrated_graphics,
            "Hybrid": self._supports_hybrid_graphics,
            "Discrete": self._supports_discrete_graphics,
        }

        if mode not in allowed:
            self._set_error("Unsupported graphics mode")
            return

        if not allowed[mode]:
            self._set_error(
                mode + " graphics mode is not available on this system"
            )
            return

        try:
            result = subprocess.run(
                [
                    "/usr/bin/pkexec",
                    "/usr/lib/iulinux/iulinux-graphics-switch",
                    mode,
                ],
                capture_output=True,
                text=True,
                timeout=120.0,
                check=False,
            )

            if result.returncode != 0:
                message = result.stderr.strip() or result.stdout.strip()
                self._set_error(
                    message or "Unable to change graphics mode"
                )
                return

            self._set_error("")
            self.refreshGraphics()

        except subprocess.TimeoutExpired:
            self._set_error("Graphics mode authentication timed out")

        except Exception as exc:
            self._set_error(str(exc))

    @Slot(str)
    def setPowerMode(self, mode):
        allowed = {
            "Saver": "power-saver",
            "Balanced": "balanced",
            "Performance": "performance",
        }

        profile = allowed.get(mode)

        if profile is None:
            self._set_error("Unsupported power profile")
            return

        if profile not in self._supported_power_profiles:
            self._set_error(
                mode + " power mode is not available on this system"
            )
            return

        try:
            result = subprocess.run(
                ["powerprofilesctl", "set", profile],
                capture_output=True,
                text=True,
                timeout=3.0,
                check=False,
            )

            if result.returncode != 0:
                message = result.stderr.strip()
                self._set_error(
                    message or "Unable to change power profile"
                )
                return

            self._set_error("")
            self.refreshPowerProfiles()
            self.refresh()

        except Exception as exc:
            self._set_error(str(exc))


app = QGuiApplication(sys.argv)

app.setApplicationName("IULinux Settings")
app.setOrganizationName("IULinux")
app.setDesktopFileName("com.iulinux.Settings")

backend = SystemBackend()

engine = QQmlApplicationEngine()
engine.rootContext().setContextProperty("systemBackend", backend)

qml = QUrl.fromLocalFile(
    "/usr/lib/iulinux/settings/Main.qml"
)

engine.load(qml)

if not engine.rootObjects():
    sys.exit(1)

sys.exit(app.exec())

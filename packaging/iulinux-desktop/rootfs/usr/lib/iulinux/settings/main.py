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

    def __init__(self):
        super().__init__()

        self._cpu = -1
        self._ram_percent = -1
        self._ram_used = -1.0
        self._gpu = "Unknown"
        self._power = "Unknown"
        self._action_error = ""
        self._supported_power_profiles = set()

        self.refreshPowerProfiles()

        self._timer = QTimer(self)
        self._timer.setInterval(1500)
        self._timer.timeout.connect(self.refresh)
        self._timer.start()

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

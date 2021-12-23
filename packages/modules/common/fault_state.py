from enum import Enum
import traceback
from typing import Optional

from helpermodules import compatibility
from helpermodules.log import MainLogger
from helpermodules import pub


class FaultStateLevel(Enum):
    NO_ERROR = 0
    WARNING = 1
    ERROR = 2


class ComponentInfo:
    def __init__(self, id: int, name: str, type: str) -> None:
        self.id = id
        self.name = name
        self.type = type

    @staticmethod
    def from_component_config(component_config: dict):
        return ComponentInfo(component_config["id"], component_config["name"], component_config["type"])


class FaultState(Exception):
    type_topic_mapping_comp = {"bat": "houseBattery", "counter": "evu", "inverter": "pv", "vehicle": "lp"}
    type_topic_mapping = {"bat": "bat", "counter": "counter", "inverter": "pv", "vehicle": "vehicle"}

    def __init__(self, fault_str: str, fault_state: FaultStateLevel) -> None:
        self.fault_str = fault_str
        self.fault_state = fault_state

    def store_error(self, component_info: ComponentInfo) -> None:
        try:
            if self.fault_state is not FaultStateLevel.NO_ERROR:
                MainLogger().error(component_info.name + ": FaultState " +
                                   str(self.fault_state) + ", FaultStr " +
                                   self.fault_str + ", Traceback: \n" +
                                   traceback.format_exc())
            ramdisk = compatibility.is_ramdisk_in_use()
            if ramdisk:
                topic = self.type_topic_mapping_comp.get(component_info.type, component_info.type)
                prefix = "openWB/set/" + topic + "/"
                if component_info.id is not None:
                    if topic == "lp":
                        prefix += str(component_info.id) + "/socF"
                    else:
                        prefix += str(component_info.id) + "/f"
                else:
                    prefix += "f"
                pub.pub_single(prefix + "aultStr", self.fault_str)
                pub.pub_single(prefix + "aultState", self.fault_state.value)
            else:
                topic = self.type_topic_mapping.get(component_info.type, component_info.type)
                pub.Pub().pub(
                    "openWB/set/" + topic + "/" + str(component_info.id) + "/get/fault_str", self.fault_str)
                pub.Pub().pub(
                    "openWB/set/" + topic + "/" + str(component_info.id) + "/get/fault_state", self.fault_state.value)
        except Exception:
            MainLogger().exception("Fehler im Modul fault_state")

    @staticmethod
    def error(message: str) -> "FaultState":
        return FaultState(message, FaultStateLevel.ERROR)

    @staticmethod
    def warning(message: str) -> "FaultState":
        return FaultState(message, FaultStateLevel.WARNING)

    @staticmethod
    def no_error() -> "FaultState":
        return FaultState("Kein Fehler.", FaultStateLevel.NO_ERROR)

    @staticmethod
    def from_exception(exception: Optional[Exception]) -> "FaultState":
        if exception is None:
            return FaultState.no_error()
        if isinstance(exception, FaultState):
            return exception
        return exception.get_default_exception_registry().translate_exception(exception)

#!/usr/bin/env python3
import argparse
import datetime as dt
import re
import subprocess
import time
import xml.etree.ElementTree as ET
from pathlib import Path


def run_adb(serial, *args):
    command = ["adb"]
    if serial:
        command.extend(["-s", serial])
    command.extend(args)
    return subprocess.run(command, check=True, capture_output=True, text=True)


def dump_ui(serial):
    result = run_adb(serial, "exec-out", "uiautomator", "dump", "/dev/tty")
    xml_start = result.stdout.find("<?xml")
    text = result.stdout[xml_start:] if xml_start >= 0 else result.stdout
    xml_end = text.rfind("</hierarchy>")
    return text[: xml_end + len("</hierarchy>")] if xml_end >= 0 else text


def node_text(node):
    return node.attrib.get("text") or node.attrib.get("content-desc") or ""


def bounds_center(bounds):
    match = re.fullmatch(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", bounds or "")
    if not match:
        return None
    left, top, right, bottom = map(int, match.groups())
    return ((left + right) // 2, (top + bottom) // 2)


def find_status_button(xml_text):
    root = ET.fromstring(xml_text)
    for node in root.iter():
        label = node_text(node)
        if "Show status" in label or label.startswith("Context window"):
            center = bounds_center(node.attrib.get("bounds"))
            if center:
                return center
    return None


def find_close_button(xml_text):
    root = ET.fromstring(xml_text)
    for node in root.iter():
        label = node_text(node)
        if label == "Close":
            center = bounds_center(node.attrib.get("bounds"))
            if center:
                return center
    return None


def status_lines(xml_text):
    root = ET.fromstring(xml_text)
    texts = [node.attrib["text"] for node in root.iter() if node.attrib.get("text")]
    values = {}
    for index, text in enumerate(texts):
        if text in {"Context:", "5h limit:", "7d limit:"} and index + 1 < len(texts):
            values[text.rstrip(":").lower()] = texts[index + 1]
    return values


def read_status(serial):
    xml_text = dump_ui(serial)
    values = status_lines(xml_text)
    if "5h limit" not in values:
        center = find_status_button(xml_text)
        if not center:
            raise RuntimeError("Could not find Codex status button in phone UI.")
        run_adb(serial, "shell", "input", "tap", str(center[0]), str(center[1]))
        time.sleep(1)
        xml_text = dump_ui(serial)
        values = status_lines(xml_text)
    if "5h limit" not in values:
        raise RuntimeError("Codex status sheet opened, but no 5h limit text was found.")
    close = find_close_button(xml_text)
    if close:
        run_adb(serial, "shell", "input", "tap", str(close[0]), str(close[1]))
    return values


def write_line(log_path, line):
    print(line, flush=True)
    if log_path:
        with Path(log_path).open("a", encoding="utf-8") as handle:
            handle.write(line + "\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--serial", default="")
    parser.add_argument("--interval-seconds", type=int, default=0)
    parser.add_argument("--log", default="")
    args = parser.parse_args()

    while True:
        now = dt.datetime.now().astimezone().strftime("%Y-%m-%d %H:%M:%S %Z")
        try:
            values = read_status(args.serial)
            line = (
                f"{now} | context={values.get('context', 'unknown')} | "
                f"5h={values.get('5h limit', 'unknown')} | "
                f"7d={values.get('7d limit', 'unknown')}"
            )
        except Exception as error:
            line = f"{now} | error={error}"
        write_line(args.log, line)
        if args.interval_seconds <= 0:
            return
        time.sleep(args.interval_seconds)


if __name__ == "__main__":
    main()

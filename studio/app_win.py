"""PopkaStudio as a Windows program: the editor in a window of its own (Edge's app window: no tabs, no address bar —
Edge comes with every Windows 10 and 11, so the installer grows by nothing), studio.py started with it and stopped when
the window closes. The Start menu shortcut runs this with pythonw (no console). bin/popkastudio.cmd still opens the
editor in the browser, with the log in its console, for those who like a terminal.

  pythonw studio/app_win.py           the window
  python studio/app_win.py --check    (a test: start studio.py, wait for its answer, find the browser, stop)

studio.py's log goes to studio/studio.log; a start that fails says so in a message box with that path."""
import ctypes
import os
import subprocess
import sys
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
URL = "http://localhost:8466"
LOG = os.path.join(HERE, "studio.log")
PROFILE = os.path.join(ROOT, ".tools", "window")  # (the window's own browser profile: its process is ours to wait for)
NO_WINDOW = 0x08000000  # CREATE_NO_WINDOW


def message(text, error=True):
    ctypes.windll.user32.MessageBoxW(None, text, "PopkaStudio", 0x10 if error else 0x40)


def answers(timeout=1.0):
    try:
        with urllib.request.urlopen(URL + "/api/about", timeout=timeout) as r:
            return r.status == 200
    except OSError:
        return False


def start_server():
    """studio.py with the console Python (its tools — arduino-cli, esptool — get a hidden console, never a flash of one)."""
    py = os.path.join(os.path.dirname(sys.executable), "python.exe")
    env = {**os.environ, "PYTHONUTF8": "1",
           "PATH": os.path.join(ROOT, ".tools", "bin") + os.pathsep + os.environ.get("PATH", "")}
    log = open(LOG, "w", encoding="utf-8", errors="replace")
    return subprocess.Popen([py if os.path.exists(py) else sys.executable, os.path.join(HERE, "studio.py")], cwd=ROOT,
                            stdout=log, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, env=env, creationflags=NO_WINDOW)


def stop_server(proc):
    """studio.py and whatever it runs (a Load's arduino-cli): the whole tree."""
    if proc and proc.poll() is None:
        subprocess.run(["taskkill", "/T", "/F", "/PID", str(proc.pid)], capture_output=True, creationflags=NO_WINDOW)


def find_browser():
    """Edge (every Windows 10/11 has it), else Chrome: a Chromium that opens a page as an app window."""
    places = []
    for base in (os.environ.get("ProgramFiles(x86)"), os.environ.get("ProgramFiles"), os.environ.get("LOCALAPPDATA")):
        if base:
            places += [os.path.join(base, "Microsoft", "Edge", "Application", "msedge.exe"),
                       os.path.join(base, "Google", "Chrome", "Application", "chrome.exe")]
    try:
        import winreg
        for exe in ("msedge.exe", "chrome.exe"):
            for hive in (winreg.HKEY_CURRENT_USER, winreg.HKEY_LOCAL_MACHINE):
                try:
                    with winreg.OpenKey(hive, r"SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths" + "\\" + exe) as k:
                        places.append(winreg.QueryValue(k, None))
                except OSError:
                    pass
    except ImportError:
        pass
    return next((p for p in places if p and os.path.isfile(p)), None)


def open_window(browser):
    """The app window; returns when it is closed (its own profile: Edge doesn't hand it to an Edge already running)."""
    os.makedirs(PROFILE, exist_ok=True)
    w, h = 1440, 900
    try:
        sw, sh = ctypes.windll.user32.GetSystemMetrics(0), ctypes.windll.user32.GetSystemMetrics(1)
        w, h = min(w, int(sw * 0.9)), min(h, int(sh * 0.88))
    except Exception:  # noqa: BLE001 — the default size
        pass
    subprocess.run([browser, f"--app={URL}", f"--user-data-dir={PROFILE}", f"--window-size={w},{h}",
                    "--no-first-run", "--no-default-browser-check", "--disable-background-mode",
                    "--disable-features=msEdgeStartupBoost,msImplicitSignin,msEdgeSidebarV2"])


def main():
    check = "--check" in sys.argv
    proc = None
    if not answers():  # (one already running — another window, the console launcher: share it, don't stop it)
        proc = start_server()
        for _ in range(240):  # (up to a minute: the first start may unpack the fonts)
            if answers(0.5):
                break
            if proc.poll() is not None:
                break
            time.sleep(0.25)
        if not answers():
            stop_server(proc)
            text = f"PopkaStudio didn't start. Its log: {LOG}"
            print(text) if check else message(text)
            return 1
    browser = find_browser()
    if check:
        print("studio.py answers; window:", browser or "(none: the default browser)")
        stop_server(proc)
        return 0
    try:
        if browser:
            open_window(browser)
        else:  # (no Edge, no Chrome: the default browser; then studio.py runs until the PC restarts or Task Manager)
            os.startfile(URL)
            return 0
    finally:
        if browser:
            stop_server(proc)
    return 0


if __name__ == "__main__":
    sys.exit(main())

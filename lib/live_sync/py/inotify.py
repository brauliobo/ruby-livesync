import pyinotify
import os
import time
import sys

class EventHandler(pyinotify.ProcessEvent):
    def process_default(self, event):
        full_path  = event.pathname
        event_desc = event.maskname
        print(f"{event_desc} {full_path}", flush=True)

def watch_path(path, excludes, recursive, mask, base_device):
    wm       = pyinotify.WatchManager()
    handler  = EventHandler()
    notifier = pyinotify.Notifier(wm, handler)
    
    def add_watch(path):
        if os.path.isdir(path) and not any(exclude in path for exclude in excludes):
            try:
                if os.stat(path).st_dev == base_device:
                    wm.add_watch(path, mask, auto_add=recursive)
                else:
                    print(f"Skipping {path} (different device)", file=sys.stderr)
            except Exception as e:
                print(f"Error adding watch on {path}: {e}", file=sys.stderr)
    
    if recursive:
        for root, dirs, _ in os.walk(path):
            add_watch(root)
            for dir in dirs:
                add_watch(os.path.join(root, dir))
    else:
        add_watch(path)
    
    try:
        while True:
            notifier.process_events()
            if notifier.check_events():
                notifier.read_events()
            time.sleep(%{delay})
    except KeyboardInterrupt:
        notifier.stop()

# Configuration
path        = '%{path}'
excludes    = [%{excludes}]
recursive   = %{recursive}
event_mask  = pyinotify.IN_CREATE | pyinotify.IN_MODIFY | pyinotify.IN_DELETE
base_device = os.stat(path).st_dev

try:
    import setproctitle
    setproctitle.setproctitle(f'livesync/py_inotify: {path}')
except ImportError: pass

watch_path(path, excludes, recursive, event_mask, base_device)


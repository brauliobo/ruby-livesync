import pyinotify
import os
import time
import sys

class EventHandler(pyinotify.ProcessEvent):
    def my_init(self, excludes, recursive, mask, base_device):
        self.excludes = excludes
        self.recursive = recursive
        self.base_device = base_device
        self.mask = mask
        self.events = set()

    def process_default(self, event):
        full_path = event.pathname
        if not any(exclude in full_path for exclude in self.excludes):
            event_desc = event.maskname
            self.events.add((event_desc, full_path))

    def print_events(self):
        if self.events:
            for event_desc, full_path in self.events:
                print(f"{event_desc} {full_path}", flush=True)
            self.events.clear()

    def watch_path(self, path):
        if not any(exclude in path for exclude in self.excludes):
            try:
                if os.stat(path).st_dev == self.base_device:
                    wm.add_watch(path, self.mask, auto_add=True)
                else:
                    print(f"Skipping {path} (different device)", file=sys.stderr)
            except Exception as e:
                print(f"Error adding watch on {path}: {e}", file=sys.stderr)

    def add_watch(self, path):
        if self.recursive:
            for root, dirs, _ in os.walk(path):
                self.watch_path(root)
                for dir in dirs:
                    self.watch_path(os.path.join(root, dir))
        else:
            self.watch_path(path)

excludes    = [%{excludes}]
recursive   = %{recursive}
event_mask  = pyinotify.IN_CREATE | pyinotify.IN_MODIFY | pyinotify.IN_MOVED_TO | pyinotify.IN_DELETE  # Event mask
base_device = os.stat('%{path}').st_dev

try:
    import setproctitle
    setproctitle.setproctitle('livesync/py_inotify: %{path}')
except ImportError: pass

wm = pyinotify.WatchManager()
handler = EventHandler(excludes=excludes, recursive=recursive, mask=event_mask, base_device=base_device)
notifier = pyinotify.Notifier(wm, handler)
handler.add_watch('%{path}')

try:
    while True:
        notifier.process_events()
        if notifier.check_events():
            notifier.read_events()
        handler.print_events()
        time.sleep(%{delay})
except KeyboardInterrupt:
    notifier.stop()


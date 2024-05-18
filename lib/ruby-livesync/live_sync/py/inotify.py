import pyinotify
import os
import time

class EventHandler(pyinotify.ProcessEvent):
    def my_init(self, excludes, recursive, mask):
        self.excludes = excludes
        self.recursive = recursive
        self.mask = mask
        self.events = set()

    def process_default(self, event):
        full_path = event.pathname
        if not any(exclude in full_path for exclude in self.excludes):
            event_desc = event.maskname
            self.events.add((event_desc, full_path))

            if 'IN_CREATE' in event.maskname and os.path.isdir(full_path):
                self.add_watch(full_path)

    def print_events(self):
        if self.events:
            for event_desc, full_path in self.events:
                print(f"{event_desc} {full_path}", flush=True)
            self.events.clear()

    def add_watch(self, path):
        wm.add_watch(path, self.mask, rec=self.recursive, auto_add=True)

excludes = [%{excludes}]
recursive = %{recursive}
event_mask = pyinotify.IN_CREATE | pyinotify.IN_MODIFY | pyinotify.IN_MOVED_TO | pyinotify.IN_DELETE  # Event mask

wm = pyinotify.WatchManager()
handler = EventHandler(excludes=excludes, recursive=recursive, mask=event_mask)
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


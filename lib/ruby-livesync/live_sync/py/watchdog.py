from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import time

class MyEventHandler(FileSystemEventHandler):
    def __init__(self, observer, excludes):
        self.observer = observer
        self.excludes = excludes
        self.events = set()

    def handle_event(self, event):
        if not any(exclusion in event.src_path for exclusion in self.excludes):
            self.events.add((event.event_type, event.src_path))
            if event.event_type == 'created' and os.path.isdir(event.src_path):
                self.schedule_directory(event.src_path)

    def on_modified(self, event):
        self.handle_event(event)

    def on_created(self, event):
        self.handle_event(event)

    def on_deleted(self, event):
        self.handle_event(event)

    def on_moved(self, event):
        self.handle_event(event)

    def print_events(self):
        if self.events:
            for event_type, src_path in self.events:
                print(f"{event_type} {src_path}", flush=True)
            self.events.clear()

    def schedule_directory(self, path):
        self.observer.schedule(self, path, recursive=%{recursive})

path = "%{path}"
excludes = [%{excludes}]
observer = Observer()
event_handler = MyEventHandler(observer, excludes)
event_handler.schedule_directory(path)

observer.start()
try:
    while True:
        time.sleep(%{delay})
        event_handler.print_events()
except KeyboardInterrupt:
    observer.stop()
observer.join()


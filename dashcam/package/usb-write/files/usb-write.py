import os
import time
import shutil
import datetime
import subprocess
import threading

from pathlib import Path
from typing import Optional
from collections import deque

USB_MOUNT_PATH = Path('/media/usb0')
RECORDING_PATH = USB_MOUNT_PATH / 'recording'


# TODO: change to min usb space required
class JpegMemoryControl:
    def __init__(self, max_size: int = 32_000_000_000, max_files: int = 64_000) -> None:
        self.base_dir : Path = USB_MOUNT_PATH
        self.max_size : int = max_size
        self.max_files : int = max_files
        self.file_queue: deque = deque()
        self.current_size : int = 0
        self.cleanup_interval : int = 5

        self.prepare()
        self._start_cleanup_thread()

    def prepare(self) -> None:
        while not os.path.ismount(USB_MOUNT_PATH):
            time.sleep(1)
        self._build_database()

    def add(self, file_path: Path) -> None:
        self.file_queue.append(file_path)
        self.current_size += os.path.getsize(file_path)

    def contains(self, file_path):
        return file_path in self.file_queue

    def _cleanup(self):
        print('cleanup')
        if self.current_size > self.max_size or len(self.file_queue) > self.max_files:
            print('in if')
            files_to_remove = min(300, len(self.file_queue))
            print('files', files_to_remove)
            for _ in range(files_to_remove):
                old_file = self.file_queue.popleft()
                print(old_file)
                try:
                    file_size = os.path.getsize(old_file)
                    os.remove(old_file)
                    self.current_size -= file_size
                except FileNotFoundError:
                    pass  # File already deleted or usb was removed

    def _build_database(self) -> None:
        self.current_size = 0
        self.file_queue.clear()
        sorted_files = sorted((file for file in RECORDING_PATH.glob('**/*.jpg')), key=lambda file: file.name.zfill(25))
        for file in sorted_files:
            self.file_queue.append(file)
            self.current_size += os.path.getsize(file)

    def _start_cleanup_thread(self):
        self.cleanup_thread = threading.Thread(target=self._run_cleanup, daemon=True)
        self.cleanup_thread.start()

    def _run_cleanup(self):
        while True:
            time.sleep(self.cleanup_interval)
            if not os.path.ismount(USB_MOUNT_PATH):
                self.prepare()    
            self._cleanup()

jpegMemoryControl = JpegMemoryControl()


gnss_offset : Optional[datetime.timedelta] = None
# Returns True if the time was set, False if it failed or if the time was already set.
def try_to_get_gnss_time() -> bool:
    global gnss_offset
    if gnss_offset is not None:
        return False
    try:
        with open('/tmp/gnss_time.txt') as f:
            gnss_time_ms = int(f.readline())
        gnss_time = datetime.datetime.fromtimestamp(gnss_time_ms / 1000)
        gnss_offset = gnss_time - datetime.datetime.now()
        print('time', gnss_time, gnss_offset)
    except FileNotFoundError:
        print('failed')
        return False

    return True

def correct_date(timestamp: datetime.datetime) -> datetime.datetime:
    if gnss_offset is None:
        return timestamp
    # print('corrected', timestamp + gnss_offset)
    return timestamp + gnss_offset

def is_mountpoint(path):
    return os.path.ismount(path)

def check_and_create_folder(base_path: str) -> str:
    corrected_date = correct_date(datetime.datetime.now())
    today = corrected_date.strftime("%Y-%m-%d")
    print('today', today)
    daily_folder = os.path.join(base_path, "recording", today)
    os.makedirs(daily_folder, exist_ok=True)
    return daily_folder

def get_latest_file(src_folder: str) -> Optional[str]:
    try:
        completed_process = subprocess.run(
            ['sh', '-c', f'ls -t {src_folder}/*.jpg | head -1'],
            capture_output=True, text=True, check=True
        )
        latest_file = completed_process.stdout.strip()
        # print(latest_file)
        return latest_file if latest_file else None
    except subprocess.CalledProcessError:
        return None

def copy_file(file_path, dest_folder: str) -> None:
    dest_folder_path = Path(dest_folder)
    corrected_timestamp = f'{correct_date(datetime.datetime.now()).timestamp()}'.replace('.', '_')
    try:
        dest_file_path = dest_folder_path / f'{corrected_timestamp}.jpg'
        shutil.copy2(file_path, dest_file_path)
        jpegMemoryControl.add(dest_file_path)
    except FileNotFoundError:
        print('Usb not found!')

def main() -> None:
    usb_path = "/media/usb0"
    source_folder = "/tmp/recording/pic"
    last_checked_date = correct_date(datetime.datetime.now()).date()
    last_check_time = time.time()
    last_copied_file = None
    fail_count = 0

    try_to_get_gnss_time()

    while True:
        if is_mountpoint(usb_path):
            dest_folder = check_and_create_folder(usb_path)

            while True:
                try:
                    if try_to_get_gnss_time() == True:
                        dest_folder = check_and_create_folder(usb_path)
                    #print('dest_folder', dest_folder)
                    latest_file = get_latest_file(source_folder)
                    if latest_file and latest_file != last_copied_file:
                        copy_file(latest_file, dest_folder)
                        last_copied_file = latest_file
                        fail_count = 0

                    current_time = time.time()
                    if current_time - last_check_time > 300:  # 5 minutes in seconds
                        current_date = correct_date(datetime.datetime.now()).date()
                        print('current_date', current_date)
                        if current_date != last_checked_date:
                            last_checked_date = current_date
                            dest_folder = check_and_create_folder(usb_path)
                        last_check_time = current_time
                    fail_count = 0
                    time.sleep(0.5)
                except Exception as e:
                    fail_count += 1
                    print(f"Error in copying file: {e}")
                    time.sleep(2)
                    if fail_count >= 10:
                        raise Exception("Failed to copy 10 images in a row")
        else: 
            print("USB not mounted")
        time.sleep(30)

if __name__ == "__main__":
    main()

import os
import time
import shutil
import datetime
import subprocess

from pathlib import Path
from typing import Optional

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
    print('corrected', timestamp + gnss_offset)
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

def get_latest_file(src_folder):
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

def copy_file(file_path, dest_folder):
    dest_path = Path(dest_folder)
    corrected_timestamp = f'{correct_date(datetime.datetime.now()).timestamp()}'.replace('.', '_')
    shutil.copy2(file_path, dest_path / f'{corrected_timestamp}.jpg')

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
                    print('dest_folder', dest_folder)
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

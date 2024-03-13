import os
import time
import shutil
import datetime
import subprocess

def is_mountpoint(path):
    return os.path.ismount(path)

def check_and_create_folder(base_path):
    today = datetime.datetime.now().strftime("%Y-%m-%d")
    daily_folder = os.path.join(base_path, "recording", today)
    if not os.path.exists(daily_folder):
        os.makedirs(daily_folder)
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
    shutil.copy2(file_path, dest_folder)

def main():
    usb_path = "/media/usb0"
    source_folder = "/tmp/recording/pic"
    last_checked_date = datetime.datetime.now().date()
    last_check_time = time.time()
    last_copied_file = None
    fail_count = 0

    while True:
        if is_mountpoint(usb_path):
            dest_folder = check_and_create_folder(usb_path)

            while True:
                try:
                    latest_file = get_latest_file(source_folder)
                    if latest_file and latest_file != last_copied_file:
                        copy_file(latest_file, dest_folder)
                        last_copied_file = latest_file
                        fail_count = 0

                    current_time = time.time()
                    if current_time - last_check_time > 300:  # 5 minutes in seconds
                        current_date = datetime.datetime.now().date()
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
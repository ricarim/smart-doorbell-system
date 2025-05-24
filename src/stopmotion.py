import time
import os
import sys
import signal
from picamera2 import Picamera2

stop_requested = False

def handle_exit(signum, frame):
    global stop_requested
    print("Received termination signal. Preparing to exit gracefully...")
    stop_requested = True

signal.signal(signal.SIGTERM, handle_exit)
signal.signal(signal.SIGINT, handle_exit)


# Get the capture folder from command-line arguments
capture_folder = sys.argv[1]

# Create the capture folder if it doesn't exist
os.makedirs(capture_folder, exist_ok=True)

# Settings
interval_sec = 1  # Time between frames (seconds)


# Initialize camera
print("Initializing camera...")
picam2 = Picamera2()
picam2.configure(picam2.create_still_configuration(main={"size": (1280, 720)}))
picam2.start()
time.sleep(2)

# Capture images
print(f"Capturing frames into {capture_folder}...")
frame_counter = 0

try:
    while not stop_requested:
        frame_filename = os.path.join(capture_folder, f"frame_{frame_counter:03d}.jpg")
        picam2.capture_file(frame_filename)
        print(f"Captured frame {frame_counter}: {frame_filename}")
        frame_counter += 1
        time.sleep(interval_sec)

except Exception as e:
    print(f"Error: {e}")

finally:
    print("Stopping camera and cleaning up...")
    try:
        picam2.stop()
    except Exception:
        pass

    print("Done.")

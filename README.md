# Smart Doorbell with Camera

This repository contains the final project for the **Embedded Systems** course 2024/2025. The project consists of a **smart doorbell** with video capture, real-time streaming, motion detection, and mobile notifications, built with **Arduino**, **Raspberry Pi**, and integrated with **Home Assistant**.

## Project Goals

- Detect motion or button press at the door
- Start a stop-motion video recording when activity is detected
- Notify the user on their Android device
- Allow access to live video stream and recorded videos
- Indicate active recording with a red

## Hardware Architecture

- **Arduino Uno R3** — handles input from PIR sensor and button
- **Raspberry Pi 3B+** — controls video recording, streaming, and LED
- **NoIR Camera V2** — captures stop-motion images
- **Red LED** — signals active recording/streaming
- **Wi-Fi connectivity** — enables communication with mobile app and Home Assistant
- **Power sources** — separate regulated power for Arduino and Pi

## Software Components

- **Arduino Firmware** — detects sensor/button events and sends via USB
- **Bash Listener** — runs as a systemd service on the Pi to handle events and trigger Python scripts
- **Python Script** — captures stop-motion frames and converts to video using `ffmpeg`
- **MediaMTX Server** — provides RTSP video streaming
- **Home Assistant (Docker)** — notifies user and allows control of streaming via UI
- **OpenSSH + curl + jq** — used for remote commands, API communication, and stream detection

## Functional Workflow

1. Motion or button press is detected by Arduino  
2. Raspberry Pi receives the signal and starts capturing images  
3. Images are converted to a video and stored for access  
4. Notification is sent via Home Assistant  
5. User can start a real-time RTSP stream through the mobile app  

## Functional & Non-Functional Requirements

- Motion detection within 3 seconds and 50cm
- Recording delay < 3 seconds after detection
- Streaming latency < 10 seconds (measured ~2s)
- Energy-efficient behavior (camera off when idle)
- Fully compatible with Android (also tested on iOS)


## Project Report

The full design, architecture, implementation, and evaluation are documented in **report_group7.pdf**.



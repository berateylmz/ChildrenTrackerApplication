# 🛡️ Smart Child Tracker 

An advanced IoT-based mobile application designed to ensure child safety using **Flutter** and **Bluetooth Low Energy (BLE)** technology. This project acts as a bridge between a wearable ESP32 device and a parent's smartphone, providing real-time distance monitoring and critical alerts.


## 📱 Features

* **Real-Time Scanning:** Instantly scans and lists nearby BLE devices.
* **Smart Distance Analysis:** Calculates distance based on RSSI (Signal Strength) values using a custom algorithm.
* **Dynamic Dashboard:**
    * 🟢 **Safe Zone:** RSSI > -60 dBm
    * 🟠 **Warning Zone:** User-defined limit
    * 🔴 **Danger Zone:** Critical distance reached
* **Instant Notifications:** Triggers high-priority local notifications when the child goes out of range or connection is lost.
* **Customizable Settings:** Parents can adjust the "Alarm Threshold" via a slider to fit different environments (park, mall, home).
* **Dark Mode UI:** Modern, battery-friendly interface.

## 🛠️ Technologies Used

* **Mobile Framework:** [Flutter](https://flutter.dev/)
* **Language:** Dart
* **Hardware:** ESP32 (configured as BLE Server)
* **Key Packages:**
    * `flutter_blue_plus` (For Bluetooth connectivity)
    * `flutter_local_notifications` (For critical alerts)
    * `shared_preferences` (For saving user settings)
    * `permission_handler` (For Android permissions)


## 🚀 How It Works?

1.  The **ESP32** broadcasts a BLE signal as a wearable device.
2.  The **Flutter App** connects to the device and subscribes to the RSSI stream.
3.  The app processes the signal strength every second.
4.  If the signal drops below the user-defined threshold (e.g., -90 dBm), the app triggers a **"CRITICAL ALERT"** notification to warn the parent.

---
*Developed by [Berat Erdoğanyılmaz - Simge Baraç]*

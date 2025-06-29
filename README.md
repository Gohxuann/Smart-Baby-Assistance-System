# 👶✨ Smart Baby Assistance System with Safety and Sleep Monitoring

Welcome to the future of baby care! This project is your all-in-one, sensor-powered, parent-friendly, peace-of-mind-giving Smart Baby Assistance System. Whether you’re a new parent or a seasoned pro, this system helps you keep an eye (and an ear!) on your little one—so you can finally finish that cup of coffee while it’s still hot. ☕👀

---

## 🚼 Why Did We Build This?

### The Problem
Babies are adorable, but let’s face it—they’re also tiny escape artists and unpredictable sleepers. Parents can’t always be on guard, and missing a cry, a roll to the crib’s edge, or a sudden temperature spike can mean stress, sleepless nights, or worse. We needed a smart, real-time, always-on solution to keep babies safe and parents sane.

### The Solution
Enter the **Smart Baby Assistance System**! Powered by an ESP32, a squad of sensors, and a slick web dashboard, this system:
- Detects motion and vibration (is baby awake? crying? plotting an escape?).
- Measures how close baby is to the edge of the crib.
- Monitors temperature and humidity for ultimate comfort.
- Lets you set your own safety distance.
- Shows all the important stuff on a cute OLED display.
- Sends real-time data to Firebase and stores history in phpMyAdmin.
- Gives you a web dashboard to check readings, get alerts, control alarms, and see trends.

---

## 🧩 How Does It Work? (Sensors & Logic)

| Sensor/Module      | What It Does                                      |
|--------------------|---------------------------------------------------|
| **PIR Sensor**     | Detects baby motion (waking up, moving, crying)   |
| **Vibration Sensor** | Detects strong vibrations (crying, hitting crib) |
| **Ultrasonic Sensor** | Measures distance to crib edge, triggers alert  |
| **DHT11 Sensor**   | Monitors temperature and humidity                 |
| **Relay Module**   | Activates alarm (auto/manual control)             |
| **ESP32 + OLED**   | Displays temp, distance, alarm, baby status       |
| **Flutter Web App**| Lets you view/control everything remotely         |

### 🧠 System Logic (a.k.a. How the Magic Happens)

| Feature                | Logic Condition                                              |
|------------------------|-------------------------------------------------------------|
| **Wake Detection**     | Motion/vibration count ≥ 5 (checked every 5 seconds)        |
| **Wake End Detection** | No new motion/vibration for 5 seconds (baby = sleeping)     |
| **Too Near Detection** | Distance < 10cm for 5 seconds                               |
| **Alarm Trigger**      | Baby awake ≥ 10s OR too near the edge                       |
| **OLED Display**       | Shows temp, distance, wake status, safety, alarm            |
| **Firebase Sync**      | Updates every ~3s: temp, hum, dist, status, safety, etc.    |
| **Manual/Auto Mode**   | Manual = you control alarm; Auto = system logic             |
| **Trends**             | See temp, distance, awake/vibration/motion trends           |
| **Failsafe**           | WiFi/Firebase retry, auto-restart on failure                |

---

## 🛠️ Schematic & Wiring

**Full schematic:** [View on Cirkit Designer](https://app.cirkitdesigner.com/project/f080b9df-b897-4bea-8497-e9b2085b4f3e)

| Component         | ESP32 Pin | Wire Color | Function/Signal         |
|-------------------|-----------|------------|------------------------|
| DHT11             | GPIO 4    | 🟨 Yellow  | Data                   |
| PIR Sensor        | GPIO 13   | 🟩 Green   | Output                 |
| Vibration Sensor  | GPIO 5    | 🔵 Blue    | Digital Output         |
| Ultrasonic Sensor | GPIO 12/14| 🟧/⚪ Orange/White | TRIG/ECHO      |
| Relay Module      | GPIO 25   | 🟪 Purple  | Signal (Alarm)         |
| OLED Display (I2C)| GPIO 21/22| ⚫/🟤 Grey/Brown | SDA/SCL         |

*All sensors powered by 3.3V or VIN, GND is always ⚫ Black.*

---

## 🤖 Code & Backend

- **Arduino Code:** [smart_baby_arduino_code.ino](https://github.com/Gohxuann/Smart-Baby-Assistance-System/blob/main/smart_baby_arduino_code/smart_baby_arduino_code.ino)
- **Backend (PHP):** [server/http](https://github.com/Gohxuann/Smart-Baby-Assistance-System/tree/main/smart_baby_web/server/http)
- **Firebase:** For real-time data
- **phpMyAdmin:** For historical data and trends

---

## 🌐 Web Dashboard (Flutter)

- **Source:** [`smart_baby_web/lib`](https://github.com/Gohxuann/Smart-Baby-Assistance-System/tree/main/smart_baby_web/lib)
- ![image](https://github.com/user-attachments/assets/0c2bb0aa-48a2-4e50-926c-31bf7dce64e5)
- ![image](https://github.com/user-attachments/assets/72fb2a22-4e8d-46e9-910e-7017da59a97a)
- ![image](https://github.com/user-attachments/assets/b237cd03-6723-4ec1-80f4-19f2cedc303f)
- **Features:**
  - Login/Register
  - Dashboard: live data, alerts, alarm control
  - Manual/Auto mode switch
  - Set safety distance
  - Trend screens: see how baby’s environment and activity change over time

---

## 🎬 See It In Action!

Check out our demo video: [YouTube Link](https://youtu.be/DbII7qmz5O4)

---

## 🚀 Ready to Get Started?

1. Clone the repo
2. Flash the Arduino code to your ESP32
3. Set up Firebase and phpMyAdmin (see code for details)
4. Run the Flutter web app
5. Enjoy smarter, safer, and more restful parenting!

---

## 👨‍👩‍👧‍👦 Made with ❤️ for parents, by techies.

Feel free to fork, star, and contribute!  
Questions? Issues? [Open an issue](https://github.com/Gohxuann/Smart-Baby-Assistance-System/issues) or reach out!

---

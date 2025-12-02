🚨 ESP32 Gas Detection System with PPM Calculation & ThingSpeak IoT Monitoring

This project is an IoT-based gas monitoring system using an ESP32 microcontroller and an MQ-series gas sensor.
The ESP32 reads the analog gas concentration, converts the raw ADC reading into an estimated PPM (Parts Per Million) value, and uploads the data to ThingSpeak Cloud for real-time monitoring.

This project is ideal for gas leakage monitoring, IoT learning, MQ sensor calibration, and cloud-based sensor analytics.

📌 Features
✅ 1. Gas Sensor Reading (MQ Series)

Reads analog gas concentration using the ESP32 ADC pin.

Supports MQ-2, MQ-3, MQ-135, MQ-9, and similar MQ analog sensors.

Includes signal smoothing to avoid noisy ADC spikes.

✅ 2. PPM (Parts Per Million) Calculation

Converts raw ADC values into meaningful PPM using:

Sensor voltage calculation

Sensor resistance (Rs) calculation

Rs/R0 ratio

Logarithmic gas concentration curve equation

Supports calibration using:

R₀ in clean air

Curve values (m, b) from sensor datasheets

✅ 3. ThingSpeak Cloud Upload

Sends PPM value to ThingSpeak every 15 seconds.

Compatible with Field1 or any field of your ThingSpeak channel.

Helpful for cloud dashboards and data logging.

✅ 4. Calibration Mode

Press C in Serial Monitor to:

Capture clean-air sample

Automatically compute R₀

Update sensor baseline

✅ 5. Robust Signal Handling

Filters unstable readings

Prevents extreme false PPM values

Clamps invalid sensor states (e.g., Vout too low)

🛠 Hardware Required
Component	Quantity
ESP32 Dev Module	1
MQ Gas Sensor (MQ-2 / MQ-3 / MQ-135 etc.)	1
Breadboard & Wires	As required
USB Cable	1
🔌 Circuit Connection
MQ Sensor Pin	ESP32 Pin
AOUT	GPIO 34 (ADC)
VCC	3.3V
GND	GND
DOUT	Not used

⚠ MQ sensors are 5V sensing devices, but when using ESP32 analog input, only AOUT must be connected to the ADC pin.
Always use 3.3V for safety on ESP32.

📡 Cloud Integration (ThingSpeak)

The ESP32 uploads PPM values to:

https://api.thingspeak.com/update


Example:

field1 = 123.45 (PPM)


Your ThingSpeak Write API Key is required.

🧠 PPM Conversion Logic

The project uses the formula:

Rs = Rload * (Vcc - Vout) / Vout
ratio = Rs / R0
log10(ppm) = (log10(ratio) - b) / m
ppm = 10 ^ (...)


Where:

Rload = load resistor (e.g., 10kΩ)

R0 = sensor resistance in clean air

m, b = curve constants from the MQ sensor datasheet

🧪 Calibration Instructions

Place sensor in fresh, clean air.

Open Serial Monitor.

Type:

c


The ESP32 automatically calculates R0.

Copy the printed R0 value into the code for future accuracy.

☁ ThingSpeak Dashboard Example

You can build:

Real-time charts

Threshold alerts

Mobile app integration

Gas leakage notifications

📁 File Structure Example
├── src/
│   └── gas_monitor.ino
├── README.md
└── LICENSE

▶️ How to Run

Install Arduino IDE or use PlatformIO.

Select ESP32 Dev Module.

Install required libraries:

WiFi.h

HTTPClient.h

Enter your:

Wi-Fi SSID

Wi-Fi password

ThingSpeak Write API Key

Upload to the ESP32.

Open Serial Monitor → view live PPM output.

Open ThingSpeak → view cloud data updates.

📊 Real-Time Readings Example

Serial output:

RAW=320 Vout=0.25V Rs=92.8 kΩ → PPM=134.50


ThingSpeak Field1 entry:

134.50

📜 License

This project is open-source under the MIT License.

⭐ Contribute

Fork the repo, submit issues, and make PRs to improve the project.

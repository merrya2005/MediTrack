# MediTrack: Step-by-Step Setup & Configuration Guide

This guide provides the complete workflow for assembling the hardware and configuring the MediTrack app for real-time RFID medication tracking.

## 📦 Phase 1: Hardware Essentials
Collect the following hardware components:
1.  **Microcontroller**: ESP32 Dev Board (recommend ESP32 DevKit V1).
2.  **Reader**: RC522 RFID Reader Module.
3.  **Tags**: Mifare 13.56MHz RFID Tags (stickers or credit card sized).
4.  **Wiring**: 7-Pin Female-to-Female Jumper Wires.
5.  **Power**: Micro-USB Cable and 5V Power adapter.

### 🛠️ Step 1.1: Hardware Assembly (Wiring)
Connect the RC522 to the ESP32 using these pin mappings:
*   **RC522 SDA** -> ESP32 GPIO 5
*   **RC522 SCK** -> ESP32 GPIO 18
*   **RC522 MOSI**-> ESP32 GPIO 23
*   **RC522 MISO**-> ESP32 GPIO 19
*   **RC522 GND** -> ESP32 GND
*   **RC522 RST** -> ESP32 GPIO 22
*   **RC522 3.3V**-> ESP32 3.3V (⚠️ Not 5V!)

---

## 📱 Phase 2: App & Tag Configuration
Follow these steps to link your physical hardware to the digital app.

### 🏁 Step 2.1: Patient Onboarding
1.  Open the **MediTrack Patient App**.
2.  Register a new account or log in with existing credentials.
3.  Navigate to the **Medicine Hub** (Middle tab) and use the **+ Add Medicine** button to register your current prescription (e.g., "Vitamin D3").
4.  Specify the daily schedule (Frequency, Timings, and Start/End dates).

### 🏷️ Step 2.2: Fetching the Tag UID
1.  Connect your ESP32 to your PC.
2.  Upload the RC522 "DumpInfo" example (from the MFRC522 Library).
3.  Open the **Serial Monitor**.
4.  Tap your physical RFID sticker/tag on the reader.
5.  **Note down the UID** displayed in the Serial Monitor (e.g., `A1 B2 C3 D4`).

### 🔗 Step 2.3: Pairing in the App
1.  In the Patient App, go to the **Profile** tab.
2.  Select **RFID Tag Management**.
3.  Find "Vitamin D3" (from Step 2.1) in the list and click it.
4.  Enter the **UID** you noted from Step 2.2 into the input field.
5.  Click **SAVE TAG**.
    *   *The app now knows that Tag `A1 B2 C3 D4` represents Vitamin D3.*

---

## 🚀 Phase 3: Real-Time Medication Tracking
Once configured, the tracking works as follows:

1.  **The Overdue Alert**: If a patient misses a dose, the **Caregiver App** will immediately show a **Red Alert** on their dashboard.
2.  **The Tap**: The patient takes the medicine bottle and taps the physical RFID tag against the Bedside Reader (ESP32 unit).
3.  **Cloud Logging**: The ESP32 sends the UID to Supabase. Supabase identifies it belongs to the patient's Vitamin D3.
4.  **Automatic Update**: 
    -   The **Patient Dashboard** instantly shows a "Completed" checkmark.
    -   The **Medicine Stock** count decreases by 1 automatically.
    -   The **Caregiver Alert** clears instantly.

## 📝 Critical Tips
*   **Tag Placement**: Stick the RFID sticker on the top cap of the medicine bottle for easy tapping.
*   **Internet Access**: Ensure the ESP32 is connected to the same Wi-Fi mentioned in your code's `WiFi.begin("SSID", "PASS")` section.
*   **Multiple Meds**: You can link different tags to different medicines (e.g., Blue tag for Heart Med, White tag for vitamins).

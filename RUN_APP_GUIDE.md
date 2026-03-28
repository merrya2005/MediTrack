# MediTrack Application Runner Guide

## Step 1: Initialize Database
We have created the fully integrated database structure inside `D:\MediTrack\FULL_DATABASE_SCHEMA.sql`.
1. Open your **Supabase Dashboard**.
2. Go to the **SQL Editor** on the left menu.
3. Click **New Query** and copy-paste the entire contents of `FULL_DATABASE_SCHEMA.sql`.
4. Run the query. This sets up all Tables, Realtime WebSockets for Chats, the Storage Bucket permissions, and the `medicine_time` columns perfectly!

## Step 2: System Clean & Rebuild
Because we added the native `nfc_manager` hardware functionality and new permissions to AndroidManifest, your current memory cache for flutter is outdated.
Run the following explicitly on your Patient App and Caregiver App folders:

### For Patient App:
```cmd
cd D:\MediTrack\patient_app
flutter clean
flutter pub get
flutter run
```

### For Caregiver App:
```cmd
cd D:\MediTrack\caregiver_app
flutter clean
flutter pub get
flutter run
```

## Step 3: Setting Up NFC Smart Medicine (Hardware Demo)
You must use a **PHYSICAL Smartphone** (Android or iPhone). An emulator mathematically cannot simulate reading magnetic NFC stickers.
1. Put standard blank NFC stickers (NTAG215) on your medicine bottles.
2. Open the **Patient App**. Go to **Medicine (Stock & Intake)**.
3. Press **[LINK TAG]**. Hold the blank sticker against the back of your physical phone. The flutter app will write the NDEF format to tie it natively to your medicine.
4. From now on, whenever your live-notification tells you to take your pill, click **TAP NFC TO VERIFY** and place the sticker nearby. It securely matches the code, deletes a stock item, and inserts the history log!

## Troubleshooting build errors
If you get compiling errors regarding `nfc_manager` on Android (usually `minSdkVersion` issues), open your `android/app/build.gradle` and ensure:
`minSdkVersion 19` (or 21 which is modern standard).

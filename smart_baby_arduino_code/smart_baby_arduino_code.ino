#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <DHT.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// OLED setup
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 32
#define OLED_RESET -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// Pin configuration
#define DHTPIN 4
#define DHTTYPE DHT11
#define PIR_PIN 13
#define VIB_PIN 5
#define TRIG_PIN 12
#define ECHO_PIN 14
#define RELAY_PIN 25

// WiFi and Firebase credentials


// Firebase objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
String firebasePath = "/babydata";

// Sensor and logic variables
DHT dht(DHTPIN, DHTTYPE);
int motionCount = 0;
int vibCount = 0;
unsigned long countTimer = 0;
const int countWindow = 60000;
float hum = 0, temp = 0;
unsigned long lastActiveTime = 0;
bool babyAwake = false;

void setup() {
  Serial.begin(115200);
  pinMode(PIR_PIN, INPUT);
  pinMode(VIB_PIN, INPUT);
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);

  // Initialize OLED display
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) { // Default I2C address 0x3C
    Serial.println(F("SSD1306 allocation failed"));
    while (true); // Stop here if OLED is not found
  }

  display.clearDisplay();
  // Display text
  display.setTextSize(1);       // Text size
  display.setTextColor(SSD1306_WHITE); // White text
  display.setCursor(0, 0);
  display.println("Booting...");
  display.display();

  // Connect WiFi
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");

  int retry = 0;
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    retry++;
    if (retry > 60) {
      Serial.println("\n❌ WiFi failed. Restarting...");
      ESP.restart();
    }
  }

  Serial.println("\n✅ WiFi Connected");
  display.clearDisplay();
  display.setCursor(0, 0);
  display.println("WiFi Connected!");
  display.println("IP: " + WiFi.localIP().toString());
  display.display();

  dht.begin();
  initFirebase();
}

void loop() {
  if (!Firebase.ready()) {
    Serial.println("⏳ Waiting for Firebase...");
    return;
  }
  runSensorLogic();
}

void runSensorLogic() {
  float temp = dht.readTemperature();
  float hum = dht.readHumidity();
  bool motion = digitalRead(PIR_PIN);
  bool vibrate = digitalRead(VIB_PIN);
  float dist = readDistance();

  if (isnan(temp) || isnan(hum)) {
    Serial.println("⚠️ DHT sensor read failed");
    return;
  }

  if (millis() - countTimer > 5000) {
    countTimer = millis();
    if (motion || vibrate) {
      motionCount++;
      vibCount++;
      lastActiveTime = millis();  // Reset idle timer
    }
  }

  // Determine if baby is awake or sleeping
  if (!babyAwake && (motionCount + vibCount >= 5)) {
    babyAwake = true;
  }

  if (babyAwake && millis() - lastActiveTime > 5000) {  // 5s no movement
    babyAwake = false;
    motionCount = 0;
    vibCount = 0;
  }

  String wakeStatus = babyAwake ? "Baby Wakeup!" : "Baby Sleeping";
  String nearStatus = (dist < 10 && dist > 0) ? "Too near!" : "Safe";

  // Fan logic
  // if (temp > 22.2) {
  //   digitalWrite(RELAY_PIN, LOW); //turn on relay or fan
  // } else if (temp < 20) {
  //   digitalWrite(RELAY_PIN, HIGH); // turn off relay or fan
  // }

  if (wakeStatus == "Baby Wakeup!" || nearStatus == "Too near!"){
    digitalWrite(RELAY_PIN, LOW);
  } else {
    digitalWrite(RELAY_PIN, HIGH);
  }

  // Serial Monitor output
  Serial.println("========== SENSOR STATUS ==========");
  Serial.println("Temp: " + String(temp) + " °C");
  Serial.println("Humidity: " + String(hum) + " %");
  Serial.println("Distance: " + String(dist) + " cm");

  Serial.println("===================================");

  Serial.println("Motion: " + String(motion ? "YES" : "NO"));
  Serial.println("Vibration: " + String(vibrate ? "YES" : "NO"));
  Serial.println("Distance: " + String(dist) + " cm");

  Serial.println("===================================");

  Serial.println("Status: " + wakeStatus);
  Serial.println("Safety: " + nearStatus);

  // OLED Page 1
  display.clearDisplay();
  display.setCursor(0, 0);
  display.println("Temp: " + String(temp) + " C");
  //display.println("Hum: " + String(hum) + " %");
  display.println("Dist: " + String(dist) + "cm");
  display.println("Status: " + wakeStatus);
  display.println("Safety: " + nearStatus);
  display.display();

  // Firebase upload
  Firebase.RTDB.setFloat(&fbdo, firebasePath + "/temp", temp);
  Firebase.RTDB.setFloat(&fbdo, firebasePath + "/hum", hum);         // ADD this
  Firebase.RTDB.setFloat(&fbdo, firebasePath + "/dist", dist);       // ADD this
  Firebase.RTDB.setString(&fbdo, firebasePath + "/status", wakeStatus);
  Firebase.RTDB.setString(&fbdo, firebasePath + "/safety", nearStatus);

  delay(3000);
}

float readDistance() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  long duration = pulseIn(ECHO_PIN, HIGH, 30000); // timeout = 30ms
  return duration * 0.034 / 2.0;
}

void initFirebase() {
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  Serial.println("Connecting to Firebase...");
  display.clearDisplay();
  display.setCursor(0, 0);
  display.println("Connecting Firebase...");
  display.display();

  unsigned long startTime = millis();
  while (auth.token.uid == "") {
    Serial.print(".");
    delay(1000);
    if (millis() - startTime > 15000) {
      Serial.println("\n❌ Firebase Auth failed. Check credentials.");
      display.clearDisplay();
      display.setCursor(0, 0);
      display.println("Firebase Failed :(");
      display.display();
      return;
    }
  }

  Serial.println("\n✅ Firebase Connected");
  display.clearDisplay();
  display.setCursor(0, 0);
  display.println("Firebase OK >-<");
  display.display();
  delay(3000);
}

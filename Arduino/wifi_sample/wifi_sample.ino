#include <Wire.h>
#include <ESP8266WiFi.h> //Indeholder WiFi-funktioner, specielt til ESP-modellen.

void setup() {
  Serial.begin(115200); //Her startes den serielle forbindelse, (hvis arduinoen er forbundet via. USB) 1152000 er baudraten, data hastigheden, modtageren skal have samme hastighed.
  delay(10); //Vent, elers går det for hurtigt
  // put your setup code here, to run once:
  const char* ssid = "Fibernet-IA01046616"; // WiFi-Netværkets SSID gemmes.
  const char* password = "rfw2zZWn";
  pinMode(LED_BUILTIN, OUTPUT); 
  digitalWrite(LED_BUILTIN, 1);
  Serial.println();
  Serial.println("Hejsa");
  
  //Opretter forbindelse til WiFi
  WiFi.begin(ssid, password);
  //Mens forbindelsen oprettes - tænke prikker:
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  //Vis at forbindelsen er oprettet
  Serial.println("");
  Serial.println("WiFi connected");
  //Vis at serveren startes og start
  //server.begin();
  //Serial.println("Server started  ");
  // IP-adressen hvor serveren findes printes
  Serial.println("IP-Address: ");
  Serial.println(WiFi.localIP());
}

void loop() {
  // put your main code here, to run repeatedly:
  delay(1000);
  digitalWrite(LED_BUILTIN, 0);
  delay(1000);
  digitalWrite(LED_BUILTIN, 1);
}

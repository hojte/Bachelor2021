/*
    Based on Neil Kolban example for IDF: https://github.com/nkolban/esp32-snippets/blob/master/cpp_utils/tests/BLE%20Tests/SampleServer.cpp
    Ported to Arduino ESP32 by Evandro Copercini
    updates by chegewara

    Modified by VidIt to suit our needs.
*/

#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
//#include <AccelStepper.h>


#define SERVICE_UUID        "ea411899-d14c-45d5-81f0-ce96b217c64a"
#define CHARACTERISTIC_UUID "91235981-23ee-4bca-b7b2-2aec7d075438"
#define CHARACTERISTIC_UUID_RX "52e6a8f9-5688-4d81-b1ad-ece87b095e52"

const int ledPin = 2;
BLEServer *VidItServer;
BLEService *VidItService;
BLECharacteristic *VidItCharacteristic;
BLEAdvertising *VidItAdvertising;

// defines pins numbers
// 1st motor
const int stepPin_1 = 33; 
const int dirPin_1 = 32; 
const int MS1_1 = 27; 
const int MS2_1 = 26; 
const int MS3_1 = 25; 

// 2nd motor
const int stepPin_2 = 22; 
const int dirPin_2 = 23;
const int MS1_2 = 18; 
const int MS2_2 = 19; 
const int MS3_2 = 21; 

// Define motor interface type
#define motorInterfaceType 1



void setup() {
  Serial.begin(115200);
  Serial.println("STARTING BLE FOR VIDIT");
  pinMode(ledPin, OUTPUT);

  //Init the BLE device with the name.
  BLEDevice::init("VidItESP32");
  //Creating the BLE device as a BLE server
  VidItServer = BLEDevice::createServer();

  
  //Creating BLE service with the service UUID
  VidItService = VidItServer->createService(SERVICE_UUID);
  //Creating BLE characteristic with UUID wit properties read and write.
  VidItCharacteristic = VidItService->createCharacteristic(
                                         CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ |
                                         BLECharacteristic::PROPERTY_WRITE
                                       );
                                       
  //The setValue should be changed in the future to display the state
  VidItCharacteristic->setValue("LOL");
  VidItService->start();
  //The following sets the attributes for the advertising. Such as the UUID, the scan response and start 
  //the BLE adverstising so BT devices can find it. 
  VidItAdvertising = BLEDevice::getAdvertising();
  VidItAdvertising->addServiceUUID(SERVICE_UUID);
  VidItAdvertising->setScanResponse(true);
  VidItAdvertising->setMinPreferred(0x06);  // functions that help with iPhone connections issue
  VidItAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  
  Serial.println("READY TO BE PAIRED");

  
  pinMode(stepPin_1,OUTPUT); 
  pinMode(dirPin_1,OUTPUT);
  pinMode(MS3_1,OUTPUT);
  pinMode(MS2_1,OUTPUT);
  pinMode(MS1_1,OUTPUT);
  digitalWrite(MS3_1,HIGH);
  digitalWrite(MS2_1,HIGH);
  digitalWrite(MS1_1,HIGH);
  digitalWrite(stepPin_1,HIGH);

  pinMode(stepPin_2,OUTPUT); 
  pinMode(dirPin_2,OUTPUT);
  pinMode(MS3_2,OUTPUT);
  pinMode(MS2_2,OUTPUT);
  pinMode(MS1_2,OUTPUT);
  digitalWrite(MS3_2,HIGH);
  digitalWrite(MS2_2,HIGH);
  digitalWrite(MS1_2,HIGH);
  digitalWrite(stepPin_2,HIGH);
  
  
}

//Rotates a single motor
void rotateSingleStepper(int dirPin, int stepPin, int direct, double _speed)
{
  digitalWrite(dirPin,direct); // Enables the motor to move in a particular direction      
  digitalWrite(stepPin,HIGH); 
  delayMicroseconds(_speed); 
  digitalWrite(stepPin,LOW); 
  delayMicroseconds(_speed);         
  delay(1); 
}

//Rotates both motors
void rotateMultipleSteppers(int dirPin1, int stepPin1, int direct1, int dirPin2, int stepPin2, int direct2, double _speed)
{
  //Motor going up and down
  digitalWrite(dirPin1,direct1); // Enables the motor to move in a particular direction      
  digitalWrite(stepPin1,HIGH); 
  delayMicroseconds(_speed); 
  digitalWrite(stepPin1,LOW); 
  delayMicroseconds(_speed);

 //Motor going right and left 
  digitalWrite(dirPin2,direct2); // Enables the motor to move in a particular direction      
  digitalWrite(stepPin2,HIGH); 
  delayMicroseconds(_speed); 
  digitalWrite(stepPin2,LOW); 
  delayMicroseconds(_speed);
  delay(1); 
}


int connectedUsers = 0;

void loop() {
  connectedUsers = VidItServer->getConnectedCount();
  
  if(connectedUsers > 0){    
    digitalWrite(ledPin, HIGH);
    Serial.println(VidItCharacteristic->getValue().c_str());

    //Splitting the input string into direction and speed
    std::string inputFromAPP = VidItCharacteristic->getValue().c_str();
    std::string delimiter = ":"; 
    std::string _direction = inputFromAPP.substr(0,inputFromAPP.find(delimiter));

    //Removes the direction from the string and finds the speed
    inputFromAPP.erase(0, inputFromAPP.find(delimiter) + delimiter.length());
    std::string _speed = inputFromAPP.substr(0,inputFromAPP.find(delimiter));
    //double convertedSpeed = atof(_speed.c_str()); 
    double convertedSpeed = 1000.0; 

    
    //Debug statement - printing in console.
    if (_direction== "Right"){
      rotateSingleStepper(dirPin_1, stepPin_1,LOW,convertedSpeed);
      }
      else if (_direction== "Left"){
        rotateSingleStepper(dirPin_1, stepPin_1,HIGH,convertedSpeed);
        }
      else if(_direction== "Up"){
        rotateSingleStepper(dirPin_2, stepPin_2,HIGH,convertedSpeed);
        }
      else if(_direction== "Down"){
        rotateSingleStepper(dirPin_2, stepPin_2,LOW,convertedSpeed);
        }
      else if(_direction== "Up & Right"){
        rotateMultipleSteppers(dirPin_2,stepPin_2,HIGH,dirPin_1,stepPin_1,LOW,convertedSpeed);
        }
      else if(_direction== "Up & Left"){
        rotateMultipleSteppers(dirPin_2,stepPin_2,HIGH,dirPin_1,stepPin_1,HIGH,convertedSpeed);
        }
      else if(_direction== "Down & Right"){
        rotateMultipleSteppers(dirPin_2,stepPin_2,LOW,dirPin_1,stepPin_1,LOW,convertedSpeed);
        }
      else if(_direction== "Down & Left"){
        rotateMultipleSteppers(dirPin_2,stepPin_2,LOW,dirPin_1,stepPin_1,HIGH,convertedSpeed);
        }
      else{
        //Do nothing
        //Serial.println("FUCKING HOLD BITHC");  
     }          
  }
  else{
    digitalWrite(ledPin, LOW);
  }
}

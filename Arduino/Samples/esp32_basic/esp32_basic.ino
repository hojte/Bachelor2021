/*     Simple Stepper Motor Control Exaple Code
 *      
 *  by Dejan Nedelkovski, www.HowToMechatronics.com
 *  altered by Mathias Olsen for esp32
 */
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

void setup() {
  // Sets the two pins as Outputs
  pinMode(stepPin_1,OUTPUT); 
  pinMode(dirPin_1,OUTPUT);
  digitalWrite(stepPin_1,HIGH);
  
  Serial.begin(115200);
  delay(10); //Vent, elers går det for hurtigt
}
void loop() {
  Serial.println("Counter-Clockwise");
  digitalWrite(dirPin_1,HIGH); // Enables the motor to move in a particular direction
  // Makes 200 pulses for making one full cycle rotation
  for(int x = 0; x < 200; x++) {
    digitalWrite(stepPin_1,HIGH); 
    delayMicroseconds(500); 
    digitalWrite(stepPin_1,LOW); 
    delayMicroseconds(500); 
  }
  
  delay(1000); // One second delay
  
  Serial.println("Clockwise");
  digitalWrite(dirPin_2,LOW); //Changes the rotations direction
  // Makes 400 pulses for making two full cycle rotation
  for(int x = 0; x < 200; x++) {
    digitalWrite(stepPin_1,HIGH);
    delayMicroseconds(500);
    digitalWrite(stepPin_1,LOW);
    delayMicroseconds(500);
  }
  delay(1000);
}

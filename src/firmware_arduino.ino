const int pir = 2;
const int but = 4;
int motion; 
int touch;

void setup() {
  pinMode(pir, INPUT);
  pinMode(but, INPUT);
  Serial.begin(9600);
  delay(2000);
}

void loop() {
  motion = digitalRead(pir);
  touch = digitalRead(but);
  
  if (motion) {
    Serial.println("motion");
    delay(1000);
  } else if (touch) {
    Serial.println("touch");
    delay(1000);
  }
  

}


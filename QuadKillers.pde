import ddf.minim.*;
//import processing.sound.*;

/* Where can I find the requirements?
 * for loop can be found literally anywhere, while loop can found in Visual file at the very bottom (class Shape)
 * return functions can be found in the CollisionClasses file at the bottom, they return a boolean
 * All title screen code and buttons are found in the Screen file
 * Every single file besides GameEngine has a class with parameters
 */

//Overall root game code

int objectCount = 0; //global variable that tracks total object count and generates unique object ids
ArrayList<GameObject> objs = new ArrayList<GameObject>(); //list of all the objects (entities)
ArrayList<TextParticle> textParticles = new ArrayList<TextParticle>(); //list of all text particles (damage indicators)
ArrayList<BgObj> bgObjs = new ArrayList<BgObj>(); //list of all particles (trail effects)
ArrayList<Shape> shapes = new ArrayList<Shape>(); //background shape effect
Shape grid;
PVector mousePos = new PVector(0, 0); //world coords for mouse (not screen)
Player player = new Player();
//SoundFile bgMusic;
Minim m;
AudioPlayer bgm;
float millis; //stores the time at the beginning of the frame
int killCount = 0; //the amount of kills so far
int enemyCount = 0;
int wave; //what wave (enemy spawning)
boolean logTime = true; //Dev tool: whether or not to log how long each gameLoop section takes

//crosshair constants
int magic; //Spell level (will increase when nail hits enemies) (max is 32 magic)
float crossScale = 1;
color crossCol = color(0, 0, 1); //color of the crosshair

void setup() {
  size(800,800, P2D); //Oversize the screen so that it maxes ou t the size (the fullscreen command does not support P2D)
  colorMode(HSB, 360, 1, 1, 1);
  frameRate(60);
  surface.setResizable(true);
  m = new Minim(this);
  bgm = m.loadFile("GameTrack.mp3");
  bgm.loop();
  //bgMusic = new SoundFile(this, "DieAlone.mp3");
  //bgMusic.loop();
  for (int i=0; i<frameLength; i++) { //code for preloading the slash animation
    slashFrame[i] = calcSlash((float)(i+1)/frameLength);
  }
  patchText = join(loadStrings("patchtext.txt"),"\n");
  shape(createShape(RECT, 0, 0, 1, 1)); //dummy shape because shape function is weird on the first usage
  titleFont = createFont("DataTransfer.ttf", 100); //set fonts
  buttonFont = createFont("Arial", 25);
  //create background shapes
  noStroke();
  rectMode(CENTER);
  ellipseMode(CENTER);
  for (int i=0; i<20; i++) { //create background particle
    fill(random(0, 360), 1, 1, 0.2);
    shapes.add(new Shape(createShape(RECT, 0, 0, 50, 50), new PVector(50, 50), random(0.5, 2), random(0, HALF_PI)) );
    fill(random(0, 360), 1, 1, 0.2);
    shapes.add(new Shape(createShape(ELLIPSE, 0, 0, 50, 50), new PVector(50, 50), random(0.5, 2), 0) );
    fill(random(0, 360), 1, 1, 0.2);
    shapes.add(new Shape(createShape(TRIANGLE, -25, -25, 25, -25, 0, 25), new PVector(50, 50), random(0.5, 2), random(0, HALF_PI)) );
  }
  initWorlds();
}

float bgBrightness = 0;
float bgHue = 0; //red
PVector screenShake = new PVector(0, 0);
//don't account for screenShake in calculations because it is a very temporary effect

void draw() {
  millis = millis();
  if (screen ==0) {
    background(0);
    for (Shape s : shapes) {
      s.update();
    }
    camPos.add(0, -1);
    textAlign(CENTER, CENTER);
    textSize(width/50);
    fill(360, map(sin(TAU*millis*0.001), 0, 1, 0.7, 1));
    text("Take a moment to full screen your window", 0.5*width, 0.5*height);
    text("(click or press key to continue)", 0.5*width, 0.5*height+50);
  } else if (screen == 2 || screen == 3) {
    gameLoop();
  } else {
    screenLoop();
  }
}

void tutorialStart() {
  player = new Player(0, 0);
  camPos.set(0, 0);
  enemyCount = 0;
  objectCount = 0;
  killCount =0;
  magic=32;
  lastSpawn = millis + 3000;
  initBasicEnemySprite();
  objs.clear();
  bgObjs.clear();
  textParticles.clear();
}

float lastSpawn = 1000; //last time when enemies were spawned
int subWave=0;//subwave counters
void gameLoop() {
  bgBrightness = lerp(bgBrightness, 0, 0.2*dt);
  background(bgHue, 1, bgBrightness);
  calcFps(); //show fps and calculate dt

  //render background shapes (outside camera push pop)
  float startTime = millis();
  for (Shape s : shapes) {
    s.update();
  }
  drawGrid(50);
  if (logTime) {
    print("bgShapes:"+(millis()-startTime));
  }
  if (screen==3) {
    worldDir.get(currentWorld).enemySpawn(); //calls loops for the currently selected world
  }
  //camera translations
  pushMatrix();
  translate(screenShake.x*camScale, screenShake.y*camScale);
  translate(0.5*width, 0.5*height); //this is the problem line
  scale(camScale);
  translate(-camPos.x, -camPos.y);

  mousePos.set((mouseX-0.5*width)/camScale+camPos.x, (mouseY-0.5*height)/camScale+camPos.y);
  //set mouse position based on camera scale and pos constant

  if (screenShake.mag() > 100) {
    screenShake.setMag(100);
  }
  screenShake.lerp(new PVector(0, 0), 0.5*dt);

  PVector avgPos = new PVector(0, 0);
  float avgCount = 0; //This iss the total n count used for calculating the average position
  for (GameObject obj : objs) {
    if (obj.type[8] /*boss*/) {
      //weight boss position by factor of 20
      avgPos.add(obj.pos.copy().mult(20));
      avgCount+=20;
    } else if (obj.type[0]) { //if the object is an enemy
      avgPos.add(obj.pos);
      avgCount++;
    } else {
      continue;
    }
  }
  if (avgCount == 0) {
    moveCamera(player.pos, player.pos, 300);
  } else {
    avgPos.div(avgCount);
    moveCamera(avgPos, player.pos, 300);
  }


  //render floor particles
  for (int i=bgObjs.size()-1; i>=0; i--) { //delete objects
    if (bgObjs.get(i).deleteObject) {
      bgObjs.remove(i);
    }
  }
  startTime = millis();
  for (BgObj b : bgObjs) {
    b.update();
  }
  if (logTime) {
    print(" particle:"+(millis()-startTime));
    print(" particle size:"+bgObjs.size());
  }

  startTime = millis();
  for (int i=objs.size()-1; i>=0; i--) { //delete objects
    if (objs.get(i).deleteObject) {
      objs.remove(i);
    }
  }
  //player has no collupdate
  for (int i=0; i<objs.size(); i++) {
    objs.get(i).collUpdate();
  }
  player.physUpdate();
  for (int i=0; i<objs.size(); i++) {
    objs.get(i).physUpdate();
  }
  if (logTime) {
    print(" objs:"+(millis()-startTime));
  }

  startTime = millis();
  //render text particles
  for (int i=textParticles.size()-1; i>=0; i--) { //delete objects
    if (textParticles.get(i).deleteObject) {
      textParticles.remove(i);
    } else {
      textParticles.get(i).update();
    }
  }
  if (logTime) {
    print(" textParticle:"+(millis()-startTime));
  }
  popMatrix();

  startTime = millis();
  drawUI();
  if (screen==2) {
    tutorialLoop();
  }
  if (logTime) {
    print(" ui:"+(millis()-startTime+"\n"));
  }
}

void drawUI() {
  //crosshair rendering
  if (magic < 8) {
    crossCol = color(0, 1, 0.7);
  } else {
    crossCol = color(0, 0, 1);
  }
  pushMatrix();
  translate(mouseX, mouseY);
  scale(crossScale);
  noFill();
  stroke(crossCol);
  strokeWeight(2);
  line(-20, 0, 20, 0);
  line(0, -20, 0, 20);
  strokeWeight(8);
  ellipseMode(CENTER);
  arc(0, 0, 50, 50, 0, map(magic, 0, 32, 0, TAU), OPEN);
  popMatrix();
  crossScale = lerp(crossScale, 1, 0.2);

  //health and magic bars
  pushMatrix();
  translate(25, 25);
  noStroke();
  if (magic < 8) {
    fill(0, 1, 0.7);
  } else {
    fill(0, 0, 1);
  }
  rectMode(CORNER);
  rect(0, 25, map(magic, 0, 32, 0, 200), 10);
  drawBar(player.health, 0, 100, 0, 200, 10);
  popMatrix();

  //kill counter
  pushMatrix();
  translate(0.5*width, 0.1*height);
  textAlign(CENTER, CENTER);
  textSize(100);
  fill(0, 0, 1);
  if (screen == 3) {
    text("Wave: " + wave, 0, 0);
  }
  popMatrix();
  
  drawKeystrokes(width-10,75,1);
}

float[] keyLerpVals = new float[10];
void updateKeyVal(int index) {
  if(inputHeld[index]) {
    keyLerpVals[index] = lerp(keyLerpVals[index], 1, 0.3*dt);
  } else {
    keyLerpVals[index] = lerp(keyLerpVals[index], 0, 0.3*dt);
  }
}
void drawKeystrokes(float x, float y, float scale) {
  strokeWeight(1);
  stroke(0,0,1);
  for (int i=0; i<10 /*length of input arrays*/; i++) {
    updateKeyVal(i);
  }
  push();
  translate(x-25,y+25); //i miscalculated when i first calculated the values, so i compensated here
  scale(scale);
  //drawn from upper right corner
  //0:space, 1:w, 2:a, 3:s, 4:d, 5:m1, 6:m2, 7:e, 8:q, 9:,10:,
  stroke(0,0,1);
  noFill();
  drawKey("E",0,0, keyLerpVals[7]);
  drawKey("W",-55,0,keyLerpVals[1]);
  drawKey("Q",-110,0,keyLerpVals[8]);
  drawKey("D",0,55,keyLerpVals[4]);
  drawKey("S",-55,55,keyLerpVals[3]);
  drawKey("A",-110,55,keyLerpVals[2]);
  drawKey("",-55,95,160,20,keyLerpVals[0]); //space key
  drawKey("LMB",-96,130,77,40,keyLerpVals[5]);
  drawKey("RMB",-13,130,77,40,keyLerpVals[6]);
  pop();
}
void drawKey(String text, float x, float y, float t) { //method for drawing the square keys
  drawKey(text,x,y,50,50,t);
}
void drawKey(String text, float x, float y, float xSize, float ySize, float t) { //t is a value from 0 to 1 that transitions between unpressed and pressed (0: no press, 1: press)
  push();
  translate(x,y);
  rectMode(CENTER);
  fill(0,0,1,lerp(0,1,t));
  rect(0,0,xSize,ySize);
  
  textAlign(CENTER,CENTER);
  textSize(30);
  fill(0,0,lerp(1,0,t));
  text(text,0,0);
  pop();
}

boolean tutorialEnd = false;
int tutorialStep=0;
void tutorialLoop() {
  pushMatrix();
  translate(0.5*width, 0.1*height+50);
  textAlign(CENTER, CENTER);
  textSize(50);
  fill(0, 0, 1);
  if (tutorialStep==0) {
    text("WASD to move", 0, 0);
    if (inputReleaseTime[1]>0&&inputReleaseTime[2]>0&&inputReleaseTime[3]>0&&inputReleaseTime[4]>0) {
      for (int j=0; j<=9; j++) {
        inputReleaseTime[j]=0;
      }
      tutorialStep=1;
    }
  } else if (tutorialStep==1) {
    text("Space to dash", 0, -40);
    text("Left click to slash", 0, 10);
    if (inputReleaseTime[0]>0&&inputReleaseTime[5]>0) {
      tutorialStep=2;
    }
  } else if (tutorialStep==2) {
    text("E to smash", 0, -40);
    text("Q to fireball", 0, 10);
    if (inputReleaseTime[7]>0&&inputReleaseTime[8]>0) {
      tutorialStep=3;
    }
  } else if (tutorialStep==3) {
    text("attack right after a dash for a combo", 0, 0);
    for (GameObject obj : objs) {
      if (obj.type[4] == true) {
        tutorialStep=4;
      }
    }
  } else if (tutorialStep==4) {
    text("Beat the enemy", 0, 0);
    if (tutorialEnd==false) {
      float angle = random(0, TAU);
      objs.add(new BasicEnemy(player.pos.x + 500*cos(angle), player.pos.y + 500*sin(angle)));
      tutorialEnd=true;
    }
    if (tutorialEnd==true&&objs.size()==0) {
      screen=6;
      spawnButtons();
    }
  }
  popMatrix();

  //slash dash indicator
  if (tutorialStep==3) {
    push();
    translate(0.5*width, height-50);
    float x;
    if (millis > player.lastDash && millis < player.lastDash + player.dashDuration + player.dashSlashBuffer) {
      x = lerp(-130, 30, map(millis, player.lastDash, player.lastDash + player.dashDuration, 0, 1));
    } else x=-130;
    text("Slash!", 0, 600);
    fill(0, 0, 0.5);
    rect(-140, -15, 60, 15, 10, 0, 0, 10);
    fill(180, 0.7, 1);
    rect(60, -15, 180, 15, 0, 10, 10, 0);
    fill(0, 0, 1);
    rect(x, -25, x+10, 25, 10);
    pop();
  }
}

PVector camPos = new PVector(200, 200);
float camScale = 1;
void moveCamera(PVector a, PVector b, float margin) {
  //ensures that copies are used instead of the original reference
  PVector v1 = a.copy();
  PVector v2 = b.copy();

  float scaleX;
  if (v1.x >= v2.x) {
    scaleX = width / (v1.x + margin - v2.x + margin);
  } else {
    scaleX = width / (v2.x + margin - v1.x + margin);
  }
  float scaleY;
  if (v1.y >= v2.y) {
    scaleY = height / (v1.y + margin - v2.y + margin);
  } else {
    scaleY = height / (v2.y + margin - v1.y + margin);
  }

  if (scaleX <= scaleY) {
    camScale = lerp(camScale, scaleX, constrain(0.05*dt, 0, 1));
  } else {
    camScale = lerp(camScale, scaleY, constrain(0.05*dt, 0, 1));
  }
  camPos.lerp(PVector.lerp(a, b, 0.5), 0.05*dt);
}

/*Input section: Uses a hashmap to track whether keys are pressed
 *Each time a key is pressed or released, it will update the arrays
 *Is used to track if multiple inputs are held at the same time*/
//0:space, 1:w, 2:a, 3:s, 4:d, 5:m1, 6:m2, 7:e, 8:q, 9:,10:,
boolean[] inputHeld = new boolean[10]; //Boolean state of whether the key is held
float[] inputPressTime = new float[10]; //the last time the button was pressed
float[] inputReleaseTime = new float[10]; //the last time the button was released

int getKeyIndex(char key) { //hardcoded function that returns the corresponding index for each potential key code
  int i = -1; //returns -1 if the key is not supported
  switch (key) {
  case ' ':
    i=0;
    break;
  case 'w':
    i=1;
    break;
  case 'W':
    i=1;
    break;
  case 'a':
    i=2;
    break;
  case 'A':
    i=2;
    break;
  case 's':
    i=3;
    break;
  case 'S':
    i=3;
    break;
  case 'd':
    i=4;
    break;
  case 'D':
    i=4;
    break;
  case 'e':
    i=7;
    break;
  case 'E':
    i=7;
    break;
  case 'q':
    i=8;
    break;
  case 'Q':
    i=8;
    break;
  }
  return i;
}
void keyPressed() {
  int i=getKeyIndex(key);
  if (i!=-1) {
    inputHeld[i] = true;
    inputPressTime[i] = millis();
  }
  if (screen ==0) {
    screen = 1;
    spawnButtons();
  }
}
void keyReleased() {
  int i=getKeyIndex(key);
  if (i!=-1) {
    inputHeld[i] = false;
    inputReleaseTime[i] = millis();
  }
}
void mousePressed() {
  if (mouseButton == LEFT) {
    inputHeld[5] = true;
    inputPressTime[5] = millis();
  } else {
    inputHeld[6] = true;
    inputPressTime[6] = millis();
  }
  if (screen ==0) {
    screen = 1;
    spawnButtons();
  }
  for (int i=0; i<buttons.size(); i++) {
    buttons.get(i).testClick();
  }
}
void mouseReleased() {
  if (mouseButton == LEFT) {
    inputHeld[5] = false;
    inputReleaseTime[5] = millis();
  } else {
    inputHeld[6] = false;
    inputReleaseTime[5] = millis();
  }
}

void mouseWheel(MouseEvent event) {
  for (scrollText scroll : textBoxes)
  {
    if (scroll.isInside(mouseX, mouseY))
    {
      scroll.scroll(event.getCount()*10);
    }
  }
}
//fps code
float dt;
/*deltatime is a scale factor that will normalize the speed of motion
 * At low fps, instead of the object moving slower, it will be scaled upward to match the speed it should move at 60fps
 */
float lastTime = 0;
String text = "";
void calcFps() {
  //calculates delta time and prints the text to the screen
  dt = constrain(60*((millis*0.001 - lastTime)), 0, 3); //the first number is the target fps (60)
  lastTime = millis*0.001;

  //show fps
  if (frameCount%(int)(frameRate*0.5)==0) { //run once every half second
    text = round(60/dt) + "fps";
  }
  fill(360);
  textAlign(RIGHT);
  textSize(20);
  text(text, width-5, 15);
  text("Object count: " + objs.size(), width-5, 30);
  text("Particle count: " + (bgObjs.size() + textParticles.size()), width-5, 45);
}

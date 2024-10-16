/*Classes and data for screens and ui*/


int screen = 0;
/* 0: wait for player input and asks to resize window
 * 1: title screen
 * 2: tutorial screen
 * 3: game
 * 4: game over
 * 5: patch notes
 * 6: tutorial end screen
 * 7: world select */
//hard to account for the initial window delay of processing. There will be an instruction telling the person to press any key, and it will start
ArrayList<Button> buttons = new ArrayList<Button>();
ArrayList<scrollText> textBoxes = new ArrayList<scrollText>();
PFont titleFont;
PFont buttonFont;

void killButtons() {
  for (Button b : buttons) {
    b.decay=true;
    b.startTime = millis;
  }
  textBoxes.clear();
}
void loopButtons() {
  for (int i=buttons.size()-1; i>=0; i--) {
    if (buttons.get(i).deleteButton) {
      buttons.remove(i);
    } else {
      buttons.get(i).update();
    }
  }
  for (scrollText scroll : textBoxes) {
    scroll.drawText();
  }
}
void spawnButtons() {
  if (screen ==1) { //title screen
    buttons.add(new PlayButton());
    buttons.add(new Title("QUAD KILLER"));
    buttons.add(new Tutorial());
    buttons.add(new PatchNotes());
    buttons.add(new WorldMenuButton());
  } else if (screen == 4) {
    buttons.add(new GameOver());
    buttons.add(new Text("YOU GOT TO WAVE " + wave, 0.5*height));
    buttons.add(new GoBack());
  } else if (screen == 5) {
    textBoxes.add(new scrollText(patchText, new PVector(width/2-150, height/4), new PVector(300, 400), new PVector(10, 10), buttonFont));
    buttons.add(new GoBack());
  } else if (screen == 6) {
    buttons.add(new Text("Congratulations! You completed the tutorial.", 0.5*height));
    buttons.add(new GoBack());
  } else if (screen == 7) {
    buttons.add(new WorldSelect("World 1", "RedWorld", 200));
    buttons.add(new WorldSelect("Testing", "TestWorld", 300));
    buttons.add(new GoBack());
  }
}
void screenLoop() {
  background(0);
  for (Shape s : shapes) {
    s.update();
  }
  camPos.add(0, -1);
  //render mouse particles
  for (BgObj p : bgObjs) {
    ((Particle)p).pos.add(0, 2);
    p.update();
  }
  ellipseMode(CENTER);
  float size = 50;
  bgObjs.add(new Particle(createShape(ELLIPSE, 0, 0, size, size), new PVector(mouseX, mouseY), 0, 500, color(180, 1, 0.7)) );

  loopButtons();
}

abstract class Button { //this class must be inherited (abstract)
  PVector pos = new PVector();
  PVector size = new PVector();
  float scale=1;
  String text;
  PFont font;
  float textSize=25;
  float alpha = 0.8;
  color buttonCol;
  color textCol;
  boolean decay = false;
  boolean deleteButton = false;

  //for smooth transitions, appear should be greater than decay
  float startTime; //initial time
  float appearTime = 1000; //time it takes for button appear
  float decayTime = 500; //time it takes for button to fade out

  Button() {//empty constructor for inheritance purposes
  }
  void update() {
    pushMatrix();
    translate(pos.x, pos.y);
    scale(scale);

    //drawn around 0,0
    if (testColl(new BoxColl(mouseX, mouseY, 25, 25, CENTER), new BoxColl(pos.x, pos.y, size.x*scale, size.y*scale, CENTER))) {
      //if mouse is hovering
      scale = lerp(scale, 1.5, 0.2);
      alpha = lerp(alpha, 1, 0.2);
    } else {
      scale = lerp(scale, 1, 0.2);
      alpha = lerp(alpha, 0.7, 0.2);
    }
    if (millis < startTime + appearTime) {
      alpha = map(millis, startTime, startTime+appearTime, 0, 0.7);
    }
    if (decay) {
      if (millis > startTime + decayTime) {
        deleteButton = true;
      }
      alpha = map(millis, startTime, startTime+decayTime, 0.7, 0);
    }
    noStroke();
    rectMode(CENTER);
    textAlign(CENTER, CENTER);
    textSize(textSize);
    textFont(font);
    fill(changeAlpha(buttonCol, alpha ));
    rect(0, 0, size.x, size.y, 20);
    fill(changeAlpha(textCol, alpha ));
    text(text, 0, 0);
    popMatrix();
  }
  void testClick() {
    if (!decay && map(millis, startTime, startTime + appearTime, 0, 1) >0.5) {
      if (testColl(new BoxColl(mouseX, mouseY, 25, 25, CENTER), new BoxColl(pos.x, pos.y, size.x*scale, size.y*scale, CENTER))) {
        scale = 1.7;
        onClick();
      }
    }
  }
  abstract void onClick(); //this method is overrided by child classes
}

class PlayButton extends Button {
  PlayButton() {
    startTime = millis;
    text = "PLAY";
    pos.set(0.5*width, 0.5*height);
    size.set(200, 50);
    textCol = color(0, 0, 0);
    textSize = 25;
    buttonCol = color(360);
    font = buttonFont;
  }
  @Override
    void onClick() {
    killButtons();
    screen = 3;
     worldDir.get(currentWorld).setWorld();
    worldDir.get(currentWorld).gameStart(); //calls gamestart for the selected world
  }
}

class WorldMenuButton extends Button { //opens the world select menu
  WorldMenuButton() {
    startTime = millis;
    text = "World Select";
    pos.set(0.5*width, 0.5*height+300);
    size.set(200, 50);
    textCol = color(0, 0, 0);
    textSize = 25;
    buttonCol = color(360);
    font = buttonFont;
  }
  @Override
    void onClick() {
    killButtons();
    screen = 7;
    spawnButtons();
  }
}

class WorldSelect extends Button {
  String worldType; //the world type that this button represents
  WorldSelect(String displayText, String worldType, float h) {
    startTime = millis;
    this.text = displayText;
    pos.set(0.5*width, h);
    size.set(200, 50);
    textCol = color(0, 0, 0);
    textSize = 25;
    buttonCol = color(360);
    font = buttonFont;
    this.worldType=worldType;
    checkType(); //update the button colors
  }
  void checkType() { //visually updates the buttons depending on the current world type
    if (worldType == currentWorld) {
      buttonCol = color(180,1,1);
    } else {
      buttonCol = color(0,0,1);
    }
  }
  @Override
    void onClick() {
    currentWorld = worldType;
    for (Button b : buttons) {
      if (b instanceof WorldSelect) {
        ((WorldSelect)b).checkType();
      }
    }
  }
}

class Tutorial extends Button {
  Tutorial() {
    startTime = millis;
    text = "TUTORIAL";
    pos.set(0.5*width, 0.5*height + 100);
    size.set(200, 50);
    textCol = color(0, 0, 0);
    textSize = 25;
    buttonCol = color(360);
    font = buttonFont;
  }
  @Override
    void onClick() {
    killButtons();
    for (int i=0; i<=9; i++) {
      inputReleaseTime[i]=0;
    }
    tutorialStep=0;
    tutorialEnd=false;
    screen = 2;
    tutorialStart();
    spawnButtons();
  }
}

class Title extends Button {
  Title(String text) {
    startTime = millis;
    this.text = text;
    pos.set(0.5*width, 0.15*height);
    size.set(1000, 100);
    textCol = color(360);
    textSize = 25;
    buttonCol = color(0);
    font = titleFont;
  }
  @Override
    void onClick() {
  }
}

class GoBack extends Button {
  GoBack() {
    startTime = millis;
    text = "GO BACK";
    pos.set(0.5*width, 0.9*height);
    size.set(200, 50);
    textCol = color(0, 0, 0);
    textSize = 25;
    buttonCol = color(360);
    font = buttonFont;
  }
  @Override
    void onClick() {
    killButtons();
    screen = 1;
    spawnButtons();
  }
}

class GameOver extends Button {
  GameOver() {
    startTime = millis;
    text = "GAME OVER";
    pos.set(0.5*width, 0.25*height);
    size.set(1000, 100);
    textCol = color(0, 1, 1);
    textSize = 25;
    buttonCol = color(0);
    font = titleFont;
  }
  @Override
    void onClick() {
  }
}

class PatchNotes extends Button {
  PatchNotes() {
    startTime = millis;
    text = "Patch Notes";
    pos.set(0.5*width, 0.5*height + 200);
    size.set(200, 50);
    textCol = color(0, 0, 0);
    textSize = 25;
    buttonCol = color(360);
    font = buttonFont;
  }
  @Override
    void onClick() {
    killButtons();
    screen = 5;
    spawnButtons();
  }
}

class Text extends Button {
  Text(String text, float h) { //h is height where the text is
    startTime = millis;
    this.text = text;
    pos.set(0.5*width, h);
    size.set(500, 50);
    textCol = color(0, 0, 0);
    textSize = 25;
    buttonCol = color(360);
    font = buttonFont;
  }
  @Override
    void onClick() {
  }
}

class scrollText {
  //I added a bunch of modifiers just in case
  String text; //the text to be added
  PGraphics buffer = new PGraphics(); //used this to get a scrollable text box
  PVector pos = new PVector(); //pos -_-
  PVector size = new PVector(); // size -_-
  PVector margin = new PVector(); //text offset from top left corner (crazy ik)
  float scroll = 0; // preserves the location of scroll (if you scroll down 20px it'll keep it at 20px)
  color bgCol = color(360, 0.8); //bg color -_-
  color textCol = color(0, 0, 0); // text color -_-
  PFont font = new PFont(); // set font -_-

  scrollText(String text, PVector pos, PVector size, PVector margin, PFont font) {
    this.text=text;
    this.pos.x = pos.x;
    this.pos.y = pos.y;
    this.size.x = size.x;
    this.size.y = size.y;
    this.margin=margin;
    this.font = font;
    buffer = createGraphics(floor(size.x), floor(size.y), P2D);
  }

  void scroll (float scroll) {
    this.scroll = max(this.scroll+scroll, 0);
  } // Scroll can't go below 0.

  void drawText()
  {
    buffer.beginDraw();
    {
      buffer.clear();
      buffer.colorMode(HSB, 360, 1, 1, 1);
      buffer.fill(bgCol);
      buffer.rect(0, 0, size.x, size.y, 20); // Border.
      buffer.fill(textCol);
      buffer.textAlign (LEFT, TOP);
      buffer.textSize(25);
      buffer.text (text, margin.x, margin.y-scroll, buffer.width-margin.x, buffer.height+scroll);
    }
    buffer.endDraw();
    image(buffer, pos.x, pos.y);
  }
  boolean isInside(float checkPosX, float checkPosY)
  {
    boolean inWidth = checkPosX > pos.x && checkPosX < pos.x+size.x;
    boolean inHeight = checkPosY > pos.y && checkPosY < pos.y+size.y;
    return inWidth && inHeight;
  }
}

String patchText;

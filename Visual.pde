/*classes for particles and other visual content*/

color changeAlpha(color c, float alpha) { //changes the alpha value of a color
  return color(hue(c), saturation(c), brightness(c), alpha);
}

void drawBar(float value, float start, float end) {
  drawBar(value, start, end, start, end, 10);
}
void drawBar(float value, float start, float end, float x1, float x2, float h) {
  fill(360, 1, 1);
  rectMode(CORNER);
  noStroke();
  rect(x1, -0.5*h, (x2-x1), h);
  fill(120, 1, 1);
  rectMode(CORNERS);
  rect(x1, -0.5*h, map(value, start, end, x1, x2), 0.5*h);
}

class TextParticle {
  boolean deleteObject = false;
  String text;
  color c; //color of text
  PVector pos;
  private float startTime; //time when particle was created
  private float duration; //time in millis particle lasts before decaying
  private float decay = 500;//time in millis for particle to decay

  TextParticle(String text, float duration, PVector pos, color c) {
    startTime = millis;
    this.text = text;
    this.duration = duration;
    this.pos = pos;
    this.c = c;
  }

  void update() {
    if (millis < startTime + duration) {
      textAlign(CENTER, CENTER);
      fill(c);
      textSize(30);
      text(text, pos.x, pos.y);
    } else if (millis > startTime + duration + decay) {
      deleteObject = true;
    } else {
      textAlign(CENTER, CENTER);
      textSize(30);
      fill( changeAlpha(c, map(millis, startTime + duration, startTime + duration + decay, 1, 0)) ); //fade to transparent
      text(text, pos.x, pos.y - map(millis, startTime + duration, startTime + duration + decay, 0, 50) ); //10 is the max height
    }
  }
}

abstract class BgObj {
  boolean deleteObject = false;
  abstract void update();
}

class Particle extends BgObj{
  PVector pos;
  PShape p;
  color col; //fill color of the particle
  float endScale = 1;
  float startScale = 1;
  private float startTime;
  private float duration; //length of time where particle is full saturation/scale before decaying
  private float decay = 500; //total length of the decay (from full to nothing)
  
  Particle(PShape p, PVector pos, float maxScale, float minScale, float duration, float decay, color c) { //override with scale stuff
    this(p,pos,duration,decay,c);
    this.startScale = maxScale;
    this.endScale = minScale;
  }
  
  Particle(PShape p, PVector pos, float duration, float decay, color c) {
    this.p = p;
    this.pos = pos;
    this.duration = duration;
    this.decay = decay;
    this.col = c;
    startTime = millis;
    p.setFill(c);
  }
  @Override
  void update() {
    if (millis < startTime + duration) {//regular particle
      push();
      translate(pos.x,pos.y);
      scale(startScale);
      shape(p, 0,0);
      pop();
    } else if (millis > startTime + duration + decay) {
      deleteObject = true;
    } else { //decay code
      p.setFill( changeAlpha(col, map(millis, startTime+duration, startTime+duration+decay, 1, 0)) );
      float scale = map(millis, startTime+duration, startTime+duration+decay, startScale, endScale);
      push();
      translate(pos.x,pos.y);
      scale(scale);
      shape(p, 0,0);
      pop();
    }
  }
}

class Shape {
  PShape p;
  PVector pos = new PVector(); //assume pos X is less than spacing
  PVector size = new PVector(100, 100);
  float spacing = 1000;
  float rot;
  float factor = 1; //individual scale factor that controls the depth illusion

  Shape(PShape p, PVector size, float factor, float rot) {
    this.p = p;
    this.size = size;
    this.factor = factor;
    this.rot = rot;
    spacing *= factor;
    pos.set(random(0, spacing), random(0, spacing));
  }
  void update() {
    pushMatrix();
    scale(camScale*factor);
    //array is drawn centered around 0,0
    //add spacing margin on edges to make it smoothly move off screen
    float x = pos.x - camPos.x % spacing; //set x pos
    while ( x+0.5*size.x >= 0) { //make sure there is a shape comletely off screen so that it can smoothly pan in
      x-=spacing;
    }
    while (x-0.5*size.x < width / (camScale*factor)) {
      float y = pos.y - camPos.y % spacing; //set y pos
      while (y+0.5*size.y >= 0) { //set y pos top edge
        y-=spacing;
      }
      while (y-0.5*size.y < height / (camScale*factor)) {
        pushMatrix();
        translate(x, y);
        rotate(rot);
        shape(p, 0, 0);
        popMatrix();
        y+=spacing;
      }
      x+=spacing;
    }
    popMatrix();
  }
}

void drawGrid(float spacing) {
  noFill();
  stroke(0,0,0.2);
  strokeWeight(1);
  pushMatrix();
  scale(camScale);
  //array is drawn centered around 0,0
  //add spacing margin on edges to make it smoothly move off screen
  float x = -camPos.x % spacing; //set x pos
  while ( x >= 0) { //make sure there is a shape comletely off screen so that it can smoothly pan in
    x-=spacing;
  }
  while (x < width / camScale) {
    line(x,0,x,height/camScale);
    x+=spacing;
  }
  
  float y = -camPos.y % spacing; //set y pos
  while (y >= 0) { //set y pos top edge
      y-=spacing;
    }
  while (y < height / camScale) {
    line(0,y,width/camScale,y);
    y+=spacing;
  }
  
  popMatrix();
}

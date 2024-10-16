int resolution = 10; //curve resolution of the image
int frameLength = 10; //The amount of preloaded frames that the slash is split into
PShape[] slashFrame = new PShape[frameLength]; //animation is split into 10 frames (this array is filled in setup)

//default geometry has radius of 100
PShape calcSlash(float tBound) {
  float radius = 100;
  PShape p;
  p = createShape();
  p.beginShape();
  p.fill(255);
  p.noStroke();
  p.strokeWeight(1);

  p.scale(1);

  p.curveVertex(radius, 0);//ends of curves need double coordinates for some reason
  p.curveVertex(radius, 0);
  for (int i=1; i<resolution; i++) {
    float t = map(i, 0, resolution, 0, tBound);
    p.curveVertex(radius*cos(3.14*t), radius*sin(3.14*t));
  }
  p.curveVertex(radius*cos(3.14*tBound), radius*sin(3.14*tBound));
  p.curveVertex(radius*cos(3.14*tBound), radius*sin(3.14*tBound));
  p.vertex((1-tBound)*radius*cos(3.14*tBound), (1-tBound)*radius*sin(3.14*tBound));
  p.curveVertex((1-tBound)*radius*cos(3.14*tBound), (1-tBound)*radius*sin(3.14*tBound));
  p.curveVertex((1-tBound)*radius*cos(3.14*tBound), (1-tBound)*radius*sin(3.14*tBound));
  for (int i=1; i<resolution; i++) {
    float t = map(i, 0, resolution, tBound, 0); //t but reverse direction
    p.curveVertex((1-t)*radius*cos(3.14*t), (1-t)*radius*sin(3.14*t));
  }
  p.curveVertex(radius, 0);
  p.curveVertex(radius, 0);

  p.endShape();
  return p;
}

class PlayerSlash extends GameObject {
  PVector pos;
  float radius; //radius of slash (reach)
  float aimAngle; //angle towards mouse
  color c;
  private float startTime; //in millis initial time when blade was spawned
  private float duration = 100; //in millis how long hitbox lasts for
  private float decay = 200; //in millis length of decay animation (no hitbox)
  private boolean flipSlash = false; //whether to flip the blade or not

  PlayerSlash (PVector pos, float aimAngle, boolean flipSlash) { //default settings
    this(pos, aimAngle, 200, 100, 200, color(0, 0, 1), flipSlash);
  }
  PlayerSlash(PVector pos, float aimAngle, float radius, float duration, float decay, color c, boolean flipSlash) {
    this.pos = pos;
    this.radius = radius;
    this.aimAngle = aimAngle;
    this.duration = duration;
    this.decay = decay;
    this.c = c;
    this.flipSlash = flipSlash;
    init();
  }
  @Override
    void init() {
    type[1] = true; //pAttack
    type[2] = true; //pSlash
    coll = new CircleColl(pos.x, pos.y, radius);
    startTime = millis;
  }
  @Override
    void physUpdate() {
    if (startTime != millis) { //waits until the frame after it was spawned before removing coll
      coll = null; //because collUpdate happens first, this line removes the coll right after the first frame of the blade animation
    }
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(aimAngle-HALF_PI); //geometry of slash was drawn 90 degrees clockwise
    scale((float)radius/100); //100 is the default radius of the blade geometry
    if (flipSlash) { //flips the direction of the blade
      scale(-1, 1);
    }

    if ( millis < startTime + duration) {
      //maps the millis to the closest frame in the array
      int index = round( map(millis, startTime, startTime + duration, 0, frameLength-1) );
      slashFrame[index].setFill(c);
      shape(slashFrame[index]);
    } else if (millis < startTime + duration + decay) {
      pos = pos.copy(); //The blade no longer follows the player
      slashFrame[frameLength-1].setFill(changeAlpha(c, map(millis, startTime+duration, startTime+duration+decay, 1, 0)));
      shape(slashFrame[frameLength-1]);
    } else if (millis > startTime + duration + decay) {
      deleteObject = true;
    }
    popMatrix();
  }
}

class PlayerFireball extends GameObject {
  float angle; //angle of the projectiles velocity
  float radius;
  color c;
  private float startTime;
  private float decay = 1000;
  PlayerFireball(PVector pos, float angle, float radius, color c) {
    this.pos = pos;
    this.angle = angle;
    this.radius = radius;
    this.c = c;
    init();
  }
  @Override
    void init() {
    startTime = millis;
    vel = PVector.fromAngle(angle).setMag(30);
    coll = new CircleColl(pos.x, pos.y, radius);
    type[1] = true; //pAttack
    type[3]=true; //pFireball
  }
  @Override
    void physUpdate() {
    pos.add(vel.copy().mult(dt));
    coll.setPos(pos.copy());
    if (millis >= startTime + decay) {
      deleteObject = true;
    }
    ellipseMode(CENTER);
    noStroke();
    fill(c);
    float size = random(25, 50);
    bgObjs.add(new Particle(createShape(ELLIPSE, 0, 0, size, size), pos.copy().add(PVector.random2D().setMag(25)), 100, 500, c) );

    noStroke();
    fill(changeAlpha(c, 0.5));
    circle(pos.x, pos.y, 2*radius);
    fill(c);
    circle(pos.x, pos.y, radius);
  }
}

class PlayerSmash extends GameObject {
  float radius;
  color c;
  private float startTime;
  private float appear = 100; //time it takes for the explosion to animate
  private float decay = 500;
  PlayerSmash (PVector pos, float radius, float decay, color c) {
    this.pos = pos;
    this.radius = radius;
    this.decay = decay;
    this.c = c;
    init();
  }
  @Override
    void init() {
    startTime = millis;
    coll = new CircleColl(pos.x, pos.y, radius);
    type[1] = true; //pAttack
    type[5] = true; //playerSmash
  }
  @Override
    void collUpdate() {
  }
  @Override
    void physUpdate() {
    if (millis != startTime) {
      coll = null; //removes the collision after the first frame
    }
    float r = radius;
    float alpha = 1;
    if (millis < startTime + appear) {
      r = map(millis, startTime, startTime + appear, 0, radius);
      screenShake.add(PVector.random2D().setMag(50));
    } else if (startTime+appear < millis && millis < startTime+appear+decay) {
      alpha = map(millis, startTime+appear, startTime + appear + decay, 1, 0);
    } else if (millis >= startTime+appear+decay) {
        alpha=0;
        deleteObject = true;
    }
    pushMatrix();
    translate(pos.x, pos.y);
    ellipseMode(CENTER);
    fill(changeAlpha(c, 0.25*alpha));
    circle(0, 0, 2*r);
    fill(changeAlpha(c, 0.5*alpha));
    circle(0, 0, 1.5*r);
    fill(changeAlpha(c, 0.25*alpha));
    circle(0, 0, 1*r);
    fill(changeAlpha(c, alpha));
    circle(0, 0, 0.5*r);
    popMatrix();
  }
}

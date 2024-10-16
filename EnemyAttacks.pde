class NeutralExplosion extends GameObject {
  private float radius; //radius of the explosion
  private float startTime; //time when object was spawned
  private float delay; //time it takes for impact to land
  private float animTime = 100; //time it takes for explosion animation to play
  private float decay = 500; //time it takes for animation to fade
  private boolean isExploded = false; //This varibable is set to true when it explodes

  NeutralExplosion(PVector pos, float radius, float delay) {
    this.pos = pos;
    this.radius = radius;
    this.delay = delay;
    init();
  }
  @Override
    void init() {
    startTime = millis;
    type[7] = true; //neutral explosion type
  }
  @Override
    void collUpdate() {
    if (startTime + delay < millis && millis < startTime + delay + animTime) { //during the explosion animation
      if (coll == null && !isExploded) { //set the explosion collider if it doesn't exist
        coll = new CircleColl(pos.x,pos.y,radius);
        isExploded = true;
        screenShake.add(player.pos.copy().sub(pos).setMag(30));
      } else if (isExploded && coll != null) {
        coll = null;
      }
      //The collision with player is active only during the animTime window
      if (testColl(coll,player.coll)) {
        player.onHit( player.pos.copy().sub(pos).setMag(50), -20);
      }
    } else {
      coll = null;
    }
  }
  @Override
    void physUpdate() {
      float d = 1;
      float a = 1;
    if (millis < startTime + delay) {
      pushMatrix(); //rotated cross
      translate(pos.x, pos.y);
      rotate(radians(45));
      fill(0, 1, 1, map(cos(TAU*millis*0.001), -1, 1, 0.1, 0.3)); //blinking red circle
      stroke(0, 0, 1);
      strokeWeight(1);
      circle(0, 0, 2*radius);
      fill(0, 1, 1, map(cos(TAU*millis*0.001), -1, 1, 0.3, 0.5)); //blinking center circle
      noStroke();
      circle(0, 0, 150);
      fill(0, 1, 1);
      rectMode(CENTER);
      rect(0, 0, 20, 100);
      rect(0, 0, 100, 20);
      popMatrix();
    } else if (millis < startTime + delay + animTime) {
      d = 2*map(millis, startTime+delay, startTime+delay+animTime, 0, radius);
    } else if (millis < startTime + delay + animTime + decay) {
      a = map(millis, startTime+delay+animTime, startTime+delay+animTime+decay, 1, 0);
      d = 2*radius;
    } else {
      deleteObject = true;
    }
    fill(0, 1, 1, 0.25*a);
    circle(pos.x, pos.y, d);
    fill(0, 1, 1, 0.5*a);
    circle(pos.x, pos.y, 0.75*d);
    fill(0, 1, 1, 0.75*a);
    circle(pos.x, pos.y, 0.5*d);
    fill(0, 1, 1, a);
    circle(pos.x, pos.y, 0.25*d);
  }
}

class EnemyBullet extends Enemy {
  private float startTime;
  private float duration = 5000; //total time of the bullet
  public EnemyBullet(PVector pos, PVector vel) {
    this.pos = pos;
    this.vel = vel;
    init();
  }
  @Override
    void init() {
    coll = new CircleColl(pos.x, pos.y, 15);
    startTime = millis;
    enemyCount--; //Makes sure that the bullet does not count as an enemy (enemyCount is used in wave summoning)
  }
  @Override
    void slashHit(GameObject obj) {
    vel.add(mousePos.copy().sub(player.pos).setMag(30)); //instantaneous
  }
  @Override
    void fireballHit(GameObject obj) {
    deleteObject = true;
    coll = null;
  }
  @Override
    void smashHit(GameObject obj) {
    vel.set(PVector.sub(pos, obj.pos).setMag(50));
  }
  @Override
    void explodeHit(GameObject obj) {
    vel.set(PVector.sub(pos, obj.pos).setMag(50));
  }
  @Override
    void contactHit(GameObject obj) {
    player.onHit(deltaPos.copy().setMag(20), -10);
  }
  @Override
    void physUpdate() {
    if (millis >= startTime + duration) {
      deleteObject = true;
    }
    pos.add(vel.copy().mult(dt));
    if (coll !=null) {
      coll.setPos(pos);
    }
    drawSprite();
  }
  void drawSprite() {
    fill(0, 1, 1);
    noStroke();
    circle(pos.x, pos.y, 30);
  }
}

class InvincBullet extends EnemyBullet {
  InvincBullet(PVector pos, PVector vel) {
    super(pos,vel);
  }
  @Override
  void slashHit(GameObject obj) {
    if (obj.type[4] /*dash slash*/) {
      vel.add(mousePos.copy().sub(player.pos).setMag(30)); //instantaneous
    } else {
      screenShake.add(PVector.sub(mousePos,player.pos).setMag(20));
    }
  }
  @Override
  void drawSprite() {
    fill(180,1,0.5);
    noStroke();
    circle(pos.x, pos.y, 30);
  }
}

PGraphics RocketFuse;
PGraphics RocketFly;
void initRocketSprite () {
  PGraphics p = createGraphics(400, 400,P2D);
  p.beginDraw();
  p.translate(200*scale, 200*scale);
  p.scale(scale);
  p.colorMode(HSB, 360, 1, 1, 1);
  p.strokeWeight(1);
  p.stroke(0, 0, 1);
  p.noFill();
  p.circle(0, 0, 400);
  p.noStroke();
  p.fill(0, 1, 1, 0.2);
  p.circle(0, 0, 400);
  p.endDraw();
  RocketFuse=p;
  
  PGraphics f = createGraphics(80, 80,P2D);
  f.beginDraw();
  f.translate(40*scale, 40*scale);
  f.scale(scale);
  f.colorMode(HSB, 360, 1, 1, 1);
  f.fill(0, 0, 0.7);
  f.noStroke();
  f.rectMode(CENTER);
  f.rect(0, 0, 40, 20);
  f.fill(0, 1, 1);
  f.quad(10, 15, 15, 0, 10, -15, 35, 0);
  f.triangle(-20, 10, -25, 20, 0, 10);
  f.triangle(-20, -10, -25, -20, 0, -10);
  f.endDraw();
  RocketFly=f;
}
class Rocket extends Enemy {
  //Rocket explosion radius is 50 less than sword swing (150 radius)
  //Rocket has modes "fly" (regular rocket fly) "fuse" (will explode soon), and "explode" (is an explosion)
  private float startTime; //during mode fuse, this is used to time the fuse of the explosion. During explode mode, startTime is what time the explosion starts (when fuse ends)
  private float fuseTime = 500; //short time before rocket explodes (when slashed)
  private float animTime = 100; //time for expanding animation of the explosion
  private float decayTime = 500; //time for explosion to fade away
  Rocket(PVector pos, PVector vel) {
    this.pos = pos;
    this.vel = vel;
    init();
  }
  @Override
    void init() {
    coll = new CircleColl(pos.x, pos.y, 25);
    mode = "fly";
    type[0] = false;
    enemyCount--; //In the parent Enemy class, it adds enemyCount by 1, so this line removes that
    type[6] = true; //type rocket
    calcSeparate[6] = true; //repel rockets
  }
  @Override
    void contactHit(GameObject obj) {
    startExplode();
  }
  @Override
    void slashHit(GameObject obj) {
    startTime = millis; //with fuse
    mode = "fuse";
    if (obj.type[4]) { //dash slash code
      vel.add(mousePos.copy().sub(player.pos).setMag(75)); //instantaneous
    } else {//regular slash code
      vel.add(mousePos.copy().sub(player.pos).setMag(50)); //instantaneous
    }
  }
  @Override
    void fireballHit(GameObject obj) {
    if (mode == "fly") { //if rocket type true
      startExplode();
    }
  }
  @Override
    void smashHit(GameObject obj) {
    if (mode == "fly") { //if rocket type true
      startExplode();
    }
  }
  @Override
    void explodeHit(GameObject obj) {
    startTime = millis; //with fuse
    mode = "fuse";
    vel.add(PVector.sub(pos, obj.pos).setMag(30));
  }
  void startExplode() {
    objs.add(new NeutralExplosion(pos.copy(), 200, 0) ); //radius 200, no initial delay
    deleteObject = true;
  }
  @Override
    void physUpdate() {
    if (vel.magSq() < sq(10)) {
      vel.add( deltaPos.copy().setMag(3) .add(separate.copy().setMag(2)) .add(vel.copy().setMag(10)) .setMag(2*dt) );
    }
    vel.lerp(0, 0, 0, 0.2*dt);
    pos.add(vel.copy().mult(dt));
    coll.setPos(pos);

    //set particles and startExplode
    float size = random(30, 50);
    if (mode == "fuse") { //during fuse
      if (millis >= startTime + fuseTime) {
        startExplode(); //IMPORTANT: STARTS THE EXPLOSION WHEN FUSE IS OVER
      }
    }
    drawSprite();
  }

  @Override
    void drawSprite() {
    if (mode == "fly" || mode == "fuse") {
      push();
      translate(pos.x, pos.y);
      rotate(vel.heading());
      if (mode == "fuse") {
        imageMode(CENTER);
        image(RocketFuse, 0, 0);
      }
      noStroke();
      imageMode(CENTER);
      image(RocketFly, 0, 0);
      pop();
    }
  }
}

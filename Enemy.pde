int scale = 1;

/*stores the code for all of the enemies*/
class Enemy extends GameObject {
  /*Parent class for all enemies (enemy classes inherit this one)
   *stores default methods for registering player attacks (slash, smash, fireball)
   *These methods can be overrided to change mechanics reacting to different attacks
   */
  PVector separate = new PVector(); //This vector stores the calculation that forces enemies to separate from eachother (calculated in collUpdate, used in physUpdate)
  boolean[] calcSeparate = new boolean[10]; //Whether or not to include this object type in separate calculations (same indices as type[])
  PVector deltaPos = new PVector(); //the displacement vector between the enemy pos and the player pos
  float maxHealth = 50;
  float health = 50;

  float lastStun; //time when enemy was last stunned
  float stunCooldown = 500; //duration of stun
  String mode = "stun"; //move, stun

  Enemy() {
    enemyCount++;
  }
  @Override
    void collUpdate() {
    deltaPos = player.pos.copy().sub(pos);
    if (testColl(player.coll, coll)) {
      contactHit(player);
    }
    if (health == 0) {
      deleteObject = true;
      killCount++;
      enemyCount --;
      if (healthCount < maxHealthCount && floor(random(1, 5))==1) { //20% chance to drop health packet
        objs.add(new Health(pos.copy()));
      }
    }
    if (mode == "stun" && millis >= lastStun + stunCooldown) { //remove stun if possible
      mode = "move";
    }
    separate.set(0, 0);
    for (int i=0; i<objs.size(); i++) {
      GameObject obj = objs.get(i);
      if (obj.id == id) { //skip self within loop
        continue;
      }

      for (int j=0; j<10; j++) {
        if (obj.type[j] && calcSeparate[j]) {
          if (pos.copy().sub(obj.pos).magSq() < sq(200)) {
            separate.add(PVector.sub(pos, obj.pos));
          }
        }
      }

      if (obj.type[1] /*type pAttack*/) {
        if (obj.type[2]/*pSlash*/&& testColl(obj.coll, coll) && deltaPos.copy().mult(-1).dot(mousePos.copy().sub(player.pos)) > 0) {
          slashHit(obj);
        } else if (mode != "stun" && obj.type[3]/*pFireball*/ && testColl(obj.coll, coll)) {
          fireballHit(obj);
        } else if (obj.type[5]/*pExplosion*/ && testColl(coll, obj.coll)) {
          smashHit(obj);
        } else { //skip uneeded objects
          continue;
        }
      } else if (obj.type[7] /*neutral explosion*/ && testColl(coll, obj.coll)) {
        explodeHit(obj);
      } else {
        continue;
      }
    }
  }
  @Override
    void physUpdate() {
    runBehavior();
    if (regularMotion()) {
      pos.add(vel.copy().mult(dt));
      vel.lerp(0, 0, 0, 0.2*dt);
      coll.setPos(pos);
    }
    if (mode == "stun") {
      fill(30, 1, 1, 0.5);
      noStroke();
      circle(pos.x, pos.y, 150);
    }
    drawSprite();
    //draw healthbar
    push();
    translate(pos.x, pos.y-40);
    drawBar(health, 0, 50, -25, 25, 10);
    pop();
  }

  //default code for receiving player attacks
  void contactHit(GameObject obj) {
    player.onHit( deltaPos.copy().setMag(30), -10);
    vel.sub(deltaPos.copy().setMag(30));
    health = constrain(health-5, 0, health);
    textParticles.add( new TextParticle("-5", random(500, 1000), pos.copy().add(random(-25, 25), random(-25, 25)), color(360)) );
  }
  void slashHit(GameObject obj) {
    magic = constrain(magic +1, 0, 32);
    if (obj.type[4]) { //dash slash code
      vel.add(mousePos.copy().sub(player.pos).setMag(75)); //instantaneous
      screenShake.add(mousePos.copy().sub(player.pos).setMag(20*camScale));
      health = constrain(health-20, 0, health);
      textParticles.add( new TextParticle("-20", random(500, 1000), pos.copy().add(random(-25, 25), random(-25, 25)), color(180, 1, 1)) );
    } else {//regular slash code
      vel.add(mousePos.copy().sub(player.pos).setMag(50)); //instantaneous
      screenShake.add(mousePos.copy().sub(player.pos).setMag(10*camScale));
      health = constrain(health-10, 0, health);
      textParticles.add( new TextParticle("-10", random(500, 1000), pos.copy().add(random(-25, 25), random(-25, 25)), color(360)) );
    }
  }
  void fireballHit(GameObject obj) { //player fireball
    mode = "stun";
    lastStun = millis;
    if (obj.type[4]/*pDashType*/) { //dashed pFireball
      health = constrain(health-30, 0, health);
      textParticles.add( new TextParticle("-30", random(500, 1000), pos.copy().add(random(-25, 25), random(-25, 25)), color(180, 1, 1)) );
      vel.add(obj.vel.copy().setMag(50)); //instantaneous
      screenShake.add(mousePos.copy().sub(player.pos).setMag(20*camScale));
    } else { //basic pFireball
      health = constrain(health-20, 0, health);
      textParticles.add( new TextParticle("-20", random(500, 1000), pos.copy().add(random(-25, 25), random(-25, 25)), color(360)) );
      vel.add(obj.vel.copy().setMag(20)); //instantaneous
      screenShake.add(mousePos.copy().sub(player.pos).setMag(10*camScale));
    }
  }
  void smashHit(GameObject obj) { //player smash
    mode = "stun";
    lastStun = millis;
    if (obj.type[4]/*pDashType*/) { //Dash Explosion
      health = constrain(health-30, 0, health);
      textParticles.add( new TextParticle("-30", random(500, 1000), pos.copy().add(random(-25, 25), random(-25, 25)), color(180, 1, 1)) );
      vel.sub(obj.pos.copy().sub(pos).setMag(50));
      screenShake.add(mousePos.copy().sub(player.pos).setMag(20*camScale));
    } else { //Regular explosion
      health = constrain(health-20, 0, health);
      textParticles.add( new TextParticle("-20", random(500, 1000), pos.copy().add(random(-25, 25), random(-25, 25)), color(360)) );
      vel.sub(obj.pos.copy().sub(pos).setMag(50));
      screenShake.add(mousePos.copy().sub(player.pos).setMag(10*camScale));
    }
  }
  void explodeHit(GameObject obj) {
    mode = "stun";
    lastStun = millis;
    health = constrain(health-10, 0, health);
    textParticles.add( new TextParticle("-10", random(500, 1000), pos.copy().add(random(-25, 25), random(-25, 25)), color(360)) );
    vel.sub(obj.pos.copy().sub(pos).setMag(30));
    screenShake.add(PVector.sub(pos, obj.pos).setMag(10*camScale));
  }

  void runBehavior() { //children will override this method with movement code (called before drawSprite)
  }
  void drawSprite() { //Children will override this method with the code to draw the sprite
  }
  boolean regularMotion() { //Whether or not to use normal position and velocity motion
    return true;
  }
}

PGraphics BasicEnemySprite; //the main body (circle and spikes)
//this should be a static function in the class but processing is ass so there is no static ;-;
void initBasicEnemySprite() {
  PGraphics p = createGraphics(80, 80,P2D);
  p.beginDraw();
  p.translate(40, 40);
  p.colorMode(HSB, 360, 1, 1, 1);
  p.noStroke();
  p.rectMode(CENTER);
  p.fill(0, 0, 0.5); //gray
  for (int i=0; i<8; i++) {
    float angle = map(i, 0, 8, 0, TAU);
    p.push();
    p.translate(20*cos(angle), 20*sin(angle));
    p.rotate(angle+HALF_PI);
    p.triangle(-5, 0, 5, 0, 0, -20);
    p.pop();
  }

  p.noStroke();
  p.fill(0, 1, 0.5); //dark red
  p.circle(0, 0, 50);
  p.endDraw();
  BasicEnemySprite = p;
}

class BasicEnemy extends Enemy {
  private float lastTeleport; //time when enemy last teleported
  private float teleportCooldown = 5000; //time between teleports

  BasicEnemy() {
    init();
  }
  BasicEnemy(float x, float y) {
    pos.set(x, y);
    init();
  }
  @Override
    void init() {
    health = 50;
    coll = new CircleColl(pos.x, pos.y, 25);
    lastTeleport = millis;
    type[0] = true; //set enemy type
    calcSeparate[0] = true; //separate from enemy types

    ellipseMode(CENTER);
    noStroke();
    fill(0);
    bgObjs.add(new Particle(createShape(ELLIPSE, 0, 0, 300, 300), pos.copy(), 0, 1000, color(30, 1, 0.5)));
  }

  //Uses the default collUpdates from the inherited class

  @Override
    void runBehavior() {
    //move closer
    if (mode == "move" && vel.mag() < 5) { //maxspeed is 3
      vel.add( deltaPos.copy().setMag(2).add(separate.copy().setMag(1)).setMag(1*dt) );
      //weights the deltaPos and separate vectors individually, then sets their average to acceleration value
    }

    if (millis >= lastTeleport + teleportCooldown) {
      lastTeleport = millis;
      teleportCooldown = round(random(5000, 10000));
      float angle = player.pos.copy().sub(mousePos).heading() + random(-HALF_PI, HALF_PI);
      pos.set(player.pos.copy().add(PVector.fromAngle(angle).setMag(500)));
      ellipseMode(CENTER);
      noStroke();
      fill(0);
      bgObjs.add(new Particle(createShape(ELLIPSE, 0, 0, 300, 300), pos.copy(), 0, 1000, color(30, 1, 0.5)));
    }
  }

  //draw sprite
  @Override
    void drawSprite() {
    push();
    translate(pos.x, pos.y);
    imageMode(CENTER);
    image(BasicEnemySprite, 0, 0);
    pop();
  }
}

PGraphics RangeEnemySprite;
void initRangeEnemySprite() {
  PGraphics p = createGraphics(80*scale, 80*scale,P2D);
  p.beginDraw();
  p.translate(25*scale, 25*scale);
  p.scale(scale);
  p.colorMode(HSB, 360, 1, 1, 1);
  p.noStroke();
  p.rectMode(CENTER);
  p.fill(0, 1, 0.5);
  p.rect(20, 0, 30, 30);
  p.rect(30, 0, 40, 20);
  p.fill(0, 1, 0.7);
  p.circle(0, 0, 50);
  p.endDraw();
  RangeEnemySprite=p;
}

class RangeEnemy extends Enemy {
  private float lastShoot; //Time the last shot was fired
  float shootCooldown = 3000; //Cooldown in between shots
  RangeEnemy(float x, float y) {
    pos.set(x, y);
    init();
  }
  @Override
    void init() {
    coll = new CircleColl(pos.x, pos.y, 25); //radius not diameter
    lastShoot = millis;
    type[0] = true; //set enemy type to true
    calcSeparate[0] = true; //set enemy separate to true

    //draw spawn particle
    ellipseMode(CENTER);
    noStroke();
    fill(0);
    bgObjs.add(new Particle(createShape(ELLIPSE, 0, 0, 300, 300), pos.copy(), 0, 1000, color(30, 1, 0.5)));
  }
  @Override
    void runBehavior() {
    //move closer
    if (mode == "move") { //maxspeed is 3
      if (PVector.sub(player.pos, pos).magSq() > sq(1000)) { //teleport if too far away from player
        float angle = player.pos.copy().sub(mousePos).heading() + random(-HALF_PI, HALF_PI);
        pos.set(player.pos.copy().add(PVector.fromAngle(angle).setMag(500)));
        ellipseMode(CENTER);
        noStroke();
        fill(0);
        bgObjs.add(new Particle(createShape(ELLIPSE, 0, 0, 300, 300), pos.copy(), 0, 1000, color(30, 1, 0.5)));
      }
      //weights the deltaPos and separate vectors individually, then sets their average to acceleration value
      PVector v;  //temporary vector used to calculate velocity
      if (deltaPos.magSq() >= sq(400)) { //if player is outside range, move closer
        v = PVector.add( separate.copy().setMag(1), deltaPos.copy().setMag(2) ); //THIS VECTOR IS NOT NORMALIZED
      } else if (deltaPos.magSq() <= sq(300)) { //move away from player
        v = PVector.add( separate.copy().setMag(1), deltaPos.copy().setMag(-2) ); //THIS VECTOR IS NOT NORMALIZED
      } else {
        v = separate.copy(); //THIS VECTOR IS NOT NORMALIZED
      }
      if (vel.magSq() <= sq(9)) { //if under max speed, use acceleration value
        vel.add(v.setMag(1*dt));
      }

      if (millis >= lastShoot + shootCooldown) {
        lastShoot = millis;
        shoot();
      }
    }
  }
  void shoot() { //Override this method to change the bullet type
    objs.add(new EnemyBullet(pos.copy(), deltaPos.copy().setMag(10)));
  }
  @Override
    void drawSprite() {
    push();
    translate(pos.x, pos.y);
    rotate(deltaPos.heading());
    imageMode(CENTER);
    image(RangeEnemySprite, 0, 0);
    pop();
  }
}

PGraphics RocketEnemySprite;
void initRocketEnemySprite () {
  PGraphics p = createGraphics(80*scale, 80*scale,P2D);
  p.beginDraw();
  p.translate(40*scale, 40*scale);
  p.scale(scale);
  p.colorMode(HSB, 360, 1, 1, 1);
  p.noStroke();
  p.fill(0, 1, 0.5);
  p.triangle(0, 0, 50, 25, 50, -25);
  p.fill(0, 1, 0.7);
  p.circle(0, 0, 50);
  p.endDraw();
  RocketEnemySprite=p;
}

class RocketEnemy extends RangeEnemy {
  RocketEnemy(float x, float y) {
    super(x, y);
  }
  @Override
    void shoot() {
    objs.add(new Rocket(pos.copy(), PVector.random2D().setMag(5)));
  }
  @Override
    void drawSprite() {
    push();
    translate(pos.x, pos.y);
    rotate(deltaPos.heading());
    imageMode(CENTER);
    image(RocketEnemySprite, 0, 0);
    pop();
  }
}

PGraphics EnemyHealerSprite;
void initEnemyHealerSprite() {
  PGraphics p = createGraphics(80*scale, 80*scale,P2D);
  p.beginDraw();
  p.translate(40*scale, 40*scale);
  p.scale(scale);
  p.colorMode(HSB, 360, 1, 1, 1);
  p.noStroke();
  p.fill(0, 1, 0.5);
  p.rectMode(CENTER);
  p.rect(0, 0, 50, 50);
  p.fill(0, 0, 0.7);
  p.rect(0, 0, 10, 30);
  p.rect(0, 0, 30, 10);
  p.endDraw();
  EnemyHealerSprite=p;
}

class EnemyHealer extends RangeEnemy {
  EnemyHealer(float x, float y) {
    super(x, y);
    coll = new BoxColl(pos.x, pos.y, 50, 50, CENTER);
  }
  @Override
    void shoot() {
    for (GameObject obj : objs) { //heal all enemies within radius 400 pixels
      if (obj.type[0] /*type is enemy*/ && testColl(new CircleColl(pos.x, pos.y, 300), obj.coll)) {
        Enemy enemyObj = (Enemy)obj;
        if (enemyObj.health < enemyObj.maxHealth) {
          textParticles.add( new TextParticle("+10", random(500, 1000), enemyObj.pos.copy().add(random(-25, 25), random(-25, 25)), color(120, 1, 1)) );
        }
        enemyObj.health = constrain(enemyObj.health + 10, 0, enemyObj.maxHealth);
      }
    }
    noStroke();
    fill(120, 1, 0.7);
    ellipseMode(CENTER);
    bgObjs.add(new Particle(createShape(ELLIPSE, 0, 0, 600, 600), pos.copy(), 0, 500, color(120, 1, 0.5)));
  }
  @Override
    void drawSprite() {
    push();
    translate(pos.x, pos.y);
    imageMode(CENTER);
    image(EnemyHealerSprite, 0, 0);
    pop();
  }
}

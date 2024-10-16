PGraphics BulletBossSprite;
void initBulletBossSprite(float upScale) {
  PGraphics p = createGraphics((int)(325*upScale), (int)(325*upScale));
  p.beginDraw();
  p.colorMode(HSB, 360, 1, 1, 1);
  p.push();
  p.translate(p.width*0.5, p.height*0.5);
  p.scale(upScale);

  p.noStroke();
  int amount = 12; //amount of barrels
  for (int i=0; i<amount; i++) {
    float angle = map(i, 0, amount, 0, TAU);
    p.pushMatrix();
    p.translate(90*cos(angle), 90*sin(angle));
    p.rotate(angle);
    p.fill(0, 1, 0.5);
    p.rectMode(CORNER);
    p.rect(0, -25, 30, 50); //big gun rect
    p.rect(30, -15, 30, 30); //small gun rect
    p.fill(0, 1, 0.7);
    p.rect(0, -15, 20, 30); //big gun rect
    //p.rect(20, -5, 20, 10); //small gun rect
    p.popMatrix();
  }

  p.fill(0, 1, 0.7);
  p.circle(0, 0, 200);
  p.fill(0, 1, 0.8);
  p.circle(0, 0, 180);
  p.fill(0, 1, 1);
  p.circle(0, 0, 160);
  p.pop();
  p.endDraw();
  BulletBossSprite = p;
}

class BulletBoss extends Enemy {
  private float lastShoot;
  private float shootCooldown = 400;//1 sec
  //Bounding Box has 120 radius
  BulletBoss(float x, float y) {
    pos.set(x, y);
    init();
  }
  @Override
    void init() {
    type[0] = true; //type enemy
    type[8] = true; //type boss
    //no separation
    coll = new CircleColl(pos.x, pos.y, 120*scale);
    health = 200;
    maxHealth = 200;
    enemyCount --; //doesn't count towards enemy wave spawning
    targetScale = 1.5;
    
    bgObjs.add(new PullVisual(this)); //temporary add pull effect
  }
  @Override
    void runBehavior() {
    //pull player closer
    player.vel.add(deltaPos.copy().setMag(-1*dt));

    //move closer
    if (mode == "move") { //maxspeed is 3
      if (PVector.sub(player.pos, pos).magSq() > sq(1200)) { //teleport if too far away from player
        float angle = player.pos.copy().sub(mousePos).heading() + random(-HALF_PI, HALF_PI);
        pos.set(player.pos.copy().add(PVector.fromAngle(angle).setMag(700)));
        noStroke();
        fill(30, 1, 1, 0.5);
        ellipseMode(CENTER);
        bgObjs.add(new Particle(createShape(ELLIPSE, 0, 0, 400, 400), pos, 0, 300, color(30, 1, 1, 0.5)));
      }

      if (millis >= lastShoot + shootCooldown) {
        lastShoot = millis;
        shoot();
      }
      rot = lerp(rot, targetRot, 0.2*dt);
      scale = lerp(scale, targetScale, 0.2*dt);
    }
    
    push();
    translate(pos.x, pos.y);
    noFill();
    strokeWeight( constrain( map(deltaPos.mag(), 1000, 1200, 1, 8), 1, 8) );
    stroke(0, 1, 1);
    circle(0, 0, 2400);
    pop();
  }
  void shoot() { //Override this method to change the bullet type
    targetRot += radians(15); //360/24 (12 turrets, moves a half of a turret)
    scale *= 1.2; //slight pop
    for (int i=0; i<12; i++) {
      float angle = rot+map(i, 0, 12, 0, TAU);
      if (floor(random(1,3))==1) {
        objs.add(new EnemyBullet( pos.copy().add(PVector.fromAngle(angle).setMag(120 * scale)), PVector.fromAngle(angle).setMag(5)));
      } else {
        objs.add(new InvincBullet( pos.copy().add(PVector.fromAngle(angle).setMag(120 * scale)), PVector.fromAngle(angle).setMag(5)));
      }
    }
  }
  
  void summonExplosionArray() {
    float spacing = 150;
    float x = player.pos.x - spacing*5;
    while (x<player.pos.x+spacing*5) {
      objs.add(new NeutralExplosion(new PVector(x,player.pos.y), 50,1500));
      x+=spacing;
    }
  }
  
  @Override
    void drawSprite() {
    push();
    translate(pos.x, pos.y);
    rotate(rot);
    scale(scale/2); //default upscale of 2
    imageMode(CENTER);
    image(BulletBossSprite, 0, 0);
    pop();
  }
}

class PullVisual extends BgObj{
  private float spacing = 100;
  GameObject boss;
  PullVisual(GameObject obj) { //reference to the boss object (used for deleteObject and position)
    this.boss = obj;
  }
  void update() {
    if (boss.deleteObject) {
      deleteObject = true;
    }
    
    push();
    translate(boss.pos.x,boss.pos.y);
    float r = 1200 /*extent radius*/ - spacing + map(millis%1000,0,1000,100,0);
    noFill();
    stroke(0,0,0.3);
    strokeWeight(2);
    while (r>=200) {
      circle(0,0,2*r);
      r-=spacing;
    }
    pop();
  }
}

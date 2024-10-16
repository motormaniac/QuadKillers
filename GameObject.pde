/*GameObject is a parent class that all objects extend from, including: players, enemies, and attacks*/

class GameObject {
  boolean deleteObject = false; //object is deleted when it is true
  PVector pos = new PVector(); //Position must be initialized before it can be passed as a reference
  PVector vel = new PVector();
  float scale = 1; //actual scale
  float targetScale = 1; //used for scale lerping
  float rot = 0; //actual rotation
  float targetRot = 0; //used for rotation lerping
  int id = 0; //unique id for the object (DOES NOT NECESSARILY MATCH LIST INDEX)
  Collider coll; //Hitbox of the object
  boolean[] type = new boolean[10]; //layer is used to differentiate between objects (objs can have multiple layers)
  //0:enemy, 1:pAttack, 2:pSlash, 3:pFireball, 4:dashAttack, 5:pSmash, 6:rocket, 7:neutralExplosion, 8:boss

  GameObject() {
    id = objectCount;
    objectCount ++;
  }
  void init() {
  }
  void collUpdate() {
  }
  void physUpdate() {
  }
  void visUpdate() {
  }
}

int healthCount = 0; //current amount of health packets
int maxHealthCount = 10; //maximum amount of health packets
class Health extends GameObject {
  private float emitStart;
  private float emitCooldown = 1000;
  Health(PVector pos) {
    this.pos = pos;
    coll = new BoxColl(pos.x, pos.y, 50, 50, CENTER);
    emitStart = millis;
    healthCount ++;
  }
  @Override
    void collUpdate() {
    if (testColl(this.coll, player.coll)) {
      player.addHealth(10);
      textParticles.add( new TextParticle("+10", random(500, 1000), pos.copy().add(random(-25, 25), random(-25, 25)), color(120, 1, 1)) );
      bgHue = 120;
      bgBrightness = 0.5;
      deleteObject = true;
      healthCount --;
    }
  }
  @Override
    void physUpdate() {
    if (testColl(new BoxColl(camPos.x, camPos.y, width/camScale, height/camScale, CENTER), coll)) {//if on screen
      ellipseMode(CENTER);
      fill(120, 1, 0.5);
      noStroke();
      if (millis > emitStart + emitCooldown) {
        emitStart = millis;
        bgObjs.add(new Particle(createShape(ELLIPSE, 0, 0, 100, 100), pos.copy(), 100, 500, color(120, 1, 0.5)) );
      }
      //draw health sprite
      pushMatrix();
      translate(pos.x, pos.y);
      rectMode(CENTER);
      noStroke();
      fill(0, 0, 0.7); //white
      rect(0, 0, 50, 50);
      fill(0, 1, 0.7); //red
      rect(0, 0, 10, 30);
      rect(0, 0, 30, 10);
      popMatrix();
    } else {
      float margin = 50;
      PVector tempPos = pos.copy(); //position of the indicator (not the health object)
      if (pos.x<camPos.x-width*0.5/camScale+margin) {
        tempPos.x = camPos.x-width*0.5/camScale+margin;
      } else if (pos.x > camPos.x+width*0.5/camScale-margin) {
        tempPos.x = camPos.x+width*0.5/camScale-margin;
      }
      if (pos.y<camPos.y-height*0.5/camScale+margin) {
        tempPos.y = camPos.y-height*0.5/camScale+margin;
      } else if (pos.y > camPos.y+height*0.5/camScale-margin) {
        tempPos.y = camPos.y+height*0.5/camScale-margin;
      }
      
      noStroke();
      pushMatrix(); //circle and point
      translate(tempPos.x,tempPos.y);
      rotate(PVector.sub(pos,tempPos).heading());
      fill(0,0,0.7);
      triangle(0,25,0,-25,50,0);
      circle(0,0,50);
      popMatrix();
      
      pushMatrix(); //cross
      translate(tempPos.x,tempPos.y);
      fill(0, 1, 0.7); //red
      rectMode(CENTER);
      rect(0, 0, 10, 30);
      rect(0, 0, 30, 10);
      popMatrix();
    }
  }
}

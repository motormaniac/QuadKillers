/*code for the player movement and input*/

class Player extends GameObject {
  private float maxSpeed = 5; //maximum movement speed while using WASD
  private float acc = 2; //Acceleration per frame when you press WASD
  private float frictAmt = 0.3; //lerp amount while applying friction
  float health = 100;

  //dash constants
  private float dashDistance = 300; //length of dash in pixels
  private float dashDuration = 100; //in millis, duration of total dash motion
  private float dashInvincDuration = 300; //in millis, the duration of invincibility after the dash finishes
  private float dashCooldown = 1500; //in millis, the cooldown in between dashes

  public float lastDash; //at what time did the last dash start
  private PVector lastKeyDir = new PVector(1, 0); //the last recorded key direction in case no keys were pressed that frame
  private PVector dashStartPos = new PVector();
  private PVector dashEndPos = new PVector();

  private float lastStun; //at what time did the stun start
  private float stunDuration = 300; //in millis duration of stun
  private float stunInvincDuration = 300; //in millis the duration of invincibility after stun finishes

  private float lastSlash; //at what time did the last slash start
  private float slashCooldown = 500; //cooldown between slashes
  private float dashSlashBuffer = 100; //a dash slash will still register a short amount of time after the dash finishes
  private boolean flipSlash = false; //boolean used to alternate the swing direction of the dash

  private float lastSpell; //at what time was last shot fired
  private float spellCooldown = 500; //millis cooldown between shots

  String mode = "move"; //the current mode the player is in: "move", "dash"
  HashMap<String, Integer> states = new HashMap<String, Integer>();
  //Stores the states of the player (0 for false, 1 for true)
  //Invinicibility (true/false)
  Player() {
    init();
  }
  Player(float x, float y) {
    pos.set(x,y);
    init();
  }
  void addHealth(float h) {
    health = constrain(health + h, 0, 100);
  }
  @Override
    void init() {
    coll = new BoxColl(pos.x, pos.y, 50, 50, CENTER);
    lastDash = -dashCooldown; //mathematically allows player to dash instantly
    lastSlash = -slashCooldown; //mathematically allows player to slash instantly

    states.put("invincible", 0); //sets invincibility to false
  }
  void onHit(PVector kb, float damage) { //damage should be a negative value
    //called when the player is hit
    if (states.get("invincible") == 0) {
      bgHue = 0;
      bgBrightness = 0.7;
      vel.add(kb);
      mode = "stun";
      lastStun = millis;
      states.put("invincible", 1);
      addHealth(damage);
      textParticles.add( new TextParticle(""+(int)damage, 1000, pos.copy().add(random(-25, 25), random(-25, 25)), color(360, 1, 1)) );

      if (health ==0) {
        objs.clear();
        textParticles.clear();
        bgObjs.clear();
        screen = 4;
        spawnButtons();
      }
    }
  }
  void resetDash() {
    lastDash = millis-dashCooldown+300; //when dash is reset, you still have to wait 500ms
  }
  @Override
    void physUpdate() {
    PVector keyDir = new PVector(0, 0); //Tracks the direction of the WASD keys e.g. Right, Upper-left, Down, etc...
    float mouseDir = mousePos.copy().sub(player.pos).heading(); //angle of the mouse relative to the player

    if (inputHeld[4]) { //d pressed
      keyDir.x += 1;
      if (vel.x < maxSpeed && mode == "move") {
        vel.x += acc*dt;
      }
    }
    if (inputHeld[2]) { //a pressed
      keyDir.x -= 1;
      if (vel.x > -maxSpeed && mode == "move") {
        vel.x -= acc*dt;
      }
    }
    if (inputHeld[1]) { //w pressed
      keyDir.y -= 1;
      if (vel.y > -maxSpeed && mode == "move") {
        vel.y -= acc*dt;
      }
    }
    if (inputHeld[3]) { //s pressed
      keyDir.y += 1;
      if (vel.y < maxSpeed && mode == "move") {
        vel.y += acc*dt;
      }
    }

    if ((millis > lastDash + dashDuration + dashInvincDuration) && (millis >= lastStun + stunDuration + stunInvincDuration)) {
      //turns off invincbility after a certain amount of time after the dash or after the stun
      states.put("invincible", 0);
    }

    if (mode == "stun") {
      pos.add(vel.copy().mult(dt));
      vel.lerp(0,0,0, 0.2*dt); //lerp to 0
      if (millis >= lastStun + stunDuration) {
        mode = "move";
      }
    } else if (mode == "move") {
      pos.add(vel.copy().mult(dt));
      vel.lerp(0,0,0, frictAmt*dt);

      if (keyDir.x != 0 || keyDir.y != 0) { //if no keys were pressed, then use lastKeyDir, otherwise set lastKeyDir to current keyDir
        lastKeyDir = keyDir.copy();
      }

      //starting the dash code
      if (inputHeld[0] && millis - lastDash >= dashCooldown) { //If space pressed, start dash
        //initialize the dash values for the motion
        mode = "dash";
        lastDash = millis; //reset the cooldown
        states.put("invincible", 1);
        dashStartPos = pos.copy();
        if (lastKeyDir.x != 0 && lastKeyDir.y != 0) { //normalizes speed on diagnals divides by √2
          dashEndPos.set(lastKeyDir.copy().mult(dashDistance).mult(0.7)).add(pos);
        } else {
          dashEndPos.set(lastKeyDir.copy().mult(dashDistance)).add(pos);
        }
      }
      if (inputHeld[6] /*m2*/) {
      }
      //starting slash code
      if (inputHeld[5]/*m1*/ && millis > lastSlash + slashCooldown) {
        lastSlash = millis;
        flipSlash = !flipSlash;
        if (inputPressTime[5] > lastDash + dashDuration && inputPressTime[5] < lastDash + dashDuration + dashSlashBuffer && millis < lastDash + dashDuration + dashSlashBuffer) {
          //Dash slash if mouse input was between dash ending and dashSlashBuffer
          objs.add(new PlayerSlash(player.pos, mouseDir, 300, 100, 1000, color(180, 1, 1), flipSlash));
          //origin player, aim towards mouse, radius 300, 100 ms slash animation, long fade (1sec), light blue color
          objs.get(objs.size()-1).type[4] = true; //Set dash slash type dashAttack to true
          screenShake.add(50*cos(mouseDir), 50*sin(mouseDir));
          bgHue = 180; //Screen flash
          bgBrightness = 0.5;
        } else { //regular slash
          objs.add(new PlayerSlash(player.pos, mouseDir, flipSlash));
        }
      }
      //Spells code
      if (millis > lastSpell + spellCooldown) {
        if (magic >= 8 && (inputHeld[8] || inputHeld[7])) {
          lastSpell = millis;
          magic = constrain(magic-8, 0, 32);
          //fireball
          if (inputHeld[8] && inputPressTime[8] > lastDash + dashDuration && inputPressTime[8] < lastDash + dashDuration + dashSlashBuffer && millis < lastDash + dashDuration + dashSlashBuffer) {
            //Dash projectile if mouse input was between dash ending and dashSlashBuffer
            objs.add(new PlayerFireball(player.pos.copy(), mouseDir, 150, color(180, 1, 1)));
            //origin player, aim towards mouse, radius 300, light blue color
            objs.get(objs.size()-1).type[4] = true; //Set dash fireball type dashAttack to true
            screenShake.add(50*cos(mouseDir), 50*sin(mouseDir));
            bgHue = 180; //Screen flash
            bgBrightness = 0.5;
          } else if (inputHeld[8]) {//regular projectile
            objs.add(new PlayerFireball(player.pos.copy(), mouseDir, 75, color(0, 0, 1))); //basic projectile
            
            //Code for explosions
          } else if (inputHeld[7] && inputPressTime[7] > lastDash + dashDuration && inputPressTime[7] < lastDash + dashDuration + dashSlashBuffer && millis < lastDash + dashDuration + dashSlashBuffer) {
            //Dash Explosion
            objs.add(new PlayerSmash(player.pos.copy(), 400,1000,color(180,1,1)));
            objs.get(objs.size()-1).type[4]=true;
            screenShake.add(50*cos(mouseDir), 50*sin(mouseDir));
            bgHue = 180; //Screen flash
            bgBrightness = 0.5;
          } else if (inputHeld[7]) {
            objs.add(new PlayerSmash(player.pos.copy(), 250,300,color(0,0,1)));
            screenShake.add(50*cos(mouseDir), 50*sin(mouseDir));
          }
        } else if (inputHeld[8] || inputHeld[7]) {
          crossScale = 2;
        }
      }
    } else if (mode == "dash") {
      //the entire dash motion is a lerp between dashStartPos and dashEndPos over the dashDuration timeframe
      if (millis - lastDash >= dashDuration) { //when the dash is finished
        mode = "move";
        pos.set(PVector.lerp(dashStartPos, dashEndPos, 1));
      } else {
        PVector p = PVector.lerp(dashStartPos, dashEndPos, map(millis, lastDash, lastDash + dashDuration, 0, 1));
        pos.set(p);
        rectMode(CENTER);
        ellipseMode(CENTER);
        noStroke();
        fill(180, 0.7, 1);
        bgObjs.add(new Particle(createShape(ELLIPSE, 0, 0, 70, 70), pos.copy().add(random(-30, 30), random(-30, 30)), 100, random(300, 500), color(180, 0.7, 1)));
        //Circle particle diameter 50, position is randomly offset from player pos, decay time random btwn 300 and 500 ms, color light blue
        bgObjs.add(new Particle(createShape(RECT, 0, 0, 70, 70), pos.copy().add(random(-30, 30), random(-30, 30)), 100, random(300, 500), color(180, 0.7, 1)));
      }
    }

    coll.setPos(pos); //update collider

    color shieldFill = color(0, 0, 1, 0.2);
    color playerFill = color(0, 0, 1);
    //color logic
    if (mode == "dash") {
      playerFill = color(180, 0.7, 1);
      shieldFill = color(180, 0.7, 1, 0.2);
    } else if (mode == "stun") {
      playerFill = color(0, 1, 1);
      shieldFill = color(0, 1, 1, 0.2);
    } else if (mode == "move") {
      if (millis >= lastDash + dashCooldown) {
        //show dash is ready
        playerFill = color(180, 0.7, 1);
        //walk particle dash blue
        rectMode(CENTER);
        noStroke();
        fill(180, 0.7, 1);
        bgObjs.add(new Particle(createShape(RECT, 0, 0, 30, 30), pos.copy().add(random(-10, 10), random(-10, 10)), 0, 300, color(180, 0.7, 1)));
      } else {
        playerFill = color(360);//basic player color
        //walk particle white
        rectMode(CENTER);
        noStroke();
        fill(0,0,1);
        bgObjs.add(new Particle(createShape(RECT, 0, 0, 30, 30), pos.copy().add(random(-10, 10), random(-10, 10)), 0, 300, color(0, 0, 1)));
      }
      if (millis <= lastDash + dashDuration + dashInvincDuration) {
        shieldFill = color(180, 0.7, 1, 0.2); //show that shield is from dash
      } else if (millis <= lastStun + stunDuration + stunInvincDuration) {
        shieldFill = color(0, 0.7, 1, 0.2); //show that shield is from damage
      }
    }

    //draw shield
    if (states.get("invincible") == 1) {
      noStroke();
      fill(shieldFill);
      strokeWeight(8);
      circle(pos.x, pos.y, 150);
    }

    //draw player
    noStroke();
    rectMode(CENTER);
    fill(playerFill);
    rect(pos.x, pos.y, 50, 50);

    pushMatrix();
    translate(pos.x, pos.y-40);
    drawBar(health, 0, 100, -25, 25, 10);
    popMatrix();
  }
}

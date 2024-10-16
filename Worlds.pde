HashMap<String, World> worldDir = new HashMap<String, World>();
String currentWorld = "RedWorld"; //the current selected world type (RedWorld by default) //this should be eventually be replaced by an enum

void initWorlds () {
  worldDir.put("TestWorld", new TestWorld());
  worldDir.put("RedWorld", new RedWorld());
}
abstract class World {
  String worldType;
  abstract void gameStart();
  abstract void setWorld(); //change the background shapes depending on the selected world
  abstract void enemySpawn();
}

class RedWorld extends World {
  RedWorld () {
    worldType = "RedWorld";
  }
  @Override
    void gameStart() {
    player = new Player(0, 0);
    camPos.set(0, 0);
    enemyCount = 0;
    objectCount = 0;
    wave=0;
    killCount =0;
    magic=0;
    lastSpawn = millis + 3000;
    objs.clear();
    bgObjs.clear();
    textParticles.clear();
  }

  @Override
    void enemySpawn () {
    if (enemyCount ==0 && millis > lastSpawn) { //spawn in next wave
      lastSpawn = millis - 1000; //instantly spawns a subwave
      wave++;
      subWave = wave;
    }
    if (millis >= lastSpawn + 1000) {
      lastSpawn = millis;
      if (round(random(1, 5))==1) {
        objs.add(new NeutralExplosion(player.pos.copy(), 400, 1500));
      }
      if (subWave>0) {
        int mod = subWave%20+1; //temp variable to store the mod of subWave
        int ceil = ceil((float)subWave/20); //temp variable stores floor (used for multiplying enemy count per wave)
        if (mod < 5) {
          for (int i=0; i<2*ceil; i++) {
            float angle = random(0, TAU);
            objs.add(new BasicEnemy(player.pos.x + 500*cos(angle), player.pos.y + 500*sin(angle)));
          }
        } else if (5 < mod && mod <= 10) {
          for (int i=0; i<ceil; i++) {
            float angle = random(0, TAU);
            objs.add(new BasicEnemy(player.pos.x + 500*cos(angle), player.pos.y + 500*sin(angle)));
          }
          for (int i=0; i<ceil; i++) {
            float angle = random(0, TAU);
            objs.add(new RangeEnemy(player.pos.x + 500*cos(angle), player.pos.y + 500*sin(angle)));
          }
        } else if (10 < mod && mod<=15) {
          for (int i=0; i<ceil; i++) {
            float angle = random(0, TAU);
            objs.add(new BasicEnemy(player.pos.x + 500*cos(angle), player.pos.y + 500*sin(angle)));
          }
          for (int i=0; i<ceil; i++) {
            float angle = random(0, TAU);
            objs.add(new EnemyHealer(player.pos.x + 500*cos(angle), player.pos.y + 500*sin(angle)));
          }
        } else if (15 < mod && mod<=20) {
          for (int i=0; i<ceil; i++) {
            float angle = random(0, TAU);
            objs.add(new BasicEnemy(player.pos.x + 500*cos(angle), player.pos.y + 500*sin(angle)));
          }
          for (int i=0; i<ceil; i++) {
            float angle = random(0, TAU);
            objs.add(new RocketEnemy(player.pos.x + 500*cos(angle), player.pos.y + 500*sin(angle)));
          }
        }
        subWave --;
      }
    }
  }
  @Override
    void setWorld() {
    initBasicEnemySprite();
    initRangeEnemySprite();
    initRocketEnemySprite();
    initEnemyHealerSprite();
    initRocketSprite();
    shapes.clear();
    rectMode(CENTER);
    ellipseMode(CENTER);
    noStroke();
    for (int i=0; i<10; i++) { //create background particle
      fill(random(0, 45), 1, 1, 0.2);
      shapes.add(new Shape(createShape(ELLIPSE, 0, 0, 50, 50), new PVector(50, 50), random(0.5, 1.5), 0) );
      fill(0,0,random(0.7,0.1),0.2);
      shapes.add(new Shape(createShape(ELLIPSE, 0, 0, 50, 50), new PVector(50, 50), random(0.5, 1.5), 0) );
    }
  }
}

class TestWorld extends World {
  TestWorld () {
    worldType = "TestWorld";
  }
  @Override
    void gameStart() {
    player = new Player(0, 0);
    camPos.set(0, 0);
    enemyCount = 0;
    objectCount = 0;
    wave=9;
    killCount =0;
    magic=0;
    lastSpawn = millis + 3000;
    objs.clear();
    bgObjs.clear();
    textParticles.clear();
    objs.add(new BulletBoss(500, 500));
  }
  @Override
    void enemySpawn () {
  }
  @Override
    void setWorld() {
    initBulletBossSprite(2);
    shapes.clear();
    for (int i=0; i<20; i++) { //create background particle
      fill(random(0, 360), 1, 1, 0.2);
      shapes.add(new Shape(createShape(RECT, 0, 0, 50, 50), new PVector(50, 50), random(0.5, 2), random(0, HALF_PI)) );
      fill(random(0, 360), 1, 1, 0.2);
      shapes.add(new Shape(createShape(ELLIPSE, 0, 0, 50, 50), new PVector(50, 50), random(0.5, 2), 0) );
      fill(random(0, 360), 1, 1, 0.2);
      shapes.add(new Shape(createShape(TRIANGLE, -25, -25, 25, -25, 0, 25), new PVector(50, 50), random(0.5, 2), random(0, HALF_PI)) );
    }
  }
}

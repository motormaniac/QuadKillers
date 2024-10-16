/*This file stores all the classes required to detect various collisions.
This file was written before the game project as a general use collision library, so many functiosn are not used. */

abstract class Collider{ //inherited class for all the collider types
  //Polymorphism: The subclasses will override the return value of this function
  //0 for box, 1 for line, 2 for circle, 3 for group
  
  /*setValues is a "fake" constructor that has the same ability. 
   *This overcomes the limitation that you can only call constructors in other constructors
   * i.e. you can only use this() in other constructors, however i can use setValues() instead */
  abstract int getType();
  abstract void setPos(float x, float y);
  void setPos(PVector p) {
    setPos(p.x,p.y);
  }
  abstract void visualize(boolean isTouching);
  void visualize() {
    visualize(false);
  }
}

boolean testColl(Collider a, Collider b) {
  if (a==null || b==null) {return false;}
  int aType = a.getType();
  int bType = b.getType();
  if(a.getType()==3) { //if groupColl
    for (Collider c : ((GroupColl)a).colls) {
      if (testColl(c, b)) {return true;}
    }
    return false;
  } else if (b.getType()==3) {
    for (Collider c: ((GroupColl)b).colls) {
      if(testColl(a,c)){
        return true;
      }
    }
    return false;
  } else {
    boolean coll = false;
    //large switch case chooses the correct collision detection function based on the type of collider
    switch(aType) {
    case 0:
      switch(bType) {
        case 0:coll = BoxBoxColl((BoxColl)a, (BoxColl)b);break;
        case 1:coll = BoxLineColl((BoxColl)a, (LineColl)b);break;
        case 2: coll = BoxCircleColl((BoxColl)a, (CircleColl)b); break;
      } break;
    case 1:
      switch(bType) {
        case 0: coll = LineBoxColl((LineColl)a, (BoxColl)b); break;
        case 1: coll = LineLineColl((LineColl)a, (LineColl)b); break;
        case 2: coll = LineCircleColl((LineColl)a, (CircleColl)b); break;
      } break;
    case 2:
      switch(bType) {
        case 0: coll = CircleBoxColl((CircleColl)a, (BoxColl)b); break;
        case 1: coll = CircleLineColl((CircleColl)a, (LineColl)b); break;
        case 2: coll = CircleCircleColl((CircleColl)a, (CircleColl)b); break;
      } break;
    }
    return coll;
  }
}

class GroupColl extends Collider {
  ArrayList<Collider> colls = new ArrayList<Collider>();
  GroupColl addColl(Collider coll) {
    colls.add(coll);
    return this;
  }
  GroupColl removeColl(int index) {
    colls.remove(index);
    return this;
  }
  @Override
  int getType() {
    return 3;
  }
  @Override
  void visualize(boolean isTouching) {
    for (Collider coll : colls) {
      coll.visualize(isTouching);
    }
  }
  @Override
  void setPos(float x, float y) {
    for (Collider coll : colls) {
      coll.setPos(x,y);
    }
  }
}

class BoxColl extends Collider {
  PVector p1 = new PVector(); //upper left corner (-x, -y)
  PVector p2 = new PVector(); //bottom right corner (+x, +y)
  PVector center = new PVector(); //center of the box
  PVector size = new PVector(); //.x is width, .y is height

  @Override
  int getType() {
    return 0;
  }
  BoxColl(){}
  BoxColl(float a, float b, float c, float d, int mode) {
    setValues(a,b,c,d,mode);
  }
  
  void setValues(float a, float b, float c, float d, int mode) {
    switch (mode) {
      case (int)CORNER:
      p1.set(a, b);
      p2.set(a + c, b + d);
      center.set(a + c*0.5, b + d*0.5);
      size.set(c, d);
      break;

      case (int)CORNERS:
      //Makes sure that a < c and b < d
      if (a < c) {
        p1.set(a, b);
        p2.set(c, d);
      } else {
        p1.set(c, b);
        p2.set(a, d);
      }
      if (d < b) {
        p1.y = d;
        p2.y = b;
      }
      center.set(0.5*(a+c), 0.5*(b+d));
      size.set(abs(c-a), abs(d-b));
      break;

      case (int)CENTER:
      p1.set(a - 0.5*c, b - 0.5*d);
      p2.set(a + 0.5*c, b + 0.5*d);
      center.set(a, b);
      size.set(c, d);
    }
  }
  @Override
  void setPos(float x, float y) {
    setValues(x,y,size.x,size.y,CENTER);
  }
  void visualize(boolean isTouching) {
    //Visualizes the collision box on screen
    rectMode(CORNERS);
    noFill();
    strokeWeight(1);
    if (isTouching) {
      stroke(255, 0, 0);
    } else {
      stroke(255);
    }
    rect(p1.x, p1.y, p2.x, p2.y);
  }
}

class LineColl extends Collider {
  PVector p1 = new PVector();
  PVector p2 = new PVector();
  BoxColl boundingBox = new BoxColl(); //create reference instead of creating new box object every frame

  @Override
  int getType() {
    return 1;
  }
  LineColl() {}
  LineColl(float x1, float y1, float x2, float y2) {
    setValues(x1,y1,x2,y2);
  }
  LineColl(PVector p1, PVector p2) {
    setValues(p1,p2);
  }
  void setValues(PVector p1, PVector p2) {
    setValues(p1.x,p1.y,p2.x,p2.y);
  }
  void setValues(float x1, float y1, float x2, float y2) {
    p1.set(x1, y1);
    p2.set(x2, y2);
    boundingBox.setValues(x1,y1,x2,y2,CORNERS);
  }
  @Override
  void setPos(float x, float y) {
    //when called, translates by the midpoint instead
    PVector deltaPos = new PVector(x,y).sub(PVector.lerp(p1,p2,0.5));
    p1.add(deltaPos); p2.add(deltaPos);
  }

  void visualize(boolean isTouching) {
    //draws the collision box on screen
    strokeWeight(1);
    if (isTouching) {
      stroke(255, 0, 0);
    } else {
      stroke(255);
    }
    line(p1.x, p1.y, p2.x, p2.y);
  }
}

class CircleColl extends Collider {
  PVector center = new PVector(); //center of circle
  float radius; //radius of circle
  BoxColl boundingBox = new BoxColl(); //create reference instead of creating new box object every frame

  @Override
  int getType() {
    return 2;
  }
  CircleColl(){}
  CircleColl(float x, float y, float r) {
    setValues(x,y,r);
  }
  void setValues(float x, float y, float r) {
    center.set(x, y);
    radius = r;
    boundingBox.setValues(x,y,2*r,2*r,CENTER);
  }
  @Override
  void setPos(float x, float y) {
    center.set(x,y);
    boundingBox.setPos(x,y);
  }
  @Override
  void visualize(boolean isTouching) {
    //draws the hitbox on screen
    if (isTouching) {
      stroke(255, 0, 0);
    } else {
      stroke(255);
    }
    ellipseMode(CENTER);
    noFill();
    ellipse(center.x, center.y, 2 * radius, 2 * radius);
  }
}

boolean BoxBoxColl(BoxColl b1, BoxColl b2) {
  //Utilizes the convention that x1 < x2 and y1 < y2
  //For example, if b1.x1 is greater than b2.x2, then b1.x2 must also be greater than b2.x2
  //Compares whether x bounds cross and whether y bounds cross independently
  boolean coll = !( (b1.p1.x > b2.p2.x) || (b1.p2.x < b2.p1.x) || (b1.p1.y > b2.p2.y) || (b1.p2.y < b2.p1.y) );
  return coll;
}
boolean BoxLineColl(BoxColl b, LineColl l) {
  //First do a general bounding box collision detection before using detailed line collision
  if (false == BoxBoxColl(b, l.boundingBox)) {
    return false;
  }
  //visualization of linear interpolation https://www.desmos.com/geometry/5nrvzkewdg
  float t1 = (b.p1.x - l.p1.x) / (l.p2.x - l.p1.x);
  float t2 = (b.p2.x - l.p1.x) / (l.p2.x - l.p1.x);
  float y1 = (1 - t1) * l.p1.y + l.p2.y * t1;
  float y2 = (1 - t2) * l.p1.y + l.p2.y * t2;

  //If y1 and y2 are on opposite sides of the box, then the line has to collide at some point
  //the boolean returns false only if both y values are either above or below the box
  return !( (y1 < b.p1.y && y2 < b.p1.y) || (y1 > b.p2.y && y2 > b.p2.y) );
}
boolean LineBoxColl(LineColl l, BoxColl b) {
  return BoxLineColl(b, l);
}

boolean BoxCircleColl(BoxColl b, CircleColl c) {
  if ( !BoxBoxColl(b, c.boundingBox) ) {//overal bounding box check
    return false;
  }
  //general strategy: find the distance from the closest point to the circle center which is either the corner or the edge

  //distance from the center of the box to the center of the circle
  //if the distance is less than the size of the box (center of circle is inside the box)
  //then it will set it to 0
  float x = abs(c.center.x - b.center.x) - b.size.x * 0.5;
  if (x < 0) {
    x = 0;
  }
  float y = abs(c.center.y - b.center.y) - b.size.y * 0.5;
  if (y < 0) {
    y=0;
  }
  return ( x*x+y*y < sq(c.radius)); //use the distance squared to avoid using square root
}
boolean CircleBoxColl(CircleColl c, BoxColl b) {
  return BoxCircleColl(b, c);
}

boolean LineCircleColl(LineColl l, CircleColl c) {
  if (false == BoxLineColl(c.boundingBox, l)) {
    return false;
  }
  //strategy developed by Matthew Emmanuel: https://www.desmos.com/geometry/luvh5tpbii
  PVector AB = l.p2.copy().sub(l.p1); //vector representing line (tail at p1, head at p2)
  PVector AC = c.center.copy().sub(l.p1); //vector between p1 and center of circle
  float ABmag = AB.mag();
  float dot = AB.dot(AC) / ABmag; //the parallel between
  if (dot >= ABmag) {
    return ( PVector.sub(l.p2, c.center).magSq() < sq(c.radius));
  } else if (dot <= 0) {
    return ( PVector.sub(l.p1, c.center).magSq() < sq(c.radius));
  }
  return (AC.magSq() - sq(dot) < sq(c.radius)); //use pythagorean theorem
}
boolean CircleLineColl(CircleColl c, LineColl l) {
  return LineCircleColl(l, c);
}

boolean CircleCircleColl(CircleColl c1, CircleColl c2) {
  //true if the distance between the centers are less than the sum of the radi
  return (dist(c1.center.x, c1.center.y, c2.center.x, c2.center.y) < c1.radius + c2.radius);
}
boolean LineLineColl(LineColl l1, LineColl l2) {
  //placeholder function for now
  return BoxBoxColl(l1.boundingBox, l2.boundingBox);
}

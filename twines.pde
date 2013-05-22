//Growing twines sketch
//Copyright (C) 2013 Anton Pirogov
//Licensed under the MIT License

ArrayList pencils; //Stores all pencil objects
boolean debug = false; //debug flag

void setup() {
  size(800,600);
  background(255);
  smooth();
  noFill();
  pencils = new ArrayList();

  //initialize first pencil on startup
  int x = int(random(width/2)+width/4);
  int y = int(random(height/2)+height/4);
  new_pencil(x,y);
}

void new_pencil(int x, int y) {
  Pencil p = new Pencil();
  p.x = x;
  p.y = y;
  p.angle = random(2*PI);
  pencils.add(p);
}

//update and remove dead pencils
void draw() {
  loadPixels();
  for(int i=0; i<pencils.size(); i++) {
    Pencil p = (Pencil)pencils.get(i);
    p.update();
    if (p.dead) {
      pencils.remove(i);
      i--; 
    }
  }
}

void mouseClicked() {
  if (mouseButton==RIGHT) {
    setup(); 
  } else {
    new_pencil(mouseX, mouseY);
  }
}

void keyReleased() {
  if (key=='d')
    debug = !debug;  
}

class Pencil {
  float x, y;               //current position
  
  boolean spiral = false;   //if spiral, no dir change and radius decreasing
  boolean dead = false;     //flag of dead pencils -> to be removed

  float angle = 0;          //angle of drawing
  int flower_sz = 3;        //width of a flower
  float rad = 1;            //radius of curve (?! whatever... some scalar value, not really radius)
  
  float delta_a = 0.05; //angle change unit per frame
  float delta_r = 0.01; //radius change unit
  
  //probabilities (tweak here)
  int direction_p = 20; //1/x chance to change direction
  int branch_p = 50;    //1/x chance to branch off
  int branch_lock = 20; //num of frames where branches are forbidden
  int flower_p = 50;    //1/x chance to draw a flower
  int spiral_p = 5;     //1/x chance to be initialized as a spiral
  
  //colors
  color clr = color(0); //color of line
  color flower_clr = color(0); //color of flowers
  
  //init colors and fill last directions
  Pencil() {
    clr = rand_green();
    flower_clr = rand_flower();
  }
  
  //random green tone
  color rand_green() {
    float gray = random(64);
    return color(gray, 128+random(128), gray); 
  }
  
  //green tone based on current one
  color rand_green(color base) {
    float gray = red(base);
    float g = green(base);
    g += random(20)-10;
    if (g<128)
      g=128;
    else if (g>255)
      g=255;
    return color(gray, g, gray);
  }
  
  //some random nice flower color
  color rand_flower() {
    int hasr = int(random(2));
    int hasg = int(random(2));
    int hasb = int(random(2));
    if (hasr==hasg && hasg==hasb)
      hasg = hasg==0 ? 1 : 0;
    return color(hasr*(192+random(64)),hasg*(128+random(128)),hasb*(192+random(64)));
  }
  
  //change direction to avert collision or kill yourself
  //TODO: prevent going in lines for long distances (ugly)
  //return: 1 for right, -1 for left, 0 -> undefined/die
  int decide() {
    //look borders
    float right = angle-PI/2;
    float left = angle+PI/2;

    //inner circle -> death
    for (float a = right; a<=left; a += abs(delta_a)) {
      int px = int(x+cos(a)*10);
      int py = int(y+sin(a)*10);
      if (px>=width || px<0 || py>=height || py<0 || pixels[py*width+px]!=color(255,255,255)) {
        dead = true;
        
        if (debug) {
          stroke(color(0)); noFill(); ellipse(px,py,3,3);
          stroke(color(255,0,0)); strokeWeight(1); ellipse(x,y,20,20);
          line(x,y,int(x+cos(right)*10), int(y+sin(right)*10));
          line(x,y,int(x+cos(angle)*10), int(y+sin(angle)*10));
          stroke(color(0,255,0));
          line(x,y,int(x+cos(left)*10), int(y+sin(left)*10));
          //println(left+","+right); println("dead");
        }
        
        return 0; 
      }
    }

    //outer circle -> avoid
    for (float a = right; a<=left; a += abs(delta_a)) {
      int px = int(x+cos(a)*rad*30);
      int py = int(y+sin(a)*rad*30);
      if (px>=width || px<0 || py>=height || py<0 || pixels[py*width+px]!=color(255,255,255)) {
        if (a<angle) //right part -> go left 
          if (delta_a>0) return 1;
          else return -2;
        else  //left part -> go right
          if (delta_a<0) return 1;
          else return -2;
      }
    }
   
    return int(random(4))*-1;
  }
  
  void update() {
    //draw new location
    clr = rand_green(clr);
    stroke(clr);
    
    if (debug)
      if (spiral)
        stroke(color(255,0,0));
        
    strokeWeight(2);
    float nx = x + cos(angle) * rad;
    float ny = y + sin(angle) * rad;
    line(x,y,nx,ny);
    x = nx;
    y = ny;
    
    //intelligent direction
    int d = decide();
    if (!spiral)
      angle += d*delta_a; 
    else
      angle += delta_a;
      
    //draw flower?
    if (int(random(flower_p))==0) {
      stroke(flower_clr);
      fill(flower_clr);
      ellipse(x+random(4)-2,y+random(4)-2,flower_sz,flower_sz);
    }
    
    if (spiral) { //just a spiral -> no more branches and fixed direction
      if (rad > 0)
        rad -= delta_r;
      else
        dead = true;
    } else {
      if (int(random(direction_p))==0) //turn?
        delta_a = -delta_a; 
      if (branch_lock==0 && int(random(branch_p)) == 0) { //branch off?
        Pencil q = new Pencil();
        q.x = x;
        q.y = y;
        q.angle = angle;
        q.delta_a = delta_a;
        q.clr = clr;
        q.flower_sz = int(random(3)+3);
        q.spiral = (int(random(spiral_p))==0) ? true : false;
        pencils.add(q);
      }
    }
    
    //branch lock countdown, preventing too many branches
    if (branch_lock > 0)
      branch_lock -= 1;
      
    if (x<0 || x>width || y<0 || y>height) //kill offscreen pencils
      dead=true;
  }
}

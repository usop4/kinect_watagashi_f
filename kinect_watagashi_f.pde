static final int SLOWNESS = 2;
static final int FALLING_RECTANGLE_WIDTH = 250;
static final int FALLING_RECTANGLE_WEIGHT = 20;
static final int FALLING_RECTANGLE_DEPTH = 40;

FallingRectangle[] fall = new FallingRectangle[50];
HumanRectangle hRct = new HumanRectangle();
int num;

// -----
// FallingRectangle
// -----

class FallingRectangle {
  int x;
  int y;
  int width = FALLING_RECTANGLE_WIDTH;
  int weight = FALLING_RECTANGLE_WEIGHT;
  color clr;
  String clrName;
  int hitCounter = 0;
  boolean isFlyingRight;
  boolean isFallingAroundYou = false;
  int getCounter = 0;

  FallingRectangle(int oldX) {
    y = 0;

    // xを決める
    int newX;
    do {
      newX = oldX + (int)random(200) - 100;
//      println("newX: " + newX); // for debug
    } while ( newX < 0 | 440 < newX | abs(newX - oldX) < 50);
    x = newX;

    switch((int)random(3)) {
      case 0: 
        clr = color(255, 0, 0);
        clrName = "red";
        break;
      case 1:
        clr = color(0, 255, 0);
        clrName = "green";
        break;
      case 2:
        clr = color(0, 0, 255);
        clrName = "blue";
        break;
      case 3:
        clr = color(0, 0, 255);
        clrName = "blue";
        break;
    }    
  }

  void update(HumanRectangle hRct) {
    //println("hitCounter= " + hitCounter + ",x= " + x + ",y= " + y);
    if (hitCounter > SLOWNESS * 2) 
    { // delete fall
      y = height + 100;
      if (isFlyingRight) x -= SLOWNESS * 10 * SLOWNESS * 2; // xを戻す
      else x += SLOWNESS * 10 * SLOWNESS * 2; // xを戻す
    }
    else if (hitCounter > 0) 
    { // fall flies away
      if (isFlyingRight) x += SLOWNESS * 10;
      else x -= SLOWNESS * 10;
      
      hitCounter ++;
    }
    else if (hRct.y <= y & y <= height) 
    { // y軸は範囲内で、かつ
      if (
      // fallがhRctの右側に引っかかっている
      hRct.x <= x & x <= hRct.x + hRct.width
      ) 
      {
        if (isFallingAroundYou) { // 内側から体が押した場合
          isFlyingRight = false;
          isFallingAroundYou = false;
        }
        else {isFlyingRight = true;} // 外側から体が押した場合
        hitCounter = 1; // 横へ飛び始める
      } else if (
      // fallがhRctの左側に引っかかっている
      hRct.x <= x + this.width & x + this.width <= hRct.x + hRct.width
      ) 
      {
        if (isFallingAroundYou) { // 内側から体が押した場合
          isFlyingRight = true;
          isFallingAroundYou = false;
        }
        else {isFlyingRight = false;} // 外側から体が押した場合
        hitCounter = 1; // 横へ飛び始める
      } else if (
      // 輪の中にうまく入った場合
      x <= hRct.x & hRct.x + hRct.width <= x + this.width
      ) 
      {
        isFallingAroundYou = true;
        y += SLOWNESS * 4; // x is OK
      }
    } 
    else 
    {
      y += SLOWNESS * 4; // x is OK
    }
  }

  void drawBack() {
    // 後ろ側の線分を描く
    stroke(clr);
    strokeWeight(weight);
    line(x, y, x + FALLING_RECTANGLE_DEPTH, y - FALLING_RECTANGLE_DEPTH); // 「／」
    line(x + FALLING_RECTANGLE_DEPTH, y - FALLING_RECTANGLE_DEPTH, 
      x + width - FALLING_RECTANGLE_DEPTH, y - FALLING_RECTANGLE_DEPTH); // 「―」
    line(x + width - FALLING_RECTANGLE_DEPTH, y - FALLING_RECTANGLE_DEPTH, 
      x + width, y); // 「＼」
  }

  void drawForward() {
    stroke(clr);
    strokeWeight(weight);
    line(x, y, x + width, y);
  }
  
  void drawScoringVE() {
    if ( getCounter < SLOWNESS * 2 ) {
      weight += SLOWNESS * 50;
      getCounter++;
      y = height;
    } else {
      isFallingAroundYou = false;
      getCounter = 0;
      y = height + 1;
      println("You get " + clrName + " !");
    }
  }    
}

class HumanRectangle {
  int x;
  int y;
  int width;
}

void setup()
{
  size(640, 480);
  background(0);
  num = 0;
  fall[num] = new FallingRectangle(width/2 - FALLING_RECTANGLE_WIDTH/2);

  hRct.width = 100;
  hRct.y = 200;
  hRct.x = width/2 - hRct.width/2;
}

void draw()
{
  // 一番下まで来たら上に戻す
  if (fall[num].y > height) {
    if ( fall[num].isFallingAroundYou ) {
      fall[num].drawScoringVE();
      return;
    }
    int oldX = fall[num].x;
    num++;
    if (num < 50) {
      fall[num] = new FallingRectangle(oldX);
    }
  }
  
  fall[num].update(hRct);

  // -----
  // 描画
  // -----
  background(0);
    
  // 後ろ側の線分を描く
  fall[num].drawBack();

  // 矩形を描く
  stroke(0, 0, 255);
  strokeWeight(0);
  rect(hRct.x, hRct.y, hRct.width, height - hRct.y);

  // 前側の線分を描く
  fall[num].drawForward();
}


void keyPressed() {
  switch(keyCode) {
    case RIGHT:
    hRct.x += 25;
    break;
    case LEFT:
    hRct.x -= 25;
    break;  
  }
}

// original
// author: weed
// https://gist.github.com/1862354

boolean isKinect = false;
boolean isArduino = false;
boolean isGamepad = true;//

// kinect関連

import SimpleOpenNI.*;
SimpleOpenNI  context;
PImage maskImg;
PImage maskedImg;

// arduino(firmata)関連

import processing.serial.*;
import cc.arduino.*;
Arduino arduino;

static final int RPIN = 13;
static final int GPIN = 12;
static final int BPIN = 11;

// gamepad関連

import procontroll.*;
import net.java.games.input.*; 

ControllIO cio;
ControllDevice gamepad;
ControllStick stick;

float transX;
float transY;

// Kinectを使うときは処理が遅くなるので4くらいが推奨

static final int SLOWNESS = 4; // original : 2
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
        if(isFallingAroundYou == false){
          if(isArduino){
            arduino.digitalWrite(RPIN,Arduino.HIGH);
          }
        }
        isFallingAroundYou = true;
        y += SLOWNESS * 4; // x is OK
      }
      else
      { 
        y += SLOWNESS * 4;
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
    if ( getCounter < (24 / SLOWNESS)) {
      weight += SLOWNESS * 50;
      getCounter++;
      y = height;
    } else {
      isFallingAroundYou = false;
      getCounter = 0;
      y = height + 1;
      println("You get " + clrName + " !");
      if(isArduino){
        arduino.digitalWrite(RPIN,Arduino.LOW);
        arduino.digitalWrite(GPIN,Arduino.LOW);
        arduino.digitalWrite(BPIN,Arduino.LOW);
      }
    }
  }    
}

class HumanRectangle {
  int x;
  int y;
  int width;
  

  void update() {
    if(isKinect){
      PVector jointLS = new PVector();
      context.getJointPositionSkeleton(1, SimpleOpenNI.SKEL_LEFT_SHOULDER,jointLS);
      PVector convertedJointLS = new PVector();
      context.convertRealWorldToProjective(jointLS, convertedJointLS);
      x = (int)convertedJointLS.x;
      y = (int)convertedJointLS.y; 
  
      PVector jointRS = new PVector();
      context.getJointPositionSkeleton(1, SimpleOpenNI.SKEL_RIGHT_SHOULDER,jointRS);
      PVector convertedJointRS = new PVector();
      context.convertRealWorldToProjective(jointRS, convertedJointRS);
      width = (int)convertedJointRS.x - x;
      
      //println("x= " + x + ", y= " + y + ", width= " + this.width);
    }
  }
}

void setup()
{
  if(isKinect){
    context = new SimpleOpenNI(this);
    
    context.setMirror(true);
    
    // enable depthMap generation 
    if(context.enableDepth() == false)
    {
       println("Can't open the depthMap, maybe the camera is not connected!"); 
       exit();
       return;
    }
    
    // 人物検出を有効にする
    context.enableScene();
     
    // enable skeleton generation for all joints
    context.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);
   
    // RGBカメラを有効にする
    if(context.enableRGB() == false)
    {
       println("Can't open the rgbMap, maybe the camera is not connected or there is no rgbSensor!"); 
       exit();
       return;
    }
  
    // 画像データと深度データの位置合わせをする
    context.alternativeViewPointDepthToImage();
  
    background(0);
  
    stroke(0,0,255);
    strokeWeight(3);
    smooth();
    
    size(context.depthWidth(), context.depthHeight()); 
  
  }
  else{
    size(640, 480);
    background(0);
  }

  num = 0;
  fall[num] = new FallingRectangle(width/2 - FALLING_RECTANGLE_WIDTH/2);

  if(isArduino){
    println(Arduino.list());
    arduino = new Arduino(this, Arduino.list()[0], 57600);  
    arduino.pinMode(RPIN, Arduino.OUTPUT);
    arduino.pinMode(GPIN, Arduino.OUTPUT);
    arduino.pinMode(BPIN, Arduino.OUTPUT);
  }

  if(isGamepad){
    cio = ControllIO.getInstance(this);
    gamepad = cio.getDevice(2);
    gamepad.plug(this,"RButtonPress",cio.ON_PRESS,0);
    gamepad.plug(this,"RButtonRelease",cio.ON_RELEASE,0);
    gamepad.plug(this,"GButtonPress",cio.ON_PRESS,2);
    gamepad.plug(this,"GButtonRelease",cio.ON_RELEASE,2);
    gamepad.plug(this,"BButtonPress",cio.ON_PRESS,3);
    gamepad.plug(this,"BButtonRelease",cio.ON_RELEASE,3);
    stick = gamepad.getStick(0);
    stick.setTolerance(0.1f);
    stick.setMultiplier(5.0f);
  }

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

  if(isGamepad){
    hRct.x = (int)stick.getTotalX();
  }
    
  if(isKinect){
    // update the cam
    context.update();
    
    maskImg = makeImgForMask(context.sceneImage());
  
    maskedImg = context.rgbImage(); // RGBカメラの映像がマスク対象
    maskedImg.mask(maskImg); // 人物の形で繰り抜いて
  
    // 矩形を更新する
    hRct.update();

  }

  fall[num].update(hRct);

  // -----
  // 描画
  // -----
  
  if(isKinect){
    image(context.depthImage(),0,0);
    // 後ろ側の線分を描く
    fall[num].drawBack();
  // とりあえずスケルトンを描画する
  // 最終的には背景をグレースケール、
  // 人物をフルカラーで描画したい
  // draw the skeleton if it's available
  //  stroke(128);
  //  strokeWeight(20);
    if(context.isTrackingSkeleton(1))
  //    drawSkeleton(1);
    image(maskedImg, 0, 0); // 表示する
    
  }else{
    background(0);
    // 後ろ側の線分を描く
    fall[num].drawBack();
    // 矩形を描く
    stroke(0, 0, 255);
    strokeWeight(0);
    rect(hRct.x, hRct.y, hRct.width, height - hRct.y);
  }
    
  // 前側の線分を描く
  fall[num].drawForward();
}

// draw the skeleton with the selected joints
void drawSkeleton(int userId)
{
  // to get the 3d joint data
  /*
  PVector jointPos = new PVector();
  context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_NECK,jointPos);
  println(jointPos);
  */
  
  context.drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);

  context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);

  context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);

  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);

  context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);

  context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);  
}

// -----------------------------------------------------------------
// SimpleOpenNI events

void onNewUser(int userId)
{
  println("onNewUser - userId: " + userId);
  println("  start pose detection");
  
  context.startPoseDetection("Psi",userId);
}

void onLostUser(int userId)
{
  println("onLostUser - userId: " + userId);
}

void onStartCalibration(int userId)
{
  println("onStartCalibration - userId: " + userId);
}

void onEndCalibration(int userId, boolean successfull)
{
  println("onEndCalibration - userId: " + userId + ", successfull: " + successfull);
  
  if (successfull) 
  { 
    println("  User calibrated !!!");
    context.startTrackingSkeleton(userId); 
  } 
  else 
  { 
    println("  Failed to calibrate user !!!");
    println("  Start pose detection");
    context.startPoseDetection("Psi",userId);
  }
}

void onStartPose(String pose,int userId)
{
  println("onStartPose - userId: " + userId + ", pose: " + pose);
  println(" stop pose detection");
  
  context.stopPoseDetection(userId); 
  context.requestCalibrationSkeleton(userId, true);
 
}

void onEndPose(String pose,int userId)
{
  println("onEndPose - userId: " + userId + ", pose: " + pose);
}

// 深度映像から人物だけを抜き出すようなマスク用画像を返す
PImage makeImgForMask(PImage img)
{
  color cBlack = color(0, 0, 0);
  color cWhite = color(255, 255, 255);

  for (int x = 0; x < img.width; x++)
  {
    for (int y = 0; y < img.height; y++) 
    {
      color c = img.get(x, y);
      // 人が写っていない白、灰色、黒はRGB値が同じ
      if (red(c) == green(c) & green(c) == blue(c)) 
      {
        img.set(x, y, cBlack); // 黒でマスクする
      }
      // 何らかの色が付いている部分は人が写っている
      else
      {
        img.set(x, y, cWhite); // 白で人の部分を残す
      }
    }
  }
  return img;
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

void RButtonPress(){
  if(isArduino){
    arduino.digitalWrite(RPIN,Arduino.HIGH);
  }
};
void RButtonRelease(){
  if(isArduino){
    arduino.digitalWrite(RPIN,Arduino.LOW);
  }
};

void GButtonPress(){
  if(isArduino){
    arduino.digitalWrite(GPIN,Arduino.HIGH);
  }
};
void GButtonRelease(){
  if(isArduino){
    arduino.digitalWrite(GPIN,Arduino.LOW);
  }
};

void BButtonPress(){
  if(isArduino){
    arduino.digitalWrite(BPIN,Arduino.HIGH);
  }
};
void BButtonRelease(){
  if(isArduino){
    arduino.digitalWrite(BPIN,Arduino.LOW);
  }
};

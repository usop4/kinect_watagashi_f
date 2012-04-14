// original
// author: weed
// https://gist.github.com/1862354

boolean isKinect = false;
boolean isArduino = true;
boolean isGamepad = true;//

// kinect関連

import SimpleOpenNI.*;
SimpleOpenNI  context;
PImage maskImg;
PImage maskedImg;

// arduino(firmata)関連
// on Arduino use SimpleDigitalFirmata.pde

import processing.serial.*;
import cc.arduino.*;
Arduino arduino;

static final int RPIN = 12;
static final int GPIN = 11;
static final int BPIN = 10;

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
static final int FALLING_RECTANGLE_NUMBER = 10;

FallingRectangle[] fall = new FallingRectangle[FALLING_RECTANGLE_NUMBER];
HumanRectangle hRct = new HumanRectangle();
int num;

// around Opening

int phase;
static final int PHASE_WAITING = 10;
static final int PHASE_INITIALIZING = 20;
static final int PHASE_FINDING_USER = 25;
static final int PHASE_CALIBRATING = 30;
static final int PHASE_MUSIC_START = 35;
static final int PHASE_BEFORE_PLAY = 37;
static final int PHASE_PLAYING = 40;
static final int PHASE_MUSIC_END = 45;
static final int PHASE_AFTER_PLAY1 = 50;
static final int PHASE_AFTER_PLAY2 = 60;

PImage calibImg;
int frame = 0;
PFont font;
int currentUserId = 1;
int VeTime = 24;

// Around Waiting

int rectX, rectY;      // Position of square button
int rectHeight = 100;     // Diameter of rect
int rectWidth = 200;     // Diameter of rect
color rectColor, circleColor, baseColor;
color rectHighlight, circleHighlight;
color currentColor;
boolean rectOver = false;
color colorBefore;

// around Music

//import ddf.minim.*;
//AudioPlayer player;
//Minim minim;

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
      if(isArduino){
        arduino.digitalWrite(RPIN,Arduino.LOW);
        arduino.digitalWrite(GPIN,Arduino.LOW);
        arduino.digitalWrite(BPIN,Arduino.LOW);
      }
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
            if(clrName == "red"){
              arduino.digitalWrite(RPIN,Arduino.HIGH);
            }
            if(clrName == "green"){
              arduino.digitalWrite(GPIN,Arduino.HIGH);
            }
            if(clrName == "blue"){
              arduino.digitalWrite(BPIN,Arduino.HIGH);
            }
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
  
  void drawScoringVE(boolean isHandUp) {
    if ( getCounter < (18 / SLOWNESS)) {
      weight += SLOWNESS * 50;
      getCounter++;
      y = height;
    } else if (isHandUp && getCounter < (36 / SLOWNESS)) {
      colorBefore = clr;
      clr = color(255, 255, 255);
      weight += SLOWNESS * 50;
      getCounter++;
      y = height;
    } else if (isHandUp && getCounter < (54 / SLOWNESS)) {
      clr = colorBefore;
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
  int ry;
  int ly;
  int width;

  void update() {
    if(isKinect){
      PVector jointLS = new PVector();
      context.getJointPositionSkeleton(currentUserId, SimpleOpenNI.SKEL_LEFT_SHOULDER,jointLS);
      PVector convertedJointLS = new PVector();
      context.convertRealWorldToProjective(jointLS, convertedJointLS);
      x = (int)convertedJointLS.x;
      y = (int)convertedJointLS.y; 
  
      PVector jointRS = new PVector();
      context.getJointPositionSkeleton(currentUserId, SimpleOpenNI.SKEL_RIGHT_SHOULDER,jointRS);
      PVector convertedJointRS = new PVector();
      context.convertRealWorldToProjective(jointRS, convertedJointRS);
      width = (int)convertedJointRS.x - x;
      
      PVector jointRH = new PVector();
      context.getJointPositionSkeleton(currentUserId, SimpleOpenNI.SKEL_RIGHT_HAND,jointRH);
      PVector convertedJointRH = new PVector();
      context.convertRealWorldToProjective(jointRH, convertedJointRH);
      ry = (int)convertedJointRH.y;

      PVector jointLH = new PVector();
      context.getJointPositionSkeleton(currentUserId, SimpleOpenNI.SKEL_LEFT_HAND,jointLH);
      PVector convertedJointLH = new PVector();
      context.convertRealWorldToProjective(jointLH, convertedJointLH);
      ly = (int)convertedJointLH.y;
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
    arduino.digitalWrite(RPIN,Arduino.LOW);
    arduino.digitalWrite(GPIN,Arduino.LOW);
    arduino.digitalWrite(BPIN,Arduino.LOW);
  }

  if(isGamepad){
    cio = ControllIO.getInstance(this);
    cio.printDevices();
    gamepad = cio.getDevice(3);
    //gamepadのボタンに機能を割り当てる
    gamepad.plug(this,"RButtonPress",cio.ON_PRESS,0);
    gamepad.plug(this,"RButtonRelease",cio.ON_RELEASE,0);
    gamepad.plug(this,"GButtonRelease",cio.ON_RELEASE,3);
    gamepad.plug(this,"BButtonPress",cio.ON_PRESS,2);
    gamepad.plug(this,"BButtonRelease",cio.ON_RELEASE,2);
    //十字キーの挙動を設定する
    stick = gamepad.getStick(0);
    stick.setTolerance(0.1f);
    stick.setMultiplier(5.0f);
  }

  hRct.width = 100;
  hRct.y = 300;// original:200
  hRct.x = width/2 - hRct.width/2;

  // Around Waiting
  rectColor = color(0);
  rectHighlight = color(51);
  baseColor = color(102);
  currentColor = baseColor;
  rectX = width/2-rectWidth/2;
  rectY = height/2-rectHeight/2;

  // Around Opening
  calibImg = loadImage("calibration-pose.png");
  font = loadFont("Osaka-48.vlw");
  textFont(font, 32);
  
  // around Music
//  minim = new Minim(this);
//  player = minim.loadFile("120412-KinectBGM.mp3", 2048);
  
  phase = PHASE_WAITING;
//  if (isKinect) {
//    phase = PHASE_INITIALIZING;
//  } else {
//    phase = PHASE_MUSIC_START;
//  }
}

void draw()
{
  if (phase == PHASE_WAITING) {
    updateMouse(mouseX, mouseY);
    background(currentColor);
    
    if(rectOver) {
      fill(rectHighlight);
    } else {
      fill(rectColor);
    }
    stroke(0, 0, 255);
    strokeWeight(0);
    stroke(255);
    rect(rectX, rectY, rectWidth, rectHeight);
    fill(255);
    text("はじめます", rectX + 20, rectY + 65);
  } 
  else if (phase == PHASE_INITIALIZING) 
  {
    background(0);
    fill(230, 0, 130);
    text("おまちください", rectX , rectY + 65);
    phase = PHASE_FINDING_USER;
  } 
  else if (phase == PHASE_FINDING_USER) 
  {
    if(isKinect){
      context.update();
      image(context.depthImage(),0,0);
      fill(0);
      text("おまちください", rectX + 2 , rectY + 67);
      fill(230, 0, 130);
      text("おまちください", rectX , rectY + 65);
    }
  } 
  else if (phase == PHASE_CALIBRATING) 
  {
    if(isKinect){
      context.update();
      image(context.depthImage(),0,0);
      // 1 second is 60 frames
      if (frame % 60 < 30) {
        image(calibImg, 200, 50);
      } 
      frame++;
      fill(0);
      text("りょうて　ちからこぶの　ポーズ", rectX - 148 , rectY + 67);
      fill(230, 0, 130);
      text("りょうて　ちからこぶの　ポーズ", rectX - 150 , rectY + 65);
    }
  } 
  else if (phase == PHASE_MUSIC_START)
  {
    player.play();
//    phase = PHASE_BEFORE_PLAY;
    phase = PHASE_PLAYING;
  }
  else if (phase == PHASE_BEFORE_PLAY)
  {
    if(isKinect){
      // update the cam
      context.update();
      image(context.depthImage(),0,0);
      
      maskImg = makeImgForMask(context.sceneImage());
    
      maskedImg = context.rgbImage(); // RGBカメラの映像がマスク対象
      maskedImg.mask(maskImg); // 人物の形で繰り抜いて
      image(maskedImg, 0, 0); // 表示する
    } else {
      background(0);
      if(isGamepad){
        hRct.x = (int)stick.getTotalX();
      }
      rect(hRct.x, hRct.y, hRct.width, height - hRct.y);
    }
    
    frame++;
    if (frame >= 600 / SLOWNESS) {
      phase = PHASE_PLAYING;
      frame = 0;
    }
  }
  else if (phase == PHASE_PLAYING) 
  {
    // 一番下まで来たら上に戻す
    if (fall[num].y > height) {
      if ( fall[num].isFallingAroundYou ) {
        if (hRct.y > hRct.ry && hRct.y > hRct.ly) { // Hands Up !!!
          fall[num].drawScoringVE(true);
        }
        else // Normal
        {
        fall[num].drawScoringVE(false);
        }
        return;
      }
      int oldX = fall[num].x;
      num++;
      fall[num] = new FallingRectangle(oldX);
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
    
      hRct.update();          // 矩形を更新する
  
    }
  
    if (num >= FALLING_RECTANGLE_NUMBER - 1) {
      num = 0;
      phase = PHASE_MUSIC_END;
      frame = 0;
      return;
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
      if(context.isTrackingSkeleton(currentUserId))
    //    drawSkeleton(1);
      image(maskedImg, 0, 0); // 表示する
      
    } else {
      background(0);
      // 後ろ側の線分を描く
      fall[num].drawBack();
      // 矩形を描く
      stroke(0, 0, 255);
      strokeWeight(0);
      fill(255, 255, 255);
      rect(hRct.x, hRct.y, hRct.width, height - hRct.y);
    }
      
    // 前側の線分を描く
    fall[num].drawForward();
    
  } 
  else if (phase == PHASE_MUSIC_END) 
  {  
//    player.setVolume(0.5); 
//    player.close();
//    minim.stop();
    
    if (isKinect) {
      phase = PHASE_AFTER_PLAY1;
    } else {
      phase = PHASE_AFTER_PLAY2;
    }
  }
  else if (phase == PHASE_AFTER_PLAY1) 
  {
    // update the cam
    context.update();
    image(context.depthImage(),0,0);
    fill(0);
    text("おつかれさまでした", rectX - 48 , rectY + 67);
    fill(230, 0, 130);
    text("おつかれさまでした", rectX - 50 , rectY + 65);
    // 1 second is 60 frames
    frame++;
    if (frame >= 600 / SLOWNESS) {
      phase = PHASE_AFTER_PLAY2;
      frame = 0;
    }
  } 
  else if (phase == PHASE_AFTER_PLAY2) 
  {
    background(0);
    fill(230, 0, 130);
    text("おつかれさまでした", rectX - 50 , rectY + 65);
    // 1 second is 60 frames
    frame++;
    if (frame >= 300) {
      phase = PHASE_WAITING;
      frame = 0;
    }
  }
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
  
  println("currentUserId: " + currentUserId);
  phase = PHASE_CALIBRATING;
}

void onLostUser(int userId)
{
  println("onLostUser - userId: " + userId);
  if ( userId == currentUserId ) {
    phase = PHASE_INITIALIZING;
    println("userId is currentUserId: " + currentUserId);
  } else {
    println("userId is not currentId: " + currentUserId);
  }
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
    currentUserId = userId;
    phase = PHASE_MUSIC_START;
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
    arduino.digitalWrite(GPIN,Arduino.LOW);
    arduino.digitalWrite(BPIN,Arduino.LOW);
  }
};

void GButtonPress(){
  if(isArduino){
    arduino.digitalWrite(GPIN,Arduino.HIGH);
  }
};
void GButtonRelease(){
  if(isArduino){
    arduino.digitalWrite(RPIN,Arduino.LOW);
    arduino.digitalWrite(GPIN,Arduino.LOW);
    arduino.digitalWrite(BPIN,Arduino.LOW);
  }
};

void BButtonPress(){
  if(isArduino){
    arduino.digitalWrite(BPIN,Arduino.HIGH);
  }
};
void BButtonRelease(){
  if(isArduino){
    arduino.digitalWrite(RPIN,Arduino.LOW);
    arduino.digitalWrite(GPIN,Arduino.LOW);
    arduino.digitalWrite(BPIN,Arduino.LOW);
  }
};

void updateMouse(int x, int y)
{
  if ( overRect(rectX, rectY, rectWidth, rectHeight) ) {
    rectOver = true;
  } else {
    rectOver = false;
  }
}

void mousePressed()
{
  if(rectOver) {
    if(isKinect) {
      phase = PHASE_INITIALIZING;
    } else {
      phase = PHASE_MUSIC_START;
    }
  }
}

boolean overRect(int x, int y, int width, int height) 
{
  if (mouseX >= x && mouseX <= x+width && 
      mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}


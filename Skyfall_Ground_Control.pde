// import libraries
import java.awt.Frame;
import java.awt.BorderLayout;
import controlP5.*; // http://www.sojamo.de/libraries/controlP5/
import processing.serial.*;
import processing.sound.*;

/* SETTINGS BEGIN */

// Serial port to connect to
String serialPortName = "/dev/tty.usbmodem1411";

// If you want to debug the plotter without using a real serial port set this to true
boolean mockupSerial = true;

/* SETTINGS END */

Serial serialPort;// Serial port object
SoundFile countdown;

// interface stuff
ControlP5 cp5;
Button launchButton;
Textfield securityCode;
Button Pray;
Button Abort;



// Settings for the plotter are saved in this file
JSONObject plotterConfigJSON;
float angle = 0;
PShape Skyfall;
PFont font,font1;
PGraphics canvas3D;


int x = 100;
int y = 200;
int SizeX = 1920;
int SizeY = 1080;
int scale = 10;
int add = 100;
int speed = 100;
int millisecs;
int seconds;
int minutes;
int GCT;
int altitudeMax;
int abortTime;
int timeLeft = 10;

boolean start = false;
boolean clicked = false;
boolean RightCode = false;
boolean aborted = false;
boolean launched = false;
boolean connectionFailed;
boolean starter;
float valueY;

// plots
Graph Altitude = new Graph(0,int(SizeY*0.24), int(SizeX*0.2), int(SizeY*0.36), color (20, 20, 200));
Graph Rotation = new Graph(0,int(SizeY*0.6), int(SizeX*0.2), int(SizeY*0.36), color (20, 20, 200));
Graph OrientationX = new Graph(int(SizeX*0.1),0, int(SizeX*0.2), int(SizeY*0.24), color (20, 20, 200));
Graph OrientationY = new Graph(int(SizeX*0.3),0, int(SizeX*0.2), int(SizeY*0.24), color (20, 20, 200));
Graph OrientationZ = new Graph(int(SizeX*0.5),0, int(SizeX*0.2), int(SizeY*0.24), color (20, 20, 200));

float [] x1 = new float[100];
float [] AltitudeY = new float [100];
float [][] RotationY = new float [3][100];
float [] OrientationxY = new float [100];
float [] OrientationyY = new float [100];
float [] OrientationzY = new float [100];

float[] barChartValues = new float[6];
float[][] AltitudeValues = new float[1][1000];
float[] AltitudeSampleNumbers = new float[1000];
color[] graphColors = new color[6];



// helper for saving the executing path
String topSketchPath = "";
String code = "1402";

void settings() {
  size(SizeX, SizeY, P3D);//define the size of the window

}

void setup() {
  
  cp5 = new ControlP5(this);
  surface.setTitle("Skyfall Ground Control");//create the title of the window
  surface.setResizable(true);//define as non-resizable
  surface.setLocation(0,0);//define the loading location of the window
  background(0);
  font = createFont("CircularStd-Book.otf",30);
  font1 = createFont("CircularStd-Book.otf",15);
  
  
  
    
  for (int i=0; i<x1.length; i++)
      {
        x1[i] = i;
        AltitudeY[i] = 10;
        //AltitudeY[i] = random(-10,10);
        
      }
  
  // set line graph colors
  graphColors[0] = color(131, 255, 20);
  graphColors[1] = color(232, 158, 12);
  graphColors[2] = color(255, 0, 0);
  graphColors[3] = color(62, 12, 232);
  graphColors[4] = color(13, 255, 243);
  graphColors[5] = color(200, 46, 232);

  // settings save file
  topSketchPath = sketchPath();
  plotterConfigJSON = loadJSONObject(topSketchPath+"/plotter_config.json");

  // gui
  
  launchButton = cp5.addButton("Launch")
      .setPosition(0.785*width,0.33*height)
      .setSize(int(0.22*width-5),int(0.1*height))
      .setColorBackground(color(179,192,164))
      .setColorForeground(color(209,222,194))
      .setColorActive(color(50,50,50))
      .setColorLabel(color(80,81,104))
      .setFont(font);

  
  // init charts
  setChartSettings();

  
 
  
  // start serial communication
    if (!mockupSerial) {
    //String serialPortName = Serial.list()[3];
    serialPort = new Serial(this, serialPortName, 115200);
  }
  else
    serialPort = null;

  // build the gui

  
  canvas3D = createGraphics(int(width), int(height), P3D);//create a graphic area for the 3D model
  //load 3D model, resize and rotate
  Skyfall = loadShape("Skyfall.obj");
  Skyfall.scale(0.3,0.3,0.3);
  Skyfall.rotateX(PI);
  countdown = new SoundFile(this, "countdown.MP3");
}

byte[] inBuffer = new byte[100]; // holds serial message
int i = 0; // loop variable


void draw() {
  
    background(0);
  /* Read serial and update values */
    if (mockupSerial || serialPort.available() > 0) {
      String myString = "";
      if (!mockupSerial) {
        try {
        serialPort.readBytesUntil('\r', inBuffer);
            }
        catch (Exception e) {
        }
        myString = new String(inBuffer);
        }
      else {
     AltitudeY[AltitudeY.length-1] = AltitudeY[AltitudeY.length-1]+random(-10,10);
    //for (int i = 0; i < RotationY.length; i++){
    for(int k=0; k<RotationY.length; k++){
    RotationY[k][RotationY[k].length-1] = RotationY[k][RotationY[k].length-1]+random(-1,1);
    //printArray(RotationY[k]);
    }
     //   }

    OrientationxY[OrientationxY.length-1] = OrientationxY[OrientationxY.length-1]+random(-1,1);
    OrientationyY[OrientationyY.length-1] = OrientationyY[OrientationyY.length-1]+random(-1,1);
    OrientationzY[OrientationyY.length-1] = OrientationzY[OrientationzY.length-1]+random(-1,1);
        myString = mockupSerialFunction();
           }
     if(altitudeMax < int(max(AltitudeY)))
     {altitudeMax = int(max(AltitudeY));
   }
     textFont(font);
    textSize(20);smooth();
    textAlign(CENTER);
    text("Alt. max : " + str(altitudeMax)+" m",0.0625*width,0.297*height);    

    //println(myString);

    // split the string at delimiter (space)
    String[] nums = split(myString, ' ');
  
    
    GCT = millis();
    int s = second();  
    int m = minute();  
    int h = hour(); 
    
    //textSize(30);
    textFont(font);
    textSize(40);smooth();
    textAlign(CENTER);
    text("SkyFall",0.895*width,50);
    textSize(25);
    textAlign(CENTER);
    text("Ground Control",0.895*width,80);
    textSize(20);
    textAlign(CENTER);
    text("CLT"+" : " + str(h)+":"+str(m)+":"+str(s)+" CT",0.895*width,120);
    
    if (GCT/100  % 10 != millisecs){
    millisecs++;
    }
    if (millisecs >= 10){
    millisecs -= 10;
    seconds++;
    }
    if (seconds >= 60){
    seconds -= 60;
    minutes++;
    }
    textSize(20);
    textAlign(CENTER);
    text("CLT"+" : " + nf(minutes, 2) + ":" + nf(seconds, 2) + "." + nf(millisecs, 1) ,0.895*width,150);



    setChartSettings();
  
  canvas3D.beginDraw();
  canvas3D.background(0);
  //canvas3D.setSize(int(width*0.25), int(height*0.6));
  canvas3D.translate(width*0.25, height*0.6);
  //canvas3D.rotateX(xangle/(PI/180)/1000);
  //canvas3D.rotateY(yangle/(PI/180)/1000);
  //canvas3D.rotateZ(/(PI/180));
  canvas3D.rotateX((OrientationxY[OrientationxY.length-1]*PI)/180);
  canvas3D.rotateY((OrientationyY[OrientationyY.length-1]*PI)/180);
  canvas3D.rotateZ((OrientationzY[OrientationzY.length-1]*PI)/180);
  canvas3D.shape(Skyfall);
  canvas3D.endDraw();
  pushMatrix();
  image(canvas3D, width*0.2, height*0.24);
  
  
  popMatrix();
  stroke(100);     //stroke color
  strokeWeight(10);   
  


    
    // count number of bars and line graphs to hide
    int numberOfInvisibleBars = 0;
    for (i=0; i<6; i++) {
      if (int(getPlotterConfigString("bcVisible"+(i+1))) == 0) {
        numberOfInvisibleBars++;
      }
    }
    int numberOfInvisibleAltitudes = 0;
    for (i=0; i<6; i++) {
      if (int(getPlotterConfigString("lgVisible"+(i+1))) == 0) {
        numberOfInvisibleAltitudes++;
      }
    }
    // build a new array to fit the data to show
    barChartValues = new float[6-numberOfInvisibleBars];

    // build the arrays for bar charts and line graphs
    int barchartIndex = 0;
    for (i=0; i<nums.length; i++) {

      // update barchart
      try {
        if (int(getPlotterConfigString("bcVisible"+(i+1))) == 1) {
          if (barchartIndex < barChartValues.length)
            barChartValues[barchartIndex++] = float(nums[i])*float(getPlotterConfigString("bcMultiplier"+(i+1)));
        }
        else {
        }
      }
      catch (Exception e) {
      }

      // update line graph
      try {
        if (i<AltitudeValues.length) {
          for (int k=0; k<AltitudeValues[i].length-1; k++) {
            AltitudeValues[i][k] = AltitudeValues[i][k+1];
          }

          AltitudeValues[i][AltitudeValues[i].length-1] = float(nums[i])*float(getPlotterConfigString("lgMultiplier"+(i+1)));
        }
      }
      catch (Exception e) {
      }
    }
  }


  // draw the line graphs
  
  //Graph.Altitude(0,0,100,100,color (20, 20, 200));
 
  Altitude.DrawAxis();
  for (int i=0;i<AltitudeValues.length; i++) {
    //Altitude.yMin=int(min(AltitudeY)); 
    //Altitude.yMax=int(max(AltitudeY)); 
    Altitude.GraphColor = graphColors[i];
    if (int(getPlotterConfigString("lgVisible"+(i+1))) == 1)
      Altitude.Altitude(x1, AltitudeY);
    
  }
 Rotation.DrawAxis();
  for (int i=0;i<RotationY.length; i++) {
    Rotation.GraphColor = graphColors[i];
      Rotation.Rotation(x1, RotationY[i]);
     
  }
  
  OrientationX.DrawAxis();
  for (int i=0;i<AltitudeValues.length; i++) {
    OrientationX.GraphColor = graphColors[i];
    if (int(getPlotterConfigString("lgVisible"+(i+1))) == 1)
      OrientationX.OrientationX(x1, OrientationxY);
     
  }
  
  OrientationY.DrawAxis();
  for (int i=0;i<AltitudeValues.length; i++) {
    OrientationY.GraphColor = graphColors[i];
    if (int(getPlotterConfigString("lgVisible"+(i+1))) == 1)
      OrientationY.OrientationY(x1, OrientationyY);
     
  }
  
  OrientationZ.DrawAxis();
  for (int i=0;i<AltitudeValues.length; i++) {
    OrientationZ.GraphColor = graphColors[i];
    if (int(getPlotterConfigString("lgVisible"+(i+1))) == 1)
      OrientationZ.OrientationZ(x1, OrientationzY);
     
  }
        
    if(RightCode){
     Pray.remove();
     securityCode.remove();
     launchButton.remove();
      if (int(millis()/100)  % 10 != abortTime && launched==false){
      abortTime++;
      println(abortTime);
      }
      if (abortTime >= 10){
      abortTime -= 10;
      timeLeft = timeLeft-1;
      Abort.setLabel("Abort : " + str(timeLeft));
      }
      if(timeLeft == 0){
        launched = true;
        Abort.remove();
        rectMode(CORNER);fill(color(197,222,205));noStroke();
        rect(0.785*width,0.33*height,0.22*width-5,0.1*height);
         fill(color(80,81,104));textFont(font);
        textAlign(CENTER, CENTER);
        text("LAUNCHED",0.895*width,0.38*height); 
    
        
      }
     
    }
     else{
     launchButton.setPosition(0.785*width,0.33*height)
                .setSize(int(0.22*width-5),int(0.1*height))
                .listenerSize();
     }
     
    if(aborted){
   
    rectMode(CORNER);fill(color(154,3,30));noStroke();
    rect(0.785*width,0.33*height,0.22*width-5,0.1*height);
     fill(color(80,81,104));textFont(font);
    textAlign(CENTER, CENTER);
    text("ABORTED",0.895*width,0.38*height); 
    noLoop();
    
    }

   
}
// called each time the chart settings are changed by the user 
void setChartSettings() {
  
  if (int(max(AltitudeY))<0){
           Altitude.yMin=int((min(AltitudeY))); 
           Altitude.yMax=int(0);
          }
          else if (int(min(AltitudeY))>0){
           Altitude.yMin= 0; 
           Altitude.yMax=int((max(AltitudeY)));
          }
          else{
          Altitude.yMin=int(1.5*min(AltitudeY)); 
           Altitude.yMax=int(1.5*max(AltitudeY));
          }
          
 if (int(max(OrientationxY))<0){
           OrientationX.yMin=int((min(OrientationxY))); 
           OrientationX.yMax=int(0);
          }
          else if (int(min(OrientationxY))>0){
           OrientationX.yMin= 0; 
           OrientationX.yMax=int((max(OrientationxY)));
          }
          else{
          OrientationX.yMin=int(1.5*min(OrientationxY)); 
           OrientationX.yMax=int(1.5*max(OrientationxY));
          }
          
if (int(max(OrientationyY))<0){
           OrientationY.yMin=int((min(OrientationyY))); 
           OrientationY.yMax=int(0);
          }
          else if (int(min(OrientationyY))>0){
           OrientationY.yMin= 0; 
           OrientationY.yMax=int((max(OrientationyY)));
          }
          else{
          OrientationY.yMin=int(1.5*min(OrientationyY)); 
           OrientationY.yMax=int(1.5*max(OrientationyY));
          }
          
if (int(max(OrientationzY))<0){
           OrientationZ.yMin=int((min(OrientationzY))); 
           OrientationZ.yMax=int(0);
          }
          else if (int(min(OrientationzY))>0){
           OrientationZ.yMin= 0; 
           OrientationZ.yMax=int((max(OrientationzY)));
          }
          else{
          OrientationZ.yMin=int(1.5*min(OrientationzY)); 
           OrientationZ.yMax=int(1.5*max(OrientationzY));
          }
  Altitude.xLabel=" Time ";
  Altitude.yLabel="Altitude";
  Altitude.Title="Altitude";  
  Altitude.yDiv = 10;
  Altitude.xDiv=6;  
  Altitude.xMax=0; 
  Altitude.xMin=-100; 
  Altitude.xPos=0;
  Altitude.yPos=int(height*0.33);
  Altitude.Width=int(width*0.25);
  Altitude.Height=int(height*0.33);
  //Altitude.yMin=int(min(AltitudeY)); 
  //Altitude.yMax=int(max(AltitudeY)); 

  //Altitude.yMin = -1000;
  //Altitude.yMax = 1000;
  
  //Altitude.yMin=int(min(AltitudeY));
  
  
  Rotation.xLabel=" Time ";
  Rotation.yLabel="Rotation";
  Rotation.Title="Rotation";  
  Rotation.yDiv = 10;
  Rotation.xDiv=6;  
  Rotation.xMax=0; 
  Rotation.yMax=100;
  Rotation.yMin=-100;
  Rotation.xMin=-100; 
  Rotation.xPos=0;
  Rotation.yPos=int(height*0.66);
  Rotation.Width=int(width*0.25);
  Rotation.Height=int(height*0.33);

  OrientationX.yLabel="Orientation X";
  OrientationX.Title="Orientation";  
  OrientationX.yDiv = 10;
  OrientationX.xDiv=6;  
  OrientationX.xMax=100; 
  OrientationX.xMin=0; 
  OrientationX.xPos=int(width*0.125);
  OrientationX.yPos=0;
  OrientationX.Width=int(width*0.22);
  OrientationX.Height=int(height*0.33);

  
  OrientationY.yLabel="Orientation Y";
  OrientationY.Title="Orientation";  
  OrientationY.yDiv = 10;
  OrientationY.xDiv=6;  
  OrientationY.xMax=0; 
  OrientationY.xMin=-100; 
  OrientationY.xPos=int(width*0.345);
  OrientationY.yPos=0;
  OrientationY.Width=int(width*0.22);
  OrientationY.Height=int(height*0.33);

  
  OrientationZ.yLabel="Orientation Y";
  OrientationZ.Title="Orientation";  
  OrientationZ.yDiv = 10;
  OrientationZ.xDiv=6;  
  OrientationZ.xMax=0; 
  OrientationZ.xMin=-100; 
  OrientationZ.xPos=int(width*0.565);
  OrientationZ.yPos=0;
  OrientationZ.Width=int(width*0.22);
  OrientationZ.Height=int(height*0.33);

 

}

// handle gui actions
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isAssignableFrom(Textfield.class) || theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class)) {
    String parameter = theEvent.getName();
    String value = "";
    if (theEvent.isAssignableFrom(Textfield.class))
      value = theEvent.getStringValue();
    else if (theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class))
      value = theEvent.getValue()+"";

    plotterConfigJSON.setString(parameter, value);
    saveJSONObject(plotterConfigJSON, topSketchPath+"/plotter_config.json");
  }
  setChartSettings();
}

// get gui settings from settings file
String getPlotterConfigString(String id) {
  String r = "";
  try {
    r = plotterConfigJSON.getString(id);
  } 
  catch (Exception e) {
    r = "";
  }
  return r;
}

void Launch(){
    println("clicked");
    
      if (clicked && aborted == false){
      
      securityCode.remove();
      Pray.remove();
      clicked=false;
      launchButton.setLabel("Launch").setColorBackground(color(179,192,164)).setColorForeground(color(209,222,194));
      }
      else{
       securityCode = cp5.addTextfield("Security Code")
      .setPosition(0.785*width,0.43*height)
      .setSize(int(0.15*width),int(0.05*height))
      //.setColorBackground( color( 255,255,255 ) )
      .setFont(font1);
      //.setLabel("");
     Pray = cp5.addButton("Pray")
      .setPosition(0.935*width,0.43*height)
      .setSize(int(0.065*width-5),int(0.05*height))
      .setColorBackground( color( 80,81,104 ) )
      .setFont(font1);
      launchButton.setLabel("Cancel").setColorBackground(color(220,196,142)).setColorForeground(color(250,226,172));
      clicked=true;
      
      }
    }
    
void Pray(){
    
    String tryCode = cp5.get(Textfield.class,"Security Code").getText();
    
    if(tryCode.equals(code) && aborted == false){
      Abort = cp5.addButton("Abort")
      .setPosition(0.785*width,0.33*height)
      .setSize(int(0.22*width-5),int(0.1*height))
      .setColorBackground(color(154,3,30))
      .setColorForeground(color(184,33,60))
      .setColorActive(color(50,50,50))
      .setColorLabel(color(80,81,104))
      .setFont(font);
                 
                 
      println("Code OK");
      RightCode = true;
      println("Launch in 10s");
      countdown.play();
      
      println(tryCode);
     
        
    }
    
    }
    
    
void Abort(){
    aborted = true;
    countdown.stop();
    Abort.remove();
    }

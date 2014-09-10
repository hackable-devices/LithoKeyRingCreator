/***********************/
/* LithoKeyRingCreator */
/***********************/

/* Basé sur le logiciel image2stl de Joel Belouet */

/* Version spécifique pour CKAB */
/* Joel Belouet http://joel.belouet.free.fr/ */
/* Cyril Chapellier http://tchap.me */

/* Mouse Controls to rotate the shape and zoom */
/* KeyBoar Controls : UP/DOWN/LEFT/RIGHT keys to rotate the shape */
/*                    SPACEBAR to generate the .stl */

import processing.opengl.*;
import controlP5.*;
import unlekker.data.*;

ControlP5 controlP5; // controls object
PImage img ; // image object

// Toggles
boolean record;
boolean choooseExportFile = false;
boolean messageExport = false;
boolean capture;
boolean inverse;
boolean square = true;
boolean scaleDown = true;
boolean blur;

// Anchor for keyring
boolean keyring = true;
float L = 10; // half-width of keyring
float e = 2; // width or ring
int def = 16; // number of points on inner circle
float[][] innerPoints;
float[][] outerPoints;

// 3D Camera stuff
float rotY = 45, rotX = 0 ;
float rotYT, rotXT = 30 ;
float zoom = 5;

/// Pixel Ratio
int px_ratio = 4; // 5px ==> 1 mm

// Offset
float offset = 10;
int resX ;
int resY ;

float[][] val ; 
float max_val; float min_val;
boolean preloaded = false ;
float hauteur = 100 ;
String filename = "example.jpg" ; // Must be in "/data"
String export_filename = "example.stl" ; // Must be in "/data"
boolean showGrid = true ;

// Gaussian blur kernel
float v = 1.0 / 9.5;
float[][] kernel = {{ v, v, v }, 
                    { v, v, v }, 
                    { v, v, v }};
                    
// Faces resolution (in pixels => 2 vertices on an axis equals the width of one pixel)           
int size_image = 202;

// For the render loop
boolean for_STL;
float display_ratio;
float display_pixel_ratio;
float real_offset;
int x_min;
int x_max;
int y_min;
int y_max;
float point1, point2, point3, point4;
int current_color;
float real_e;
float real_L;
float unit_angle;
float angle;
      
// For Video capture      
import processing.video.*;
Capture cam;
String[] cameras;
boolean list_cameras_done = false;
boolean capture_ready;
boolean capture_do;
PImage capturedImg;

void setup() {
  size(displayWidth, displayHeight, P3D); // Inits OpenGL
  makeControls(); // Creates all controls on screen (defined in controls.pde)
  load_image(); // Loads the default image
}

void draw() {

  background(0);

  // rotation ---
  if ( rotXT != rotX ) {
    rotX += ( rotXT - rotX ) / 5 ;
    if ( abs(rotX - rotXT) < 1 ) rotX = rotXT ;
  }
  if ( rotYT != rotY ) {
    rotY += ( rotYT - rotY ) / 5 ;
    if ( abs(rotY - rotYT) < 1 ) rotY = rotYT ;
  }
  //------------

  if ( preloaded ) {

    if (choooseExportFile == true) {
      selectOutput("Où voulez-vous exporter le fichier STL ?", "exportFileChosen");
      choooseExportFile = false;
    }
    
    if (record == true) { // Ready to Record ? ...

      rec();
    }
    
    if (capture == true) { // Display webcam
      capture(); 
    }
    
    if (capture_ready == true) { // Take current camera snapshot
      take_snapshot();
    }
  
    // Drawing the shape extruded from the image according to the brightness values
    if (!record && !capture && !capture_ready) {
      
      if (messageExport == true && choooseExportFile == false) { message("Exporting in progress"); }
      pushMatrix();
      translate(5*width/9, height/2);
      rotateY(radians(rotY));
      rotateX(radians(rotX));
      rotateZ(radians(180));
      renderLoop();
      
      view();
      popMatrix();
  
    }
    
  }
  
  labels();
  credits();
}

void view() {

  if ( showGrid ) { // drawing the grid
    stroke(150,125);
    line (-200*zoom, 0, 200*zoom, 0 );
    line (0, -200*zoom, 0, 200*zoom );
    stroke(255,125);
    for ( int i=-int(6*10*zoom); i<=int(6*10*zoom) ; i+=int(10*zoom) ) {
      line (i, -50*zoom, i, 50*zoom );
    }
    for ( int i=-int(6*10*zoom); i<=int(6*10*zoom) ; i+=int(10*zoom) ) {
      line (-50*zoom, i, 50*zoom, i );
    }
    stroke(100,125);
    pushMatrix();
    rotateX(radians(90));
    line (0, 0, 0, 100*zoom );
    for ( int i=0; i<=6*10*zoom ; i+=10*zoom ) {
      line (-5*zoom, i, 5*zoom, i );
    }
    popMatrix();
  }
}


void checkPixels() {

  //Blurs stuff first
  if (blur) {
 
    // Create an opaque image of the same size as the original
    PImage edgeImg = createImage(img.width, img.height, RGB);
  
    edgeImg.loadPixels();
    // Loop through every pixel in the image
    for (int y = 1; y < img.height-1; y++) {   // Skip top and bottom edges
      for (int x = 1; x < img.width-1; x++) {  // Skip left and right edges
        float sum = 0; // Kernel sum for this pixel
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            // Calculate the adjacent pixel for this kernel point
            int pos = (y + ky)*img.width + (x + kx);
            // Image is grayscale, red/green/blue are identical
            float val = red(img.pixels[pos]);
            // Multiply adjacent pixels based on the kernel values
            sum += kernel[ky+1][kx+1] * val;
          }
        }
        // For this pixel in the new image, set the gray value
        // based on the sum from the kernel
        edgeImg.pixels[y*img.width + x] = color(sum);
      }
    }
    // State that there are changes to edgeImg.pixels[]
    edgeImg.updatePixels();
    img = edgeImg;
    
  }
        
  // Generates the border that extends the surface to Z=0 for watertightness
  color border_color = color(255);
  if ( !inverse ) {
    border_color = color(255); //  (255 = top when not inverse)
  } else {
    border_color = color(0);
  }
  
  // We put a 1px "black" border around the image (black or white depending on way of extrusion)
  img.loadPixels();
  int total = img.pixels.length;

  for (int i = 0; i < total; i++) {
    if ( i%img.width == 0 ) { img.pixels[i] = border_color; } // Left border
    if ( i<img.width ) { img.pixels[i] = border_color; } // Top border
    if ( i>total-img.width) { img.pixels[i] = border_color; } // Bottom border 
    if ( i%img.width == 0 && i>0 ) { img.pixels[i-1] = border_color; } // Right border
  }
  
  // Let's update the image to reflect the changes
  img.updatePixels();
  
  // Then Checks the brightness value of each pixel in the image
  // 0 < val < 1*hauteur
  max_val = 0; min_val = 0;
  for (int x =0; x<resX; x++) {
    for (int y =0; y<resY; y++) {      
      if ( !inverse ) {
        val[x][y] = (-brightness(img.get(x, y))+255)/255*hauteur;
      } else { 
        val[x][y] = brightness(img.get(x, y))/255*hauteur;
      }
      max_val = max(max_val, abs(val[x][y]));
      min_val = min(min_val, abs(val[x][y]));
    }
  }

}


// Records the data inside a STL buffer in unlekker
void exportFileChosen(File selection) {
 
 if (selection != null) {
    
    export_filename = selection.getAbsolutePath();
    int l = export_filename.length();
    String extension = ".STL";
    if (export_filename.substring(l-4,l).toUpperCase().equals(extension) == false) {
      export_filename = export_filename + ".STL";
    }
    
 }
 
 record = true;

}

void rec() {

  beginRaw("unlekker.data.STL", export_filename);
    print("begin .. ");
    renderLoop();
  endRaw();
  println(" .. end");
  record = false;
  messageExport = false;
  
}

void capture() {
  if (!list_cameras_done)   {
    cameras = Capture.list();
    list_cameras_done = true;
    if (cameras.length == 0) {
      message("No cameras available for capture.");
      capture = false;
    } else {
      println("Available cameras:");
      for (int i = 0; i < cameras.length; i++) {
        println(i + " : " + cameras[i]);
      }
    }
  }
  cam = new Capture(this);
  cam.start(); 
  capture = false; 
  capture_do = false; 
  capture_ready = true;
  capture_button();
  println( "c : " + capture + " c_do : " + capture_do + " cread : " + capture_ready );
  
}

void take_snapshot(){
  if (cam.available() == true) {
      cam.read();
    }
    
    loadPixels();
    cam.loadPixels(); 
    // Wait for the size of the camera
    if (cam.width > 0 && cam.height > 0) {
      if (cam.width > 1280) {
        capturedImg = createImage(cam.width, cam.height, RGB);
        capturedImg.copy(cam,0,0,cam.width, cam.height, 0,0,cam.width, cam.height);
        capturedImg.resize(720, 0);
        image(capturedImg, 5*width/9, height/2-50, capturedImg.width, capturedImg.height);
      } else {
        image(cam, 5*width/9, height/2-50);
      }
    }
    
    if (capture_do == true && cam.width > 0 && cam.height > 0) {
      // Take image
      capturedImg = createImage(cam.width, cam.height, RGB);
      capturedImg.copy(cam,0,0,cam.width, cam.height, 0,0,cam.width, cam.height);
      capturedImg.resize(720, 0);
      println("Capturing at w : " + capturedImg.width + " & h : " + capturedImg.height);
      capturedImg.updatePixels();
      cam.stop();
      cam.stop();
      capture_ready = false; 
      capture_do = false; 
      capture = false;
      capture_button();
      load_image();
      checkPixels();
    }
}

// The main render loop for screens and STL
void renderLoop() {
  
  for_STL = (record);
  
  display_ratio = zoom;
  if (for_STL) { display_ratio = 1; }
  display_pixel_ratio = display_ratio/px_ratio;
  
  real_offset = offset*display_ratio;
  x_min = floor(resX/2);
  x_max = ceil(resX/2);
  y_min = floor(resY/2);
  y_max = ceil(resY/2);

  rotateZ(radians(180));
  colorMode(HSB, 255);
  noFill();
  
  for (int x =-x_min; x<x_max-1; x++) {
    for (int y =-y_min; y<y_max-1; y++) {

      current_color = int((val[x+x_min][y+y_min]*230)/max_val);
    
      beginShape();      
      stroke(current_color, 255, 255);
      if (for_STL) {
        fill(current_color, 255, 255);
      }
      
      point1 = (val[x+x_min][y+y_min]-min_val)*display_ratio + real_offset;
      point2 = (val[x+x_min+1][y+y_min]-min_val)*display_ratio + real_offset;
      point3 = (val[x+x_min+1][y+1+y_min]-min_val)*display_ratio + real_offset;
      point4 = (val[x+x_min][y+1+y_min]-min_val)*display_ratio + real_offset;
      
      // Try to triangulate 
      // CASE 0 : all points at the same height : QUAD
      if ( point1 == point4 && point1 == point2 && point1 == point3 ) {
        vertex(x*display_pixel_ratio, y*display_pixel_ratio, point1);
        vertex(x*display_pixel_ratio, (y+1)*display_pixel_ratio, point4);
        vertex((x+1)*display_pixel_ratio, (y+1)*display_pixel_ratio, point3);
        vertex((x+1)*display_pixel_ratio, y*display_pixel_ratio, point2);
      //----- END OF CASE 0
      // CASE 1&2 : three points aligned
      } else if ( (point1 == point3 && point1 == point2) || (point1 == point3 && point1 == point4) ) {
        vertex(x*display_pixel_ratio, y*display_pixel_ratio, point1);
        vertex(x*display_pixel_ratio, (y+1)*display_pixel_ratio, point4);
        vertex((x+1)*display_pixel_ratio, y*display_pixel_ratio, point2);
        endShape(CLOSE);
        beginShape();
        vertex((x+1)*display_pixel_ratio, y*display_pixel_ratio, point2);
        vertex(x*display_pixel_ratio, (y+1)*display_pixel_ratio, point4); 
        vertex((x+1)*display_pixel_ratio, (y+1)*display_pixel_ratio, point3);
      } else if ( (point1 == point4 && point1 == point2) || (point2 == point3 && point2 == point4) ) {
        vertex(x*display_pixel_ratio, y*display_pixel_ratio, point1);
        vertex((x+1)*display_pixel_ratio, (y+1)*display_pixel_ratio, point3);
        vertex((x+1)*display_pixel_ratio, y*display_pixel_ratio, point2);
        endShape(CLOSE);
        beginShape();
        vertex(x*display_pixel_ratio, y*display_pixel_ratio, point1);
        vertex(x*display_pixel_ratio, (y+1)*display_pixel_ratio, point4); 
        vertex((x+1)*display_pixel_ratio, (y+1)*display_pixel_ratio, point3);
      //----- END OF CASE 1&2
      // CASE 3 : two by two
      } else if (point1 == point3 && point2 == point4 && point2 > point3 ) { // 2 triangles
        vertex(x*display_pixel_ratio, y*display_pixel_ratio, point1);
        vertex(x*display_pixel_ratio, (y+1)*display_pixel_ratio, point4);
        vertex((x+1)*display_pixel_ratio, y*display_pixel_ratio, point2);
        endShape(CLOSE);
        beginShape();
        vertex((x+1)*display_pixel_ratio, y*display_pixel_ratio, point2);
        vertex(x*display_pixel_ratio, (y+1)*display_pixel_ratio, point4); 
        vertex((x+1)*display_pixel_ratio, (y+1)*display_pixel_ratio, point3);
      } else if (point1 == point3 && point2 == point4 && point2 < point3 ) { // 2 triangles
        vertex(x*display_pixel_ratio, y*display_pixel_ratio, point1);
        vertex((x+1)*display_pixel_ratio, (y+1)*display_pixel_ratio, point3);
        vertex((x+1)*display_pixel_ratio, y*display_pixel_ratio, point2);
        endShape(CLOSE);
        beginShape();
        vertex(x*display_pixel_ratio, y*display_pixel_ratio, point1);
        vertex(x*display_pixel_ratio, (y+1)*display_pixel_ratio, point4); 
        vertex((x+1)*display_pixel_ratio, (y+1)*display_pixel_ratio, point3);
      // ----- END OF CASE 3
      } else { // Well, let's choose a side
        vertex(x*display_pixel_ratio, y*display_pixel_ratio, point1);
        vertex((x+1)*display_pixel_ratio, (y+1)*display_pixel_ratio, point3);
        vertex((x+1)*display_pixel_ratio, y*display_pixel_ratio, point2);
        endShape(CLOSE);
        beginShape();
        vertex(x*display_pixel_ratio, y*display_pixel_ratio, point1);
        vertex(x*display_pixel_ratio, (y+1)*display_pixel_ratio, point4); 
        vertex((x+1)*display_pixel_ratio, (y+1)*display_pixel_ratio, point3);
      }
      
      endShape(CLOSE);
      
    }
  }
  
  stroke(125, 125, 125);
  fill(125, 100);
  
  // Keyring
  if (keyring) {
  
    def = int(L*3);
    if (e >= L) { e = L - 2; }
    if (L > resX/(2*px_ratio)) { L = int(resX/(2*px_ratio)); }
    real_e = e*px_ratio;
    real_L = L*px_ratio;

    innerPoints = new float[def][2];
    outerPoints = new float[def][2];
    unit_angle = PI/(def-1);
    
    // Create inner & outer points
    for(int i=0; i<def; i++) {
      angle = i*unit_angle;
      innerPoints[i][0] = (real_L - real_e)*cos(angle)*display_pixel_ratio;
      innerPoints[i][1] = (-y_min - (real_L - real_e)*sin(angle))*display_pixel_ratio;
      outerPoints[i][0] = real_L*cos(angle)*display_pixel_ratio;
      outerPoints[i][1] = (-y_min - real_L*sin(angle))*display_pixel_ratio;
    }

    // Now create triangles
    for (int j=0; j<def-1; j++) {
        // Floor
        if (j==0 && for_STL) {
          for(int k=0; k<real_e; k++) {
            beginShape();
            vertex((real_L - real_e + k)*display_pixel_ratio, -y_min*display_pixel_ratio, 0);
            vertex(outerPoints[j+1][0], outerPoints[j+1][1], 0);
            vertex((real_L - real_e + k+1)*display_pixel_ratio, -y_min*display_pixel_ratio, 0);
            endShape(CLOSE);
          }
        } else {
          beginShape();
          vertex(innerPoints[j][0], innerPoints[j][1], 0);
          vertex(outerPoints[j+1][0], outerPoints[j+1][1], 0);
          vertex(outerPoints[j][0], outerPoints[j][1], 0);
          endShape(CLOSE);
        }
        if (j==def-2 && for_STL) {
          for(int k=0; k<real_e; k++) {
            beginShape();
            vertex(innerPoints[j][0], innerPoints[j][1], 0);
            vertex((-(real_L - real_e) - k)*display_pixel_ratio, -y_min*display_pixel_ratio, 0);
            vertex((-(real_L - real_e) - k-1)*display_pixel_ratio, -y_min*display_pixel_ratio, 0);
            endShape(CLOSE);
          }
        } else {
          beginShape();
          vertex(innerPoints[j][0], innerPoints[j][1], 0);
          vertex(innerPoints[j+1][0], innerPoints[j+1][1], 0);
          vertex(outerPoints[j+1][0], outerPoints[j+1][1], 0);
          endShape(CLOSE);
        }
        //Ceil
        if (j==0 && for_STL) {
          for(int k=0; k<real_e; k++) {
            beginShape();
            vertex((real_L - real_e + k)*display_pixel_ratio, -y_min*display_pixel_ratio, real_offset);
            vertex((real_L - real_e + k+1)*display_pixel_ratio, -y_min*display_pixel_ratio, real_offset);
            vertex(outerPoints[j+1][0], outerPoints[j+1][1], real_offset);
            endShape(CLOSE);
          }
        } else {
          beginShape();
          vertex(innerPoints[j][0], innerPoints[j][1], real_offset);
          vertex(outerPoints[j][0], outerPoints[j][1], real_offset);
          vertex(outerPoints[j+1][0], outerPoints[j+1][1], real_offset);
          endShape(CLOSE);
        }
        if (j==def-2 && for_STL) {
          for(int k=0; k<real_e; k++) {
            beginShape();
            vertex(innerPoints[j][0], innerPoints[j][1], real_offset);
            vertex((-(real_L - real_e) - k-1)*display_pixel_ratio, -y_min*display_pixel_ratio, real_offset);
            vertex((-(real_L - real_e) - k)*display_pixel_ratio, -y_min*display_pixel_ratio, real_offset);
            endShape(CLOSE);
          }
        } else {
          beginShape();
          vertex(innerPoints[j][0], innerPoints[j][1], real_offset);
          vertex(outerPoints[j+1][0], outerPoints[j+1][1], real_offset);
          vertex(innerPoints[j+1][0], innerPoints[j+1][1], real_offset);
          endShape(CLOSE);
        }
        // Outer shell
        beginShape();
        vertex(outerPoints[j][0], outerPoints[j][1], real_offset);
        vertex(outerPoints[j][0], outerPoints[j][1], 0);
        vertex(outerPoints[j+1][0], outerPoints[j+1][1], 0);
        endShape(CLOSE);
        beginShape();
        vertex(outerPoints[j][0], outerPoints[j][1], real_offset);
        vertex(outerPoints[j+1][0], outerPoints[j+1][1], 0);
        vertex(outerPoints[j+1][0], outerPoints[j+1][1], real_offset);
        endShape(CLOSE);
        // Inner shell
         beginShape();
        vertex(innerPoints[j][0], innerPoints[j][1], real_offset);
        vertex(innerPoints[j+1][0], innerPoints[j+1][1], 0);
        vertex(innerPoints[j][0], innerPoints[j][1], 0);
        endShape(CLOSE);
        beginShape();
        vertex(innerPoints[j][0], innerPoints[j][1], real_offset);
        vertex(innerPoints[j+1][0], innerPoints[j+1][1], real_offset);
        vertex(innerPoints[j+1][0], innerPoints[j+1][1], 0);
        endShape(CLOSE);
    }
  
}
  
  
  // Bottom line and right line cannot be determined since pixels = points
  // so for the closing shape we need to strip one line right and one line at the bottom
  // hence x_max-1 and y_max -1
  
  // Close shape
  
  if (for_STL) {
    // Fond correctement triangulé
    for (int x =-x_min; x<x_max-1; x++) {
      for (int y =-y_min; y<y_max-1; y++) {
        beginShape();
        vertex(x*display_pixel_ratio, y*display_pixel_ratio, 0);
        vertex((x+1)*display_pixel_ratio, y*display_pixel_ratio, 0);
        vertex((x+1)*display_pixel_ratio, (y+1)*display_pixel_ratio, 0);
        vertex(x*display_pixel_ratio, (y+1)*display_pixel_ratio, 0);
        endShape(CLOSE);
      }
    }
      
    // LEFT
    for (int y =-y_min; y<y_max-1; y++) {
      beginShape();
      vertex(-x_min*display_pixel_ratio, y*display_pixel_ratio, real_offset);
      vertex(-x_min*display_pixel_ratio, y*display_pixel_ratio, 0 );
      vertex(-x_min*display_pixel_ratio, (y+1)*display_pixel_ratio, 0);
      vertex(-x_min*display_pixel_ratio, (y+1)*display_pixel_ratio, real_offset );
      endShape(CLOSE);
    }
    
    // BOTTOM
    for (int x =-x_min; x<x_max-1; x++) {
      beginShape(); // BOTTOM
      vertex(x*display_pixel_ratio, (y_max-1)*display_pixel_ratio, real_offset);
      vertex(x*display_pixel_ratio, (y_max-1)*display_pixel_ratio, 0 );
      vertex((x+1)*display_pixel_ratio, (y_max-1)*display_pixel_ratio, 0);
      vertex((x+1)*display_pixel_ratio, (y_max-1)*display_pixel_ratio, real_offset);
      endShape(CLOSE);
    }
     
    // RIGHT
    for (int y =-y_min; y<y_max-1; y++) {
      beginShape();
      vertex((x_max-1)*display_pixel_ratio, y*display_pixel_ratio, real_offset);
      vertex((x_max-1)*display_pixel_ratio, (y+1)*display_pixel_ratio, real_offset );
      vertex((x_max-1)*display_pixel_ratio, (y+1)*display_pixel_ratio, 0);
      vertex((x_max-1)*display_pixel_ratio, y*display_pixel_ratio, 0 );
      endShape(CLOSE);
    }
    
    // TOP
    for (int x =-x_min; x<x_max-1; x++) {
      // We need to strip down the triangles above the keyring if any
      if (!keyring || (( x>=0 && (x >= L*px_ratio || x < (L-e)*px_ratio)) || (x<=0 && (x < -L*px_ratio || x >= -(L-e)*px_ratio))) ) {
        beginShape(); // BOTTOM
        vertex(x*display_pixel_ratio, -y_min*display_pixel_ratio, real_offset);
        vertex((x+1)*display_pixel_ratio, -y_min*display_pixel_ratio, real_offset);
        vertex((x+1)*display_pixel_ratio, -y_min*display_pixel_ratio, 0);
        vertex(x*display_pixel_ratio, -y_min*display_pixel_ratio, 0);
        endShape(CLOSE);
      }
    }
  
  } else {
    // Fond simple pour la visualisation
    beginShape();
    vertex(-x_min*display_pixel_ratio, -y_min*display_pixel_ratio, 0);
    vertex(-x_min*display_pixel_ratio, (y_max-1)*display_pixel_ratio, 0);
    vertex((x_max-1)*display_pixel_ratio, (y_max-1)*display_pixel_ratio, 0);
    vertex((x_max-1)*display_pixel_ratio, -y_min*display_pixel_ratio, 0);
    endShape(CLOSE);
      
    // LEFT
    beginShape();
    vertex(-x_min*display_pixel_ratio, -y_min*display_pixel_ratio, real_offset);
    vertex(-x_min*display_pixel_ratio, (y_max-1)*display_pixel_ratio, real_offset );
    vertex(-x_min*display_pixel_ratio, (y_max-1)*display_pixel_ratio, 0);
    vertex(-x_min*display_pixel_ratio, -y_min*display_pixel_ratio, 0 );
    endShape(CLOSE);
 
    // BOTTOM
    beginShape(); // BOTTOM
    vertex(-x_min*display_pixel_ratio, (y_max-1)*display_pixel_ratio, real_offset);
    vertex(-x_min*display_pixel_ratio, (y_max-1)*display_pixel_ratio, 0 );
    vertex((x_max-1)*display_pixel_ratio, (y_max-1)*display_pixel_ratio, 0);
    vertex((x_max-1)*display_pixel_ratio, (y_max-1)*display_pixel_ratio, real_offset);
    endShape(CLOSE);
  
    // RIGHT
    beginShape();
    vertex((x_max-1)*display_pixel_ratio, -y_min*display_pixel_ratio, real_offset);
    vertex((x_max-1)*display_pixel_ratio, (y_max-1)*display_pixel_ratio, real_offset );
    vertex((x_max-1)*display_pixel_ratio, (y_max-1)*display_pixel_ratio, 0);
    vertex((x_max-1)*display_pixel_ratio, -y_min*display_pixel_ratio, 0 );
    endShape(CLOSE);
    
    // TOP
    beginShape(); // BOTTOM
    vertex(-x_min*display_pixel_ratio, -y_min*display_pixel_ratio, real_offset);
    vertex((x_max-1)*display_pixel_ratio, -y_min*display_pixel_ratio, real_offset);
    vertex((x_max-1)*display_pixel_ratio, -y_min*display_pixel_ratio, 0);
    vertex(-x_min*display_pixel_ratio, -y_min*display_pixel_ratio, 0);
    endShape(CLOSE);

  }
  
}


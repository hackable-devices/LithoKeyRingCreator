/***********************/
/* LithoKeyRingCreator */
/***********************/

/* Basé sur le logiciel image2stl de Joel Belouet */

/* Version spécifique pour CKAB */
/* Joel Belouet http://joel.belouet.free.fr/ */
/* Cyril Chapellier http://tchap.me */



/* Creates the GUI */
Button cap;

void makeControls() {

  controlP5 = new ControlP5(this);
  
  controlP5.addButton("Choisir", 0.0, 25, 145, 90, 30);
  controlP5.addButton("Webcam", 0.0, 125, 145, 90, 30);
  controlP5.addToggle("ratio", true, 25, 185, 15, 15);
  controlP5.addToggle("lisser", false, 55, 185, 15, 15);
  controlP5.addToggle("reduire", true, 85, 185, 15, 15);
  controlP5.addToggle("retourner", false, 125, 185, 15, 15);
  
  controlP5.addSlider("px_ratio", 4, 10, 4, 25, 270, 150, 15);
  Slider s0 = (Slider)controlP5.controller("px_ratio");
  s0.setLabel("pixel / mm");
  s0.setNumberOfTickMarks(11);
  
  controlP5.addSlider("hauteur", 0, 60, 15, 25, 325, 150, 15);
  Slider s1 = (Slider)controlP5.controller("hauteur");
  s1.setLabel("hauteur (1/10mm )");
  s1.setNumberOfTickMarks(61);
  
  controlP5.addSlider("offset", 1, 10, 1, 25, 355, 150, 15);
  Slider s2 = (Slider)controlP5.controller("offset");
  s2.setLabel("offset (1/10mm )");
  s2.setNumberOfTickMarks(10);

  controlP5.addToggle("inverser", false, 25, 385, 15, 15);
  
  controlP5.addToggle("activer", true, 25, 530, 15, 15);
  
  controlP5.addSlider("largeur", 5, 50, 20, 25, 470, 150, 15);
  Slider s4 = (Slider)controlP5.controller("largeur");
  s4.setLabel("largeur ( mm )");
  s4.setNumberOfTickMarks(16);
  
  controlP5.addSlider("epaisseur", 10, 30, 20, 25, 500, 150, 15);
  Slider s5 = (Slider)controlP5.controller("epaisseur");
  s5.setLabel("epaisseur ( 1/10 mm )");
  s5.setNumberOfTickMarks(21);
  
  controlP5.addToggle("grille", true, 25, 615, 15, 15);

  controlP5.addButton("Exporter", 0.0, 25, 730, 120, 30);

  cap = controlP5.addButton("Capturer", 0.0, 5*width/9-25, 60, 50, 40);
  cap.setColorBackground(color(255, 128, 0, 128));
  cap.hide();
}

void labels() {
  fill(255);
  stroke(255);
  
  
  text ( "Fichier image :", 25, 135 );
  line( 18, 125, 18, 215);

  text ( "Ratio pixel par mm :", 25, 255 );
  text ( "Déformation :", 25, 315 );
  line ( 18, 245, 18, 415 ); 

  text ( "Anse :", 25, 460 );
  line ( 18, 450, 18, 560 ); 

  text ( "Vue :", 25, 605 );
  line ( 18, 595, 18, 645 );

  text ( "Générer le .STL :", 25, 720 );
  line ( 18, 710, 18, 760 );
  
}

void credits() {
  fill(255);
  text ( "image2stl vCKAB", 5.5*width/6, height-60 );
}

void capture_button(){
  if (capture_ready) {
    cap.show();
  } else { 
    cap.hide();
  }
}


void message(String s) {
  fill(0, 255, 255);
  noStroke();
  rect(18, 18, 2*width/10, 90);
  fill(255);
  stroke(0);
  text ( "Please wait ...",140, 60);
  text ( s, 120, 72);
}


void load_image() {

    if (capturedImg == null) {
      img = loadImage(filename);
    } else {
      capturedImg.loadPixels();
      img = createImage(capturedImg.width, capturedImg.height, RGB);
      img.copy(capturedImg,0,0, capturedImg.width, capturedImg.height, 0, 0, capturedImg.width, capturedImg.height);
      img.updatePixels();
    }
    if ( img == null ) {
      preloaded = false;
    } else {
      preloaded = true;
    }
    
    println("Original image : " + img.width + "x" +img.height);
    if ( preloaded ) {
      imageMode(CENTER);
      
      // Foolproof image size for large images
      if (img.width > 800 || img.height > 800) {
        if ( img.width > img.height ) {
          img.resize(800, 0);
        } else {
          img.resize(0, 800);
        }
      }
      
      // Make square
      if (square == true) {
        int min_size = min(img.width, img.height);
        PImage squareImg = createImage(min_size, min_size, RGB);
        squareImg.copy(img, (img.width-min_size)/2, (img.height-min_size)/2, min_size, min_size, 0, 0, min_size, min_size);
        
        resX = min_size;
        resY = min_size;
        val = new float[resX][resY];
        println(" >> Image squared to '" + min_size + "px'");

        if (scaleDown == true) {
          squareImg.resize(size_image, 0);
          println(" >> Image resized to '" + size_image + "px'");
        }
        img = squareImg;
        img.updatePixels();
      } else if (scaleDown == true) {
        println(" >> Image resized to '" + size_image + "px'");
        if ( img.width > img.height ) {
          img.resize(size_image, 0);
        } else {
          img.resize(0, size_image);
        }    
      }
      
      img.loadPixels();    
      resX = img.width;
      resY = img.height;
      println("New size : " + img.width + "x" +img.height);
      val = new float[resX][resY];

      checkPixels();
    }
}

/* Interface Buttons to toggle values */
void inverser(boolean theFlag) {
  inverse = theFlag;
  checkPixels();
}

void lisser(boolean theFlag) {
  blur = theFlag;
  load_image();
  checkPixels();
}

void reduire(boolean theFlag) {
  scaleDown = theFlag;
  load_image();
  checkPixels();
}

void grille(boolean theFlag) {
  showGrid = theFlag;
}

void activer(boolean theFlag) {
  keyring = theFlag;
}

void retourner(boolean theFlag) {
  flip = theFlag;
  load_image();
  checkPixels();
}

void ratio(boolean theFlag) {
  square = theFlag;
  load_image();
  checkPixels();
}

/* Sliders */
void offset(float off) {
  offset = off/10;
  // checkPixels();
  // println("INFO : Setting Offset to : " + offset);
}

// Extrusion height
void hauteur(float haut) {
  hauteur = haut/10;
  checkPixels();
  // println("INFO : Setting Height to " + hauteur + " mm");
}

// Keyring width
void largeur(int larg) {
  L = larg/2;
  // checkPixels();
  // println("INFO : Setting Height to " + hauteur + " mm");
}

// Keyring width
void epaisseur(int ep) {
  e = float(ep)/10;
  // checkPixels();
  // println("INFO : Setting Height to " + hauteur + " mm");
}

// PX Ratio
void px_ratio(int ratio) {
  px_ratio = ratio;
  checkPixels();
  // println("INFO : Setting PX Ratio to : "+ echelle);
}


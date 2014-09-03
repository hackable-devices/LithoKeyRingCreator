/***********************/
/* LithoKeyRingCreator */
/***********************/

/* Basé sur le logiciel image2stl de Joel Belouet */

/* Version spécifique pour CKAB */
/* Joel Belouet http://joel.belouet.free.fr/ */
/* Cyril Chapellier http://tchap.me */


/* Zooming with the wheel */
void mouseWheel(MouseEvent event) {
  println(event.getCount());
  zoom = min(max(5.0,zoom - float(event.getCount())/5.0),20.0);
  println("zoom " + zoom);
  //checkPixels();
  //s3.setValue(zoom);
  // println("INFO : Setting Zoom to : " + meshSize);
}

/* Rotating (left-click) */
void mouseDragged() { 
  
  if ( mouseX > 200 ) {
    
    if ( pmouseX < mouseX ) {
      rotYT += mouseX - pmouseX;
    } else {
      rotYT -= pmouseX - mouseX;
    }

    if ( pmouseY < mouseY ) {
      rotXT -= mouseY - pmouseY;
    } else {
      rotXT += pmouseY - mouseY;
    }
  }
  
}


/* KeyBoar Controls : UP/DOWN/LEFT/RIGHT keys to rotate the shape */
/*                    SPACEBAR to generate the .stl */
void keyPressed() {

  switch(keyCode) {
  case LEFT: 
    rotYT -= 15 ;
    break;
  case RIGHT: 
    rotYT += 15 ;
    break;
  case UP: 
    rotXT += 15 ;
    break;
  case DOWN: 
    rotXT -= 15 ;
    break;
  case BACKSPACE: // You can use BackSpace to generate the .stl  
    record = true;
    break;
  default:           
    break;
  }
}


/* When clicking on "choose" */
void controlEvent(ControlEvent theEvent) {
  if (theEvent.getController().getName() == "Choisir") {
      selectInput("Choisir une image (jpg, jpeg ou png) : ", "fileSelected");
  } else if (theEvent.getController().getName() == "Exporter") {
    message("Exporting in progress");
    record = true;
  } else if (theEvent.getController().getName() == "Webcam") {
    message("Initializing video");
    capture = true;
  } else if (theEvent.getController().getName() == "Capturer") {
    capture_do = true;
  }
}

void fileSelected(File selection) {
  if (selection != null) {
    capturedImg = null;
    filename = selection.getAbsolutePath();
    println("User selected " + filename);
    load_image();
  }
}


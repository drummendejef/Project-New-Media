import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import de.fhpotsdam.unfolding.*; 
import de.fhpotsdam.unfolding.geo.*; 
import de.fhpotsdam.unfolding.utils.*; 
import de.fhpotsdam.unfolding.providers.*; 
import de.fhpotsdam.unfolding.marker.*; 
import de.fhpotsdam.unfolding.interactions.*; 
import de.fhpotsdam.unfolding.events.*; 
import com.onformative.leap.*; 
import com.leapmotion.leap.*; 
import com.leapmotion.leap.Gesture.State; 
import com.leapmotion.leap.Gesture.Type; 
import com.leapmotion.leap.KeyTapGesture; 
import com.leapmotion.leap.ScreenTapGesture; 
import com.leapmotion.leap.CircleGesture; 
import org.geonames.*; 
import controlP5.*; 
import java.net.InetAddress; 
import processing.net.*; 
import java.net.*; 
import codeanticode.glgraphics.*; 

import org.apache.http.*; 
import org.apache.http.impl.io.*; 
import org.apache.http.client.params.*; 
import org.apache.commons.codec.language.*; 
import org.apache.http.impl.client.*; 
import org.apache.http.annotation.*; 
import org.apache.http.client.protocol.*; 
import org.geonames.wikipedia.*; 
import org.apache.http.util.*; 
import org.apache.http.impl.auth.*; 
import org.apache.http.client.methods.*; 
import org.apache.http.protocol.*; 
import org.apache.http.cookie.params.*; 
import org.apache.http.entity.*; 
import org.apache.http.auth.*; 
import org.apache.commons.codec.*; 
import org.apache.commons.codec.digest.*; 
import org.apache.http.client.entity.*; 
import org.apache.http.conn.socket.*; 
import org.apache.http.conn.params.*; 
import org.apache.http.cookie.*; 
import org.apache.http.conn.routing.*; 
import org.geonames.*; 
import org.apache.commons.logging.*; 
import org.apache.http.impl.conn.*; 
import org.apache.http.impl.pool.*; 
import org.apache.http.config.*; 
import org.apache.http.impl.entity.*; 
import org.apache.http.conn.util.*; 
import org.apache.commons.logging.impl.*; 
import org.apache.http.concurrent.*; 
import org.apache.http.conn.*; 
import org.apache.http.client.config.*; 
import org.apache.commons.codec.net.*; 
import org.apache.http.pool.*; 
import org.apache.http.io.*; 
import org.apache.http.client.*; 
import org.apache.commons.codec.language.bm.*; 
import org.apache.http.impl.*; 
import org.apache.http.impl.conn.tsccm.*; 
import org.apache.http.client.utils.*; 
import org.apache.http.impl.cookie.*; 
import org.apache.http.auth.params.*; 
import org.apache.commons.codec.binary.*; 
import org.apache.http.conn.ssl.*; 
import org.apache.http.params.*; 
import org.apache.http.message.*; 
import org.geonames.utils.*; 
import org.apache.http.impl.execchain.*; 
import org.apache.http.conn.scheme.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class spel extends PApplet {

//IMPORT LIBRARIES

//unfolding








//leapmotion


 



   

//geonames


//Controls (textboxen, buttons,...)


//Om het IP adres te kunnen opvragen


//Sockets (server - client)


//andere



DefaultHttpClient httpClient;


//GLOBALE VARIABELEN

//create a reference to a "Map" object
UnfoldingMap myMap;
//locaties
de.fhpotsdam.unfolding.geo.Location belgieLocation = new de.fhpotsdam.unfolding.geo.Location(50.859591f, 4.350117f);

//Geonames user name
String username = "frederic.gryspeerdt";
String countryClick;

LeapMotionP5 leap;

JSONObject json;

//telkens er geklikt wordt, moet een marker opgeslagen worden
ArrayList<MarkerInfo> lstMarkers = new ArrayList();

ScreenPosition centerPos;
Location centerLoc;
Location handLoc;


PVector fingerPos;
PVector handPos;

//HUE
String KEY = "fredericgryspeerdt"; // "secret" key/token
String IP = "172.23.190.22"; // ip bridge

int hue = 0;	//rood = 0 of 65280 / groen = 25500 tot 36210 / blauw = 46920
int brightness = 0;	//van 0 tot 255
int saturation = 0;

//WEBSOCKETS (hier worden client en server aangemaakt omdat we nog nie weten wie wat gaat zijn.)
Server myServer; //Voor de server
Client myClient; //Voor de client
final int portNumber = 5204;//Poort nummer waar je gaat op opstarten.

//CONTROLS
ControlP5 cp5;

//IP ADRES VINDEN
InetAddress inet;
String myIP;



//LOGICA
Location searchLoc = new Location(50.835925f, 4.350409f);	//locatie die gezocht moet worden
SimplePointMarker searchMark = new SimplePointMarker(searchLoc);

Location cursorLoc;	//locatie van de cursor
int distance;	//afstand tussen gezochte locatie en locatie van "cursor"

//GAME
int gameState = 0; //0 = INTRO - 1 = STARTED - 3 = STOPPED

public void setup() {
	//Venster aanmaken
	size(800,600);
	smooth();
	frameRate(10);

	//INIT UNFOLDING
	setupMyMap();

	//INIT GEONAMES
	setupGeoNamesWebService();

	//INIT LEAPMOTION
  	setupLeapMotion();

  	//HttpCLient
  	httpClient = new DefaultHttpClient();

	//logger: will setup basic logging to the console
	org.apache.log4j.BasicConfigurator.configure();

	//Controls
	cp5 = new ControlP5(this);

	//Startscherm controls aanmaken (gamestate = 0)
	makeStartButtons();

	//Mag waarschijnlijk al weg.
	println("DEVELOPER COMMENTAAR:\nDruk op s om solo te starten,\n Druk a om als server te kunnen starten,\n Druk z om als client te kunnen starten.");

}

public void draw() {

	switch (gameState) {
		case 0 : //INTRO (kiezen van spelmodus, en van hoe )
			background(0);
			
		break;	

		case 1 : //STARTED
				myMap.draw();
	
				//get the Location of the map at the current mouse position, and show its latitude and longitude as black text.
				//Location location = myMap.getLocation(mouseX, mouseY);
				//text(location.getLat() + ", " + location.getLon(), mouseX, mouseY);
				
				//weergeven van alle markers (plaatsen waar geklikt is)
				addMarkers(lstMarkers);

				try {
			      //text(mouseX + ", " + mouseY,mouseX,mouseY);
			      fingerPos = leap.getTip(leap.getFinger(0));    
			    } catch (Exception e) {
			      println("> fingerposition: "+e);
			    }
			    
			    try {
			       for (Hand hand : leap.getHandList()) {
			        handPos = leap.getPosition(hand);
			        ellipse(handPos.x, handPos.y, 20, 20);
			        fill(255);
			        ellipse(handPos.x, handPos.y, 20, 20);

			        checkPanning(handPos);
			        handLoc = new Location(handPos.x, handPos.y);
			      }
			    } catch (Exception e) {
			      println("> handPos: "+e);
			    }


			    //aanvulling
			    try {
			    	cursorLoc = myMap.getLocation(mouseX, mouseY);
			    	distance = (int)searchLoc.getDistance(cursorLoc);
			    	println(">> DISTANCE: " + distance);
			    	//distanceToColorConverter();

			    	checkDistance();
			    	//hueTest();

			    } catch (Exception e) {
			    	println(">> DISTANCE: " + e);
			    }
		break;					

		case 2 : //Startscherm van de server, blijft hier op hangen tot hij en client vind.
				//Afdrukken IP adres 
				textFont(createFont("HelveticaNeue",15));
				fill(0xff776F5F);
				text("Wachtend op client om te connecten.\nMijn IP adres:" + myIP, width/2 - 100, height / 2 -50);
		break;
	}
	

}

public void keyPressed() {
  if (key == 's' || key == 'S') {//Wisselen van intro naar spel
    speelSoloButton();
	}
  if(key == 'a' || key == 'A' && gameState == 0) {//Opstarten als server
  	speelServerButton();
  }
  if(key == 'z' || key == 'Z' && gameState == 0) {//Opstarten als client
  	speelClientButton();
  }
 }

public void hueTest(){
	try {
    String data = "{\"on\":true, \"hue\":"+hue+", \"bri\":"+brightness+", \"sat\":"+saturation+", \"transitiontime\":5}";

    StringEntity se = new StringEntity(data);
    HttpPut httpPut = new HttpPut("http://"+IP+"/api/"+KEY+"/lights/3/state");

    httpPut.setEntity(se);

    HttpResponse response = httpClient.execute(httpPut);
    HttpEntity entity = response.getEntity();
    if (entity != null) entity.consumeContent();
  }
  catch(Exception e) {
    e.printStackTrace();
  }
}

public void checkDistance(){
	//max hue = 65.280
	//max brightness = 255
	//max saturation = 255
	//max distance = +-20.000

	hue = (int)map(distance, 0, 20000, 0, 46920); // hoe dichter bij gezochte locatie, hoe rooder 
	//println("hue: "+hue);
	brightness = (int)map(distance, 0, 20000, 170, 0); //hoe dicht bij gezochte locatie, hoe meer helder
	//println("brightness: "+brightness);
	saturation = (int)map(distance, 0, 20000, 255, 0); // hoe dichter bij gezochte locatie, hoe meer saturation
	//println("saturation;: "+saturation);
}





public void checkPanning(PVector handPosition){

    Location panLocation = myMap.getLocation(handPosition.x,handPosition.y);
    // map.panTo(handPosition.x, handPosition.y);
    myMap.panTo(panLocation);
}

public void addMarkers(ArrayList<MarkerInfo> lst){
	try {
		//alle markers overlopen in ArrayList
		for (MarkerInfo markInfo : lst) {

			//MarkerInfo heeft 2 fields: marker (SimplePointMarker, de default marker) en info (String, bevat naam land)
			Location clickLocation = markInfo.marker.getLocation();
			ScreenPosition clickPos = markInfo.marker.getScreenPosition(myMap);
			float txtWidth = textWidth(markInfo.info);
	  		

			//we maken een custom marker 'ClickLocationMarker' (zelfgemaakte klasse)
			ClickLocationMarker clickMarker = new ClickLocationMarker(clickLocation, markInfo.info, txtWidth);
			//plaatsen marker op de map
			myMap.addMarkers(clickMarker);
		
		}
	} catch (Exception e) {
		println("> addMarker: "+e);
	}
	
}
//Willekeurig nieuw land kiezen
public void RandomCountry()
{

}

//Afstand berekenen tussen aangeduide plek en random land
public void CalculateDistance()
{

}

//TODO: 

//Tekstvakje dat naam van een land weergeeft

//Google maps weergeven

//Afstand berekenen van random land en philips hueu daarmee aansturen

//Uitzoeken hoe 2 spelers te kunnen connecteren.
// https://processing.org/reference/libraries/net/Server.html
// https://processing.org/reference/libraries/net/Client.html


public void setupMyMap(){
	//initialize a new map object and add default event functioning
	//for basis interaction
	myMap = new UnfoldingMap(this,new Microsoft.AerialProvider());	//use another then default map style


	//UnfoldingMap(processing.core.PApplet p, float x, float y, float width, float height)
  	//Creates a new map with specific position and dimension. 
 	//myMap = new UnfoldingMap(this, 0f,0f,width,height,new Microsoft.AerialProvider());
 	//println((int)map.getWidth()+"," +(int)map.getHeight());
	MapUtils.createDefaultEventDispatcher(this, myMap); //basisinteractie toevoegen: map reageert op muis en toetsen
	
  	centerPos = new ScreenPosition(width/2,height/2);
  	centerLoc = myMap.getLocation(centerPos);
  	myMap.zoomAndPanTo(centerLoc,2);
  	//myMap.setPanningRestriction(centerLoc, 10000);
  	//myMap.setScaleRange(1f, 18f);

  	myMap.setZoomRange(2,18);		//2 = max uitzoomlevel; 18 = max. inzoomlevel
  									//range: 0 is max. uitgezoomd, 18 (of meer indien mogelijk) is max. uitgezoomd


  	myMap.addMarker(searchMark);								
}

public void setupGeoNamesWebService(){
	//setup webservice geonames
	WebService.setUserName("frederic.gryspeerdt");
}

public void setupLeapMotion(){
  leap = new LeapMotionP5(this);
  leap.enableGesture(Type.TYPE_SCREEN_TAP);
  leap.enableGesture(Type.TYPE_CIRCLE);
  leap.enableGesture(Type.TYPE_KEY_TAP);
}

public void mouseClicked() {
	//locatie ophalen adhv x en y van muis
 	Location clickLocation = myMap.getLocation(mouseX, mouseY);
 	//marker aanmaken (die later op de map zal worden getoond)
	SimplePointMarker clickMarker = new SimplePointMarker(clickLocation);
 	//ScreenPosition clickPos = clickMarker.getScreenPosition(myMap);
 	zoekNaamLocatie(clickLocation);
 	MarkerInfo markInfo = new MarkerInfo(clickMarker, countryClick);
 	lstMarkers.add(markInfo);
 	//println("lstMarkers: "+lstMarkers);
}


public void zoekNaamLocatie(Location clickLocation) {
	//obv de clickLocatie (gebruiker heeft ergens op de kaart geklikt), de naam van het land (en andere info)
	//waarop geklikt werd, ophalen
	//we gebruiken hiervoor de webservice van geonames: obv latitude en longitude kan deze dit achterhalen

	//ophalen latitude en longitude van clickLocation
	float lat = clickLocation.getLat();
	float lon = clickLocation.getLon();

	//service aanspreken op volgende link: http://api.geonames.org/findNearbyPlaceNameJSON?lat=[X].3&lng=[X]&username=[X]
	try {
		//try - catch is verplicht als je met URI werkt
		URI uri = new URIBuilder()
        .setScheme("http")
        .setHost("api.geonames.org")
        .setPath("/findNearbyJSON")
        .setParameter("lat", ""+lat)
        .setParameter("lng", ""+lon)
        .setParameter("username", username)
        .build();

		//println("> URI = "" + uri);

		//webservice heeft json terug
		json = loadJSONObject(""+uri);
  		//println("> json: "+json);

  		//Get the element that holds the information
  		JSONArray values = json.getJSONArray("geonames");
  		//println("values: "+values.size());

  		//array overlopen
  		for (int i = 0; i < values.size(); i++) {
    
    		JSONObject geoname = values.getJSONObject(i); 

    		//land waarop geklikt werd ophalen
    		countryClick = geoname.getString("countryName");
  			//println("> countryClick: "+countryClick);
  		}
	} catch (Exception e) {
		println("> zoekNaamLocatie: "+ e);
		countryClick = "Onbekend";
	}
}


public void screenTapGestureRecognized(ScreenTapGesture gesture) {
  if (gesture.state() == State.STATE_STOP) {
	println("> SCREENTAP");

  	/*
    System.out.println("//////////////////////////////////////");
    System.out.println("Gesture type: " + gesture.type());
    System.out.println("ID: " + gesture.id());
    System.out.println("Position: " + leap.vectorToPVector(gesture.position()));
    System.out.println("Direction: " + gesture.direction());
    System.out.println("Duration: " + gesture.durationSeconds() + "s");
    System.out.println("//////////////////////////////////////");
	*/
 

    Location tapLocation = myMap.getLocation(handPos.x, handPos.y);
    SimplePointMarker tapMarker = new SimplePointMarker(tapLocation);
    zoekNaamLocatie(tapLocation);
    MarkerInfo markInfo = new MarkerInfo(tapMarker, countryClick);
    //ScreenPosition tapPos = tapMarker.getScreenPosition(myMap);
      
    lstMarkers.add(markInfo);
    //println("lstMarkers: "+lstMarkers); 

    /*
    PVector position = leap.vectorToPVector(gesture.position());
    float xposFinger = position.x;
    float yposFinger = position.y;

    println("xposFinger: "+xposFinger);
    println("yposFinger: "+yposFinger);

    float xposMouse = mouseX;
    float yposMouse = mouseY;

    println("xposMouse: "+xposMouse);
    println("yposMouse: "+yposMouse);
    */

  } 
  else if (gesture.state() == State.STATE_START) {

  } 
  else if (gesture.state() == State.STATE_UPDATE) {
   
  }
}

public void circleGestureRecognized(CircleGesture gesture, String clockwiseness) {
  if (gesture.state() == State.STATE_STOP) {
  	 /*
    System.out.println("//////////////////////////////////////");
    System.out.println("Gesture type: " + gesture.type().toString());
    System.out.println("ID: " + gesture.id());
    System.out.println("Radius: " + gesture.radius());
    System.out.println("Normal: " + gesture.normal());
    System.out.println("Clockwiseness: " + clockwiseness);
    System.out.println("Turns: " + gesture.progress());
    System.out.println("Center: " + leap.vectorToPVector(gesture.center()));
    System.out.println("Duration: " + gesture.durationSeconds() + "s");
    System.out.println("//////////////////////////////////////");
    */

    PVector center = leap.vectorToPVector(gesture.center());
    ScreenPosition handPos = new ScreenPosition(center.x, center.y);   //-----> BELANGRIJK: gebruik screenpostion en zet daarna om in screenLocation!
                                                                      // anders niet correct!

    //Location circleLoc = new Location(fingerPos.x, fingerPos.y);
    //Location circleLoc = new Location(center.x, center.y);
    Location circleLoc = myMap.getLocation(handPos);


    int zoomLvl = myMap.getZoomLevel();
    if (clockwiseness == "clockwise") {

      println("> CIRCLE: clockwise");
      myMap.zoomLevelIn();
      //myMap.zoomAndPanTo(circleLoc,zoomLvl + 1);
      myMap.panTo(circleLoc);
      
                
    } else {

      println("> CIRCLE: counterclockwise");
      myMap.zoomLevelOut();
      //map.zoomAndPanTo(circleLoc, zoomLvl - 1);
      //map.panTo(center.x,center.y);
      myMap.panTo(circleLoc);
    }

   

  } 
  else if (gesture.state() == State.STATE_START) {
  } 
  else if (gesture.state() == State.STATE_UPDATE) {
  }
}

//Opvangen speel alleen button
public void speelSoloButton()
{
	removeStartButtons();//Startscherm weghalen
	makeGoHomeButton();//Terug naar home button maken.
	gameState = 1;
}

//Opvangen server button
public void speelServerButton()
{
	removeStartButtons();//Controls van het eerste scherm verwijderen.

	myServer = new Server(this, portNumber);
		//IP adress opzoeken
	try
	{
		inet = InetAddress.getLocalHost();
		myIP = inet.getHostAddress();
	}
	catch(Exception ex)
	{
		ex.printStackTrace();
		myIP = "Kon IP adres niet ophalen";
	}

	gameState = 2;
}

//Opvangen client button
public void speelClientButton()
{
	//tekstvak (IP) leeghalen
	String serverIP = cp5.get(Textfield.class, "speelClientTextfield").getText();

	//myClient aanmaken
	myClient = new Client(this, serverIP, portNumber);

	//Verbinden met client?

}

//Opvangen GoHome button (ga terug naar startscherm)
public void homeButton()
{
	gameState = 0;
	makeStartButtons();
	removeGoHomeButton();
}

//Maak buttons en tekstvakken aan voor het startscherm gamestate = 0
public void makeStartButtons()
{
	cp5.addButton("speelSoloButton", 1, width/2 - 50, height/2 - 90, 100,30).setCaptionLabel("Speel Alleen");//Button om alleen te spelen
	cp5.addButton("speelServerButton", 1, width/2 - 50, height/2 - 30, 100,30).setCaptionLabel("Speel Server");//Button om als server te starten
	cp5.addTextfield("speelClientTextfield",width/2 - 110, height/2 + 30, 100,30).setCaptionLabel("Speel als client, geef IP van server in");//Tekstvak waar je het IP van de server moet ingeven
	cp5.addButton("speelClientButton",1,width/2 + 10, height/2 + 30, 100,30).setCaptionLabel("Start als Client");//Button om als client te starten.
}

//Verwijder buttons en tekstvakken van het startscherm
public void removeStartButtons()
{
	cp5.getController("speelSoloButton").remove();
	cp5.getController("speelServerButton").remove();
	cp5.getController("speelClientTextfield").remove();
	cp5.getController("speelClientButton").remove();
}

//Button om terug naar startscherm te gaan aanmaken
public void makeGoHomeButton() 
{
	cp5.addButton("homeButton", 1, 10,10,60,30);
}

//Button om terug naar startscherm te gaan verwijderen
public void removeGoHomeButton() 
{
	cp5.getController("homeButton").remove();
}




public void stop() {
  leap.stop();
  httpClient.getConnectionManager().shutdown();
  super.stop();
  //Server en client afsluiten?

}	
//deze klasse is nodig omdat we per click een SimplePointMarker
//en een label (bv. landnaam) willen bijhouden
class MarkerInfo{
	private String info;
	private SimplePointMarker marker;

	//Constructor
	public MarkerInfo(SimplePointMarker marker, String info){
		this.marker = marker;
		this.info = info;
	}

	//getters
	public SimplePointMarker marker() {
		return this.marker;
	}

	public String info() {
		return this.info;
	}

}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "spel" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}

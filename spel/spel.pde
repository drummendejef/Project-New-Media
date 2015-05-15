//IMPORT LIBRARIES

//unfolding
import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.utils.*;
import de.fhpotsdam.unfolding.providers.*;
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.interactions.*;
import de.fhpotsdam.unfolding.events.*;

//leapmotion
import com.onformative.leap.*;
import com.leapmotion.leap.*;
import com.leapmotion.leap.Gesture.State; 
import com.leapmotion.leap.Gesture.Type;
import com.leapmotion.leap.KeyTapGesture;
import com.leapmotion.leap.ScreenTapGesture;
import com.leapmotion.leap.CircleGesture;   

//geonames
import org.geonames.*;

//Controls (textboxen, buttons,...)
import controlP5.*;

//Om het IP adres te kunnen opvragen
import java.net.InetAddress;

//Sockets (server - client)
import processing.net.*;

//andere
import java.net.*;
import codeanticode.glgraphics.*;

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
int dataIn; //Data die de server doorstuurt naar de client.
byte stopReadTeken = 10;
String inString;
String[] messageFromServer; 

//CONTROLS
ControlP5 cp5;


//IP ADRES VINDEN
InetAddress inet;
String myIP;

//COUNTDOWN
int startCountDownWaarde = 3;//Visueel zie je het dan starten bij 3.
int timeCountDownGestart;
int teller; 

//Fonts
PFont fontNormaal;
PFont fontGroot;




//LOGICA
//Location searchLoc = new Location(50.835925, 4.350409);	//locatie die gezocht moet worden
//SimplePointMarker searchMark = new SimplePointMarker(searchLoc);

Location searchLoc;	//locatie die gezocht moet worden
SimplePointMarker searchMark; //onzichtbare marker op de kaart (nodig om afstand tot zoeklocatie te weten)


Location cursorLoc;	//locatie van de cursor
int distance = 999999;	//afstand tussen gezochte locatie en locatie van "cursor" (joren heeft distance op 999999 gezet omdat het berekenen van de score anders fout is door de start van het spel)

boolean isMultiplayer = false; //Om te kijken of we in multiplayer spelen of niet. Als er in multiplayer gespeeld wordt moeten er andere acties gedaan worden

final int aantalBeurten = 3; //Aantal markers die je mag zetten voordat je beurt om is.
int aantalBeurtenResterend = 0;

ArrayList<String> arrLanden = new ArrayList();
String teZoekenLand;
ArrayList<SimplePointMarker> arrMarkersSpeler1 = new ArrayList(); //in deze array worden de 3 markers die de speler op de kaart heeft gezet
ArrayList<SimplePointMarker> arrMarkersSpeler2 = new ArrayList(); //in deze array worden de 3 markers die de speler op de kaart heeft gezet

int shortestDistance = 999999; //Om de score te berekenen, moet je de korste afstand bijhouden, dat doen we hier in.
int shortestDistanceOtherPlayer; //De andere speler z'n score hier op vangen.



//GAME
int gameState = 0; //0 = INTRO - 1 = STARTED - 2 = SERVER wachtscherm - 3 = AFTELSCHERM

void setup() {
	//Venster aanmaken
	size(800,600);
	smooth();
	frameRate(10);
	noStroke();

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
	println("DEVELOPER COMMENTAAR:\nDruk op s om solo te starten,\n Druk a om als server te starten,\n Druk z om als client te starten.");

	//landen inladen
	arrLanden = GetCountries();

	//Font aanmaken
	fontNormaal = createFont("HelveticaNeue",15);
	fontGroot = createFont("HelveticaNeue",50);



}

void draw() {

	switch (gameState) {
		case 0 : //INTRO (kiezen van spelmodus, en van hoe )
			background(0);
			 for (Hand hand : leap.getHandList()) {
			        handPos = leap.getPosition(hand);
			        ellipse(handPos.x, handPos.y, 20, 20);
			        fill(255);
			        ellipse(handPos.x, handPos.y, 20, 20);
			    }

			 //println(">rndLand: " + getRandomLand(arrLanden));
			
			
		break;	

		case 1 : //STARTED

				myMap.draw();

				//toevoegen te zoeken land
        		myMap.addMarker(searchMark);
				
				//get the Location of the map at the current mouse position, and show its latitude and longitude as black text.
				//Location location = myMap.getLocation(mouseX, mouseY);
				//text(location.getLat() + ", " + location.getLon(), mouseX, mouseY);
				
				//weergeven van alle markers (plaatsen waar geklikt is)
				addMarkers(lstMarkers);

				//fingerpositie ophalen --> gebruikt om in/uitzoomen te regelen
				try {
			      //text(mouseX + ", " + mouseY,mouseX,mouseY);
			      fingerPos = leap.getTip(leap.getFinger(0));    
			    } catch (Exception e) {
			      println("> fingerposition: "+e);
			    }

			    //handpositie ophalen --> gebruikt om over kaart te bewegen
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


			    //afstand berekenen tss handpositie speler en te zoeken land
			    //OPGEPAST: - mouseX, mouseY moet nog aangepast worden naar handpositie
			    //			- hueTest() uit commentaar halen
			    try {
			    	cursorLoc = myMap.getLocation(mouseX, mouseY);
			    	distance = (int)searchLoc.getDistance(cursorLoc);
			    	//println(">> DISTANCE: " + distance);

			    	checkDistance();
			    	//hueTest();

			    } catch (Exception e) {
			    	println(">> DISTANCE: " + e);
			    }

			    //Spelinfo afdrukken
			    textFont(fontNormaal);
			    //aantal resterende beurten afdrukken.
			    fill(#776F5F);
			    rect(195, 10, 160, 30);
			    rect(495, 10, 200, 30);
			    fill(#FFFFFF);
			    text("Resterende beurten: " + aantalBeurtenResterend, 200, 30);
			    text("Te zoeken land: " + teZoekenLand, 500, 30);

			    //Kijken of de beurten op zijn
			    if(aantalBeurtenResterend <= 0)//Beurten zijn op
			    {
			    	println("Beurten zijn op");

				    for (int i = lstMarkers.size() - 1; i >= 0; i--) //De markers lijst weer leeg maken.
				    {
	   					lstMarkers.remove(i);
	   				}

	   				//We waren singleplayer aan het spelen
	   				if(!isMultiplayer)
	   					soloGameEnd();//Solospel is afgelopen, gaat hier vanalles resetten.
	   				else //We waren multiplayer aan het spelen.
	   					gameState = 4;//Beurten op, ga naar wachtscherm, wachten op andere speler.
   				}



		break;					

		case 2 : //Startscherm van de server, blijft hier op hangen tot hij en client vind.
				//Afdrukken IP adres 
				background(0);
				textFont(fontNormaal);
				fill(#776F5F);
				text("Wachtend op client om te connecten.\nMijn IP adres:" + myIP, width/2 - 100, height / 2 -50);
		break;

		case 3 : //Aftelscherm, de client is geconnecteerd met de server, aftelscherm om spelers gewaar te maken dat het spel gaat starten.

				background(0);
				textFont(fontGroot);
				fill(#FF5555);
				teller = startCountDownWaarde - int((millis() - timeCountDownGestart)/1000);
				println("teller: "+teller);
				println("millis()/1000: "+millis()/1000);
				text(teller, width/2, height/2);
				if(teller <= 0)//Als de teller is afgelopen, spel beginnen.
				{
					gameState = 1;
				}

				textFont(fontNormaal);//door Joren: Dit moet hier omdat in multiplayer de tekst anders heel erg groot is (het font van de teller)
		break;

		case 4 : //Eind scherm (beurt is gedaan, wachten op andere speler)
				background(0);
				textFont(fontNormaal);
				fill(#776F5F);
				text("Wachten op andere speler", width/2, height/2);
		break;

		case 5 : //Eindscherm voor allebei, winnaar aanduiden, 
				 //verschil (afstand) tussen allebij tonen, kleinste afstand van elke speler tonen
				 // speel opnieuw of terug naar start button.

		break;

		case 6 : //Spelregelscherm
				background(0);
				textFont(fontNormaal);
				fill(#776F5F);
				/*text("Spelregels:\n In dit spel krijg je de naam van een land.\n Je moet proberen een marker in dit land te plaatsen.\n 
					Dit doe je met behulp van de leapmotion of met je muis.\n 
					De philips hue kan je helpen, hoe groener, hoe dichterbij, hoe roder, hoe verder.\n
					Speel dit spel ook met 2 en zie hoe dicht je tegenspeler is!
					", width/2, height/2);*/
				text("Spelregels", width/2, height/2);

		break;

		case 7 : //Solo eindscherm
				background(0);
				textFont(fontNormaal);
				fill(#776F5F);
				text("Spel over, eindscore: " + shortestDistance, width/2, height/2);

				//TODO
				//In die laatste lijn moet nog '+korsteDistance' (of een andere naam) afgedrukt worden.
				//Hoe kleiner het getal, hoe beter de score.
		break;
	}
	

}

void keyPressed() {
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

	hue = (int)map(distance, 0, 20000, 0, 46920); // hoe dichter bij gezochte locatie, hoe roder 
	//println("hue: "+hue);
	brightness = (int)map(distance, 0, 20000, 170, 0); //hoe dichter bij gezochte locatie, hoe meer helder
	//println("brightness: "+brightness);
	saturation = (int)map(distance, 0, 20000, 255, 0); // hoe dichter bij gezochte locatie, hoe meer saturation
	//println("saturation;: "+saturation);
}


public void checkPanning(PVector handPosition){

    Location panLocation = myMap.getLocation(handPosition.x,handPosition.y);
    // map.panTo(handPosition.x, handPosition.y);
    myMap.panTo(panLocation);
}

void addMarkers(ArrayList<MarkerInfo> lst){
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


  	//myMap.addMarker(searchMark);								
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

void mouseClicked() {
	

		//locatie ophalen adhv x en y van muis
	 	Location clickLocation = myMap.getLocation(mouseX, mouseY);
	 	//marker aanmaken (die later op de map zal worden getoond)
		SimplePointMarker clickMarker = new SimplePointMarker(clickLocation);
	 	//ScreenPosition clickPos = clickMarker.getScreenPosition(myMap);
	 	zoekNaamLocatie(clickLocation);
	 	MarkerInfo markInfo = new MarkerInfo(clickMarker, countryClick);
	 	lstMarkers.add(markInfo);
	 	println("lstMarkers: "+lstMarkers);

	 	//Aantal beurten minderen
	 	aantalBeurtenResterend--;

	 	//De kleinste afstand opslaan. (om de score te berekenen)
	 	if(shortestDistance > distance && gameState == 1)//Als de kortste afstand, groter is dan de afstand op het moment dat er geklikt wordt.
	 	{
	 		println("Geklikt, afstand: "+distance);
	 		shortestDistance = distance; //De nieuwe kortste afstand wordt opgeslagen.
	 	}

}

public ArrayList<String> GetCountries()
{
	//webservice: http://www.groupkt.com/post/c9b0ccb9/restful-webservices-to-get-and-search-countries.htm

	try {
		URI uri = new URIBuilder()
			.setScheme("http")
			.setHost("services.groupkt.com")
			.setPath("/country/get/all")
			.build();

		//webservice geeft json terug
		JSONObject jsonLanden = loadJSONObject("" + uri);
		//println("jsonLanden: "+jsonLanden);

		JSONObject restResponse = jsonLanden.getJSONObject("RestResponse");
		//println("restResponse: "+restResponse);

		JSONArray result = restResponse.getJSONArray("result");
		//println("result: "+result);

		for (int i = 0; i < result.size(); ++i) {
			JSONObject land = result.getJSONObject(i);
			String sLand = land.getString("name");
			//println("sLand: "+sLand);

			arrLanden.add(sLand);

		}
		//println("arrLanden: "+arrLanden);

	} catch (Exception e) {
		println("> GetCountries error: "+e);
	}
	return arrLanden;
}

public String getRandomLand(ArrayList<String> arrLanden){
	int index = int(random(arrLanden.size()));
	return arrLanden.get(index);
}

public void zoekLatEnLong(String sLand){
	float lat;
	float lon;

	//http://api.geonames.org/search?username=frederic.gryspeerdt&name_equals=belgium&lang=nl&type=json
	try {
		//try - catch is verplicht als je met URI werkt
		URI uri = new URIBuilder()
        .setScheme("http")
        .setHost("api.geonames.org")
        .setPath("/search")
        .setParameter("name_equals", sLand)
        .setParameter("lang", "nl")
        .setParameter("type", "json")
        .setParameter("username", username)
        .build();

        JSONObject search = loadJSONObject(""+uri);
        JSONArray geonames = search.getJSONArray("geonames");

        for (int i = 0; i < 1; ++i) {
        	JSONObject countryInfo = geonames.getJSONObject(i);

        	lat = Float.parseFloat(countryInfo.getString("lat"));
        	lon =  Float.parseFloat(countryInfo.getString("lng"));

        	searchLoc = new Location(lat,lon);
        	println("searchLoc: "+searchLoc);
        	searchMark = new SimplePointMarker(searchLoc);

        }
    } catch (Exception e) {
        	println("zoekLatLon exception: "+e);
    }
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
 
 	//if(gameState == 1) //Enkel markers plaatsen als het spel bezig is. (lijkt niet te werken en fouten te geven.)
 	//{
	    Location tapLocation = myMap.getLocation(handPos.x, handPos.y);
	    SimplePointMarker tapMarker = new SimplePointMarker(tapLocation);
	    zoekNaamLocatie(tapLocation);
	    MarkerInfo markInfo = new MarkerInfo(tapMarker, countryClick);
	    //ScreenPosition tapPos = tapMarker.getScreenPosition(myMap);
	      
	    lstMarkers.add(markInfo);

	    aantalBeurtenResterend--;
    //}

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
	aantalBeurtenResterend = aantalBeurten;
	isMultiplayer = false;//Solo spel.

	//Random land kiezen.
	teZoekenLand = getRandomLand(arrLanden);
	zoekLatEnLong(teZoekenLand);

	gameState = 1;
}

//Opvangen server button
public void speelServerButton()
{
	println("In de method: speelServerButton");
	removeStartButtons();//Controls van het eerste scherm verwijderen.
	makeGoHomeButton();
	myServer = new Server(this, portNumber);
	//IP adress opzoeken
	println("IP adress aan het opzoeken");
	try
	{
		inet = InetAddress.getLocalHost();
		myIP = inet.getHostAddress();
	}
	catch(Exception ex)
	{
		println("Niet gelukt om IP adres op te halen");
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

	//Verbinden met client
	myClient = new Client(this, serverIP, portNumber);
}

//Opvangen spelregelbutton
public void spelregelButton() {
	
	//Juiste buttons tonen
	makeGoHomeButton();
	removeStartButtons();

	//Veranderen naar spelregelpagina
	gameState = 6;
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
	cp5.addTextfield("speelClientTextfield",width/2 - 110, height/2 + 30, 100,30).setCaptionLabel("Speel als client, geef IP van server in").setFocus(true).setText("192.168.1.3");//Tekstvak waar je het IP van de server moet ingeven
	cp5.addButton("speelClientButton",1,width/2 + 10, height/2 + 30, 100,30).setCaptionLabel("Start als Client");//Button om als client te starten.
	cp5.addButton("spelregelButton", 1, width/2 - 50, height/2 + 90, 100, 30).setCaptionLabel("Spelregels");//Button om het spelregelscherm te weergeven.
}

//Verwijder buttons en tekstvakken van het startscherm
public void removeStartButtons()
{
	cp5.getController("speelSoloButton").remove();
	cp5.getController("speelServerButton").remove();
	cp5.getController("speelClientTextfield").remove();
	cp5.getController("speelClientButton").remove();
	cp5.getController("spelregelButton").remove();
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
  myServer.stop();
  myClient.stop();

}	

//Wordt aangeroepen wanneer er een client connecteert.
public void serverEvent(Server someServer, Client someClient)
{
	//Klant is verbonden
	println("Klant is verbonden");

	//Is een multispeler spel
	isMultiplayer = true; //(benodigd om multiplayer logica te laten werken.)

	//Aantal beurten instellen
	aantalBeurtenResterend = aantalBeurten;

	//Random land kiezen
	teZoekenLand = getRandomLand(arrLanden);
	zoekLatEnLong(teZoekenLand);


	//TODO:
	//Naam land doorsturen naar speler. 
	//(MOET AANGEPAST WORDEN, BUG DAT HIJ GEEN NIEUW LAND STUURT BIJ OPNIEUW SPELEN)
	//******************************************************************************
	myServer.write("gezochtland:" + teZoekenLand);
	myServer.write(stopReadTeken);//Zeggen tegen de client dat de boodschap is doorgegeven.

	//Countdown starten
	timeCountDownGestart = millis();
	gameState = 3;
}

//Wordt aangeroepen als de server iets stuurt.
public void clientEvent(Client someClient)
{
	print("Server zegt: ");
	if(myClient.available() > 0)//Kijken of de server wel iets stuurt.
	{
		println("myClient.available(): "+myClient.available());
		//dataIn = myClient.read();
		inString = myClient.readStringUntil(stopReadTeken);		
	}

	println("inString: "+inString);

	if(inString != null)//De hele string is doorgestuurd geraakt, nu kunnen we er dingen mee doen.
	{ 
		println("DEBUG: inString is ingevuld!!!");
		messageFromServer = split(inString, ':');//Opsplitsen, wat de boodschap is en de waarde. 

		if(messageFromServer[0].equals("gezochtland"))//Het te zoeken land.
		{
			println("gezochtland: "+messageFromServer[1]);
			zoekLatEnLong(messageFromServer[1]);//Het te zoeken land omzetten naar locatie. 
			teZoekenLand = messageFromServer[1];

			aantalBeurtenResterend = aantalBeurten; //Aantal beurten instellen
			timeCountDownGestart = millis();//Om te zorgen dat de countdown weet dat hij nu gestart is, en hij niet van het begin van het opstarten van het spel gaat rekenen.

			removeStartButtons();
			makeGoHomeButton();

			gameState = 3;
		}
		else if(messageFromServer[0].equals(""))
		{
			
		}
	}	
}

//Wordt aangeroepen als je als solo speler klaar bent met spelen
public void soloGameEnd()
{
	//Gamestate veranderen
	gameState = 7;

	//Waarden terug resetten.
	shortestDistance = 999999;

	//Als je een highscore blad wil maken, zou je dat hier ook kunnen opslaan, voor een solo speler.
}

//Wordt aangeroepen als je als multiplayer klaar bent met spelen
public void multiplayerClientGameEnd()
{
	//Kijken of de andere speler al klaar is

}
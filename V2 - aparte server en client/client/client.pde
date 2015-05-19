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
//-----------------KAART-------------------------------------------//
//create a reference to a "Map" object
UnfoldingMap myMap;
Location boundTopLeft;
Location boundBottomRight;

//telkens er geklikt wordt, moet een marker opgeslagen worden
ArrayList<MarkerInfo> lstMarkers = new ArrayList();

ScreenPosition centerPos;
Location centerLoc;
Location handLoc;

JSONObject json;


//Geonames user name
String username = "frederic.gryspeerdt";
String countryClick;

//-------LEAP MOTION ----------//
LeapMotionP5 leap;
PVector fingerPos;
PVector handPos;

//---------HUE------------------//
String KEY = "fredericgryspeerdt"; // "secret" key/token
String IP = "172.23.190.22"; // ip bridge
String LIGHT = "1";//Welke lamp gebruik je?

int hue = 0;	//rood = 0 of 65280 / groen = 25500 tot 36210 / blauw = 46920
int brightness = 0;	//van 0 tot 255
int saturation = 0;


//CONTROLS
ControlP5 cp5;


//COUNTDOWN
int startCountDownWaarde = 5;//Visueel zie je het dan starten bij 3.
int timeCountDownGestart;
int teller; 



//Fonts
PFont fontNormaal;
PFont fontGroot;

PFont f;
//PFont fontControls;
ControlFont fontControls;


//Afbeeldingen
PImage speluitlegImage;
PImage achtergrondHome;



//LOGICA

Location searchLoc;	//locatie die gezocht moet worden
SimplePointMarker searchMark; //onzichtbare marker op de kaart (nodig om afstand tot zoeklocatie te weten)


Location cursorLoc;	//locatie van de cursor
int distance = 999999;	//afstand tussen gezochte locatie en locatie van "cursor" 
						//(joren heeft distance op 999999 gezet omdat het berekenen van de score anders fout is door de start van het spel)



final int aantalBeurten = 3; //Aantal markers die je mag zetten voordat je beurt om is.
int aantalBeurtenResterend = 0;

ArrayList<String> arrLanden = new ArrayList();
String teZoekenLand;

int shortestDistance = 999999; //Om de score te berekenen, moet je de korste afstand bijhouden, dat doen we hier in.



//GAME
int gameState = 0; //0 = INTRO - 1 = STARTED - 2 = SERVER wachtscherm - 3 = AFTELSCHERM

//------------MULTIPLAYER--------------
final int portNumber = 5204;//Poort nummer waar je gaat op opstarten.

Client myClient;

boolean isMultiplayer = false;
boolean isWinner = false;
boolean isResetCompleted = true;
boolean isEndMapFinished = false;
boolean isFirstLoop = true;
boolean isFirstLoop2 = true;
boolean isServerOpDeHoogte = false;


String messageCode; //bepaalt welke soort bericht de server stuurt 
					//(bv. bericht ivm gameState begint met GAMESTATE)
int winnendeAfstand;

void setup() {
	//Venster aanmaken
	size(1200,700);
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
	//org.apache.log4j.BasicConfigurator.configure();

	//Controls
	cp5 = new ControlP5(this);

	//Startscherm controls aanmaken (gamestate = 0)
	makeStartButtons();

	//landen inladen
	arrLanden = GetCountries();

	//Font aanmaken
		/*print list met aanwezige fonts op computer
		String[] fontList = PFont.list();
				println(fontList);
	*/
	fontNormaal = createFont("HelveticaNeue",15);
	fontGroot = createFont("HelveticaNeue",50);
	f = createFont( "Arial",16,true);


	//Afbeeldingen inladen
	//speluitlegImage = loadImage("./Afbeeldingen/New_Media_EindProject_Speluitleg.jpg");
	speluitlegImage = loadImage("speluitleg.png");
	achtergrondHome = loadImage("achtergrond_home.PNG");

	//Zorgen dat de coordinaten van waar we beginnen het center van de foto zijn.
	//imageMode(CENTER);

}

void draw() {
	
	luisterNaarServer();

	switch (gameState) {
		case 0 : //INTRO (kiezen van spelmodus, en van hoe )
			background(221,217,195);
			image(achtergrondHome,0,0);
			
			if(!isResetCompleted){
				println("> Bezig met reset ...");
				resetMap();
			}

			showStartButtons();

			/*
			
			 for (Hand hand : leap.getHandList()) {
			        handPos = leap.getPosition(hand);
			        ellipse(handPos.x, handPos.y, 20, 20);
			        fill(255);
			        ellipse(handPos.x, handPos.y, 20, 20);
			    }
			*/
			 //println(">rndLand: " + getRandomLand(arrLanden));
				
		break;	

		case 1 : //je bent de eerste speler die geconnecteerd is met de server, dus moet je nog wachten op speler 2
				background(0);
				fill(255);
				textFont(f);
				textAlign(CENTER);
				text("Wachten op speler 2 ...",width / 2, height /2);

		break;

		case 2: //alle twee de spelers zijn verbonden met de server --> aftelscherm starten
				background(0);
				textFont(fontGroot);
				fill(#FF5555);
				
				teller = startCountDownWaarde - int((millis() - timeCountDownGestart)/1000);
				//println("teller: "+teller);
				//println("millis()/1000: "+millis()/1000);
				text(teller, width/2, height/2);
				if(teller <= 1)//Als de teller is afgelopen, spel beginnen.
				{
					gameState = 3;
					println("Teller is gestopt!");
				}
				
				textFont(fontNormaal);//door Joren: Dit moet hier omdat in multiplayer de tekst anders heel erg groot is (het font van de teller)
		break;

		case 3: //aftelscherm is gedaan --> spel mag starten
				background(0);
				checkBoundingBox();
				
				try {
					myMap.draw();
				} catch (Exception e) {
					println(">> Probleem met kaart te tekenen: "+e);
				}

				//toevoegen te zoeken land
        		myMap.addMarker(searchMark);
							
				//weergeven van alle markers (plaatsen waar geklikt is) op de kaart
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
			    //			- veranderKleurHue() uit commentaar halen
			    try {
			    	//cursorLoc = myMap.getLocation(mouseX, mouseY);  //---> uit commentaar halen voor muis input
			    	cursorLoc = myMap.getLocation(handPos.x, handPos.y);  //----> uit commentaar halen voor leap motion input

			    	distance = (int)searchLoc.getDistance(cursorLoc);
			    	//println(">> DISTANCE: " + distance);

			    	stelHueWaardenIn();
			    	veranderKleurHue();

			    } catch (Exception e) {
			    	println(">> DISTANCE: " + e);
			    }

			    //Spelinfo afdrukken
			    textFont(fontNormaal);
			    //aantal resterende beurten afdrukken.
			    fill(#776F5F);
			    rect(195, 10, 160, 30);
			    rect(495, 10, 300, 30);
			    fill(#FFFFFF);
			    text("Resterende beurten: " + aantalBeurtenResterend, 200, 30);
			    text("Te zoeken land: " + teZoekenLand, 500, 30);

			    //Kijken of de beurten op zijn
			    if(aantalBeurtenResterend <= 0)//Beurten zijn op
			    {

			    	println("Beurten zijn op");
			    	//println("lstMarkers: "+lstMarkers);

				    myMap.draw();  //map nog één maal tekenen met alle drie de markers

				    
				    if (isMultiplayer) {
				    	multiplayerGameEnd();			    	
				    } else {
				    	soloGameEnd();
				    }
   				}

		break;

		case 4 : // eerste speler is klaar met al zijn beurten
				if (isFirstLoop) {

						fill(200, 80);
						rect(0,0, width, height);

						isFirstLoop = false;
				};

				//background(0);
				textFont(fontNormaal);
				fill(0);
				text("Wachten tot andere speler klaar is ...", width/2, height/2);

			
		break;	

		case 5:	//beide spelers zijn klaar met spelen --> overgaan tot tonen winnaar/verliezer
					
				if (isFirstLoop2) {
					background(0);
					myMap.draw();
					
					fill(200, 80);
					rect(0,0, width, height);

					showGoHomeButton();				


					isFirstLoop2 = false;
				};
				/*
				if (!isEndMapFinished) {
					addMarkers(lstMarkers);

					myMap.setTweening(true);
					myMap.zoomAndPanTo(searchLoc,2);
					myMap.draw();

					ScreenPosition searchMarkPos = searchMark.getScreenPosition(myMap);
				    strokeWeight(16);
					stroke(67, 211, 227, 100);
					noFill();
					ellipse(searchMarkPos.x, searchMarkPos.y, 36, 36);

					isEndMapFinished = true;
					noStroke();	
				}
				*/
				textFont(fontGroot);
				fill(0);
				textAlign(CENTER);

				if (isMultiplayer) {
					if (!isServerOpDeHoogte) {
						myClient.write("EXIT*");
						println("> CLIENT STUURT: EXIT");

						isServerOpDeHoogte = true;
					}
					
					if (isWinner) {
						text("!!WINNAAR!!", width/2, height/2);
						textSize(25);
						text("Jij was " + shortestDistance + "km verwijderd van " + teZoekenLand, width/2, height/2 + 60);
					} else {
						text("Verliezer :(", width/2, height/2);
						textSize(25);
						text("Jij was " + shortestDistance + "km verwijderd van " + teZoekenLand, width/2, height/2 + 60);	
						text("Winnende afstand: " + winnendeAfstand + "km", width/2, height/2 + 120);			
					}

				} else {
					textSize(25);
					text("Je was " + shortestDistance + "km verwijderd van " + teZoekenLand, width/2, height/2);
				}

		break;

		case 6: //Spelregels

				image(speluitlegImage, 0,0);

		break;

		default : //Als er een foute waarde in de gameState gestoken wordt, komt hij hier terecht.
				background(0, 0, 255);
				fill(255);
				textAlign(CENTER);
				text("Er is ergens iets fout gelopen.", width/2, height/2);

				println("ERROR: In default gameState terecht gekomen.");
			
		break;	
	}
}

/*-----------------------------------------------START SETUP-----------------------------------------------*/
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
  	//myMap.zoomAndPanTo(centerLoc,2);
  	//myMap.setPanningRestriction(centerLoc, 10000);
  	//myMap.setScaleRange(1f, 18f);

  	//myMap.setZoomRange(2,18);		//2 = max uitzoomlevel; 18 = max. inzoomlevel
  									//range: 0 is max. uitgezoomd, 18 (of meer indien mogelijk) is max. uitgezoomd		

  	myMap.zoomAndPanTo(centerLoc, 2);
  	myMap.setZoomRange(2,18);

  	boundTopLeft = myMap.getTopLeftBorder();
  	boundBottomRight = myMap.getBottomRightBorder();				
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
/*-----------------------------------------------EINDE SETUP-----------------------------------------------*/


/*-----------------------------------------------START HUE-----------------------------------------------*/

public void veranderKleurHue(){
	try {
    String data = "{\"on\":true, \"hue\":"+hue+", \"bri\":"+brightness+", \"sat\":"+saturation+", \"transitiontime\":5}";

    StringEntity se = new StringEntity(data);
    HttpPut httpPut = new HttpPut("http://"+IP+"/api/"+KEY+"/lights/"+ LIGHT + "/state");			//nummer licht aanpassen!

    httpPut.setEntity(se);

    HttpResponse response = httpClient.execute(httpPut);
    HttpEntity entity = response.getEntity();
    if (entity != null) entity.consumeContent();
  }
  catch(Exception e) {
    e.printStackTrace();
  }
}

public void stelHueWaardenIn(){
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
/*-----------------------------------------------EINDE HUE-----------------------------------------------*/


/*-----------------------------------------------START KAART-----------------------------------------------*/

public ArrayList<String> GetCountries(){
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

public void plaatsTeZoekenLandOpKaart(String sLand){
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
        	searchMark.setHidden(true);

        }
    } catch (Exception e) {
        	println("zoekLatLon exception: "+e);
        	//opnieuw proberen, anders loopt spel vast!
        	plaatsTeZoekenLandOpKaart(getRandomLand(arrLanden));
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

public void checkBoundingBox() {

  Location mapTopLeft = myMap.getTopLeftBorder();

  Location mapBottomRight = myMap.getBottomRightBorder();

  ScreenPosition mapTopLeftPos = myMap.getScreenPosition(mapTopLeft);
  ScreenPosition boundTopLeftPos = myMap.getScreenPosition(boundTopLeft);

  if (boundTopLeft.getLon() > mapTopLeft.getLon()) {
    myMap.panBy(mapTopLeftPos.x - boundTopLeftPos.x, 0);
  }
  if (boundTopLeft.getLat() < mapTopLeft.getLat()) {
    myMap.panBy(0, mapTopLeftPos.y - boundTopLeftPos.y);
  }
  ScreenPosition mapBottomRightPos = myMap.getScreenPosition(mapBottomRight);
  ScreenPosition boundBottomRightPos = myMap.getScreenPosition(boundBottomRight);
  if (boundBottomRight.getLon() < mapBottomRight.getLon()) {
    myMap.panBy(mapBottomRightPos.x - boundBottomRightPos.x, 0);
  }
  if (boundBottomRight.getLat() > mapBottomRight.getLat()) {
    myMap.panBy(0, mapBottomRightPos.y - boundBottomRightPos.y);
  }
}
/*-----------------------------------------------EINDE KAART-----------------------------------------------*/



/*-----------------------------------------------START LEAPMOTION-----------------------------------------------*/

public void screenTapGestureRecognized(ScreenTapGesture gesture) {
  if (gesture.state() == State.STATE_STOP) {
	println("> SCREENTAP");

 	//if(gameState == 1) //Enkel markers plaatsen als het spel bezig is. (lijkt niet te werken en fouten te geven.)
 	//{
	    Location tapLocation = myMap.getLocation(handPos.x, handPos.y);
	    SimplePointMarker tapMarker = new SimplePointMarker(tapLocation);
	    zoekNaamLocatie(tapLocation);
	    MarkerInfo markInfo = new MarkerInfo(tapMarker, countryClick);
	    //ScreenPosition tapPos = tapMarker.getScreenPosition(myMap);
	      
	    lstMarkers.add(markInfo);

	    aantalBeurtenResterend--;

	    //De kleinste afstand opslaan. (om de score te berekenen)
	 	if(shortestDistance > distance)//Als de kortste afstand, groter is dan de afstand op het moment dat er geklikt wordt.
	 	{
	 		println("Geklikt, afstand: "+distance);
	 		shortestDistance = distance; //De nieuwe kortste afstand wordt opgeslagen.
	 	}
    //}

    //println("lstMarkers: "+lstMarkers); 
  } 
}

public void circleGestureRecognized(CircleGesture gesture, String clockwiseness) {
  if (gesture.state() == State.STATE_STOP) {
 
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
}

/*-----------------------------------------------EINDE LEAPMOTION-----------------------------------------------*/


/*-----------------------------------------------START BUTTONS-----------------------------------------------*/

//Maak buttons en tekstvakken aan voor het startscherm gamestate = 0
public void makeStartButtons(){
	cp5.setColorBackground(color(94,94,94))
		.setColorCaptionLabel(color(191,191,191))
		.setFont(createFont("Arabic Typesetting",20,true));

	cp5.addButton("speelSoloButton", 1, width/2 - 520, height/2 + 90, 250,40)
		.setCaptionLabel("een speler")
		.getCaptionLabel().align(CENTER,CENTER);//Button om alleen te spelen
	cp5.addTextfield("speelClientTextfield",width/2 - 250, height/2 + 150,  250,40)
		.setCaptionLabel("GEEF IP ADRES VAN SERVER").setColorCaptionLabel(0)
		.setFocus(true);//Tekstvak waar je het IP van de server moet ingeven
	cp5.addButton("speelClientButton",1,width/2 - 250, height/2 + 90,  250,40)
		.setCaptionLabel("twee spelers")
		.getCaptionLabel().align(CENTER,CENTER);//Button om als client te starten.
	cp5.addButton("spelregelButton", 1, width/2 + 250, height/2 + 90,  250,40)
		.setCaptionLabel("spelregels")
		.getCaptionLabel().align(CENTER,CENTER);//Button om het spelregelscherm te weergeven.
	cp5.addButton("homeButton", 1, 10,10,110,30)
		.getCaptionLabel().align(CENTER,CENTER); //Button om terug naar startscherm te gaan aanmaken
	hideGoHomeButton();
}

//Verwijder buttons en tekstvakken van het startscherm
public void hideStartButtons(){
	cp5.getController("speelSoloButton").hide();
	cp5.getController("speelClientTextfield").hide();
	cp5.getController("speelClientButton").hide();
	cp5.getController("spelregelButton").hide();
}

public void showStartButtons(){
	cp5.getController("speelSoloButton").show();
	cp5.getController("speelClientTextfield").show();
	cp5.getController("speelClientButton").show();
	cp5.getController("spelregelButton").show();
}

//Button om terug naar startscherm te gaan verwijderen
public void hideGoHomeButton(){
	cp5.getController("homeButton").hide();
}

public void showGoHomeButton(){
	cp5.getController("homeButton").show();
}

//Opvangen speel alleen button
public void speelSoloButton(){
	hideStartButtons();//Startscherm weghalen
	showGoHomeButton();//Terug naar home button maken.
	aantalBeurtenResterend = aantalBeurten;

	//Random land kiezen.
	teZoekenLand = getRandomLand(arrLanden);
	plaatsTeZoekenLandOpKaart(teZoekenLand);

	timeCountDownGestart = millis();

	gameState = 2; //aftellen beginnen
}

//Opvangen spelregelbutton
public void spelregelButton() {
	
    println("spelregelButton ingedrukt");
	//Juiste buttons tonen
	hideStartButtons();//Controls van het eerste scherm verwijderen.
	showGoHomeButton();
	
	//Veranderen naar spelregelpagina
	gameState = 6;
}

//Opvangen GoHome button (ga terug naar startscherm)
public void homeButton(){
	gameState = 0;

	showStartButtons();
	hideGoHomeButton();

	isResetCompleted = false;

	//Waardes van ingame al resetten
	shortestDistance = 999999;
}

/*-----------------------------------------------EINDE BUTTONS-----------------------------------------------*/




/*-----------------------------------------------START MULTIPLAYER-----------------------------------------------*/
//Opvangen client button
public void speelClientButton(){
	//tekstvak (IP) leeghalen
	String serverIP = cp5.get(Textfield.class, "speelClientTextfield").getText();
	println("serverIP: "+serverIP);

	//Verbinden met server
	myClient = new Client(this, serverIP, portNumber);

	//Is een multispeler spel
	isMultiplayer = true; //(benodigd om multiplayer logica te laten werken)

	hideStartButtons();//Controls van het eerste scherm verwijderen.
}

public void luisterNaarServer(){
	//if (myClient != null) {
		try {
			// If there is information available to read from the Server
			if (myClient.available() > 0) {
				// Read message as a String, all messages end with an asterisk
				String in = myClient.readStringUntil('*');

				// Print message received
				println( "Receiving: " + in);

				// Split up the String into an array of integers
				String[] vals = splitTokens(in, ";*");
				

				messageCode = vals[0];
				String state = "GAMESTATE";
				String land = "LAND";
				String winnaar = "WINNAAR";

				println("messageCode: "+messageCode);

				if (messageCode.equals(state) == true) {
					gameState = Integer.parseInt(vals[1]);
					println("gameState: "+gameState);

					switch (gameState) {
						case 2 :
							//Countdown starten
							timeCountDownGestart = millis();
						break;	
					}

				} else if (messageCode.equals(land) == true) {
					teZoekenLand = vals[1];
					println("teZoekenLand: "+teZoekenLand);

					plaatsTeZoekenLandOpKaart(teZoekenLand);
					//Aantal beurten instellen
					aantalBeurtenResterend = aantalBeurten;

				} else if (messageCode.equals(winnaar) == true) {
					winnendeAfstand = Integer.parseInt(vals[1]);

					if (winnendeAfstand == shortestDistance) {
						isWinner = true;
					}

				}
			}
		} catch (Exception e) {
			//println("e: "+e);
		}
		
	//}	
}

public void multiplayerGameEnd(){
	//TODO
	//Kijken of de andere speler al klaar is

	//Client is klaar met spelen, even laten weten aan de server.
	
	//TODO: Stuur score door naar de server.
	myClient.write("clientReady;"+ shortestDistance +"*");//Zeg tegen server dat klant klaar is, score erbij steken
	println("> CLIENT STUURT: clientReady met kortste afstand = " + shortestDistance);

	gameState = 4;//Naar wachtscherm gaan
}
/*-----------------------------------------------EINDE MULTIPLAYER-----------------------------------------------*/


/*-----------------------------------------------START OVERIG-----------------------------------------------*/

void stop() {
  leap.stop();
  httpClient.getConnectionManager().shutdown();
  super.stop();
}	

public void checkPanning(PVector handPosition){

    Location panLocation = myMap.getLocation(handPosition.x,handPosition.y);
    // map.panTo(handPosition.x, handPosition.y);
    myMap.panTo(panLocation);
}

void mouseClicked(){
	
	if(gameState == 3)
	{
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
	 	if(shortestDistance > distance /*&& gameState == 1*/)//Als de kortste afstand, groter is dan de afstand op het moment dat er geklikt wordt.
	 	{
	 		println("Geklikt, afstand: "+distance);
	 		shortestDistance = distance; //De nieuwe kortste afstand wordt opgeslagen.
	 	}
	 }
}

//Wordt aangeroepen als je als solo speler klaar bent met spelen
public void soloGameEnd()
{
	//Gamestate veranderen naar wachtscherm
	gameState = 5;

	//Als je een highscore blad wil maken, zou je dat hier ook kunnen opslaan, voor een solo speler.
}


public void resetMap(){
	lstMarkers.clear();
	setupMyMap();
	
	//booleans terug naar beginwaarde zetten
	isResetCompleted = true;
	isEndMapFinished = false;
	isFirstLoop = true;
	isFirstLoop2 = true;
	isServerOpDeHoogte = false;
	isWinner = false;
}

/*-----------------------------------------------EINDE OVERIG-----------------------------------------------*/

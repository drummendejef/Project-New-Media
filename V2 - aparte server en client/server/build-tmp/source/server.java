import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.net.*; 
import java.net.InetAddress; 
import java.net.*; 
import java.io.*; 
import org.geonames.*; 

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

public class server extends PApplet {

//IMPORT LIBRARIES AND PACKAGES






//geonames


DefaultHttpClient httpClient;


//GLOBALE VARIABELEN


//Geonames user name
String username = "frederic.gryspeerdt";


JSONObject json;

ArrayList<String> arrLanden = new ArrayList();
String teZoekenLand;


PFont f;

//server declareren
Server myServer;


final int portNumber = 5204;//Poort nummer waar je gaat op opstarten.

int serverState = 0;

String binnenkomendBericht = "";
String messageCode;
int aantalClients = 0;
int aantalReadyClients = 0;

int afstandClient1 = 0;
int afstandClient2 = 0;
int winnendeAfstand = 0;

//IP ADRES VINDEN
InetAddress inet; //represents IP address
String myIP;
String externalIP;

String stopReadTeken = "*";



public void setup() {
	size(400,200);
	background(200, 80);
	fill(0);
	smooth();
	f = createFont( "Arial" ,16,true);


	setupServer();

	//landen inladen
	arrLanden = GetCountries();
}

public void draw() {
	if (aantalClients == 0) {
		serverState = 1;
	}
	switch (serverState) {
		case 1 :	
				//server is opgestart
				//Startscherm van de server, blijft hier op hangen tot hij en client vindt
				//Afdrukken IP adres
				background(200, 80); 
				textFont(f);
				textAlign(CENTER);
				text("Wachtend op client om te connecteren.\nMijn IP adres:" + myIP +
					"\nMijn poortnummer: " + portNumber, width / 2, 40);
		break;

		case 2 : //1ste client is verbonden
				//Startscherm van de server, blijft hier op hangen tot hij en client vindt
				//Afdrukken IP adres 
    			background(200, 80);
				fill(0);
				textFont(f);
				textAlign(CENTER);
				text("Wachtend op 2de client om te connecteren.\nMijn IP adres:" + myIP +
					"\nMijn poortnummer: " + portNumber, width / 2, 40);

				text("Nieuwe client verbonden! \nAantal clients: " +""+aantalClients, width / 2, 140);
		break;

		case 3 : //2de client is verbonden

			background(200, 80);
			fill(0);
			textFont(f);
			textAlign(CENTER);
			text("Nieuwe client verbonden! \nAantal clients: " +""+aantalClients, width / 2, 140);

			//start spel logica: 
			//println("serverState: "+serverState);	

			//alle nodige info doorsturen naar de clients
			//stuurSetupDoorNaarClients();	

			luisterNaarClientBerichten();
			break;		
		
	}
	
}

public void setupServer(){
	myServer = new Server(this, portNumber);
	//IP adress opzoeken
	println("IP adress aan het opzoeken");
	try
	{
		
		inet = InetAddress.getLocalHost();
		myIP = inet.getHostAddress();
		serverState = 1; //ip-adres tonen op scherm
		
		/*
		URL whatismyip = new URL("http://checkip.amazonaws.com");
		BufferedReader in = new BufferedReader(new InputStreamReader(
                whatismyip.openStream()));

		externalIP = in.readLine(); //you get the IP as a String
		System.out.println(externalIP);
		*/
		
	}
	catch(Exception ex)
	{
		println("Niet gelukt om IP adres op te halen");
		ex.printStackTrace();
		myIP = "Kon IP adres niet ophalen";
	}
}

//Wordt aangeroepen wanneer er een client connecteert.
public void serverEvent(Server someServer, Client someClient)
{
	aantalClients += 1;
	println("> aantalClients: "+aantalClients);

	switch (aantalClients) {
		case 1 :
			serverState = 2;

			myServer.write("GAMESTATE;1*");
			println("> SERVER VERSTUURT: GAMESTATE;1*");
		break;	

		case 2 :
			serverState = 3;

			teZoekenLand = getRandomLand(arrLanden);
			println("teZoekenLand: "+teZoekenLand);

			myServer.write("GAMESTATE;2*");
			println("> SERVER VERSTUURT: GAMESTATE;2*");

			myServer.write("LAND;" + teZoekenLand + "*");
			println("> SERVER VERSTUURT: te zoeken land = "+ teZoekenLand);
		break;	
	}
	
	binnenkomendBericht = " A new client has connected: " + someClient.ip();


	
	/*
	//Aantal beurten instellen
	aantalBeurtenResterend = aantalBeurten;

	//Random land kiezen
	teZoekenLand = getRandomLand(arrLanden);
	zoekLatEnLong(teZoekenLand);

	//Land doorsturen naar client.
	myServer.write("gezochtland:" + teZoekenLand);
	myServer.write(stopReadTeken);//Zeggen tegen de client dat de boodschap is doorgegeven.

	//Countdown starten
	timeCountDownGestart = millis();
	gameState = 3;
	*/
}

public void luisterNaarClientBerichten(){

	Client myClient = myServer.available();

	if (myClient != null) {
		println("> SERVER: ER KOMT EEN CLIENTBERICHT BINNEN");

		try {
			// Read message as a String, all messages end with an asterisk
				String in = myClient.readStringUntil('*');

				// Print message received
				println( "Receiving: " + in);

				// Split up the String into an array of integers
				String[] vals = splitTokens(in, ";*");
				

				messageCode = vals[0];
				String state = "GAMESTATE";
				String land = "LAND";
				String ready = "clientReady";
				String exit = "EXIT";

				println("messageCode: "+messageCode);

				if (messageCode.equals(state) == true) {
					println("> messageCode: "+messageCode);

					int gameState = Integer.parseInt(vals[1]);
					println("gameState: "+gameState);
					
				} else if (messageCode.equals(land) == true) {
					println("> messageCode: "+messageCode);

					teZoekenLand = vals[1];
					println("teZoekenLand: "+teZoekenLand);

				} else if (messageCode.equals(ready) == true) {
					println("> messageCode: "+messageCode);

					aantalReadyClients += 1;

					switch (aantalReadyClients) {
						case 1 :
							afstandClient1 = Integer.parseInt(vals[1]);
							println("> SERVER: korste afstand van client 1 = " + afstandClient1);
						break;	

						case 2 :
							afstandClient2 = Integer.parseInt(vals[1]);
							println("> SERVER: korste afstand van client 2 = " + afstandClient2);

							if (afstandClient1 <= afstandClient2) {
								winnendeAfstand = afstandClient1;
							} else{
								winnendeAfstand = afstandClient2;
							}

							myServer.write("WINNAAR;" + winnendeAfstand + "*");
							println("> SERVER VERSTUURT: WINNAAR;"+ winnendeAfstand + "*");

							myServer.write("GAMESTATE;5*");
							println("> SERVER VERSTUURT: GAMESTATE;5");
						break;	
					}
				} else if (messageCode.equals(exit) == true) {
					myServer.disconnect(myClient);
					println("> SERVER: DISCONNECTING CLIENT");

					aantalClients -= 1;
					aantalReadyClients -=1;
				}
		} catch (Exception e) {
			println("e: "+e);
		}
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
	int index = PApplet.parseInt(random(arrLanden.size()));
	return arrLanden.get(index);
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "server" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}

import processing.core.*;
import processing.core.PApplet;
import java.lang.Math;
import de.fhpotsdam.unfolding.geo.Location;
import de.fhpotsdam.unfolding.marker.SimplePointMarker;
import de.fhpotsdam.unfolding.utils.ScreenPosition;
 


public class ClickLocationMarker extends SimplePointMarker {

  private float pi = (float)Math.PI;
  private float arcX = (float)44;
  
  private Location location;
  private ScreenPosition screenpos;
  private String info;
  private float textWidth;

 
  public ClickLocationMarker(Location location, ScreenPosition screenPosition, String info) {
    super(location);
    this.screenpos = screenPosition;
    this.info = info;
  }

  public ClickLocationMarker(Location location, String info,float textWidth) {
    super(location);
    this.info = info;
    this.textWidth = textWidth;
  }
 
  public void draw(PGraphics pg, float x, float y) {
    
    pg.pushStyle();
    pg.strokeWeight(5);
    pg.stroke(200, 0, 0, 200);
    pg.strokeCap(PConstants.SQUARE);
    pg.noFill();
    pg.arc(x, y, arcX, arcX, (float)(-pi * 0.9), (float)(-pi * 0.1));
    pg.arc(x, y, arcX, arcX, (float)(pi * 0.1), (float)(pi * 0.9));
    pg.fill(0);
    pg.text(info, x - textWidth / 2, y + 4);
    pg.popStyle();
  }
}

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

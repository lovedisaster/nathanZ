<% include PageHero %>
<script src="http://maps.googleapis.com/maps/api/js?key=AIzaSyCLGyjooxWpcLPoakWjH52wGsSRtjLiJm8&sensor=false">
</script>

<script>
var AUSCenter=new google.maps.LatLng($AddressLatitude,$AddressLongitude);

function initialize()
{
  var mapProp = {
  center:AUSCenter,
  zoom:15,
  mapTypeId:google.maps.MapTypeId.ROADMAP
};
var map=new google.maps.Map(document.getElementById("googleMap"),mapProp);
	var point$Pos  = new google.maps.LatLng($AddressLatitude,$AddressLongitude);
	var marker$Pos=new google.maps.Marker({
	  position:point$Pos,
	  icon:'themes/t2/i/point.png',
	  animation:google.maps.Animation.BOUNCE
	});
	marker$Pos .setMap(map);
	
	var infowindow$Pos = new google.maps.InfoWindow({content:"<h3><font color='black'>$AddressLine1</font></h3>"});
	google.maps.event.addListener(marker$Pos, 'click', function() {
	  infowindow$Pos .open(map,marker$Pos);
	});
}

google.maps.event.addDomListener(window, 'load', initialize);
</script>
<div id="stores-index" class="padding">
	<div id="StoreSearchForm">
	<% if StoreSearchForm %>
		$StoreSearchForm
	<% end_if %>
	</div>
	<div id="googleMap" style="width:515px;height:200px;"></div>
	<h2>$AddressLine1</h2>
	<div class="left">
		<h3>Address</h3>
		<p>$AddressLine2,$AddressLine3<br>
		$AddressSuburb,$AddressState $AddressPostcode</p>
		<h3>Contact</h3>
		<p>
		Phone: $Phone <br>
		Fax: $Fax</p>
	</div>
	<div class="left hours">
		<h3>Hours</h3>
		<p>$OpeningHours</p>
	</div>
</div>
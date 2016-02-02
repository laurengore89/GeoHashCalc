﻿<%@ Control Language="vb" %>

<script runat="server">
    Public Property QueryLat As String = ""
    Public Property QueryLon As String = ""
    
    Public Property MarkLat As String = ""
    Public Property MarkLon As String = ""
    Public Property MarkLatTomorrow As String = ""
    Public Property MarkLonTomorrow As String = ""
    
    Public Property GlobalLat As String = ""
    Public Property GlobalLon As String = ""
    
    Public Property HomeColor As String = "00FF00" ' green
    Public Property HashColor As String = "FF0000" ' red
    Public Property GlobalColor As String = "FFFFFF" ' white
    Public Property TomorrowColor As String = "FFFF00" ' yellow
    Public Property LineColor As String = "FF00FF" ' magenta
    
</script>

<style>
    #map-canvas {
    width: 100%;
    height: 360px;
    border: 1px solid black;
    }
</style>

<script src="https://maps.googleapis.com/maps/api/js"></script>
<script type="text/javascript">

    var map;
    var queries;

    function locateSuccess(position) {
        var whereLat = position.coords.latitude
        var whereLon = position.coords.longitude

        var locationString = location.origin + "?lat=" + whereLat + "&lon=" + whereLon;
        <% If Page.Request.QueryString("date") IsNot Nothing AndAlso Page.Request.QueryString("date") IsNot "" Then%>
        locationString += "&date=" + "<%=Page.Request.QueryString("date")%>";
        <% End If%>

        location.replace(locationString);
    }

    function locateFail() {
        alert("Don't know where you are - sorry.");
    }

    function drawLine(location, map, color, isLongitude) {
        var start;
        var middle;
        var end;
        var drawnLine;

        var line

        if (isLongitude) {
            // Mercator projection never actually reaches the poles
            // cuts off at just over 85 degrees in Google's depiction
            start = new google.maps.LatLng(-89, location);
            middle = new google.maps.LatLng(0, location);
            end = new google.maps.LatLng(89, location);
            
            drawnLine = new google.maps.Polyline({
                path: [start, middle, end],
                geodesic: true,
                map: map,
                strokeColor: color,
                strokeOpacity: 1.0,
                strokeWeight: 0.5
            });
        } else {
            start = new google.maps.LatLng(location, -180);
            middle = new google.maps.LatLng(location, 0);
            end = new google.maps.LatLng(location, 180);
            
            drawnLine = new google.maps.Polyline({
                path: [start, middle, end],
                geodesic: false,
                map: map,
                strokeColor: color,
                strokeOpacity: 1.0,
                strokeWeight: 0.5
            });
        }
    }

    function drawMarker(latlng, map, pinImage) {
        var marked = new google.maps.Marker({
            position: latlng,
            map: map,
            icon: pinImage
        });
        var labelled = new google.maps.InfoWindow({
            content: '<a href="http://maps.google.co.uk/maps?q=' + latlng.toString() +'" target="_blank">' + latlng.toString() + '</a>'
        });
        marked.addListener('click', function() {
            labelled.open(map,marked);
        });
    }

    function initialize(lat, lon) {
        var latlng = new google.maps.LatLng(lat, lon);
        var mapOptions = {
            zoom: 7,
            center: latlng
        };
        map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions);

        <% If QueryLat.Length > 0 AndAlso QueryLon.Length > 0 Then %>
        var intStartLat = <%=QueryLat.Substring(0,QueryLat.IndexOf("."))%>;
        var intStartLon = <%=QueryLon.Substring(0,QueryLon.IndexOf("."))%>;
        var hashLat = 0<%=MarkLat%>;
        var hashLon = 0<%=MarkLon%>;
        var hashLatTomorrow = 0<%=MarkLatTomorrow%>;
        var hashLonTomorrow = 0<%=MarkLonTomorrow%>;
        var globalLat = 0<%=GlobalLat%>;
        var globalLon = 0<%=GlobalLon%>;

        var homeColor = "<%=HomeColor%>";
        var globalColor = "<%=GlobalColor%>";
        var hashColor = "<%=HashColor%>";
        var tomorrowColor = "<%=TomorrowColor%>";
        var lineColor = "<%=LineColor%>";

        // lines
        for (i=-180;i<180;i++) {
            drawLine(i,map,lineColor,true);
        }
        for (i=-90;i<90;i++) {
            drawLine(i,map,lineColor,false);
        }
        
        // home location
        var pinImage;
        pinImage = {
            url: "http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|" + homeColor,
            size: new google.maps.Size(21, 34),
            origin: new google.maps.Point(0,0),
            anchor: new google.maps.Point(10, 34)
        };
        var homeMarker = new google.maps.Marker({
            position: new google.maps.LatLng(<%=Querylat%>, <%=Querylon%>),
            map: map,
            icon: pinImage
        });
        
        // globalhash
        var latlng;
        pinImage = {
            url: "http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|" + globalColor,
            size: new google.maps.Size(21, 34),
            origin: new google.maps.Point(0,0),
            anchor: new google.maps.Point(10, 34)
        };
        latlng = new google.maps.LatLng((180*globalLat)-90, (360*globalLon)-180);
        drawMarker(latlng, map, pinImage);
        
        // regular hashes in red
        pinImage = {
            url: "http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|" + hashColor,
            size: new google.maps.Size(21, 34),
            origin: new google.maps.Point(0,0),
            anchor: new google.maps.Point(10, 34)
        };
        var markerCount = 6;
        for (i=1-markerCount; i<markerCount; i++) {
            var newLat = intStartLat + i;
            for (j=1-markerCount; j<markerCount; j++) {
                var newLon = intStartLon + j;
                if (newLat > 0) {
                    if (newLon > 0) {
                        latlng = new google.maps.LatLng(newLat + hashLat, newLon + hashLon);
                        drawMarker(latlng, map, pinImage);
                    } else if (newLon < 0) {
                        latlng = new google.maps.LatLng(newLat + hashLat, newLon - hashLon);
                        drawMarker(latlng, map, pinImage);
                    } else {
                        // longitude zero
                        latlng = new google.maps.LatLng(newLat + hashLat, 0 - hashLon);
                        drawMarker(latlng, map, pinImage);
                        latlng = new google.maps.LatLng(newLat + hashLat, 0 + hashLon);
                        drawMarker(latlng, map, pinImage);
                    }
                } else if (newLat < 0) {
                    if (newLon > 0) {
                        latlng = new google.maps.LatLng(newLat - hashLat, newLon + hashLon);
                        drawMarker(latlng, map, pinImage);
                    } else if (newLon < 0) {
                        latlng = new google.maps.LatLng(newLat - hashLat, newLon - hashLon);
                        drawMarker(latlng, map, pinImage);
                    } else {
                        // longitude zero
                        latlng = new google.maps.LatLng(newLat - hashLat, 0 - hashLon);
                        drawMarker(latlng, map, pinImage);
                        latlng = new google.maps.LatLng(newLat - hashLat, 0 + hashLon);
                        drawMarker(latlng, map, pinImage);
                    }
                } else {
                    if (newLon > 0) {
                        // latitude zero
                        latlng = new google.maps.LatLng(0 + hashLat, newLon + hashLon);
                        drawMarker(latlng, map, pinImage);
                        latlng = new google.maps.LatLng(0 - hashLat, newLon + hashLon);
                        drawMarker(latlng, map, pinImage);
                    } else if (newLon < 0) {
                        // latitude zero
                        latlng = new google.maps.LatLng(0 + hashLat, newLon - hashLon);
                        drawMarker(latlng, map, pinImage);
                        latlng = new google.maps.LatLng(0 - hashLat, newLon - hashLon);
                        drawMarker(latlng, map, pinImage);
                    } else {
                        // both zeroes
                        latlng = new google.maps.LatLng(0 + hashLat, 0 + hashLon);
                        drawMarker(latlng, map, pinImage);
                        latlng = new google.maps.LatLng(0 + hashLat, 0 - hashLon);
                        drawMarker(latlng, map, pinImage);
                        latlng = new google.maps.LatLng(0 - hashLat, 0 + hashLon);
                        drawMarker(latlng, map, pinImage);
                        latlng = new google.maps.LatLng(0 - hashLat, 0 - hashLon);
                        drawMarker(latlng, map, pinImage);
                    }
                }
            }
            
            // tomorrow's hashes in yellow
            if (hashLatTomorrow != 0 || hashLonTomorrow != 0) {
                var pinImageTomorrow = {
                    url: "http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|" + tomorrowColor,
                    size: new google.maps.Size(21, 34),
                    origin: new google.maps.Point(0,0),
                    anchor: new google.maps.Point(10, 34)
                };
                var markerCount = 6;
                for (k=1-markerCount; k<markerCount; k++) {
                    var newLat = intStartLat + k;
                    for (l=1-markerCount; l<markerCount; l++) {
                        var newLon = intStartLon + l;
                        if (newLat > 0) {
                            if (newLon > 0) {
                                latlng = new google.maps.LatLng(newLat + hashLatTomorrow, newLon + hashLonTomorrow);
                                drawMarker(latlng, map, pinImageTomorrow);
                            } else if (newLon < 0) {
                                latlng = new google.maps.LatLng(newLat + hashLatTomorrow, newLon - hashLonTomorrow);
                                drawMarker(latlng, map, pinImageTomorrow);
                            } else {
                                // longitude zero
                                latlng = new google.maps.LatLng(newLat + hashLatTomorrow, 0 - hashLonTomorrow);
                                drawMarker(latlng, map, pinImageTomorrow);
                                latlng = new google.maps.LatLng(newLat + hashLatTomorrow, 0 + hashLonTomorrow);
                                drawMarker(latlng, map, pinImageTomorrow);
                            }
                        } else if (newLat < 0) {
                            if (newLon > 0) {
                                latlng = new google.maps.LatLng(newLat - hashLatTomorrow, newLon + hashLonTomorrow);
                                drawMarker(latlng, map, pinImageTomorrow);
                            } else if (newLon < 0) {
                                latlng = new google.maps.LatLng(newLat - hashLatTomorrow, newLon - hashLonTomorrow);
                                drawMarker(latlng, map, pinImageTomorrow);
                            } else {
                                // longitude zero
                                latlng = new google.maps.LatLng(newLat - hashLatTomorrow, 0 - hashLonTomorrow);
                                drawMarker(latlng, map, pinImageTomorrow);
                                latlng = new google.maps.LatLng(newLat - hashLatTomorrow, 0 + hashLonTomorrow);
                                drawMarker(latlng, map, pinImageTomorrow);
                            }
                        } else {
                            if (newLon > 0) {
                                // latitude zero
                                latlng = new google.maps.LatLng(0 + hashLatTomorrow, newLon + hashLonTomorrow);
                                drawMarker(latlng, map, pinImageTomorrow);
                                latlng = new google.maps.LatLng(0 - hashLatTomorrow, newLon + hashLonTomorrow);
                                drawMarker(latlng, map, pinImageTomorrow);
                            } else if (newLon < 0) {
                                // latitude zero
                                latlng = new google.maps.LatLng(0 + hashLatTomorrow, newLon - hashLonTomorrow);
                                drawMarker(latlng, map, pinImageTomorrow);
                                latlng = new google.maps.LatLng(0 - hashLatTomorrow, newLon - hashLonTomorrow);
                                drawMarker(latlng, map, pinImageTomorrow);
                            } else {
                                // both zeroes
                                latlng = new google.maps.LatLng(0 + hashLatTomorrow, 0 + hashLonTomorrow);
                                drawMarker(latlng, map, pinImageTomorrow);
                                latlng = new google.maps.LatLng(0 + hashLatTomorrow, 0 - hashLonTomorrow);
                                drawMarker(latlng, map, pinImageTomorrow);
                                latlng = new google.maps.LatLng(0 - hashLatTomorrow, 0 + hashLonTomorrow);
                                drawMarker(latlng, map, pinImageTomorrow);
                                latlng = new google.maps.LatLng(0 - hashLatTomorrow, 0 - hashLonTomorrow);
                                drawMarker(latlng, map, pinImageTomorrow);
                            }
                        }
                    }
                }
            }
        }
    <% End If %>
    }


    $(document).ready(function () {
        queries = {};
        $.each(document.location.search.substr(1).split('&'), function (c, q) {
            var i = q.split('=');
            if (i[0] != undefined && i[1] != undefined) {
                queries[i[0].toString()] = i[1].toString();
            }
        })
        
        if (queries["lat"] == undefined || queries["lon"] == undefined) {
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(locateSuccess, locateFail,
                {
                    enableHighAccuracy: true
                });
            } else {
                alert("Turn geolocation on.");
            }
        } else {
            initialize(queries["lat"], queries["lon"]);
        }
    });

</script>
<div id="map-canvas"></div>

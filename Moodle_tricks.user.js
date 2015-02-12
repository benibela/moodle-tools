// ==UserScript==
// @name        Moodle tricks
// @namespace   http://benibela.de
// @include     https://moodle.uni-luebeck.de/*
// @version     1
// @grant       none
// ==/UserScript==
 
var loc = location.toString();
var page = /moodle[^/]+([^?]*)/.exec(loc)[1];
 
function assert(b, m) {
  console.assert(b, m);
  if (!b) { alert("assert failure: "+m); throw "assert"; }
}

String.contains = function(s) { return this.indexOf(s) >= 0; }

switch (page) {
  case "/grade/report/grader/index.php": 

    var t = document.getElementById("user-grades");
    
   
    var HEADER_SKIP = 2;
    var FOOTER_SKIP = 0;

    for (var r = t.rows.length - 1; r >= 0 && t.rows[r].id.indexOf("user") < 0;  r--)
      FOOTER_SKIP++;
    assert(FOOTER_SKIP > 0 && FOOTER_SKIP <= 2);

    var header = t.rows[1];
    var count = "<TH>" + (FOOTER_SKIP == 2 ? "(Gruppen-)" : "") +  "Abgaben</TH>";
    for (var c = 1; c < header.cells.length; c++){
      if (t.rows[2].cells[c].nodeName == "TH") { count += "<th></th>"; continue; }
      var submitted = 0;
      
      
      for (var r = HEADER_SKIP; r < t.rows.length - FOOTER_SKIP; r++) {
        var s = t.rows[r].cells[c].firstElementChild;
        if (!s) continue;
        var empty = s.textContent == "-";
        assert (s.tagName == "SPAN");// && (empty == s.classList.contains("dimmed_text")), c+":"+empty + " '"+s.textContent + "' "+ s.className + " "+t.rows[r].textContent); 
        if (!empty) submitted ++;
      }
      count += "<td>"+submitted+"</td>";
    }
     
    t.createTFoot().innerHTML = "<tr>"+count+"</tr>";
    FOOTER_SKIP += 1;  

    function showScores() {
      var as = header.getElementsByTagName("a");
      for (var i = 0; i < as.length; i++) 
        if (as[i].href.contains("assign") && !localStorage['points'+(/=([0-9]+)/.exec(as[i].href)[1])]) return;       
      
      for (var c = 1; c < header.cells.length; c++){
        
      }
      t.createTFoot().innerHTML = "<tr>"+count+"</tr>";
    }
    var as = header.getElementsByTagName("a");
    for (var i = 0; i < as.length; i++) 
      if (as[i].href.contains("assign") && !localStorage['points'+(/=([0-9]+)/.exec(as[i].href)[1])]) 
        getAssignMaxPoints((/=([0-9]+)/.exec(as[i].href)[1]), showScores);
    
    showScores();
     
    break;
    
  case "/mod/assign/view.php": 
    if (loc.contains("action=grading")) {
      var edits = document.getElementsByClassName("quickgrade");
      var submitted = 0; var notSubmitted = 0;
      for (var i=0;i<edits.length;i++){
        if (edits[i].nodeName != "INPUT") continue;
        if (edits[i].value == "") notSubmitted ++;
        else submitted ++;
      }
      
      var t = document.getElementsByClassName("generaltable")[0];
      var realRows = -1;
      for (var i=0;i<t.rows.length;i++) 
        if (!t.rows[i].classList.contains("emptyrow")) realRows++;
      if (submitted + notSubmitted != realRows) alert("row mismatch: "+ realRows+ " users "+ submitted + " sub "+ notSubmitted + " not sub");
      
      t.parentNode.parentNode.insertBefore(document.createTextNode("Bisherige Abgaben: "+submitted), t.parentNode.nextSibling);
    }
    
    break;
}

function getAssignMaxPoints(id, callback){
  var oReq = new XMLHttpRequest();
  oReq.onload = function(){
    localStorage["points"+id] = this.responseXML.getElementById("id_modgrade_point").value;
    console.log("points"+id + "=>"+localStorage["points"+id]);
    callback();
  };
  oReq.open("get", "https://moodle.uni-luebeck.de/course/modedit.php?update="+id, true);
  oReq.responseType = "document";
  oReq.send();
}
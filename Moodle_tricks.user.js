// ==UserScript==
// @name        Moodle tricks
// @namespace   http://benibela.de
// @include     https://moodle.uni-luebeck.de/*
// @version     1
// @grant       GM_addStyle
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
    var courseid = extractId(location.href.toString());

    var t = document.getElementById("user-grades");
    
   
    var HEADER_SKIP = 2;
    var FOOTER_SKIP = 0;

    for (var r = t.rows.length - 1; r >= 0 && t.rows[r].id.indexOf("user") < 0;  r--)
      FOOTER_SKIP++;
    assert(FOOTER_SKIP > 0 && FOOTER_SKIP <= 2);
 
    function parseStudentPoints(cell){
      var s = cell.firstElementChild;
      if (!s) return -1;
      var empty = s.textContent == "-";
      assert (s.tagName == "SPAN");// && (empty == s.classList.contains("dimmed_text")), c+":"+empty + " '"+s.textContent + "' "+ s.className + " "+t.rows[r].textContent); 
      if (!empty) return s.textContent * 1
      else return -1;
    }

    var header = t.rows[1];
    var count = "<TH>" + (FOOTER_SKIP == 2 ? "(Gruppen-)" : "") +  "Abgaben</TH>";
    for (var c = 1; c < header.cells.length; c++){
      if (t.rows[2].cells[c].nodeName == "TH") { count += "<th></th>"; continue; }
      var submitted = 0;
      
      
      for (var r = HEADER_SKIP; r < t.rows.length - FOOTER_SKIP; r++) {
        if (parseStudentPoints(t.rows[r].cells[c]) >= 0) 
          submitted ++;
      }
      count += "<td>"+submitted+"</td>";
    }
    var tfoot = t.createTFoot();
    tfoot.innerHTML = "<tr>"+count+"</tr>";
    FOOTER_SKIP += 1;  

    function showScores() {
      var HEADER_COL_SPAN_SKIP = 1;
      var STUDENT_COL_SKIP = 3;

      function getPointsForColumn(c){
        return localStorage['points'+(/=([0-9]+)/.exec(header.cells[c - HEADER_COL_SPAN_SKIP].getElementsByTagName("a")[0].href)[1])]
      }
      function getAssignNameFromColumn(c){
        return header.cells[c - HEADER_COL_SPAN_SKIP].getElementsByTagName("a")[0].textContent;
      }
      
      //show max points
      var as = header.getElementsByTagName("a");
      for (var i = 0; i < as.length; i++) 
        if (as[i].href.contains("assign") && !localStorage['points'+(/=([0-9]+)/.exec(as[i].href)[1])]) return;       
      
      var points = "<th>Maximal Punkte</th>"
      for (var c = 1; c < header.cells.length; c++){
        if (c < STUDENT_COL_SKIP) points += "<th></td>";
        else points += "<td>"+getPointsForColumn(c)+"</td>";
      }
      
      tfoot.innerHTML =  "<tr>"+points+"</tr>" + tfoot.innerHTML;
      FOOTER_SKIP ++;
      
      //color students
      for (var r = HEADER_SKIP; r < t.rows.length - FOOTER_SKIP; r++) {
        //t.rows[r].style.backgroundColor = "violet";
        //t.rows[r].style.padding = "10px";
        //for (var c = 0; c < STUDENT_COL_SKIP; c++){
        //  t.rows[r].cells[c].style.backgroundColor = "transparent";
        //}
      }
      var cellHeight;
      var failed = new Array(t.rows.length);
      var missing = new Array(t.rows.length);
      var presentationFailed = new Array(t.rows.length);
      for (var r = HEADER_SKIP; r < t.rows.length - FOOTER_SKIP; r++) {
        failed[r] = 0;
        missing[r] = 0;
        presentationFailed[r] = false;
      }
      for (var c = STUDENT_COL_SKIP; c < header.cells.length; c++){
        var reqPoints = getPointsForColumn(c) / 2;
        var name = getAssignNameFromColumn(c);
        var presentation = false;
        if (( /Blatt|Zettel|Sheet/i).test(name)) ;
        else if (( /rechnet|Presented/i).test(name)) { reqPoints = 2; presentation = true; }
        else if (( /klausur/i).test(name)) continue;
        
        
        for (var r = HEADER_SKIP; r < t.rows.length - FOOTER_SKIP; r++) {
          var cell = t.rows[r].cells[c];
          if (!cellHeight) cellHeight = cell.clientHeight - 6;
          var scoreClass;
          var points =  parseStudentPoints(cell);
          if (points < 0) scoreClass = "extmissing";
          else if (points >= reqPoints) scoreClass = "extpass";
          else scoreClass = "extfail";
          
          if (scoreClass != "extpass") {
            if (presentation) presentationFailed[r] = true;
            else failed[r] ++;
            if (scoreClass == "extmissing") missing[r] ++;
          }
          
          if (!cell.firstElementChild) cell.innerHTML = "<span>" + cell.innerHTML + "</span>";
          cell.firstElementChild.classList.add("extgradespan");
          cell.firstElementChild.classList.add(scoreClass);
        }
        count += "<td>"+submitted+"</td>";
      }      
      
      var countMissing = 0;
      var countFail = 0;
      var countPass = 0;
      var countAlmost = 0;
                
      
      for (var r = HEADER_SKIP; r < t.rows.length - FOOTER_SKIP; r++) {
        if (missing[r] >= 4 ) { t.rows[r].classList.add("extmissing"); countMissing++; }
        else if (failed[r] > 2) { t.rows[r].classList.add("extfail"); countFail++; }
        else if (presentationFailed[r]) { t.rows[r].classList.add("extalmost"); countAlmost++; }
        else { t.rows[r].classList.add("extpass"); countPass++; }
      }
      
      var div = document.createElement("div");
      div.innerHTML = "Klausurzulassung: "+countPass+"<br> Beinahe: "+countAlmost+"<br> Aktive ohne Zulassung: "+countFail+ " <br> Inaktive: "+countMissing+"<br> Total: "+(countPass+countAlmost+countFail+countMissing);
      
      t.parentNode.appendChild(div);
      
      GM_addStyle(".extgradespan {display: inline-block; width: 100%; height: "+cellHeight+"px; text-align: center; padding-top: "+(cellHeight/3-2)+"px }" +  //vertical-align: middle
        ".extgradespan.extpass {background-color: #55FF55}"+
        ".extgradespan.extfail {background-color: #FF5555}"+
        ".extgradespan.extmissing {background-color: #555555}"+

        "tr.extpass td, tr.extpass th {background-color: #66FF66 !important}"+
        "tr.extfail td, tr.extfail th {background-color: #FF6666 !important}"+
        "tr.extmissing td, tr.extmissing th {background-color: #666666 !important}"+
        "tr.extalmost td, tr.extalmost th {background-color: #FFFF66 !important}"
      );      
      
      var sumCell = header.cells[header.cells.length-1];
      var as = sumCell.getElementsByTagName("a");
      var changeSum = document.createElement("span");
      changeSum.innerHTML = '<a href="/grade/edit/tree/calculation.php?courseid='+courseid+'&id='+extractId( as[as.length-1].href)+'&gpr_type=edit&gpr_plugin=tree&gpr_courseid='+courseid+'"><img src="/theme/image.php/uzl/core/1423503077/t/calc"></a>';
      sumCell.appendChild(changeSum);
    }
    var ths = header.getElementsByTagName("th"); 
    for (var h = HEADER_SKIP; h < ths.length; h++) {
      var as = ths[h].getElementsByTagName("a");
      if (as.length < 2) continue;
      assert(as[0].href.contains("assign") && as[1].href.contains("sortitem"));
      localStorage["assign-id-map"+courseid+'-'+extractId(as[1].href)] = extractId(as[0].href);
      if (as[0].href.contains("assign") && !localStorage['points'+extractId(as[0].href)]) 
        getAssignMaxPoints(extractId(as[0].href), showScores);
    }
    
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
    
  case "/grade/edit/tree/calculation.php":
    var courseid = extractId(location.href.toString());
    //var sumid = extractId( /gpr_.*/.replace(location.href.toString(), ""));
    var idsparent = document.getElementById("idnumbers");
    var ids = idsparent.getElementsByClassName("idnumber");
    for (var i=0;i<ids.length;i++)
      if (!ids[i].value) { 
        ids[i].value = "a" + localStorage["assign-id-map"+courseid+'-'+/[0-9]+/.exec(ids[i].id)[0]];
        ids[i].style.backgroundColor = "yellow";
      }
      
    var lis = idsparent.getElementsByTagName("li");
    var presentationId;
    var formula = "";
    for (var i=0;i<lis.length;i++) {
      var name = lis[i].textContent;
      var id = /\[\[[a-zA-Z0-9]+\]\]/.exec(name);
      if (!id/* && name.contains("Summe") */) continue;
      id = id[0];
      if (( /Blatt|Zettel|Sheet/i).test(name)) {
      } else if (( /rechnet|Presented/i).test(name)) presentationId = id;
      else if (( /klausur/i).test(name)) continue;
      
      if (formula) formula += " + ";
      formula = formula + 'min(1; floor( '+id+' / ' + ( localStorage['points'+ /[0-9]+/.exec(id)[0]] / 2 )   +  ' ))';
    }
    if (presentationId) formula = "("+formula+") * 100 + "+presentationId;
    
    formula = " = "+formula;
    
    var calc = document.getElementById("id_calculation");
    var insert = document.createElement("pre");
    insert.textContent = formula;
    calc.parentNode.insertBefore(document.createElement("br"), calc.nextSiblingElement);
    calc.parentNode.insertBefore(document.createTextNode("Suggested TCS formula:"), calc.nextSiblingElement);
    calc.parentNode.insertBefore(insert, calc.nextSiblingElement);
//    alert(presentationId);
//    alert(formula);
    break;
}

function extractId(href){
  return /id=([0-9]+)$/.exec(href)[1]
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
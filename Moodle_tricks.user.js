// ==UserScript==
// @name        Moodle tricks
// @namespace   http://benibela.de
// @include     https://moodle.uni-luebeck.de/*
// @include     https://www.uni-luebeck.de/studium/studierenden-service-center/service/termine/vorlesungszeiten.html
// @include     http://www.uni-luebeck.de/studium/studierenden-service-center/service/termine/vorlesungszeiten.html
// @version     1
// @grant       GM_addStyle
// @grant       GM_xmlhttpRequest
// @grant       GM_setValue 
// @grant       GM_getValue
// ==/UserScript==


var loc = location.toString();
var page = /moodle[^/]+([^?]*)/.exec(loc);
if (page) page = page[1];
else page = loc;
 
function assert(b, m) {
  console.assert(b, m);
  if (!b) { alert("assert failure: "+m); throw "assert"; }
}

String.prototype.contains = function(s) { return this.indexOf(s) >= 0; }

function selectOptionValue(select, value){
  for (var i=0; i<select.options.length; i++)
    if (select.options[i].value == value) { 
      select.selectedIndex = i; 
      return true; 
    }
  return false;
}
function selectOptionText(select, optionText){
  for (var i=0; i<select.options.length; i++)
    if (select.options[i].textContent == optionText) { 
      select.selectedIndex = i; 
      return true; 
    }
  return false;
}

function makeButton(text, onclick) {
    var btn = document.createElement("button");
    btn.textContent = text;
    btn.addEventListener("click", function(e){
      e.preventDefault();
      onclick(e);
      return false;
    });
    return btn;
}

function getLectureDate(y) { return GM_getValue("lectures"+y); } //e.g. WS2015 means WS 15/16. Use getParsedLectureDate for everything except checking if it exists
function getParsedLectureDate(y) { 
  var ld = getLectureDate(y);
  if (!ld) { return {"contains": function(){return false;}}; } 
  var temp = JSON.parse(ld);
  temp.from = new Date(temp.from);
  temp.from.setHours(0,0,0,0);
  temp.to = new Date(temp.to);
  if (temp.xmas) {
    temp.xmas.from = new Date(temp.xmas.from);
    temp.xmas.from.setHours(0,0,0,0);
    temp.xmas.to = new Date(temp.xmas.to);
  }
  temp.contains = function(date){
    if (date < this.from || date > this.to) return false;
    if (this.xmas) if (date >= this.xmas.from && date <= this.xmas.to) return false;
    return true;
  };
 // alert(temp.toSource());
  return temp;
}


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
        else if (( /klausur|Einreichung Ihres Codes für/i).test(name)) continue;
        var pointsOverride = (/\( *([0-9]+) *(points|punkte)\)/i).exec(name);
        if (pointsOverride) reqPoints = pointsOverride[1]/2;
        
        for (var r = HEADER_SKIP; r < t.rows.length - FOOTER_SKIP; r++) {
          var cell = t.rows[r].cells[c];
          if (!cellHeight) cellHeight = cell.clientHeight - 6;
          var scoreClass;
          var points =  parseStudentPoints(cell);
          if (points < 0) scoreClass = "extmissing";
          else if (points >= reqPoints) scoreClass = presentation ? "extpasspresentation" : "extpass";
          else scoreClass = "extfail";
          
          if (scoreClass.indexOf("extpass")<0) {
            if (presentation) presentationFailed[r] = true;
            else failed[r] ++;
          }
          if (scoreClass == "extmissing") missing[r] ++;
          else missing[r] = 0;
          
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
        ".extgradespan.extpasspresentation {background-color: #55FF88}"+
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
        if (edits[i].nodeName == "INPUT") {
          if (edits[i].value == "") notSubmitted ++;
          else submitted ++;
        } else if (edits[i].nodeName == "SELECT") {
          if (edits[i].selectedIndex == 0) notSubmitted ++;
          else submitted ++;
        }
      }
      
      var t = document.getElementsByClassName("generaltable")[0];
      var realRows = -1;
      for (var i=0;i<t.rows.length;i++) 
        if (!t.rows[i].classList.contains("emptyrow")) realRows++;
      if (submitted + notSubmitted != realRows /*&& submitted + notSubmitted != 0*/) alert("row mismatch: "+ realRows+ " users "+ submitted + " sub "+ notSubmitted + " not sub");
      
      t.parentNode.parentNode.insertBefore(document.createTextNode("Bisherige Abgaben: "+submitted), t.parentNode.nextSibling);

      var isExam = false;
      var h2s = document.getElementsByTagName("h2");
      for (var i=0;i<h2s.length;i++) 
        if (h2s[i].textContent.toLowerCase().contains("klausur") || h2s[i].textContent.toLowerCase().contains("exam")) {
          isExam = true;
          break;
        }

      if (isExam) {
        function selectOptionGrade(select, optionText){
          for (var i=0; i<select.options.length; i++)
            if (select.options[i].textContent.contains(optionText)) { 
              select.selectedIndex = i; 
              return; 
            }
          for (var i=0; i<select.options.length; i++)
            if (select.options[i].textContent.contains(optionText.replace(",","."))) { 
              select.selectedIndex = i; 
              return; 
            }
           throw "Grade not found: " + optionText + " in "+select.innerHTML;
        }

        function findUser(users, data, onfuzzy){
          function normalize(s) { return s.replace(/[ -]/g, "").replace(/ä/g, "ae").replace(/ö/g, "oe").replace(/ü/g, "ue").replace(/ß/g, "ss").replace(/ø/g,"oe"); }
          var fn = data.firstName ? data.firstName.toLowerCase() : null;
          var ln = data.lastName ? data.lastName.toLowerCase() : null;
          var fullname = fn + " " + ln;
          var shortname = fn.replace(/ .*/, "") + " " + ln;
          var fullnameNoPunctation = normalize(fullname);
          var shortnameNoPunctation = normalize(shortname);
          
          var fallback = -1;
          for (var i=0;i<users.length;i++){
            var tc = users[i].textContent.toLowerCase();
            if (tc == fullname) return i;
            if (tc == shortname) fallback = i;
            else {
              tc = normalize(tc);
              if (tc == fullnameNoPunctation || tc == shortnameNoPunctation) fallback = i;
            }
            /*
            if (fn) {
              if (tc.indexOf(fn) < 0 &&
                  tc.indexOf(fn.replace(/ +/g, "-")) < 0 &&
                  tc.indexOf(fn.replace(/-/g, " ")) < 0) continue;
            }
            if (ln) {
              if (tc.indexOf(ln) < 0 &&
                  tc.indexOf(ln.replace(/ +/g, "-")) < 0 &&
                  tc.indexOf(ln.replace(/-/g, " ")) < 0) continue;
            }*/
          }
          if (fallback >= 0) {
            if (onfuzzy) onfuzzy(data.raw + "\nto: " + users[fallback].textContent);
            return fallback;
          }
          //throw "User name not found: "+JSON.stringify(data);
          return -1;
        }

        function setScores(data, onerror, onfuzzy){
        /* data is array of 
          {firstName: 
           lastName: 
           grade:
           scores:  []
           score:
           }
        */
          
          var as = t.getElementsByTagName("a");
          var users = [];
          for (var i=0;i<as.length;i++) 
            if (as[i].href.indexOf("user") >= 0) users.push(as[i]);
          var errors = 0;
          for (var i=0;i<data.length;i++) {
            var uid = findUser(users,data[i], onfuzzy);
            if (uid < 0) { onerror(data[i].raw); errors++; continue; }
            var row = users[uid].parentNode.parentNode;
            var gradings = row.getElementsByClassName("quickgrade");
            for (var j=0;j<gradings.length;j++) {
              if (gradings[j].nodeName == "INPUT") gradings[j].value = data[i].grade;
              else if (gradings[j].nodeName == "TEXTAREA") gradings[j].value = "Score: "+ data[i].score + " Grade: "+ data[i].grade + "\n" + "Partial scores: "+data[i].scores.join(" ");
              else if (gradings[j].nodeName == "SELECT") selectOptionGrade(gradings[j], data[i].grade);
            }
          }
          alert("Results imported for " + (data.length - errors) + "/" + data.length + " students");
        }

        function parseExamResults(dump){
          var numeric = /^[0-9,]+$/;
          data = dump.trim().split(/[ \n\r]+/);
          var res = [];
          var i = 0;
          function expectName(){ if (numeric.test(data[i])) throw ("Expected name, got: " + data[i]); }
          function expectNumber(){ if (!numeric.test(data[i])) throw ("Expected number, got: " + data[i]); }
          function expectOne(){ if (data[i] != "1") throw ("Expected '1', got: " + data[i]); }
          
          var cur = {};
          var phase = 0;
          var runningSum; var scoreCols; var scoreColsFirst;
          for (i=0;i<data.length;i++){
            var v = data[i];
            switch (phase) {
              case 0: expectName(); cur.lastName = v; phase++; break;
              case 1: if (!numeric.test(data[i])) { cur.firstName = (cur.firstName ? cur.firstName + " " : "") + v; break; } else phase++;  
              case 2: expectNumber(); cur.id = v; phase++; break;
              case 3: expectOne(); phase++; break;
              case 4: expectOne(); phase++; runningSum = 0; scoreCols = 0; cur.scores = []; break;
              default: 
                if (v.indexOf(",") >= 0) { 
                  cur.score = cur.scores.pop();
                  cur.grade = v; 
                  if (cur.score * 2 != runningSum) throw "Score mismatch: " + cur.score + " <> "+(runningSum/2);
                  if (!scoreColsFirst) scoreColsFirst = scoreCols;
                  if (scoreColsFirst != scoreCols) throw "Score col count mismatch for: " + JSON.stringify(cur)
                  res.push(cur);
                  cur = {};
                  phase = 0; 
                  break;
                } else { runningSum = runningSum + v * 1; cur.scores.push(v*1); scoreCols++; }
                phase++;
                break
            }
          }
          return res
        }
           
        function parseExamResultsNew(dump){
           var REGEX_MATRIKEL_NR = /^[0-9]{6}$/;
           var REGEX_GRADE = /^[0-9]\.[0-9]$/;
           var REGEX_NAME = /^[^0-9]+/;
           var REGEX_PO = /^[WS]S[0-9]+|PO\s*[0-9]$/;
           var REGEX_NUMERIC = /^[0-9]+$/;
          
           var result = [];
           var data = dump.trim().split(/[\n\r]+/).forEach(function(row){
             var trow = row.trim();
             if (!trow) return;
             var cur = {"firstName": "", "lastName": "", "grade": "", "scores": [], "score": ""};
             var phase = 0;
             var runningSum = 0;
             trow.split(/\t/).forEach(function(rv){
               var v = rv.trim();
               function abort(s) { alert("Unexpected \"" + v+"\" in \"" + row+"\""+s+"\ncur:"+JSON.stringify(cur)) }
               function expectNothing() { if (v != "") abort("nothing"); }
               switch (phase) {
                 case 0: 
                   if (REGEX_GRADE.test(v)) /*fallthrough*/; 
                   else {
                     if (REGEX_MATRIKEL_NR.test(v)) phase++; else expectNothing();
                     break;
                   }
                 case 1: 
                   if (REGEX_GRADE.test(v)) {
                     cur.grade = v;
                     phase = 2;
                   } else expectNothing()
                   break;
                 case 2: 
                   if (REGEX_NAME.test(v)) {
                     cur.lastName = v;
                     phase = 3;
                   } else expectNothing()
                   break;
                 case 3: 
                   if (REGEX_NAME.test(v)) {
                     cur.firstName = v;
                     phase = 4;
                     break;
                   } else expectNothing()
                   break;
                 case 4: 
                   if (REGEX_NUMERIC.test(v))  { cur.scores.push(v); runningSum += v*1; }
                   else if (v == "") phase = 5; 
                   //else  abort()
                   break;
                 case 5: 
                   if (REGEX_NUMERIC.test(v)) { cur.score = v; if (runningSum != v) abort("sum mismatch: "+runningSum+ " " + v); phase=6; }
                   else expectNothing();
                   break;
                 default:
                   if (v != "kritisch") expectNothing()
               }
             });
             if (!cur.score && cur.scores.length > 2 && cur.scores[cur.scores.length - 1] * 2 == runningSum) 
               cur.score = cur.scores.pop();
             if (cur.score) {
               cur.raw = trow;
               result.push(cur);
             } else alert("confusing row: "+row);
           }); 
          return result
        }
       
        t.parentNode.parentNode.insertBefore(document.createElement("br"), t.parentNode.nextSibling);
        var importtextarea = document.createElement("textarea");
        t.parentNode.parentNode.insertBefore(importtextarea, t.parentNode.nextSibling);
        var imp = document.createElement("button");
        t.parentNode.parentNode.insertBefore(imp, t.parentNode.nextSibling);
        imp.textContent = "import...";
        imp.addEventListener("click", function(e){
          e.preventDefault();
          try {
            var parsed = parseExamResultsNew(importtextarea.value);
            var fuzzy = "";
            var errors = "";
            setScores(parsed, function(m) {
              //alert(m);
              errors += m + "\n";
            }, function(m) {
              fuzzy += m + "\n";
            });//prompt("Exam results:")));
            if (fuzzy) fuzzy = "\n\nFUZZY:\n" + fuzzy;
            if (errors) errors = "\n\nNOT FOUND:\n" + errors;
            importtextarea.value = errors + "\n" + fuzzy;
          } catch (e) {
            alert(e);
            throw e
          }
          return false;
        })
      }

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
  case "/course/modedit.php": 
    var addbtn = document.getElementById("id_option_add_fields");
    //if (/add=choice/.test(loc)) { 
    if (addbtn) {      
      var count = document.getElementsByName("option_repeats");
      function doImport(){
        if (localStorage["choiceImport"]) {
          var lines = localStorage["choiceImport"].split("\n");
          if (!lines[lines.length-1]) lines.pop();
          if (count.value * 1 < lines.length) addbtn.click(); 
          else {
            for (var i=0;i<lines.length;i++)
              document.getElementsByName("option["+i+"]")[0].value = lines[i];
            localStorage["choiceImport"] = "";
          }
        }
      }
      if (count)  {
        count = count[0];
        doImport();
      }
      addbtn.parentNode.appendChild(makeButton("import", function(){
        var importarea = document.getElementById("bbimportarea");
        if (!importarea) {
          addbtn.parentNode.appendChild(document.createElement("br"));
          var area = document.createElement("textarea");
          area.id = "bbimportarea";
          addbtn.parentNode.appendChild(area);
        } else {          
          localStorage["choiceImport"] = importarea.value;
          doImport();
        }
      }));
      addbtn.parentNode.appendChild(makeButton("set limit", function(){
        var limit = prompt("limit");  
        if (limit) {
          for (var i=0;i<count.value*1;i++)
            document.getElementsByName("limit["+i+"]")[0].value = limit;
        }
      }));
    }
    break;
    
  case "/calendar/event.php": 
    function setMoodleDate(id, date){
      selectOptionValue(document.getElementById(id+"_year"),date.getFullYear());
      selectOptionValue(document.getElementById(id+"_month"),date.getMonth()+1);
      selectOptionValue(document.getElementById(id+"_day"),date.getDate());
    }
    setTimeout(function(){ 
    var realWallDate = new Date(); var y = realWallDate.getFullYear();
    var startselect = document.createElement("select");
    var endselect = document.createElement("select");
    
    startselect.innerHTML = '<option value="">this week</option><option value="WS'+(y-1)+'">WS'+(y-1)+'/'+(y)+'</option><option value="SS'+y+'">SS'+y+'</option><option value="WS'+y+'">WS'+y+'/'+(y+1)+'</option>';
    var startchanged = function(){
      var dateToUse;
      if (startselect.value == "") {
        dateToUse = realWallDate;
        selectOptionValue(endselect, 16);
      } else {
        if (!getLectureDate(startselect.value)) { getLectureDates(startchanged); return; }
        var semester = getParsedLectureDate(startselect.value);
        dateToUse = semester.from;
        selectOptionValue(endselect, startselect.value);
      }
      selectOptionValue(document.getElementById("id_timestart_year"),dateToUse.getFullYear());
      selectOptionValue(document.getElementById("id_timestart_month"),dateToUse.getMonth()+1);
      selectOptionValue(document.getElementById("id_timestart_day"),dateToUse.getDate());
    };
    startselect.addEventListener("change", startchanged);

    var temp = '<option value="16">after 16 times</option><option value="WS'+(y-1)+'">WS'+(y-1)+'/'+(y)+'</option><option value="SS'+y+'">SS'+y+'</option><option value="WS'+y+'">WS'+y+'/'+(y+1)+'</option>';
    for (var i=1;i<16;i++) temp += '<option value="' + i + '">after '+i+' times</option>';
    endselect.innerHTML = temp;
    var endchanged = function(){
      if (endselect.value * 1 == endselect.value) return;
      if (!getLectureDate(endselect.value)) getLectureDates(endchanged);
    };
    endselect.addEventListener("change", endchanged);
    
    var form = document.getElementById("mform1");
    var btn = document.createElement("button");
    btn.textContent = "UNIVIS Time Import";
    btn.addEventListener("click", function(e){
      e.preventDefault();
      var univis = prompt("Univis time:");
      if (!univis) return;
      var kind = /^ *([A-Z]+)/.exec(univis)[1];
      var datePattern = /((; *(Mo|Di|Mi|Do|Fr|Sa|So))|[0-9]+[.][0-9]+[.][0-9]+)(.*)/;
      var timePattern = /([0-9]+):([0-9]+) *- *([0-9]+):([0-9]+)(.*)/;
      
      var times = [];
      var currentDate = "?";
      while (true) {
        datePos = univis.search(datePattern);
        timePos = univis.search(timePattern);
        if (timePos < 0) break;
        if (datePos >= 0 && datePos < timePos) {
          var nextDate = datePattern.exec(univis);
          currentDate = nextDate[3] ? nextDate[3] : nextDate[1];
          univis = nextDate[4];
        }
        var nextTime = timePattern.exec(univis);
        univis = nextTime[5];
        
        var fh = nextTime[1] * 1;
        var fm = nextTime[2] * 1;
        var th = nextTime[3] * 1;
        var tm = nextTime[4] * 1;
        
        if (fm == 0) { //remove c.t., no break
          fm = 15;
          if (th == fh + 2 && tm == 0) {
            th -= 1;
            tm = 45;
          }
        }
        
        times.push([currentDate, fh, fm, th, tm]);
        
      }
      //times: [Day, From Hour, FH Minute, To Hour, TH Minute]
      
      function setChecked(cb, value) {
        if (cb.checked == value) return;
        cb.checked = value;
        var event = new Event("change");
        cb.dispatchEvent(event);
      }
      
      var prettyKind = {"VORL": "Vorlesung", "UE": "Übung", "SEM": "Seminar", "HS": "Hauptseminar"}[kind];
      
      document.getElementById("id_name").value = prettyKind;
      if (times.length >= 2) alert("Veranstaltungen mit mehreren Daten sind momentan nicht unterstützt. TODO: Send Form with XMLHTTPRequest");
      for (var i=0;i < times.length; i++) {
        var t = times[i];
        selectOptionText(document.getElementById("id_timestart_hour"), t[1]);
        selectOptionText(document.getElementById("id_timestart_minute"), t[2]);
        setChecked(document.getElementById("id_duration_1"), true);
        selectOptionText(document.getElementById("id_timedurationuntil_hour"), t[3]);
        selectOptionText(document.getElementById("id_timedurationuntil_minute"), t[4]);
        if (t[0].length == 2) {
          var JSSortedDays = new Array("So","Mo","Di","Mi","Do","Fr","Sa");  
          var neededDay = JSSortedDays.indexOf(t[0]);
          var date = new Date(document.getElementById("id_timestart_year").value*1,document.getElementById("id_timestart_month").value*1-1,document.getElementById("id_timestart_day").value*1);
          var curDay = date.getDay();
          date.setDate(date.getDate() + neededDay - curDay + (neededDay < curDay ? 7 : 0) );
          var repcount = endselect.value;
          if (endselect.value * 1 != endselect.value) {
             var semester = getParsedLectureDate(endselect.value);
             semester.to.setHours(0,0,0,0);
             var oneDay = 24*60*60*1000; 
             var diffDays = Math.round((semester.to.getTime() - date.getTime()) / (oneDay)) + 1; //same day => 1, one week => 8
             if (diffDays <= 0) repcount = 1;
             else repcount = Math.ceil( diffDays  / 7);
          }
          setChecked(document.getElementById("id_repeat"), repcount != "1");
          document.getElementById("id_repeats").value = repcount;
        } else {
          var pd = /([0-9]+)[.]([0-9]+)[.]([0-9]+)/.exec(t[0]);
          date = new Date(pd[3]*1,pd[2]-1,pd[1]*1);
          setChecked(document.getElementById("id_repeat"), false);
          document.getElementById("id_repeats").value = "1";
        }
        
        selectOptionValue(document.getElementById("id_timestart_year"),date.getFullYear());
        selectOptionValue(document.getElementById("id_timestart_month"),date.getMonth()+1);
        selectOptionValue(document.getElementById("id_timestart_day"),date.getDate());
        selectOptionValue(document.getElementById("id_timedurationuntil_year"),date.getFullYear());
        selectOptionValue(document.getElementById("id_timedurationuntil_month"),date.getMonth()+1);
        selectOptionValue(document.getElementById("id_timedurationuntil_day"),date.getDate());
      }

      
      return false;
    });
    var insertBefore = form.firstElementChild;
    form.insertBefore(btn, insertBefore);
    form.insertBefore(document.createTextNode("start:"), insertBefore);
    form.insertBefore(startselect, insertBefore);
    form.insertBefore(document.createTextNode("end:"), insertBefore);
    form.insertBefore(endselect, insertBefore);
    }, 500);
    break;
  case "/calendar/view.php":     
    function markHolidays() {
      var tables = document.getElementsByClassName("calendartable");
      for (var ti=0;ti<tables.length;ti++) {
        var table = tables[ti];
        var temp;
        var as = table.getElementsByTagName("a");
        if (as.length > 0) temp = /time=([0-9]+)/.exec(as[0].href);
        if (!temp) temp = /time=([0-9]+)/.exec(loc);
        var date =  temp ? new Date(temp[1]*1000) : new Date();
        var year = date.getFullYear();
        var month = date.getMonth()+1;
        //var year = /(2[0-9]{3}) *$/.exec(document.title)[1]*1;
        if (localStorage["stateHolidays"+year]=="0") localStorage["stateHolidays"+year] = "";
        if (!localStorage["stateHolidays"+year]) { getStateHolidays(year, markHolidays); return; }  
        //alert(year+":"+!getLectureDate("SS"+year)  + "::"+ !getLectureDate("WS"+year) + "::"+ !getLectureDate("WS"+(year-1)))
        if (  (month < 10 && !getLectureDate("SS"+year))	
           || (month > 6 &&  !getLectureDate("WS"+year)) 
           || (month < 6 &&  !getLectureDate("WS"+(year-1)))) { getLectureDates(markHolidays); return; }
        date.setHours(0,0,0,0);

        var stringholidays = JSON.parse(localStorage["stateHolidays"+year]);
        var holidays = [];
        for (var i=0;i<stringholidays.length;i++) 
          holidays.push(new Date(stringholidays[i]));
 
        var ss = getParsedLectureDate("SS"+year);
        var ws = getParsedLectureDate("WS"+year);
        //alert(ws.toSource());
        var lastws = getParsedLectureDate("WS"+(year-1));

        var tbody = table.getElementsByTagName("tbody")[0];
 
        for (var i=0;i<tbody.rows.length;i++){
          for (var j=0;j<tbody.rows[i].cells.length;j++){
            var cell = tbody.rows[i].cells[j];
            var day = /^ *([0-9]+)/.exec(cell.textContent);
            if (!day) continue;
            day = day[1] * 1;
            date.setDate(day);

            var isInLectureTime = ss.contains(date) || ws.contains(date) || lastws.contains(date);
            if (!isInLectureTime) {
              //cell.style.backgroundColor = "#AAAAAA";
              cell.classList.add("lecture-free");
            }

            //if (day < 3) alert(date);
            var isHoliday = false;
            for (var k=0;k<holidays.length;k++) 
              if (holidays[k].getMonth() == date.getMonth() && holidays[k].getDate() == date.getDate() ) isHoliday = true;
            if (isHoliday) {
              //cell.style.backgroundColor = "#555555";
              cell.classList.add("holiday");
            }
          }
        }
        GM_addStyle(".lecture-free {background-color: #AAAAAA }" +
                    ".holiday {background-color: #555555 }" );
        //add again moodle default styles to prioritize it
        GM_addStyle(".calendar_event_course{background-color:#ffd3bd} .calendar_event_global{background-color:#d6f8cd} .calendar_event_group{background-color:#fee7ae}.calendar_event_user{	background-color:#dce7ec}"); 
        
        /*function dateTD(date){
          var date = date.getDate();
          //tbody.rows[date % 7].
          for (var i=0;i<tbody.rows.length;i++){
            for (var j=0;j<tbody.rows[i].cells.length;j++){
              if (tbody.rows[i].cells[j].textContent.trim().startsWith(date)) return tbody.rows[i].cells[j];
            }
          }
          return null;
        }
        for (var i=0;i<holidays.length;i++) {
          var then = new Date(holidays[i]);
          if (then.getMonth() == date.getMonth()) {
            dateTD(then).style.backgroundColor = "#555555";
          }
        }*/
      }
    }
    function iterateEvents(callback){
      var tables = document.getElementsByClassName("calendartable");
      //for (var ti=0;ti<tables.length;ti++) {
      var ti = 0;
      var table = tables[ti];
      var tbody = table.getElementsByTagName("tbody")[0];
 
      var hasLinks = false;
 
      for (var i=0;i<tbody.rows.length;i++){
        for (var j=0;j<tbody.rows[i].cells.length;j++){
          var cell = tbody.rows[i].cells[j];
          as = cell.getElementsByTagName("a");
          if (as.length == 0) continue;
          hasLinks = true;
          callback(as, cell);
        }
      }
      return hasLinks;
    }
    function removeFromHolidays(){
      if (!localStorage["deletionInProgress"]) return;
      urls = JSON.parse(localStorage["urlsToDelete"]);
      var hasLinks = iterateEvents(function(as, cell){
        if (cell.classList && (cell.classList.contains("lecture-free") || cell.classList.contains("holiday"))) {
          urls.push(as[0].href);
        }
      });
      
      localStorage["urlsToDelete"] = JSON.stringify(urls);
      if (hasLinks) location.href = document.getElementsByClassName("next")[0].href;
      else location.href = urls[0];
    }
    function calendarExport(){
      if (!localStorage["exportInProgress"]) return;
      exports = JSON.parse(localStorage["export"]);
 
      var hasLinks = iterateEvents(function(as, cell){
        var temp = [];
        for (var i=1;i<as.length;i++)
          temp.push({"name": as[i].textContent, "href": as[i].href});
        exports.push({
          "time": /time=([0-9]+)/.exec(as[0].href)[1]*1000,
          "href":  as[0].href,
          "events": temp
        });
      });
 
      localStorage["export"] = JSON.stringify(exports);
      if (hasLinks) location.href = document.getElementsByClassName("next")[0].href;
      else {
        localStorage["exportInProgress"] = "";
        var res = [];
        for (var i=0;i<exports.length;i++) { 
          var oneHalfDay = 24*60*60*1000 / 2;
          var d = (new Date(exports[i].time + oneHalfDay));
          var JSSortedDays = new Array("So","Mo","Di","Mi","Do","Fr","Sa");  
          res.push(JSSortedDays[d.getDay()] + ", " + d.toISOString().substr(0,10) + ": "+exports[i].events.map(function(o){return o.name;}).join(" ") ); 
        }
        alert(res.join("\n"));
      }
    }
    markHolidays();
    if (loc.contains("view=month")) {
      if (localStorage["deletionInProgress"]) removeFromHolidays();
      if (localStorage["exportInProgress"]) calendarExport();
      var buttons = document.getElementsByClassName("buttons")[0];
      buttons.appendChild(makeButton("remove from holidays", function(){
        localStorage["deletionInProgress"] = "true";
        localStorage["urlsToDelete"] = "[]";
        removeFromHolidays();
      }));
      buttons.appendChild(makeButton("export", function(){
        localStorage["exportInProgress"] = "true";
        localStorage["export"] = "[]";
        calendarExport();
      }));
    } else if (loc.contains("view=day")) {
      if (localStorage["deletionInProgress"]) {
        var found = false;
        var commands = document.getElementsByClassName("commands");
        if (commands.length > 0) {
          var as = commands[0].getElementsByTagName("a");
          for (var i=0;i<as.length;i++) if (as[i].href.contains("delete")) { location.href = as[i].href; found = true; break;}
        }
        if (!found) {
          urls = JSON.parse(localStorage["urlsToDelete"]);
          //alert(loc+"\n"+urls);
          
          var nurls = [];
          for (var i=0;i<urls.length;i++) if (urls[i] != loc) nurls.push(urls[i]);          
          localStorage["urlsToDelete"] = JSON.stringify(nurls);
          if (nurls.length == 0) { localStorage["deletionInProgress"] = ""; alert("done"); }
          else location.href = nurls[0];        
        }
      }
    } else if (localStorage["deletionInProgress"]) {
      urls = JSON.parse(localStorage["urlsToDelete"]);
      if (urls.length == 0) localStorage["deletionInProgress"] = "";
      else location.href = urls[0];
    }
    break;
  case "/calendar/delete.php":
    if (localStorage["deletionInProgress"]) {
      var forms = document.getElementsByTagName("form");
      forms[0].submit();
      /*for (var i=0;i<inputs.length;i++) 
        if (inputs[i].type == "submit") {
          inputs[i].
          break;
        }*/
    }
    break;
  case "http://www.uni-luebeck.de/studium/studierenden-service-center/service/termine/vorlesungszeiten.html":
  case "https://www.uni-luebeck.de/studium/studierenden-service-center/service/termine/vorlesungszeiten.html":
    parseLectureDates(document, 
      function(n,v){
        GM_setValue(n,v); 
        if (GM_getValue(n) != v) 
          alert(n+": "+GM_getValue(n) + " != "+v);  
      }, 
      function (n) {return GM_getValue(n); });
    break;
}

function extractId(href){
  return /id=([0-9]+)(&sortitemid=[a-zA-Z]+)?$/.exec(href)[1]
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
 
function normalizeDate(date){
  if (date.contains(".")) {
    var temp = /([0-9]+)[.]([0-9]+)[.]([0-9]+)/.exec(date);
    date = temp[3]+"-"+temp[2]+"-"+temp[1];
  }
  return date;
}
 
function getStateHolidays(year, callback){
  var oReq = new XMLHttpRequest();
  oReq.onload = function(){
    //alert(this.response);
    var response = JSON.parse(this.response);
    var dates = [];
    for (var i=0;i<response.length;i++) {
      var date = normalizeDate(response[i].date);
      dates.push(date);
    }
    localStorage["stateHolidays"+year] = JSON.stringify(dates);
    console.log("stateHolidays"+year + "=>"+localStorage["stateHolidays"+year]);
    callback();
  };
  oReq.open("get", "https://sec.ipty.de/feiertag/api.php?do=getFeiertage&loc=SH&jahr="+year, true);
  oReq.send();
}


function parseLectureDates(doc, setValue, getValue){
    var list = doc.getElementsByClassName("bodytext");
    var lastWinter;
    for (var i=0;i<list.length;i++) {
      var cur = list[i].textContent.trim();
      var dateRange = /([0-9.]+) *[-–] *([0-9.]+) *$/.exec(cur);
      if (!dateRange) continue;
      //          alert(cur+"?")
      //alert(cur+":"+dateRange[1]);
      //alert(normalizeDate(dateRange[1]));
      var from = normalizeDate(dateRange[1]);
      var to = normalizeDate(dateRange[2]);
      var range = {"from": from, "to": to};
      var year = (new Date(from)).getFullYear();
      //alert(cur);
      
      if (cur.startsWith("Sommersemester")) setValue("lecturesSS"+year, JSON.stringify(range));
      else if (cur.startsWith("Wintersemester")) {
        setValue("lecturesWS"+year, JSON.stringify(range));
        lastWinter = "lecturesWS"+year;
      } else if (cur.startsWith("Weihnachtsfrei") && lastWinter) {
        var temp = JSON.parse(getValue(lastWinter));
        temp.xmas = range;
        setValue(lastWinter, JSON.stringify(temp));
      }
    }
}

function getLectureDates(callback){
  location.href = "https://www.uni-luebeck.de/studium/studierenden-service-center/service/termine/vorlesungszeiten.html";
}

/* not working :(
function getLectureDates(callback){
if (called) return;
called = 1;
  var ret = GM_xmlhttpRequest({
  "onload": function(response){
  alert(response.responseText);
    var responseXML = new DOMParser().parseFromString(response.responseText, "text/html");
    parseLectureDates(responseXML, localStorage...
    callback();
  },
  "method": "GET",
  "url": "https://www.uni-luebeck.de/studium/studierenden-service-center/service/termine/vorlesungszeiten.html",
  "responseType": "document"
  });
}*/

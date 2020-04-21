// ==UserScript==
// @name     moodle helper jite
// @version  1
// @grant    none
// @include https://moodle.uni-luebeck.de/question/question.php*
// ==/UserScript==

var header = document.getElementById("id_generalheader");
var answers = document.getElementById("id_answerhdr");

var div = document.createElement("div");
div.innerHTML = "<textarea id='multianswers'></textarea><a id='multianswersbtn'  href='#'>set all</a>" 
answers.parentNode.insertBefore(div, answers); 

function simpleSendEvent (target, name){
  var evt = document.createEvent("Events");
  evt.initEvent(name, true, true);
  target.dispatchEvent(evt);
};

function isCorrect(s){
  return s != "" && s.charAt(0) == ' '
}

function selectOptionValue(select, value){
  for (var i=0; i<select.options.length; i++)
    if (select.options[i].value == value) { 
      select.selectedIndex = i; 
      return true; 
    }
  return false;
}


function setanswers(){  
  var a = localStorage["_currentAnswers"].split("\n").filter(function(s){return s.trim() != "";});
    
  if (a.length <= 1) return;
  
  if (!document.getElementById("id_answer_0")) return;
  if (!document.getElementById("id_answer_" + (a.length-1)) ) {
    document.getElementById("id_addanswers").click();
    return ;
  }
  var correct = 0;
  for (var i=0;i<a.length;i++) if (isCorrect(a[i])) correct++;
  //alert(correct);
  code = "" + (1/correct);
  if (code.length > 7) code = "" + (1/correct).toFixed(7);
  //alert(code);
  if (correct == 1) selectOptionValue(document.getElementById("id_single"), "1"); 
  else if (correct > 1) selectOptionValue(document.getElementById("id_single"), "0");
  
  selectOptionValue(document.getElementById("id_answernumbering"), "none");
  
  var qt = document.getElementById("id_questiontext");
  if (qt.value == "") {
    if (correct == 1) qt.value = "Markieren Sie die korrekte Aussage:";
    else if (correct > 1) qt.value = "Markieren Sie alle korrekten Aussagen:";
  }
  
  var qtf = document.getElementById("menuquestiontextformat");
  var format = qtf.options[qtf.selectedIndex].value;
  
  for (var i=0;i<a.length;i++) {
    document.getElementById("id_answer_" + i).value = a[i].trim();
    selectOptionValue(document.getElementById("menuanswer["+i+"]format"), format);
    if (isCorrect(a[i])) selectOptionValue(document.getElementById("id_fraction_" + i), code);
  }
      
  localStorage["_currentAnswers"] = "";
  
  return;
};

if (localStorage["_currentAnswers"]) setanswers();

document.getElementById("multianswersbtn").onclick = function(){
  document.getElementById("id_defaultmark").value = "0";
  localStorage["_currentAnswers"] =  document.getElementById("multianswers").value;
  setanswers();
  return false;
}
var win = Titanium.UI.currentWindow;
var myData = '';



var label2 = Titanium.UI.createLabel({
	color:'#999',
	text:win.title + myData,
	font:{fontSize:20,fontFamily:'Helvetica Neue'},
	textAlign:'center',
	width:'auto'
});

var xhr = Ti.Network.createHTTPClient(); 
xhr.onload = function(e) { 
    //handle response 
    myData = JSON.parse(this.responseText);
    Titanium.API.log(myData.error);
    Titanium.API.log(myData.message);
    
    
    var label2 = Titanium.UI.createLabel({
    	color:'#999',
    	text:myData.message,
    	font:{fontSize:20,fontFamily:'Helvetica Neue'},
    	textAlign:'center',
    	width:'auto'
    });
    win.add(label2);
}; 

xhr.open('GET','http://dev.sendlove.us/~schoash/candpweb/api.php?action=login&username=dev@schoash.com&password=test'); 
//xhr.send();

win.add(label2);
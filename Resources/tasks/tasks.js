//http://dev.sendlove.us/~schoash/candpweb/api.php?action=mission
function each(obj, fn ) {
    for( var i in obj ) {
        fn(obj[i]);
    }
}

var data = [];

// create table view
var tableview = Titanium.UI.createTableView({
	data:data
});

// add table view to the window
Titanium.UI.currentWindow.add(tableview);

var xhr = Ti.Network.createHTTPClient(); 
xhr.onload = function(e) { 
    //handle response 
    myData = JSON.parse(this.responseText);
    
    // create table view data object
    var data = [];
    var i = 0;
    each(myData.payload, function( item ) {
        var data = { hasChild:true,title:item.title, deadline:item.deadline, distance:item.distance, fontSize:10 };
        tableview.appendRow(data);
        i++;
    });
    
    
    // create table view event listener
    tableview.addEventListener('click', function(e)
    {
    	var win = Titanium.UI.createWindow({
    		url:'task_details.js',
    		title:e.rowData.title,
    		deadline:e.rowData.deadline,
    		distance:e.rowData.distance
    	});
    	win.title = e.rowData.title;
    	Titanium.UI.currentTab.open(win,{animated:true});
    });
    
}; 

xhr.open('GET','http://dev.sendlove.us/~schoash/candpweb/api.php?action=mission'); 
xhr.send();



/*var loading = Titanium.UI.createLabel({
	color:'#999',
	text:'Loading ...',
	font:{fontSize:20,fontFamily:'Helvetica Neue'},
	textAlign:'center',
	width:'auto'
});
Titanium.UI.currentWindow.add(loading);*/
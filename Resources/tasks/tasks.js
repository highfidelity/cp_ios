Ti.include("../helper.js");
Ti.include("../settings.js");
Ti.include("../version.js");
var win = Titanium.UI.currentWindow;
win.barColor = '#000000';

if (isIPhone3_2_Plus())
{
    //NOTE: starting in 3.2+, you'll need to set the applications
    //purpose property for using Location services on iPhone
    Ti.Geolocation.purpose = "Coffee and Power location";
}

var xhr = Ti.Network.createHTTPClient();
var data = [];
var latitude = '';
var longitude = '';
var db = '';

// create table view
var tableview = Titanium.UI.createTableView({
    data:data
});

function showIndicator()
{
	// window container
	indWin = Titanium.UI.createWindow({
		height:150,
		width:150
	});

	// black view
	var indView = Titanium.UI.createView({
		height:150,
		width:150,
		backgroundColor:'#000',
		borderRadius:10,
		opacity:0.8
	});
	indWin.add(indView);

	// loading indicator
	actInd = Titanium.UI.createActivityIndicator({
		style:Titanium.UI.iPhone.ActivityIndicatorStyle.BIG,
		height:30,
		width:30
	});
	indWin.add(actInd);

	// message
	var message = Titanium.UI.createLabel({
		text:'Loading',
		color:'#fff',
		width:'auto',
		height:'auto',
		font:{fontSize:20,fontWeight:'bold'},
		bottom:20
	});
	indWin.add(message);
	indWin.open();
	actInd.show();

};

function hideIndicator()
{
	actInd.hide();
	indWin.close({opacity:0,duration:1000});
};

function openDb(){
    db = Titanium.Database.open('candp');
    db.execute('CREATE TABLE IF NOT EXISTS CACHEDB  (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, deadline TEXT, distance TEXT)');
}

function closeDb(){
    db.close();
}
function deleteDb(){
    openDb();
    db.execute('DELETE FROM CACHEDB');
    closeDb();
}

function loadList(){
    xhr.open('GET', API_URL+'?action=mission&lat='+latitude+'&lon='+longitude); 
    xhr.send();
}

function setTableData(myData, cache){
    cache = typeof(cache) != 'undefined' ? cache : true;
    
    // create table view data object
    openDb();
    data = [];
    each(myData, function( item ) {
        var row = Ti.UI.createTableViewRow({height:50, hasChild:true, d_title:item.title, d_deadline:item.deadline, d_distance:item.distance});
        var title_lbl = Ti.UI.createLabel({text:item.title, font:{fontSize:14}, color:'#222', left:5, top:5, width:260, height:17});
        row.add(title_lbl);
        var distance_lbl = Ti.UI.createLabel({text:parseFloat(item.distance).toFixed(2)+' miles', font:{fontSize:12}, color:'#888', right:25, top:30, textAlign: 'right'});
        row.add(distance_lbl);
        //Titanium.API.info(item.title + ' ' +item.distance);
        var tmpdate = prettyDate(strtotime(item.deadline));
        if(tmpdate != 'Overdue'){
            tmpdate = "expires in " + tmpdate;
        }
        var expires_lbl = Ti.UI.createLabel({text: tmpdate, font:{fontSize:12}, color:'#888', left:5, top:30});
        row.add(expires_lbl);
        data.push(row);
        if(cache){
            db.execute('INSERT INTO CACHEDB (title, deadline, distance ) VALUES(?,?,?)', item.title, item.deadline, item.distance);
        }
    });
    closeDb();
    tableview.setData(data);
}
function loadListFromCache(){
    openDb();
    var rows = db.execute('SELECT * FROM CACHEDB');
    Titanium.API.info('ROW COUNT = ' + rows.getRowCount());
    if(rows.getRowCount() == 0){
        //Load the list from the internet, because there is nothing in the cache
        loadList();
    }
    Titanium.API.info('loading from cachedb');
    var myData = [];
    while (rows.isValidRow())
    {
        var tmp = [];
        tmp.title = rows.fieldByName('title');
        tmp.deadline = rows.fieldByName('deadline');
        tmp.distance = rows.fieldByName('distance');
        myData.push(tmp);
        rows.next();
    }
    rows.close();
    closeDb();
    setTableData(myData,0);
}

xhr.onload = function(e) {
    //handle response
    try{
        myData = JSON.parse(this.responseText);
    } catch(e){
        Titanium.API.info(this.responseText);
        return;
    }
    deleteDb();
    setTableData(myData.payload);
};
xhr.onerror = function(){Ti.API.info('error in api request');};

// create table view event listener
tableview.addEventListener('click', function(e)
{
    var win = Titanium.UI.createWindow({
        url:'task_details.js',
        title:e.rowData.d_title,
        deadline:e.rowData.d_deadline,
        distance:e.rowData.d_distance
    });
    win.title = e.rowData.d_title;
    Titanium.UI.currentTab.open(win,{animated:true});
});

//
//  SHOW CUSTOM ALERT IF DEVICE HAS GEO TURNED OFF
//
if (Titanium.Geolocation.locationServicesEnabled==false)
{
    Titanium.UI.createAlertDialog({title:'Coffee and Power', message:'Your device has geo turned off - turn it on.'}).show();
}
else
{
    if (Titanium.Platform.name != 'android') {
        var authorization = Titanium.Geolocation.locationServicesAuthorization;
        //Ti.API.log('Authorization: '+authorization);
        if (authorization == Titanium.Geolocation.AUTHORIZATION_DENIED) {
            Ti.UI.createAlertDialog({
                title:'Coffee and Power',
                message:'You have disallowed Coffee and Power from running geolocation services.'
            }).show();
        }
        else if (authorization == Titanium.Geolocation.AUTHORIZATION_RESTRICTED) {
            Ti.UI.createAlertDialog({
                title:'Coffee and Power',
                message:'Your system has disallowed Coffee and Power from running geolocation services.'
            }).show();
        }
    }

    Titanium.Geolocation.accuracy = Titanium.Geolocation.ACCURACY_NEAREST_TEN_METERS;

    Titanium.Geolocation.distanceFilter = 50;

    function getLocationAndReload(){
        showIndicator();
        Titanium.Geolocation.getCurrentPosition(function(e)
        {
            if (!e.success || e.error)
            {
                alert('Your system has disallowed Coffee and Power from running geolocation services.');
                return;
            }
            longitude = e.coords.longitude;
            latitude = e.coords.latitude;

            loadList();
        });
        hideIndicator();
    }
    getLocationAndReload();
}

var refresh = Titanium.UI.createButton({
	systemButton:Titanium.UI.iPhone.SystemButton.REFRESH
});
refresh.addEventListener('click', function(e)
{
    Titanium.API.info('reload');
    tableview.setData([]);
    getLocationAndReload();
});


if (Ti.Platform.name == 'iPhone OS') {
    win.leftNavButton = refresh;
} else {
    refresh.top = 5;
    refresh.title = "Refresh";
    refresh.width = 200;
    //win.add(refresh);
}

if(isAndroid()){
    tableview.top = 50;
    
    var view = Titanium.UI.createView({top:0, height:50});
    view.add(refresh);
    win.add(view);
}


loadListFromCache();
// add table view to the window
win.add(tableview);

Ti.App.addEventListener('resumed',function(e){
	Ti.API.info("app has resumed from the background");
	getLocationAndReload();
});
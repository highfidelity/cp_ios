var win = Titanium.UI.currentWindow;
win.barColor = '#000000';


var label2 = Titanium.UI.createLabel({
	color:'#999',
	text:'title: '+win.title,
	font:{fontSize:20,fontFamily:'Helvetica Neue'},
	textAlign:'center',
	width:'auto',
	top: 10
});

win.add(label2);


var label3 = Titanium.UI.createLabel({
	color:'#999',
	text:'distance: '+win.distance,
	font:{fontSize:20,fontFamily:'Helvetica Neue'},
	textAlign:'center',
	width:'auto',
	top: 50
});

win.add(label3);

var label4 = Titanium.UI.createLabel({
	color:'#999',
	text:'deadline: '+win.deadline,
	font:{fontSize:20,fontFamily:'Helvetica Neue'},
	textAlign:'center',
	width:'auto',
	top: 90
});

win.add(label4);
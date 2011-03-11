/*
 * @copyright (c) Copyright Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * @brief Set up all the styles we're using in the app.  We then shortcut this 
 * to $$ for convenience
 * 
 */

(function() {	
	// globally available theme object to hold theme colors/constants
	candp.view.theme = {
		textColor:'#000000',
		grayTextColor:'#888888',
		headerColor:'#333333',
		lightBlue:'#006cb1',
		darkBlue:'#93caed',
		fontFamily: candp.os({
			iphone:'Helvetica Neue',
			android:'Droid Sans'
		})
	};

	// shared property sets
	candp.view.properties = {
		// phone/screen dimensions
		platformWidth: Ti.Platform.displayCaps.platformWidth,
		platformHeight: Ti.Platform.displayCaps.platformHeight,
		
		// default components
		button: {
			backgroundImage:'images/button_off.png',
			backgroundSelectedImage:'images/button_on.png',
			borderStyle: Titanium.UI.BUTTON_BORDERSTYLE_ROUNDED,
			height:50,
			color:'#FFF',
			font: {
				fontSize:18,
				fontWeight:'bold'
			}
		},
		Label: {
			color:candp.view.theme.textColor,
			font: {
				fontFamily:candp.view.theme.fontFamily,
				fontSize:12
			},
			height:'auto'
		},
		Window: {
			backgroundImage:'images/ruff.png',
			navBarHidden:true,
			fullscreen: true,
			softInputMode:(Ti.UI.Android) ? Ti.UI.Android.SOFT_INPUT_ADJUST_RESIZE : ''
		},
		TableView: {
			backgroundImage:'images/ruff.png',
			separatorStyle:Ti.UI.iPhone.TableViewSeparatorStyle.NONE
		},
		TableViewRow: {
			backgroundImage:'images/tweet_bg.png',
			// the following is currently inconsistent between iPhone and Android.  Ho hum.
			selectedBackgroundColor: candp.view.theme.darkBlue, 
			backgroundSelectedColor: candp.view.theme.darkBlue,
			// height:110,
			className:'tvRow'
		},
		TextField: {
			height:55,
			borderStyle:Titanium.UI.INPUT_BORDERSTYLE_ROUNDED,
			color:'#000000'
		},
		TextArea: {
			borderRadius:10,
			backgroundColor:'#efefef',
			// gradient only works on iPhone
			backgroundGradient:{
				type:'linear',
				colors:[
					{color:'#efefef',position:0.0},
					{color:'#cdcdcd',position:0.50},
					{color:'#efefef',position:1.0}
				]
			}
		},
		WebView: {
		    scalesPageToFit: false,
		    backgroundImage: 'images/ruff.png'
		},
		
		ImageView: {
		    defaultImage: 'images/ruff.png',
	 	    borderColor: '#ffffff',
		    borderRadius: 5,
		    borderWidth: 2,
			canScale: false
		},

		// we use these as JS-based 'style classes'
		animationDuration: 500,
		stretch: {
			top:0,bottom:0,left:0,right:0
		},
		variableTopRightButton: {
			top:5,
			right:5,
			height:30,
			width:candp.os({
				iphone:60,
				android:'auto'
			}),
			color:'#ffffff',
			font: {
				fontSize:12,
				fontWeight:'bold'
			},
			backgroundImage:'images/button_30_off.png',
			backgroundSelectedImage:'images/button_30_on.png',
			borderStyle: Titanium.UI.BUTTON_BORDERSTYLE_ROUNDED
		},
		topRightButton: {
			top:5,
			right:5,
			height:30,
			width:38
		},
		headerText: {
			top:8,
			height:'auto',
			textAlign:'center',
			// color:candp.view.theme.headerColor,
            color: '#FFFFFF',
			font: {
				fontFamily:candp.view.theme.fontFamily,
				fontSize:18,
				fontWeight:'bold'
			}
		},
 		footerView: {
			backgroundImage:'images/buttonbar_bg.png',
			// 49 points is the iPhone standard footer
			// *FIXME: change the magic number into a named constant
			height: 49, 
            left: 0,
            right: 0,
            bottom:0
		},
        footerButton: {
            height: 49,
            bottom: 0
        },
 		headerView: {
			backgroundImage:'images/header_bg.png',
			// 44 points is the iPhone standard header size
			// *FIXME: change the magic number into a named constant
			height:44, 
			left: 0,
			right: 0,
			top:0
		},
		boldHeaderText: {
			height:'auto',
			color:'#000000',
			font: {
				fontFamily:candp.view.theme.fontFamily,
				fontSize:14,
				fontWeight:'bold'
			}
		},
		smallText: {
			color:candp.view.theme.grayTextColor,
			font: {
				fontFamily:candp.view.theme.fontFamily,
				fontSize:10
			},
			height:'auto'
		},
		spacerRow: {
			backgroundImage:'images/spacer_row.png',
			height:30,
			className:'spacerRow'
		}
	};
})();

// global shortcut for UI properties
var $$ = candp.view.properties;

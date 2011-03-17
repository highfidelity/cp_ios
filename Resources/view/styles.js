/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
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
        label: {
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
        tableView: {
            // separatorStyle:Ti.UI.iPhone.TableViewSeparatorStyle.NONE
            backgroundColor: '#FFFFFF'
        },
        tableViewRow: {
            backgroundSelectedColor: candp.view.theme.darkBlue,
            // height:110,
            className:'tvRow'
        },
        textField: {
            height: candp.os({
                iphone: 35,
                android: 40
            }),
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
        
        imageView: {
            canScale: true,
            height: 100,
            width: 100
        },

        // we use these as JS-based 'style classes'
        animationDuration: 500,
        stretch: {
            top:0,bottom:0,left:0,right:0
        },
        contained: {
            top: candp.config.headerHeight,
            bottom: candp.config.footerHeight,
            left: 0,
            right: 0,
            backgroundImage: 'images/default_background.png',
            zIndex: 10
        },
        containerView: {
            top: 0,
            bottom: 0,
            left: 0,
            right: 0
        },
        variableTopRightButton: {
            top:5,
            right:5,
            height:30,
            width: 60,
            /*
            width: candp.os({
                iphone:60,
                android:'auto'
            }),
            */
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
            width: 'auto',
            color: '#FFFFFF',
            font: {
                fontFamily:candp.view.theme.fontFamily,
                fontSize:18,
                fontWeight:'bold'
            }
        },
        titleText: {
            color: candp.view.theme.textColor,
            font: {
                fontFamily:candp.view.theme.fontFamily,
                fontSize:16,
                fontWeight: 'bold'
            },
            height:'auto'
        },
        largeText: {
            height:'auto',
            textAlign:'left',
            color:candp.view.theme.textColor,
            width: 'auto',
            font: {
                fontFamily:candp.view.theme.fontFamily,
                fontSize:25,
                fontWeight:'bold'
            }
        },
        mediumText: {
            color: candp.view.theme.textColor,
            font: {
                fontFamily:candp.view.theme.fontFamily,
                fontSize:14
            },
            height:'auto'
        },
        smallText: {
            color:candp.view.theme.grayTextColor,
            font: {
                fontFamily:candp.view.theme.fontFamily,
                fontSize:10
            },
            height:'auto'
        },
        smallSizeView: {
            width: Ti.Platform.displayCaps.platformWidth * 6 / 7,
            height: Ti.Platform.displayCaps.platformHeight / 2
        },
        footerView: {
            backgroundImage:'images/buttonbar_bg.png',
            height: candp.config.footerHeight, 
            left: 0,
            right: 0,
            bottom:0,
            zIndex: 20
        },
        footerButton: {
            height: 49,
            bottom: 0
        },
        headerView: {
            backgroundImage:'images/header_bg.png',
            height: candp.config.headerHeight, 
            left: 0,
            right: 0,
            top: 0,
            zIndex: 20
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
        spacerRow: {
            backgroundImage:'images/spacer_row.png',
            height:30,
            className:'spacerRow'
        },
        spacerLine: {
            backgroundImage: 'images/spacer_line.png',
            height: 1,
            left: 20,
            right: 20
        }
    };
})();

// global shortcut for UI properties
var $$ = candp.view.properties;

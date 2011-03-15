/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief Top level main application framework
 * 
 */

(function() {
    var platformWidth = Ti.Platform.displayCaps.platformWidth;

    //create the main application window
    candp.view.createApplicationWindow = function(args) {
        var win = Ti.UI.createWindow(candp.combine($$.Window, {
            exitOnClose:true,
            orientationModes:[Ti.UI.PORTRAIT]
        }));

        // application framework level views
        var buttonBarView = candp.view.createButtonBarView();
        var headerBarView = candp.view.createHeaderBarView({backgroundImage: 'images/buttonbar_bg.png'});
        var containerView = Ti.UI.createView($$.containerView);

        // add the framework level views to our top level window
        win.add(containerView);
        win.add(buttonBarView);
        win.add(headerBarView);

        // global views
        candp.view.views.missionDetails = candp.view.createMissionDetailsView();
        // candp.view.views.chat = candp.view.createChatView();
        candp.view.views.chat = candp.view.createUserProfileView();
        candp.view.views.missionList = candp.view.createMissionListView();
        candp.view.views.loginView = candp.view.createLoginView();

        // add the gobal views to our top level window
        for (var view in candp.view.views) {
            containerView.add(candp.view.views[view]);
        }

        // keep track of our currenly active view
        // candp.view.currentActiveView = 'missionList';       
        candp.view.currentActiveView = 'chat';

        // set our initial start screen 
        win.addEventListener('open', function() {
            candp.view.views[candp.view.currentActiveView].show();
        });

    
        // check for network connection and make sure we let people know if it's not available
        // Apple make us check this every time we make a connection out
        // *FIXME: put this code in a better place; it doesn't belong here!
        if (Ti.Network.online == false) {
            // *FIXME: use the alert shortcut we've created
            // *FIXME: create i18n strings for these messages
            Ti.UI.createAlertDialog({
                title: 'No Network Connection', 
                message: 'Sorry, but we couldn\'t detect a connection to the internet so functionality will be limited.'
            }).show();
        }
        
        // We need to check our current GPS location, using our last known location 
        // as a backup but we can't do a check for GPS location on the android here, as 
        // Titanium will cancel it straight away (as a battery preservation technique!).  
        // As such we have our GPS checking done in the MissionList view.  Yeah, I know, 
        // it's a pain :-(

        // check our current session id, and see if we're still logged in
        candp.sessionId = Ti.App.Properties.getString('sessionId', '');
        applicationModel.checkLoggedIn();


        // respond to the top level footer/header button presses
        // *FIXME: add slide left/right
        Ti.App.addEventListener('app:buttonBar.click', function(e) {
            switch (candp.osname) {
                case 'android':
                    // *TODO: investigate the problems with Android animations
		            candp.view.views[candp.view.currentActiveView].hide();
		            candp.view.views[e.nextViewToShow].show();
                    break;
                case 'iphone':
		            // make the current view slide out, and the new view slide in
		            candp.view.views[e.nextViewToShow].left = $$.platformWidth;
		            candp.view.views[e.nextViewToShow].show();
		               
		            candp.view.slide(candp.view.views[candp.view.currentActiveView], 'left', function() {
		                candp.view.views[candp.view.currentActiveView].hide();
		            }, function() {
		                candp.view.slide(candp.view.views[e.nextViewToShow], 'left');                
		            });
		            break;
            }

            candp.view.currentActiveView = e.nextViewToShow;

            // and as we've pressed a button bar button, we need to 
            // hide the login screen if it's showing
            Ti.App.fireEvent('app:login.hide');
        });

        return win;
    };
})();

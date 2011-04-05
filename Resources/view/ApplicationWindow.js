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
        var containerView;

        var win = Ti.UI.createWindow(candp.combine($$.Window, {
            exitOnClose:true,
            orientationModes:[Ti.UI.PORTRAIT]
        }));

        // whilst we're waiting for things to happen, get that activity indicator showing
        var spinnerView = candp.view.createSpinnerView();
        win.add(spinnerView);
        Ti.App.fireEvent('app:spinner.show');

        // application framework level views
        var buttonBarView = candp.view.createButtonBarView();
        var headerBarView = candp.view.createHeaderBarView();
        var loginView = candp.view.createLoginView();
        var makeOfferView = candp.view.createMakeOfferView();


        // Unfortunately, we need to differentiate between android and iphone
        // if we're android, we want to add a simple container view
        if (candp.osname === 'android') {
            containerView = Ti.UI.createView(candp.combine($$.containerView, {}));
            win.add(containerView);
        }
        
        // add the framework level views to our top level window
        win.add(buttonBarView);
        win.add(headerBarView);
        win.add(loginView);
        win.add(makeOfferView);

        // global views
        candp.view.views.chat = candp.view.createChatView();
        candp.view.views.userList = candp.view.createUserListView();
        candp.view.views.missionList = candp.view.createMissionListView();
        candp.view.views.notifications = candp.view.createNotificationsView();
        candp.view.views.missionDetails = candp.view.createMissionDetailsView();
        candp.view.views.userProfile = candp.view.createUserProfileView();

        if (candp.osname === 'iphone') {
            containerView = Ti.UI.createScrollableView(candp.combine($$.containerView, {
                views: [
                    candp.view.views.chat, 
                    candp.view.views.userList, 
                    candp.view.views.missionList, 
                    candp.view.views.notifications,
                    candp.view.views.missionDetails, 
                    candp.view.views.userProfile
                ],
                showPagingControl: false,
                currentPage: 2
            }));
            win.add(containerView);
        }

        for (var view in candp.view.views) {
            if (candp.view.views.hasOwnProperty(view)) {
                candp.os({
                    android: function() { containerView.add(candp.view.views[view]); },
                    iphone: function() { candp.view.views[view].visible = true; }
                });
            }
        }


        // keep track of our currently active view
        candp.view.currentActiveView = 'missionList';

        // set our initial start screen 
        win.addEventListener('open', function() {
            candp.os({
                android: function() { 
                    candp.view.views[candp.view.currentActiveView].show(); 
                },
                iphone: function() { 
                    containerView.scrollToView(2); 
                } 
            });
        });

        
        // We need to check our current GPS location, using our last known location 
        // as a backup but we can't do a check for GPS location on the android here, as 
        // Titanium will cancel it straight away (as a battery preservation technique!).  
        // As such we have our GPS checking done in the MissionList view.  Yeah, I know, 
        // it's a pain :-(

        // go get the latest set of missions, even before we've logged in
        Ti.App.fireEvent('app:missionList.getMissions');

        // check our current session id, and see if we're still logged in
        candp.sessionId = Ti.App.Properties.getString('sessionId', '');
        applicationModel.checkLoggedIn();


        // respond to the top level footer/header button presses
        Ti.App.addEventListener('app:buttonBar.click', function(e) {
            switch (candp.osname) {
               case 'android':
                    // *TODO: investigate the problems with Android animations
		            candp.view.views[candp.view.currentActiveView].hide();
		            candp.view.views[e.nextViewToShow].show();
                    break;
                case 'iphone':
                    containerView.scrollToView(e.clickedButtonIndex);
		            break;
            }
                                    
            candp.view.currentActiveView = e.nextViewToShow;

            // and as we've pressed a button bar button, we need to 
            // hide the login screen if it's showing
            Ti.App.fireEvent('app:login.hide');

            // and same thing with a make offer page if it's showing
            Ti.App.fireEvent('app:makeOffer.hide', {show: 'refreshButton'});
        });


        // as we have the container view here, we want to scroll to the
        // mission detail screen when it gets shown
        Ti.App.addEventListener('app:missionDetail.show', function() {
            candp.os({
                android: function() {
                    candp.view.currentActiveView = 'missionDetails';
                },
                iphone: function() {
                    containerView.scrollToView(4);                
                }         
            });
        });

        // as we have the container view here, we want to scroll to the
        // user profile detail screen when it gets shown
        Ti.App.addEventListener('app:userProfile.show', function() {
            candp.os({
                android: function() {
                    candp.view.currentActiveView = 'userProfile';
                },
                iphone: function() {
                    containerView.scrollToView(5);   
                }
            });
        });

        // make sure we respond to APN register for push notifications
        Ti.App.addEventListener('app:applicationWindow.registerForPushNotifications', function(e) {
            applicationModel.registerForPushNotifications();
        });

        // make sure we update the candp server with our location when we get a GPS signal
        Ti.App.addEventListener('app:applicationWindow.setLocation', function(e) {
            applicationModel.setLocation(e);
        });

        return win;
    };
})();

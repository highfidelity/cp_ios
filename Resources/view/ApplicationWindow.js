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

        // application framework level views
        var buttonBarView = candp.view.createButtonBarView();
        var headerBarView = candp.view.createHeaderBarView();
        var loginView = candp.view.createLoginView();
        var makeOfferView = candp.view.createMakeOfferView();

        // Unfortunately, we need to differentiate between android and iphone
        // if we're android, we want to add a simple container view
        if (candp.osname === 'android') {
            containerView = Ti.UI.createView(candp.combine($$.containerView, {}));
            candp.view.containerView = containerView;
            win.add(containerView);
        }
        
        // add the framework level views to our top level window
        win.add(buttonBarView);
        win.add(headerBarView);
        win.add(loginView);
        win.add(makeOfferView);

        // now that we have a header bar, we can start our spinner off
        Ti.App.fireEvent('app:spinner.show');

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

        // we only want our iphone views to be visible at this point in time
        if (candp.osname === 'iphone') {
            for (var view in candp.view.views) {
                if (candp.view.views.hasOwnProperty(view)) {
                    candp.view.views[view].visible = true;
                }
            }
        }

        // keep track of our currently active view
        candp.view.currentActiveView = 'missionList';

        // set our initial start screen 
        win.addEventListener('open', function() {
            candp.os({
                android: function() {
                    // with Android we're doing JIT view creation
                    containerView.add(candp.view.views[candp.view.currentActiveView]);
                    candp.view.views[candp.view.currentActiveView].show(); 
                },
                iphone: function() { 
                    containerView.scrollToView(2); 
                } 
            });
        });

        
        // We need to check our current GPS location, using our last known location 
        // as a backup but we can't do a check for GPS location on the Android here, as 
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

                    // Android JIT view creation means we need to remove the previous view
                    containerView.remove(candp.view.views[candp.view.currentActiveView]);
                    containerView.add(candp.view.views[e.nextViewToShow]);

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

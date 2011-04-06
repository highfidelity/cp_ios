/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief View for top header bar.  We use our own custom view so that we have 
 * the same layout in both Android and iPhone
 * 
 */

(function() {
    candp.view.createHeaderBarView = function (options) {
        // helper function for centering the two header text sections
        function _centerText(firstLabel, secondLabel) {
            firstLabel.visible = false;
            secondLabel.visible = false;

            headerBarView.remove(firstLabel);
            headerBarView.add(firstLabel);

            headerBarView.remove(secondLabel);
            headerBarView.add(secondLabel);

            var label1size = firstLabel.toImage().width;
            var label2size = secondLabel.toImage().width;
            var firstLabelLeft = ($$.platformWidth/2) - ((label1size + label2size)/2);
            var secondLabelLeft = label1size + firstLabelLeft;

            firstLabel.left = firstLabelLeft;
            secondLabel.left = secondLabelLeft;

            firstLabel.visible = true;
            secondLabel.visible = true;
        }

        // where should our back button go to?
        var backButtonDestination = {
            destinationView: 'missionList',
            destinationIndex: 2
        };

        // container for our main header bar view
        var headerBarView = Ti.UI.createView(candp.combine($$.headerView, {
            backgroundImage: 'images/buttonbar_bg.png',
            zIndex: 30
        }));

        // label for our nickname when logged in, or the app title when logged out
        var headerBarNickname = Ti.UI.createLabel(candp.combine($$.headerText, {
            text: L('coffee_and_power'),
            textAlign: 'right',
            left: 10
        }));

        Ti.App.addEventListener('headerBar:headerBarNickname.changeText', function(e) {
            headerBarNickname.text = e.newText;
            _centerText(headerBarNickname, headerBarBalance);
        });
        headerBarView.add(headerBarNickname);

        // label for our balance when logged in, or blank when logged out
        var headerBarBalance = Ti.UI.createLabel(candp.combine($$.headerText, {
            text: ' ',
            color: '#00FF00',
            textAlign: 'left',
            left: 42
        }));

        Ti.App.addEventListener('headerBar:headerBarBalance.changeText', function(e) {
            headerBarBalance.text = e.newText;
            _centerText(headerBarNickname, headerBarBalance);
        });
        headerBarView.add(headerBarBalance);

        // center the first display of 'coffee&power'
        _centerText(headerBarNickname, headerBarBalance);

 
        // button to allow us to login or logout
        var loginButton = Ti.UI.createButton(candp.combine($$.variableTopRightButton, {
            title: L('login')
        }));

        loginButton.addEventListener('click', function(e) {
            headerBarModel.loginButton(e);
        });

        Ti.App.addEventListener('headerBar:loginButton.changeText', function(e) {
            loginButton.title = e.newText;
        });
        headerBarView.add(loginButton);


        // keep track of which button is showing so that we 
        // know which one to restore after we've finished
        // with the spinner
        var whichButtonIsShowing = 'refreshButton';

        // now to create our spinner/activity indicator
        candp.view.spinnerIsEnabled = true;
        var activityIndicator;
        if (candp.osname === 'iphone') {
            activityIndicator = Titanium.UI.createActivityIndicator({
                height:30,
                width:30,
                top: 5,
                left: 13
            });
        } else {
            var images = [];
            for (var i=1; i<12; i++) {
                images.push('images/wait30trans_neg_' + ((i<10)?'00'+i:'0'+i)+'.gif');
            }

            activityIndicator = Titanium.UI.createImageView({
                height:30,
                width:30,
                top: 5,
                left: 13,
                duration: 150,
                repeatCount: 0,
                images: images
            });

            activityIndicator.addEventListener('load', function(e) {
                activityIndicator.start();
            });
        }
        headerBarView.add(activityIndicator);

        Ti.App.addEventListener('app:spinner.show', function() {
            if (candp.view.spinnerIsEnabled) {
                Ti.App.fireEvent('headerBar:refreshButton.hideBoth');
                activityIndicator.show();
            }
        });

        Ti.App.addEventListener('app:spinner.hide', function() {
            if (candp.view.spinnerIsEnabled) {
                activityIndicator.hide();
                Ti.App.fireEvent('headerBar:' + whichButtonIsShowing + '.show');
            }
        });


        // generic back button
        var backButton = Ti.UI.createButton(candp.combine($$.backTopLeftButton, {
            title: L('back'),
            visible: false
        }));
        backButton.addEventListener('click', function(e) {
            Ti.App.fireEvent('app:buttonBar.click', {
                nextViewToShow: backButtonDestination.destinationView,
                clickedButtonIndex: backButtonDestination.destinationIndex,
                button_name: backButtonDestination.destinationView
            });
            Ti.App.fireEvent('headerBar:backButton.hide');
        });
        headerBarView.add(backButton);

        
        // generic refresh button
        var refreshButton;
        refreshButton = Ti.UI.createButton(candp.combine($$.refreshTopLeftButton, {
            visible: true
        }));
        refreshButton.addEventListener('click', function(e) {
            // refresh button should determine which action to do
            // based on what's currently showing on the screen
            switch(candp.view.currentActiveView) {
                case 'missionList' :
                    Ti.App.fireEvent('app:missionList.getMissions');
                    break;
                case 'userList' :
                    Ti.App.fireEvent('app:userList.getUsers');
                    break;
            }
        });
        headerBarView.add(refreshButton);

        // handle the showing and hiding of the two back/refresh buttons
        Ti.App.addEventListener('headerBar:backButton.show', function(e) {
            whichButtonIsShowing = 'backButton';
            if (e.destinationView && e.destinationIndex) {
                backButtonDestination = {
                    destinationView: e.destinationView,
                    destinationIndex: e.destinationIndex
                };
            }
            backButton.show();
            refreshButton.hide();
        });
        Ti.App.addEventListener('headerBar:backButton.hide', function(e) {
            whichButtonIsShowing = 'refreshButton';
            backButton.hide();
            refreshButton.show();
        });
        Ti.App.addEventListener('headerBar:refreshButton.show', function(e) {
            whichButtonIsShowing = 'refreshButton';
            refreshButton.show();
            backButton.hide();
        });
        Ti.App.addEventListener('headerBar:refreshButton.hide', function(e) {
            whichButtonIsShowing = 'backButton';
            refreshButton.hide();
            backButton.show();
        });
        Ti.App.addEventListener('headerBar:refreshButton.hideBoth', function(e) {
            refreshButton.hide();
            backButton.hide();
        });
        

        // respond to login/logout state changes
        Ti.App.addEventListener('app:headerBar.changeState', function(e) {
            headerBarModel.changeState(e);
        });


        // respond to swipe down/up to display the logged in status bar
        headerBarView.addEventListener('touchstart', function(e) {
            headerBarView.touchStart = e.y;
        });
        headerBarView.addEventListener('touchend', function(e) {
            headerBarView.touchEnd = e.y;

            if (headerBarView.touchEnd > headerBarView.touchStart + 10) {
                Ti.App.fireEvent('app:loggedInBar.show');
            }
            if (headerBarView.touchEnd < headerBarView.touchStart - 10) {
                Ti.App.fireEvent('app:loggedInBar.hide');
            }

            headerBarView.touchStart = $$.platformHeight;
        });


        return headerBarView;
    };
})();


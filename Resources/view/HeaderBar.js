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


        // generic back button
        var backButton = Ti.UI.createButton(candp.combine($$.backTopLeftButton, {
            title: L('back'),
            visible: false
        }));
        backButton.addEventListener('click', function(e) {
            Ti.App.fireEvent('app:buttonBar.clicked', {
                nextViewToShow: backButtonDestination.destinationView,
                clickedButtonIndex: backButtonDestination.destinationIndex,
                button_name: backButtonDestination.destinationView
            });
            Ti.App.fireEvent('headerBar:backButton.hide');
        });
        headerBarView.add(backButton);
        
        // generic refresh button
        var refreshButton;
        if (candp.osname === 'iphone') {
            refreshButton = Ti.UI.createButton(candp.combine($$.refreshTopLeftButton, {
                image: 'images/refresh.png',
                visible: true
            }));
        } else {
            refreshButton = Ti.UI.createButton(candp.combine($$.refreshTopLeftButton, {
                visible: true
            }));            
        }
        refreshButton.addEventListener('click', function(e) {
            Ti.App.fireEvent('app:missionList.getMissions');
        });
        headerBarView.add(refreshButton);

        // handle the showing and hiding of the two back/refresh buttons
        Ti.App.addEventListener('headerBar:backButton.show', function(e) {
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
            backButton.hide();
            refreshButton.show();
        });
        Ti.App.addEventListener('headerBar:refreshButton.show', function(e) {
            refreshButton.show();
            backButton.hide();
        });
        Ti.App.addEventListener('headerBar:refreshButton.hide', function(e) {
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


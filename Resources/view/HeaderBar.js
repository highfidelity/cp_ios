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
            Ti.API.info('Label1 (' + firstLabel.text + ') size = ' + label1size);

            var label2size = secondLabel.toImage().width;
            Ti.API.info('Label2 (' + secondLabel.text + ')size = ' + label2size);

            var firstLabelLeft = ($$.platformWidth/2) - ((label1size + label2size)/2);
            var secondLabelLeft = label1size + firstLabelLeft;
            Ti.API.info('first = ' + firstLabelLeft + ' second = ' + secondLabelLeft);

            firstLabel.left = firstLabelLeft;
            secondLabel.left = secondLabelLeft;

            firstLabel.visible = true;
            secondLabel.visible = true;
        }

        // container for our main header bar view
        var headerBarView = Ti.UI.createView(candp.combine($$.headerView, options));

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


        // generic back/refresh button
        var refreshButton = Ti.UI.createButton(candp.combine($$.refreshTopLeftButton, {
            title: L('back')
        }));
        headerBarView.add(refreshButton);


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
                Ti.API.info('app:loggedInBar.show');
            }
            if (headerBarView.touchEnd < headerBarView.touchStart - 10) {
                Ti.API.info('app:loggedInBar.hide');
            }

            headerBarView.touchStart = $$.platformHeight;
        });


        return headerBarView;
    };
})();


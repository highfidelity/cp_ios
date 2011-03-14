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
            // *TODO: investigate why this centering code doesn't work reliably
            var label1size = firstLabel.toImage().width;
            Ti.API.info('Label1 (' + firstLabel.text + ') size = ' + label1size);

            var label2size = firstLabel.toImage().width;
            Ti.API.info('Label2 (' + secondLabel.text + ')size = ' + label2size);

            var firstLabelLeft = ($$.platformWidth/2) - ((label1size + label2size)/2);
            var secondLabelLeft = label1size + firstLabelLeft;
            Ti.API.info('first = ' + firstLabelLeft + ' second = ' + secondLabelLeft);

            firstLabel.left = firstLabelLeft;
            secondLabel.left = secondLabelLeft;

            firstLabel.top = oldTop;
            secondLabel.top = oldTop;
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
        });


        // label for our balance when logged in, or blank when logged out
        var headerBarBalance = Ti.UI.createLabel(candp.combine($$.headerText, {
            text: ' ',
            color: '#00FF00',
            textAlign: 'left',
            left: 42
        }));

        Ti.App.addEventListener('headerBar:headerBarBalance.changeText', function(e) {
            headerBarBalance.text = e.newText;
        });

 
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


        // assemble  our header bar
        headerBarView.add(headerBarNickname);
        headerBarView.add(headerBarBalance);
        headerBarView.add(loginButton);


        // respond to login/logout state changes
        Ti.App.addEventListener('app:headerBar.changeState', function(e) {
            headerBarModel.changeState(e);
        });

        

        // *TODO: Add refresh button on left hand side of the header bar



/*
        // *FIXME: Remove this label when we go live!
        // Keep a check on our memory usage while we work
        var memoryCheck = Ti.UI.createLabel(candp.combine($$.headerText, {
            left: 5,
            height: 20,
            width: 100,
            font: {
                fontSize:10,
                fontWeight:'bold'
            },
            text: String.format('%5.2f', Ti.Platform.availableMemory)
        }));
        headerBarView.add(memoryCheck);

        // *FIXME: Remove this callback when we go live!
        setInterval(function() {
            memoryCheck.text = String.format('%5.2f', Ti.Platform.availableMemory);            
        }, 1000);
*/


        return headerBarView;
    };
})();


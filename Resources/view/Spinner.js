/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief Spinner/loading animatino view
 * 
 */

(function() {
    candp.view.createSpinnerView = function (args) {
        var activityIndicator, spinnerView;

        if (candp.osname === 'iphone') {
            spinnerView = Ti.UI.createView({
                backgroundColor: '#000000',
                borderRadius: 15,
                opacity: 0.8,
                width: 'auto',
                left: 10, 
                right: 10,
                height: 70,
                zIndex: 100
            });                

            activityIndicator = Titanium.UI.createActivityIndicator({
                style: Titanium.UI.iPhone.ActivityIndicatorStyle.BIG,
                height:30,
                width:30,
                top: 20,
                left: 30
            });
            spinnerView.add(activityIndicator);
    
            var message = Ti.UI.createLabel(candp.combine($$.mediumText, {
                text: L('activity_indicator'),
                color: '#FFFFFF',
                width: 'auto',
                height: 'auto',
                top: 15,
                left: 80,
                right: 30
            }));
            spinnerView.add(message);
        } else {
            spinnerView = Ti.UI.createView({
                backgroundImage: 'images/transparent.png',
                width: 'auto',
                left: 10, 
                right: 10,
                height: 70,
                zIndex: 100
            }); 

            // android is much easier for activity indicators!
            activityIndicator = Ti.UI.createActivityIndicator({
                message: L('activity_indicator')
            });
        }
    

        Ti.App.addEventListener('app:spinner.show', function() {
            spinnerView.show();                
            activityIndicator.show();
        });

        Ti.App.addEventListener('app:spinner.hide', function() {
            activityIndicator.hide();
            spinnerView.hide();                
         });

        return spinnerView;
    };
})();

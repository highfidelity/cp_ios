/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief View for make offer screen.  This is shown as a modal dialog which gets
 * the user's offer to run a mission and sends the data to the candp server
 * 
 */

(function() {
    candp.view.createMakeOfferView = function (options) {
        var viewOptions = options || {
            missionTitle: '',
            receiverUserId: 0,
            missionId: 0           
        };

        var makeOfferView = Ti.UI.createView(candp.combine($$.contained, {
            visible: false,
            // *TODO: investigate problems with Android detecting view visiblity
            showing: false,
            zIndex: 8
        }));

        // use a dialog container
        var containerView = Ti.UI.createView(candp.combine($$.smallSizeView, {
            top: 20,
            left: 20,
            right: 20,
            height: 300,
            backgroundColor: '#FFFFFF',
            borderRadius: 15
        }));

        // offer details
        var missionTitle = Ti.UI.createLabel(candp.combine($$.titleText, {
            top: 15,
            left: 15,
            right: 15,
            textAlign: 'left',
            color: '#000000',
            text: L('offer_for') + ' : ' + viewOptions.missionTitle
        }));
        containerView.add(missionTitle);

        var offerTitleText = Ti.UI.createTextArea(candp.combine($$.textArea, {
            top: 70,
            left: 15,
            right: 15,
            height: 80,
            keyboardType: Titanium.UI.KEYBOARD_DEFAULT,
            autocapitalization: Titanium.UI.TEXT_AUTOCAPITALIZATION_SENTENCES,
            returnKeyType: Titanium.UI.RETURNKEY_NEXT
        }));

        offerTitleText.addEventListener('return', function() {
            offerAmount.focus();
        });

        containerView.add(offerTitleText);

        var offerAmountLabel = Ti.UI.createLabel(candp.combine($$.headerText, {
            color: '#000000',
            top: 165,
            left: 15,
            text: '$'
        }));
        containerView.add(offerAmountLabel);
        
        var offerAmount = Ti.UI.createTextField(candp.combine($$.textField, {
            top: 160,
            left: 40,
            width: 80,
            keyboardType: Titanium.UI.KEYBOARD_NUMBERS_PUNCTUATION,
            autocapitalization: Titanium.UI.TEXT_AUTOCAPITALIZATION_NONE,
            returnKeyType: Titanium.UI.RETURNKEY_DONE
        }));

        offerAmount.addEventListener('return', function() {
            offerAmount.blur();
            makeOfferButton.fireEvent('click');
        });

        containerView.add(offerAmount);

        var makeOfferButton = Ti.UI.createButton(candp.combine($$.button, {
            title: L('make_offer'),
            top: 220,
            height: 37,
            left: (candp.osname === 'iphone') ? 5 : 20,
            width: (candp.osname === 'iphone') ? 130 : 110
        }));
        makeOfferButton.addEventListener('click', function(e) {
            offerAmount.blur();
            offerTitleText.blur();
            
            // validate our input and then send off an offer
            if (!candp.model.validateInput(offerAmount.value, candp.config.validationPositiveNumeric)) {
                // at least make sure you have an amount put in, eh?
                candp.view.alert(L('error'), L('make_offer_fill_in_amount'));
            } else if (!candp.model.validateNotEmpty(offerTitleText.value)) {
                // don't you want to say something nice to your mission co-ordinator?
                candp.view.alert(L('error'), L('make_offer_fill_in_title'));
            } else {
                // ok, we can send the offer
                missionDetailsModel.makeOffer({
                   offerTitle: offerTitleText.value,
                   offerAmount: offerAmount.value,
                   receiverUserId: viewOptions.receiverUserId,
                   missionId: viewOptions.missionId,
                   payMe: 1
                }, function(e) {
                    if (e.succeeded) {
                        // yay, it worked out just fine
                        candp.view.alert(L('make_offer_made'), L('make_offer_success'));
                        Ti.App.fireEvent('app:makeOffer.hide', {show: 'backButton'});
                    } else {
                        // boo, something went wrong
                        candp.view.alert(L('error'), L('make_offer_generic_error'));
                    }
                });
            }
        });
        containerView.add(makeOfferButton);

        var cancelButton = Ti.UI.createButton(candp.combine($$.button, {
            title: L('cancel'),
            top: 220,
            height: 37,
            right: (candp.osname === 'iphone') ? 5 : 20,
            width: (candp.osname === 'iphone') ? 130 : 110
        }));
        cancelButton.addEventListener('click', function(e) {
            offerAmount.blur();
            offerTitleText.blur();
                                                      
            Ti.App.fireEvent('app:makeOffer.hide', {show: 'backButton'});
        });
        containerView.add(cancelButton);


        Ti.App.addEventListener('app:makeOffer.show', function(options) {
            // disable any spinner/activity indicator actions
            // whilst we're here
            candp.view.spinnerIsEnabled = false;

            viewOptions = options || {
                missionTitle: '',
                receiverUserId: 0,
                missionId: 0           
            };

            // set up mission text, clear fields, etc
            missionTitle.text = L('offer_for') + ' : ' + viewOptions.missionTitle;
            offerTitleText.value = '';
            offerAmount.value = '';

            switch (candp.osname) {
                case 'android':
                    // *TODO: investiate the problems with Android animations
                    makeOfferView.show();
                    makeOfferView.showing = true;
                    break;
                case 'iphone':
                    makeOfferView.top = -$$.platformHeight;
				    makeOfferView.show();
                    candp.view.slide(makeOfferView, 'down', null, null);
                    break;
            }

        });

        Ti.App.addEventListener('app:makeOffer.hide', function(e) {
            // re-enable spinner/activity indicator actions
            candp.view.spinnerIsEnabled = true;

            // and show any header bar buttons we might have also vanished
            Ti.App.fireEvent('headerBar:' + e.show + '.show');

            switch (candp.osname) {
                case 'android':
                    // *TODO: investigate the problems with Android animations
                    makeOfferView.hide();
                    makeOfferView.showing = false;
                    break;
                case 'iphone':
	                candp.view.slide(makeOfferView, 'up', function() {
	                    makeOfferView.hide();
	                }, null);
                    break;
            }
        });


        makeOfferView.add(containerView);

        return makeOfferView;
    };
})();
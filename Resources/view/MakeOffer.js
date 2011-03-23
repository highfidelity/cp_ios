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
        var makeOfferView = Ti.UI.createWindow(candp.combine($$.contained, {
            visible: false,
            // *TODO: investigate problems with Android detecting view visiblity
            showing: false,
            zIndex: 25
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

        // offer detail
        containerView.add(Ti.UI.createLabel(candp.combine($$.titleText, {
            top: 15,
            left: 15,
            right: 15,
            textAlign: 'left',
            color: '#000000',
            text: L('offer_for') + ' : ' + options.missionTitle
        })));

        var offerTitleText = Ti.UI.createTextArea(candp.combine($$.textArea, {
            top: 70,
            left: 15,
            right: 15,
            height: 80,
            returnKeyType: Titanium.UI.RETURNKEY_NEXT
        }));
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
            returnKeyType: Titanium.UI.RETURNKEY_DONE
        }));
        containerView.add(offerAmount);

        var makeOfferButton = Ti.UI.createButton(candp.combine($$.button, {
            title: L('make_offer'),
            top: 220,
            height: 37,
            left: 5,
            width: 130
        }));
        makeOfferButton.addEventListener('click', function(e) {
            missionDetailsModel.makeOffer({
               offerTitle: offerTitleText.value,
               offerAmount: offerAmount.value,
               receiverUserId: options.receiverUserId,
               missionId: options.missionId,
               payMe: 1
            }, function(e) {
                makeOfferView.close({transition: Ti.UI.iPhone.AnimationStyle.FLIP_FROM_RIGHT});
            });
        });
        containerView.add(makeOfferButton);

        var cancelButton = Ti.UI.createButton(candp.combine($$.button, {
            title: L('cancel'),
            top: 220,
            height: 37,
            right: 5,
            width: 130
        }));
        cancelButton.addEventListener('click', function(e) {
            makeOfferView.close({transition: Ti.UI.iPhone.AnimationStyle.FLIP_FROM_RIGHT});
        });
        containerView.add(cancelButton);


        makeOfferView.add(containerView);

        return makeOfferView;
    };
})();
/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief View for the mission details.  This view gives more detailed information
 * regarding a particular mission.  From here, the user is able to chat with the 
 * mission creator, view the profile of the mission creator, or make an offer to
 * carry out the mission
 * 
 */

(function() {
    candp.view.createMissionDetailsView = function(args) {
        var userId;
        var missionId;

        var missionDetailsView = Ti.UI.createScrollView(candp.combine($$.contained, {
            backgroundColor: '#FFFFFF',
            contentHeight: 'auto',
            contentWidth: $$.platformWidth,
            showHorizontalScrollIndicator: false,
            visible: false
        }));

        // use a dialog container
        var containerView = Ti.UI.createView({
            top: 20,
            left:20,
            right: 20,
            // *FIXME: + 30 is a hack to get a longer screen, but we really want the size
            // to adjust automatically.  It *is* possible
            height: $$.platformHeight + 30,
            backgroundColor: '#FFFFFF',
            borderRadius: 15
        });
        missionDetailsView.add(containerView);


        var authorImage = Ti.UI.createImageView(candp.combine($$.imageView, {
            defaultImage: 'images/no_picture.jpg',
            top: 20,
            left: 20
        }));
        authorImage.addEventListener('click', function(e) {
            Ti.App.fireEvent('app:buttonBar.clicked', {button_name: 'userProfile'});
            setTimeout(function() {
                missionDetailsView.hide();
                Ti.App.fireEvent('app:userProfile.getUserProfile', {
                    user_id: userId
                });
            }, 100);
        });
        containerView.add(authorImage);

        var missionTitle = Ti.UI.createLabel(candp.combine($$.titleText, {
            top: 20,
            left: 130,
            right: 20
        }));
        containerView.add(missionTitle);

        var byWhenLabel = Ti.UI.createLabel(candp.combine($$.smallText, {
            left: 130,
            top: 110,
            right: 20
        }));
        containerView.add(byWhenLabel);



        // put the rest of the content in a vertical layout view
        var layoutContainer = Ti.UI.createView({
            top: 125,
            left: 20,
            right: 20,
            layout: 'vertical'
        });
        containerView.add(layoutContainer);

        // show the details of the mission
        var missionDetails = Ti.UI.createLabel(candp.combine($$.mediumText, {
            top: 0,
            left: 0,
            right: 0
        }));
        layoutContainer.add(missionDetails);

        var howMuchLabel = Ti.UI.createLabel(candp.combine($$.mediumBoldText, {
            left: 0,
            top: 10,
            right: 0
        }));
        layoutContainer.add(howMuchLabel);

        // where is this mission based?
        var mapImage = Ti.UI.createImageView(candp.combine($$.imageView, {
            top: 0,
            left: 0,
            right: 0,
            height: 'auto',
            width: $$.platformWidth * 2 / 3,
            canScale: false
        }));
        layoutContainer.add(mapImage);

        // keep the buttons nice and contained
        var buttonsContainer = Ti.UI.createView({
            top: 0,
            left: -15,
            right: -15,
            height: 37
        });
        layoutContainer.add(buttonsContainer);

        // make an offer to the user
        var makeOfferButton = Ti.UI.createButton(candp.combine($$.button, {
            title: L('make_offer'),
            top: 0,                                                                   
            height: 37,
            left: 0,
            width: 130
        }));
        buttonsContainer.add(makeOfferButton);

        makeOfferButton.addEventListener('click', function(e) {
            var makeOfferView = candp.view.createMakeOfferView({
                missionTitle: missionTitle.text,
                receiverUserId: userId,
                missionId: missionId
            });
            makeOfferView.open({transition: Ti.UI.iPhone.AnimationStyle.FLIP_FROM_LEFT});
            makeOfferView.show();
            Ti.App.fireEvent('headerBar:refreshButton.hideBoth');
        });

        // get chatting 1:1 with the user
        var initiateChatButton = Ti.UI.createButton(candp.combine($$.button, {
            title: L('chat1_1'),
            top: 0,
            height: 37,
            right: 0,
            width: 130
        }));
        buttonsContainer.add(initiateChatButton);

        // respond to mission details from push notifications (i.e. get the mission by its id)
        Ti.App.addEventListener('app:missionDetail.getById', function(mission) {
            missionDetailsModel.getMissionById(mission, function(mission) {
                Ti.App.fireEvent('app:missionDetail.show', mission);
            });
        });

        // respond to showing mission details to the user
        Ti.App.addEventListener('app:missionDetail.show', function(mission) {
            userId = mission.author_id;
            missionId = mission.id;
            mapImage.image = 'http://maps.google.com/maps/api/staticmap?markers=color:red%7Clabel:M|' + mission.lat + ',' + mission['long'] + '&zoom=16&size=300x160&sensor=false';

            // fill in the details of the mission
            missionTitle.text = (mission.mission_type === 'want') ? L('i_want') + ' ' + mission.title : L('i_will') + ' ' + mission.title;
            missionDetails.text = mission.description;
            byWhenLabel.text = mission.deadline_formatted;
            var howMuchText = (mission.mission_type === 'want') ? L('i_will_pay') + mission.proposed_price : L('i_want_pay') + mission.proposed_price; 
            howMuchLabel.text = howMuchText + ' (' + L('mission_is') + ' ' + mission.status + ')';

            // make sure we start at the top of the page if someone has
            // left us scrolled to the bottom on the previous viewing
            missionDetailsView.scrollTo(0, 0);
            missionDetailsView.show();

            userProfileModel.getUserImage({
                image_id: mission.photo
            }, function(image) {
                authorImage.image = image;
            });
        });

        return missionDetailsView;
    };
})();

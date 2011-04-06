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
        var missionTitle;

        var data = [];

        var missionDetailsView = Ti.UI.createView(candp.combine($$.contained, {
            backgroundColor: '#FFFFFF',
            visible: false
        }));

        var missionDetailsTable = Ti.UI.createTableView(candp.combine($$.tableView, {
            top: 30,
            left: 20,
            right: 20,
            bottom: 75,
            borderRadius: 15
        }));
        missionDetailsView.add(missionDetailsTable);
    

        // keep the buttons nice and contained
        var buttonsContainer = Ti.UI.createView({
            bottom: 20,
            left: 0,
            right: 0,
            height: 37
        });

        // make an offer to the user
        var makeOfferButton = Ti.UI.createButton(candp.combine($$.button, {
            title: L('make_offer'),
            top: 0,                                                                   
            height: 37,
            left: (candp.osname === 'iphone') ? 20 : 20,
            width: (candp.osname === 'iphone') ? 130 : 110
        }));
        buttonsContainer.add(makeOfferButton);

        makeOfferButton.addEventListener('click', function(e) {
            var makeOfferViewOptions = {
                missionTitle: missionTitle,
                receiverUserId: userId,
                missionId: missionId
            };
            Ti.App.fireEvent('app:makeOffer.show', makeOfferViewOptions);
            Ti.App.fireEvent('headerBar:refreshButton.hideBoth');
        });

        // get chatting 1:1 with the user
        var initiateChatButton = Ti.UI.createButton(candp.combine($$.button, {
            title: L('chat1_1'),
            top: 0,
            height: 37,
            right: (candp.osname === 'iphone') ? 20 : 20,
            width: (candp.osname === 'iphone') ? 130 : 110
        }));
        buttonsContainer.add(initiateChatButton);

        initiateChatButton.addEventListener('click', function(e) {
            Ti.App.fireEvent('app:chat.initiateChat', {userId: userId} );
            setTimeout(function() {
                Ti.App.fireEvent('app:buttonBar.clicked',{
                    nextViewToShow: 'chat',
                    clickedButtonIndex: 0,
                    button_name: 'chat'
                });
            }, 100);
        });

        missionDetailsView.add(buttonsContainer);


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
            missionTitle = mission.title;

            data = [];

            // mission title related info
            var missionTitleRow = Ti.UI.createTableViewRow(candp.combine($$.tableRow, {
                height: 'auto',
                selectedBackgroundColor: '#FFFFFF'
            }));
    
            var missionTitleHeader = Ti.UI.createLabel({
    			color:'#333333',
    			font:{fontSize:16,fontWeight:'bold', fontFamily:'Arial'},
    			left:10,
    			top:5,
    			height: 25,
    			clickName:'missionTitle',
    			text: L('mission_title')          
            });
            missionTitleRow.add(missionTitleHeader);
            
            var missionTitleLabel = Ti.UI.createLabel({
    			color:'#333333',
    			font:{fontSize:14,fontWeight:'normal', fontFamily:'Arial'},
    			left:10,
    			top:35,
    			height: 'auto',
                bottom: 10,
    			right:10,
    			clickName:'missionTitle',
                text: (mission.mission_type === 'want') ? L('i_want') + ' ' + mission.title : L('i_will') + ' ' + mission.title
            });
            missionTitleRow.add(missionTitleLabel);
            data.push(missionTitleRow);


            // mission description related info
            var missionDescriptionRow = Ti.UI.createTableViewRow(candp.combine($$.tableRow, {
                height: 'auto',
                selectedBackgroundColor: '#FFFFFF',
                layout: 'vertical'
            }));

            var missionDescriptionLabel = Ti.UI.createLabel({
    			color:'#333333',
    			font:{fontSize:16,fontWeight:'bold', fontFamily:'Arial'},
    			left:10,
    			top:5,
    			height: 25,
    			clickName:'missionDescription',
    			text: L('mission_description')            
            });
            missionDescriptionRow.add(missionDescriptionLabel);
            
            var missionDescription = Ti.UI.createLabel({
    			color:'#333333',
    			font:{fontSize:14,fontWeight:'normal', fontFamily:'Arial'},
    			left:10,
    			top: 0,
    			height: 'auto',
    			right:10,
                bottom: 5,
    			clickName:'missionDescription',
                text: mission.description
            });
            missionDescriptionRow.add(missionDescription);
            data.push(missionDescriptionRow);


            // mission creator related info
            var missionCreatorRow = Ti.UI.createTableViewRow(candp.combine($$.tableRow, {
                height: 'auto',
                hasChild: true
            }));

            var missionCreatorPhoto = Ti.UI.createImageView(candp.combine($$.imageView, {
                defaultImage: 'images/no_picture.jpg',
                top: 10,
                left: 10,
                width: 75,
                height: 75,
                bottom: 10,
                image: (mission.filename) ? candp.config.baseUrl + mission.filename : 'images/no_picture.jpg'
            }));
            missionCreatorRow.add(missionCreatorPhoto);
           
            var postedByLabel = Ti.UI.createLabel({
    			color:'#333333',
    			font:{fontSize:14,fontWeight:'normal', fontFamily:'Arial'},
    			left:95,
    			top: 10,
    			height: 'auto',
    			right:10,
    			clickName:'postebBy',
                text: L('posted_by') + ' ' + mission.nickname 
            });
            missionCreatorRow.add(postedByLabel);

            missionCreatorRow.addEventListener('click', function(e) {
                setTimeout(function() {
                    missionDetailsView.hide();
                    Ti.App.fireEvent('app:userProfile.show', {
                        user_id: userId
                    });
                }, 100);
            });
            data.push(missionCreatorRow);


            // pay/expires related info
            var missionPayRow = Ti.UI.createTableViewRow(candp.combine($$.tableRow, {
                height: 'auto',
                selectedBackgroundColor: '#FFFFFF'
            }));

            var howMuchText = (mission.mission_type === 'want') ? L('i_will_pay') + mission.proposed_price : L('i_want_pay') + mission.proposed_price; 
            var iWillPayLabel = Ti.UI.createLabel({
    			color:'#333333',
    			font:{fontSize:13,fontWeight:'normal', fontFamily:'Arial'},
    			left:10,
    			top: 10,
    			width: 'auto',
                height: 'auto',
                bottom: 10,
    			clickName:'iwillpay',
                text: howMuchText
            });
            missionPayRow.add(iWillPayLabel);

            var expiresLabel = Ti.UI.createLabel({
    			color:'#333333',
    			font:{fontSize:13,fontWeight:'normal', fontFamily:'Arial'},
    			right:10,
    			top: 10,
    			width: 'auto',
                height: 'auto',
                bottom: 10,
    			clickName:'expires',
                text: L('expires') + ' ' + ((mission.formattedTimeDiff === '0 min') ? L('overdue') : (mission.formattedTimeDiff === '-1 min') ? L('never_expires') : mission.formattedTimeDiff)
            });
            missionPayRow.add(expiresLabel);
            data.push(missionPayRow);

            missionDetailsTable.setData(data);

            // For Android we're using JITViewing                         
            if (candp.osname === 'android') {
                candp.view.containerView.add(missionDetailsView);
            }
            missionDetailsView.show();
        });

        return missionDetailsView;
    };
})();

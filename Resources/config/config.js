/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief All application configuration settings go here
 * 
 */

(function() {
    var baseUrl = 'http://www.coffeeandpower.com/';

    candp.config = {
        // CandP server URL endpoints
        baseUrl: baseUrl,
        loginUrl: baseUrl + 'login.php',
        logoutUrl: baseUrl + 'logout.php',
        actionServerUrl: baseUrl + 'ActionServer.php',
        missionsUrl: baseUrl + 'missions.php',
        apiUrl: baseUrl + 'api.php',
        registerAPNTokenUrl: baseUrl + 'registerApnToken.php',
        offersUrl: baseUrl + 'offers.php',
        chatIndexUrl: baseUrl + 'chat/indexcandp.php',
        chatUrl: baseUrl + 'chat/aj.php',

        // 44 points is the iPhone standard header size
        headerHeight: 44,

        // 49 points is the iPhone standard footer
        footerHeight: 49,

        // how often should we get the user's balance (in milliseconds)
        getBalanceTime: 30000 // every 30 seconds
    };
})();

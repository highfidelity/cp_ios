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
        missionsUrl: baseUrl + 'missions.php'
    };
})();

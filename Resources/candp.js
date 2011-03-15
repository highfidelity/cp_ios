/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief App namespace 'candp'
 * 
 */

var candp = {};

(function() {
    // application state variables are held in this namespace  
    // such as the current app window, for instance, which is created in app.js
    candp.app = {};

    // *FIXME: this code needs attention -- it's poor layout and bad variable names!
    // extend an object with the properties from another 
    // as per Dojo - http://docs.dojocampus.org/dojo/mixin
    var empty = {};
    function mixin(target, source) {
        var name, s, i;
        for (name in source) {
            s = source[name];
            if(!(name in target) || (target[name] !== s && (!(name in empty) || empty[name] !== s))) {
                target[name] = s;
            }
        }
        return target;
    };
    candp.mixin = function(/*Object*/ obj, /*Object...*/ props){
        if(!obj){ obj = {}; }
        for(var i=1, l=arguments.length; i<l; i++){
            mixin(obj, arguments[i]);
        }
        return obj; // Object
    };
    // create a new object, combining the properties of the passed objects 
    // with the last arguments having priority over the first ones
    candp.combine = function(/*Object*/ obj, /*Object...*/ props) {
        var newObj = {};
        for(var i=0, l=arguments.length; i<l; i++){
            mixin(newObj, arguments[i]);
        }
        return newObj;
    };


    
    // locale and os specific branching helpers adapted from the Helium library
    // for Titanium: http://github.com/kwhinnery/Helium
    var locale = Ti.Platform.locale;
    var osname = Ti.Platform.osname;
    candp.osname = osname;

    // *FIXME: this code needs attention -- it's poor layout and bad variable names!
    candp.locale = function(/*Object*/ map) {
        var def = map.def||null; //default function or value
        if (map[locale]) {
            if (typeof map[locale] == 'function') { return map[locale](); }
            else { return map[locale]; }
        }
        else {
            if (typeof def == 'function') { return def(); }
            else { return def; }
        }
    };

    candp.os = function(/*Object*/ map) {
        var def = map.def||null; //default function or value
        if (map[osname]) {
            if (typeof map[osname] == 'function') { return map[osname](); }
            else { return map[osname]; }
        }
        else {
            if (typeof def == 'function') { return def(); }
            else { return def; }
        }
    };
})();


// include our other namespaces -- view, model, and our configuration
Ti.include(
    '/config/config.js',
    '/view/view.js',
    '/model/model.js'
);

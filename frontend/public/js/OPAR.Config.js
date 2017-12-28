// --
// OPAR.Config.js - provides functions for OPAR authors
// Copyright (C) 2010-2011 Perl-Services.de, http://perl-services.de/\n";
// --
// $Id: OPAR.Config.js
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var OPAR = OPAR || {};

/**
 * @namespace
 * @exports TargetNS as Author.Package
 * @description
 *      This namespace contains all form functions.
 */
OPAR.Config = (function (TargetNS) {
 
    var Config = {};

    /**
     * @function
     * @description set a config option
     * @param Key - name of the config option
     * @param Value - value of the config option
     * @return nothing
     */
    TargetNS.Set = function (Key, Value) {
        Config[Key] = Value;
    };
    
    /**
     * @function
     * @description get the value of a config option
     * @param Key - name of the config option
     * @return {String} - value of the config option
     */
    TargetNS.Get = function (Key) {
        return Config[Key];
    };

    return TargetNS;
}(OPAR.Config || {}));

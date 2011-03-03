// --
// OPAR.Package.js - provides functions for OPAR authors
// Copyright (C) 2010-2011 Perl-Services.de, http://perl-services.de/\n";
// --
// $Id: OPAR.Package.js
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var OPAR = OPAR || {};

/**
 * @namespace
 * @exports TargetNS as OPAR.Help
 * @description
 *      This namespace contains all form functions.
 */
OPAR.Help = (function (TargetNS) {
 
    var Config = {};

    /**
     * @function
     * @description This function creates a "delete" job
     * @param PackageID - ID of the package that should be deleted
     * @return nothing
     */
    TargetNS.Show = function (Divname, MessageKey) {
        var Message = TargetNS.Get( MessageKey );
        
        var HelpDiv = $(Divname);
        HelpDiv.update( Message );
        
        HelpDiv.style.display = 'block';
    };

    /**
     * @function
     * @description hide div that shows error message
     * @return nothing
     */
    
    TargetNS.Hide = function (Divname) {
        var HelpDiv = $(Divname);
        HelpDiv.style.display = 'none';
    };

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
}(OPAR.Help || {}));

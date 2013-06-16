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
 * @exports TargetNS as OPAR.Package
 * @description
 *      This namespace contains all form functions.
 */
OPAR.User = (function (TargetNS) {

    /**
     * @function
     * @description This function creates a "delete" job
     * @param PackageID - ID of the package that should be deleted
     * @return nothing
     */
    TargetNS.CheckUsername = function (Username) {
        var URL = OPAR.Config.Get( 'BaseURL' );
    };
    
    TargetNS.CheckPassword = function (PasswordToCheck) {
    };

    return TargetNS;
}(OPAR.User || {}));

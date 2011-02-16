// --
// OPAR.Author.js - provides functions for OPAR authors
// Copyright (C) 2010-2011 Perl-Services.de, http://perl-services.de/\n";
// --
// $Id: OPAR.Author.js
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Author = Author || {};

/**
 * @namespace
 * @exports TargetNS as Author.Package
 * @description
 *      This namespace contains all form functions.
 */
Author.Package = (function (TargetNS) {

    /**
     * @function
     * @description This function creates a "delete" job
     * @param PackageID - ID of the package that should be deleted
     * @return nothing
     */
    TargetNS.Delete = function (PackageID) {
        var URL = Core.Config.Get('BaseURL');
    };

    return TargetNS;
}(Author.Package || {}));

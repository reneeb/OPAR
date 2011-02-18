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
OPAR.Package = (function (TargetNS) {

    /**
     * @function
     * @description This function creates a "delete" job
     * @param PackageID - ID of the package that should be deleted
     * @return nothing
     */
    TargetNS.Delete = function (PackageID) {
        var URL = OPAR.Config.Get('BaseURL');
        
        URL += '/package/delete/' + PackageID;
        
        new Ajax.Request( 
            URL,
            {
                method: 'get',
                onSuccess: function(transport) {
                    var data = transport.responseText.evalJSON(true);
                    $("span_" + PackageID).className = 'visible';
                    $("deletion_date_" + PackageID).innerHTML = data.deletionTime;
                    $("delete_link_" + PackageID).onclick = function(event){OPAR.Package.UnDelete(PackageID)};
                }
            }
        );
    };
    
    TargetNS.UnDelete = function (PackageID) {
        var URL = OPAR.Config.Get('BaseURL');
        
        URL += '/package/undelete/' + PackageID;
        
        new Ajax.Request( 
            URL,
            {
                method: 'get',
                onSuccess: function(transport) {
                    var data = transport.responseText.evalJSON(true);
                    
                    if ( data.Success ) {
                        $("span_" + PackageID).className = 'hidden';
                        $("delete_link_" + PackageID).onclick = function(event){OPAR.Package.Delete(PackageID)};
                    }
                }
            }
        );
    };

    return TargetNS;
}(OPAR.Package || {}));

/**
 * This class can be accessed outside of the manage package that allows users to manage Copado Licenses.
 * @author Pranjal Singh
 * @version 1.0
 * @date 14.02.2024
 */
@RestResource(urlMapping='/License')
global with sharing class LicenseAPI {

    @HttpGet
    global static GlobalAPI.CopadoLicenses getLicenseInfo() {
        return new GlobalAPI().getLicenseInformation();
    }
}
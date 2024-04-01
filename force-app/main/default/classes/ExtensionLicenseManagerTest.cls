/**
 * This class is used to test the implementation of CopadoExtLicenseInterface
 * ExtensionLicenseManager class is tested using LicenseManagerCtrlTest class
 */
@IsTest
public with sharing class ExtensionLicenseManagerTest implements CopadoExtLicenseInterface {
    public List<ExtLicenseInfo> getTotalLicense() {
        list<ExtLicenseInfo> lic = new List<ExtLicenseInfo>();
        lic.add(new ExtLicenseInfo('ExtensionLicense', 'Extension License', 5, 10));
        return lic;
    }
    public List<ExtLicenseInfo> getLicenseAssigned() {
        list<ExtLicenseInfo> lic = new List<ExtLicenseInfo>();
        lic.add(new ExtLicenseInfo(UserInfo.getUserId(), 'ExtensionLicense'));
        return lic;
    }
    public void validateExtLicense(List<ExtLicenseAssignment> addToExtPackage, List<ExtLicenseAssignment> removeFromExtPackage) {
        //Core successfully sent license info to extension package
        throw new ExtensionLicenseManagerException('Extension validation was successfull');
    }
    public void setExtLicense(List<ExtLicenseAssignment> addToExtPackage, List<ExtLicenseAssignment> removeFromExtPackage) {
        //Core successfully sent license info to extension package
        throw new ExtensionLicenseManagerException('Extension license assignment was successfull');
    }
    public class ExtensionLicenseManagerException extends Exception {
    }
}
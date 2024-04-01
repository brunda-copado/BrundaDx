global interface CopadoExtLicenseInterface {
   List<ExtLicenseInfo> getTotalLicense();
   List<ExtLicenseInfo> getLicenseAssigned();
   void validateExtLicense(List<ExtLicenseAssignment> addToExtPackage, List<ExtLicenseAssignment> removeFromExtPackage);
   void setExtLicense(List<ExtLicenseAssignment> addToExtPackage, List<ExtLicenseAssignment> removeFromExtPackage);
}
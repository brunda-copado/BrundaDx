global class ExtLicenseAssignment {
    global String ExtLicenseName;
    global List<Id> UserIds;

    // Only core should be able to initialize this class.
    public ExtLicenseAssignment(String ExtLicenseName, List<Id> UserIds) {
        this.ExtLicenseName = ExtLicenseName;
        this.UserIds = UserIds;
    }
}
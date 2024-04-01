global class ExtLicenseInfo {
    global String name;
    global String label;
    global Integer used;
    global Integer available;
    global String userId;

    global ExtLicenseInfo(String name, String label, Integer used, Integer available) {
        this.name = name;
        this.label = label;
        this.used = used;
        this.available = available;
    }

    global ExtLicenseInfo(String userId, String name) {
        this.userId = userId;
        this.name = name;
    }
}
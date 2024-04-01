public with sharing class PackageLicenseManager {
    private Set<String> namespaces = new Set<String>();

    private Map<String, PackageLicense> licensesByNamespace {
        get {
            if (licensesByNamespace == null) {
                licensesByNamespace = new Map<String, PackageLicense>();
                // FALSE POSITIVE: setup object
                for (PackageLicense license : [
                    SELECT AllowedLicenses, UsedLicenses, NamespacePrefix
                    FROM PackageLicense
                    WHERE NamespacePrefix = :namespaces
                    ORDER BY NamespacePrefix
                ]) {
                    licensesByNamespace.put(license.NamespacePrefix, license);
                }
            }
            return licensesByNamespace;
        }
        set;
    }

    private Map<String, List<Id>> addToPackage;
    private Map<String, List<Id>> removeFromPackage;

    // CTOR

    public PackageLicenseManager(Map<String, List<Id>> addToPackage, Map<String, List<Id>> removeFromPackage) {
        this.namespaces.addAll(addToPackage.keySet());
        this.namespaces.addAll(removeFromPackage.keySet());

        this.addToPackage = addToPackage;
        this.removeFromPackage = removeFromPackage;
    }

    // PUBLIC

    public List<String> validateAssignment() {
        Map<String, String> packageNamesByNamespace = new Map<String, String>{
            PackageNamespace.copado.name() => Label.Copado_Managed_Package,
            PackageNamespace.copadometrics.name() => Label.Copado_Analytics,
            PackageNamespace.copadovsm.name() => Label.Copado_VSM
        };

        List<String> result = new List<String>();
        for (String pkg : addToPackage.keySet()) {
            Integer licensesToAdd = addToPackage.get(pkg).size();
            Integer licensesToRemove = removeFromPackage.get(pkg) != null ? removeFromPackage.get(pkg).size() : 0;
            PackageLicense license = licensesByNamespace.get(pkg);
            Boolean areEnoughLicenses = (licensesToAdd - licensesToRemove) <= (license.AllowedLicenses - license.UsedLicenses);

            if (!areEnoughLicenses) {
                result.add(packageNamesByNamespace.get(pkg));
            }
        }
        return result;
    }

    public void assign() {
        List<UserPackageLicense> upls = new List<UserPackageLicense>();
        for (String pkg : addToPackage.keySet()) {
            for (Id userId : addToPackage.get(pkg)) {
                upls.add(new UserPackageLicense(PackageLicenseId = licensesByNamespace.get(pkg).Id, UserId = userId));
            }
        }
        // FALSE POSITIVE: setup object
        insert upls;
    }

    public void remove() {
        if (!removeFromPackage.isEmpty()) {
            String whereClause = '';
            for (String pkg : removeFromPackage.keySet()) {
                String stringIds = getStringIds(removeFromPackage.get(pkg));
                whereClause += ' (PackageLicenseId = \'' + licensesByNamespace.get(pkg).Id + '\' AND UserId IN ' + stringIds + ') OR';
            }
            whereClause = whereClause.removeEnd(' OR');
            // FALSE POSITIVE injection: No need to escape single quotes since Id type is safe and it is not subjected to user manual input
            // FALSE POSITIVE permissions: setup object
            List<UserPackageLicense> upls = Database.query('SELECT Id FROM UserPackageLicense WHERE' + whereClause);
            // FALSE POSITIVE: setup object
            delete upls;
        }
    }

    private String getStringIds(List<Id> ids) {
        String result = '(';
        for (String id : ids) {
            result += '\'' + id + '\',';
        }
        result = result.removeEnd(',');
        result += ')';
        return result;
    }
}
public with sharing class UniversalFeatureToggle {
    private static final String FMA_FIELD = 'UniversalFeatureToggle';
    private Integer fmaValue;

    @testVisible
    private static Integer mockValue = 0;

    // CONSTRUCTOR

    public UniversalFeatureToggle() {
        fmaValue = (Test.isRunningTest()) ? mockValue : FeatureManagement.checkPackageIntegerValue(FMA_FIELD);
    }

    // PUBLIC

    public Boolean isEnabled(Feature feature) {
        return 0 != (fmaValue & 1 << feature.ordinal());
    }

    public Boolean isDisabled(Feature feature) {
        return !isEnabled(feature);
    }

    // INNER

    public enum Feature {
        APEX_TESTS_WITH_V2, // [US-0025930]
        UNUSED_2, // Add User Story Autoname for details
        UNUSED_3, // Add User Story Autoname for details
        UNUSED_4, // Add User Story Autoname for details
        UNUSED_5, // Add User Story Autoname for details
        UNUSED_6, // Add User Story Autoname for details
        UNUSED_7, // Add User Story Autoname for details
        UNUSED_8, // Add User Story Autoname for details
        UNUSED_9, // Add User Story Autoname for details
        UNUSED_10, // Add User Story Autoname for details
        UNUSED_11, // Add User Story Autoname for details
        UNUSED_12, // Add User Story Autoname for details
        UNUSED_13, // Add User Story Autoname for details
        UNUSED_14, // Add User Story Autoname for details
        UNUSED_15, // Add User Story Autoname for details
        UNUSED_16, // Add User Story Autoname for details
        UNUSED_17, // Add User Story Autoname for details
        UNUSED_18, // Add User Story Autoname for details
        UNUSED_19, // Add User Story Autoname for details
        UNUSED_20, // Add User Story Autoname for details
        UNUSED_21, // Add User Story Autoname for details
        UNUSED_22, // Add User Story Autoname for details
        UNUSED_23, // Add User Story Autoname for details
        UNUSED_24, // Add User Story Autoname for details
        UNUSED_25, // Add User Story Autoname for details
        UNUSED_26, // Add User Story Autoname for details
        UNUSED_27, // Add User Story Autoname for details
        UNUSED_28, // Add User Story Autoname for details
        UNUSED_29, // Add User Story Autoname for details
        UNUSED_30, // Add User Story Autoname for details
        UNUSED_31 // Add User Story Autoname for details
    }
}
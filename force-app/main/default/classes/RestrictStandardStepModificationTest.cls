@IsTest
private class RestrictStandardStepModificationTest {

    @IsTest
    private static void insertWithSettingEnabled() {
        // Setup
        Exception expectedException = null;
        Helper helper = new Helper().createTemplate();


        // Exercise
        try {
            helper.createStep();
        }
        catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        System.assertEquals(null, expectedException);
    }


    @IsTest
    private static void insertWithSettingDisabled() {
        // Setup
        Exception expectedException = null;
        Helper helper = new Helper()
                                .createTemplate()
                                .disableSetting();


        // Exercise
        try {
            helper.createStep();
        }
        catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        System.assertNotEquals(null, expectedException);
        System.assert(expectedException.getMessage().contains(Label.StandardTemplateModificationNotAllowed));
    }


    @IsTest
    private static void updateWithSettingDisabled() {
        // Setup
        Exception expectedException = null;
        Helper helper = new Helper()
                                .createTemplate()
                                .createStep()
                                .disableSetting();


        // Exercise
        try {
            helper.updateStep('Name', 'Modified');
        }
        catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        System.assertNotEquals(null, expectedException);
        System.assert(expectedException.getMessage().contains(Label.StandardTemplateModificationNotAllowed));
    }


    @IsTest
    private static void deleteWithSettingDisabled() {
        // Setup
        Exception expectedException = null;
        Helper helper = new Helper()
                                .createTemplate()
                                .createStep()
                                .disableSetting();


        // Exercise
        try {
            helper.deleteStep();
        }
        catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        System.assertNotEquals(null, expectedException);
        System.assert(expectedException.getMessage().contains(Label.StandardTemplateModificationNotAllowed));
    }


    // HELPER

    private class Helper {
        private JobStep__c step;
        private Settings__c setting;
        private JobTemplate__c template;

        private Helper() {
            setting = new Settings__c();
            setting.SetupOwnerId = UserInfo.getOrganizationId();
            setting.Enable_Standard_Job_Template_Edit__c = true;
            insert setting;
        }

        private Helper enableSetting() {
            setting.Enable_Standard_Job_Template_Edit__c = true;
            update setting;

            return this;
        }


        private Helper disableSetting() {
            setting.Enable_Standard_Job_Template_Edit__c = false;
            update setting;

            return this;
        }


        private Helper createTemplate() {
            template = new JobTemplate__c(Name = 'Sample', Version__c = 1, Type__c = 'Standard');
            insert template;

            return this;
        }


        private Helper createStep() {
            step = new JobStep__c(Name = 'step1', JobTemplate__c = template.Id, Type__c = 'Manual');
            insert step;

            return this;
        }


        private Helper updateStep(String fieldName, Object value) {
            step.put(fieldName, value);
            update step;

            return this;
        }


        private Helper deleteStep() {
            delete step;

            return this;
        }
    }
}
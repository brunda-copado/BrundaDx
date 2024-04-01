public with sharing class TestsManagerCtrl {
    // PUBLIC

    @AuraEnabled
    public static void runTestsOf(Id parentId) {
        try {
            List<Test__c> tests = new TestsSelector().byParentAndAutomaticallyExecutableTests(parentId);
            if (!tests.isEmpty()) {
                new RunTestsInExtension(tests).executeAsync();
            }
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void runTest(Id testId) {
        try {
            List<Test__c> tests = new TestsSelector().byIds(new Set<Id>{ testId });
            new RunTestsInExtension(tests).execute();
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static List<TestWrapper> getTests(Id parentId) {
        try {
            List<TestWrapper> result = new List<TestWrapper>();

            Set<Id> parentIds = new Set<Id>{ parentId };
            for (Test__c test : new TestsSelector().byParentWithLatestResult(parentIds)) {
                result.add(prepareWrapper(test));
            }

            return result;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    // PRIVATE

    private static TestWrapper prepareWrapper(Test__c test) {
        return new TestWrapper()
            .id(test.id)
            .name(test.Name)
            .testType(test.Type__c)
            .testTool(test.ExtensionConfiguration__r.ExtensionTool__c)
            .testUrl()
            .result(test)
            .readyToRun(test.ReadyToRun__c)
            .extensionActive(test.ExtensionConfiguration__r.Active__c);
    }

    //INNER
    public with sharing class TestWrapper {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String testType;
        @AuraEnabled
        public String testTool;
        @AuraEnabled
        public String runDate;
        @AuraEnabled
        public String result;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String testUrl;
        @AuraEnabled
        public String resultUrl;
        @AuraEnabled
        public Boolean isReadyToRun;
        @AuraEnabled
        public Boolean isExtensionActive;

        private TestWrapper id(String id) {
            this.id = id;
            return this;
        }

        private TestWrapper name(String name) {
            this.name = name;
            return this;
        }

        private TestWrapper testType(String testType) {
            this.testType = testType;
            return this;
        }

        private TestWrapper testTool(String testTool) {
            this.testTool = testTool;
            return this;
        }

        private TestWrapper status(Test__c test, String status) {
            if (!test.ReadyToRun__c || !test.ExtensionConfiguration__r.Active__c) {
                this.status = 'Not Executable';
            } else {
                this.status = status;
            }

            return this;
        }

        private TestWrapper testUrl() {
            this.testUrl = '/' + this.id;
            return this;
        }

        private TestWrapper result(Test__c test) {
            if (!test.Results__r.isEmpty()) {
                Result__c result = test.Results__r[0];
                this.runDate = result.Start_Time__c != null ? result.Start_Time__c.format('dd/MM/yyyy hh:mm a') : '';
                this.result = result.Name;
                status(test, result.Status__c);
                this.resultUrl = '/' + result.id;
            } else {
                status(test, '');
            }
            return this;
        }

        private TestWrapper readyToRun(Boolean readyToRun) {
            this.isReadyToRun = readyToRun;
            return this;
        }

        private TestWrapper extensionActive(Boolean extensionActive) {
            this.isExtensionActive = extensionActive;
            return this;
        }
    }
}
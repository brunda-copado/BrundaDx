@isTest
private with sharing class AggregateCoverageResultTest {
    @isTest
    private static void calculateCoveragePercentage() {
        System.runAs(getTestUser()) {
            // Setup
            AggregateCoverageResult aggregateCoverageResult = createMockAggregateCoverageResult();

            // Exercise
            Double coveragePercentage = aggregateCoverageResult.calculateCoveragePercentage();

            // Verify
            System.assertEquals(50.0, coveragePercentage, 'Coverage percentage should be 50%');
        }
    }

    @isTest
    private static void calculateMetadataFilesWithoutCoverage() {
        System.runAs(getTestUser()) {
            // Setup
            AggregateCoverageResult aggregateCoverageResult = createMockAggregateCoverageResult();

            // Exercise
            Integer classesWithoutMinimumCoverage = aggregateCoverageResult.calculateMetadataFilesWithoutCoverage(75, 'ApexClass');

            // Verify
            System.assertEquals(1, classesWithoutMinimumCoverage, 'Only one class does not fulfil the minimum coverage');
        }
    }
    
    @isTest
    private static void calculateMetadataFilesWithNoCoverableLines() {
        System.runAs(getTestUser()) {
            // Setup
            AggregateCoverageResult aggregateCoverageResult = createMockAggregateWithNoCoverableLines();

            // Exercise
            Integer classesWithoutMinimumCoverage = aggregateCoverageResult.calculateMetadataFilesWithoutCoverage(75, 'ApexClass');

            // Verify
            System.assertEquals(0, classesWithoutMinimumCoverage, 'File with no coverable lines should not be in result.');
        }
    }

    @isTest
    private static void calculateFileCoveragePercentage() {
        System.runAs(getTestUser()) {
            // Setup
            AggregateCoverageResult aggregateCoverageResult = createMockAggregateCoverageResult();
            AggregateCoverageResult.FileCoverageResult coverageResultFile1 = aggregateCoverageResult.records[0];

            // Exercise
            Double fileCoveragePercentage = coverageResultFile1.calculateFileCoveragePercentage();

            // Verify
            System.assertEquals(75.0, fileCoveragePercentage, 'File Coverage should be 75%');
        }
    }
    
    private static AggregateCoverageResult createMockAggregateWithNoCoverableLines() {
        AggregateCoverageResult result = new AggregateCoverageResult();
        
        AggregateCoverageResult.FileCoverageResult mockCoverageFile1 = new AggregateCoverageResult.FileCoverageResult();
        mockCoverageFile1.ApexClassOrTrigger = new AggregateCoverageResult.ApexClassDto();
        mockCoverageFile1.ApexClassOrTrigger.attributes = new AggregateCoverageResult.ApexMetadataAttributes();
        mockCoverageFile1.ApexClassOrTrigger.attributes.url = 'ApexClass';
        mockCoverageFile1.NumLinesCovered = 0;
        mockCoverageFile1.NumLinesUncovered = 0;
        
        result.records = new List<AggregateCoverageResult.FileCoverageResult>{ mockCoverageFile1};

        return result;
    }

    private static AggregateCoverageResult createMockAggregateCoverageResult() {
        AggregateCoverageResult result = new AggregateCoverageResult();

        AggregateCoverageResult.FileCoverageResult mockCoverageFile1 = new AggregateCoverageResult.FileCoverageResult();
        mockCoverageFile1.ApexClassOrTrigger = new AggregateCoverageResult.ApexClassDto();
        mockCoverageFile1.ApexClassOrTrigger.attributes = new AggregateCoverageResult.ApexMetadataAttributes();
        mockCoverageFile1.ApexClassOrTrigger.attributes.url = 'ApexClass';
        mockCoverageFile1.ApexClassOrTrigger.attributes.url = 'ApexClass';
        mockCoverageFile1.NumLinesCovered = 75;
        mockCoverageFile1.NumLinesUncovered = 25;

        AggregateCoverageResult.FileCoverageResult mockCoverageFile2 = new AggregateCoverageResult.FileCoverageResult();
        mockCoverageFile2.ApexClassOrTrigger = new AggregateCoverageResult.ApexClassDto();
        mockCoverageFile2.ApexClassOrTrigger.attributes = new AggregateCoverageResult.ApexMetadataAttributes();
        mockCoverageFile2.ApexClassOrTrigger.attributes.url = 'ApexClass';
        mockCoverageFile2.NumLinesCovered = 25;
        mockCoverageFile2.NumLinesUncovered = 75;
        
        result.records = new List<AggregateCoverageResult.FileCoverageResult>{ mockCoverageFile1, mockCoverageFile2 };

        return result;
    }

    @TestSetup
    private static void setupUser() {
        new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
    }

    private static User getTestUser() {
        return [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@test.org' LIMIT 1].get(0);
    }
}
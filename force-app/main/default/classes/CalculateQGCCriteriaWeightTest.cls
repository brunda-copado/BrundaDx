@IsTest
private class CalculateQGCCriteriaWeightTest {

    @IsTest
    private static void calculateCriteriaWeight() {
        System.runAs(getRunAsUser()) {
            // Setup
            String filterCriteria = '{$Changes.Directory.notContains("Classes")} && {$Changes.Type.startsWith("apex")}';

            // Exercise
            Integer criteriaWeight = new CalculateQGCCriteriaWeight(filterCriteria).execute();

            // Verify
           
            // Criteria Weight: 'Directory' => 20 * 'notContains' => 4 + 'Type' => 10 * 'startsWith' => 5
            // (20 * 4) + (10 * 5) => 80 + 50 => 130
            System.assertEquals(130, criteriaWeight, 'Weight should be 130');
        }
    }
    
    @IsTest
    private static void calculateWithoutFilterCriteria() {
        System.runAs(getRunAsUser()) {
            // Setup
            String filterCriteria;

            // Exercise
            Integer criteriaWeight = new CalculateQGCCriteriaWeight(filterCriteria).execute();

            // Verify
            System.assertEquals(0, criteriaWeight, 'Weight should be 0');
        }
    }

    @IsTest
    private static void calculateCriteriaWeightWithoutLogicalOperator() {
        System.runAs(getRunAsUser()) {
            // Setup
            String filterCriteria = '{$Changes.Directory.notContains("ApexTrigger")}';

            // Exercise
            Integer criteriaWeight = new CalculateQGCCriteriaWeight(filterCriteria).execute();

            // Verify
            
            // Criteria Weight: 'Directory' => 20 * 'notContains' => 4 
            System.assertEquals(80, criteriaWeight, 'Weight should be 80');
        }
    }

    @IsTest
    private static void calculateCriteriaWeightWithOr() {
        System.runAs(getRunAsUser()) {
            // Setup
            String filterCriteria = '{$Changes.Directory.notContains("Classes")} || {$Changes.Type.startsWith("Apex")}';

            // Exercise
            Integer criteriaWeight = new CalculateQGCCriteriaWeight(filterCriteria).execute();

            // Verify
            
            // Criteria Weight: Min ('Directory' => 20 * 'notContains' => 4, 'Type' => 10 * 'startsWith' => 5)
            // (20 * 4) - (10 * 5) => Min(80, 50) => 50
            System.assertEquals(50, criteriaWeight, 'Weight should be 50');
        }
    }

    @IsTest
    private static void calculateCriteriaWeightWithAndOr() {
        System.runAs(getRunAsUser()) {
            // Setup
            String filterCriteria = '({$Changes.Directory.notContains("ApexTrigger")} && {$Changes.Type.startsWith("Apex")} ) || {$Changes.Name.equals("Selector")}';

            // Exercise
            Integer criteriaWeight = new CalculateQGCCriteriaWeight(filterCriteria).execute();

            // Verify

            // Criteria Weight: Min (('Directory' => 20 * 'notContains' => 4 + 'Type' => 10 * 'startsWith' => 5), ('Name' => 30 * 'equals' => 10))
            // Min ((80 + 50), 300) => 130
            System.assertEquals(130, criteriaWeight, 'Weight should be 130');
        }
    }

    @IsTest
    private static void calculateCriteriaWeightWithAndOrAnd() {
        System.runAs(getRunAsUser()) {
            // Setup
            String filterCriteria = '( {$Changes.Directory.notContains("ApexTrigger")} && {$Changes.Type.equals("ApexTrigger")} ) || ( {$Changes.Name.equals("Selector")} && {$Changes.Type.startsWith("Apex")} )';

            // Exercise
            Integer criteriaWeight = new CalculateQGCCriteriaWeight(filterCriteria).execute();

            // Verify

            // Criteria Weight: Min (('Directory' => 20 * 'notContains' => 4 + 'Type' => 10 * 'equals' => 10), ('Name' => 30 * 'equals' => 10 + 'Type' => 10 * 'startsWith' => 5))
            // Min ((80 + 100), (300 + 50)) => Min (180, 350) => 180
            System.assertEquals(180, criteriaWeight, 'Weight should be 180');
        }
    }

    @IsTest
    private static void calculateCriteriaWeightWithMultipleAndOr() {
        System.runAs(getRunAsUser()) {
            // Setup
            String filterCriteria = '(({$Changes.Directory.notContains("ApexTrigger")} && {$Changes.Type.startsWith("Apex")}) || {$Changes.Name.endsWith("Selector")}) && {$Changes.Type.equals("ApexClass")}';

            // Exercise
            Integer criteriaWeight = new CalculateQGCCriteriaWeight(filterCriteria).execute();

            // Verify

            // Criteria Weight: Min (('Directory' => 20 * 'notContains' => 4 + 'Type' => 10 * 'startsWith' => 5), ('Name' => 30 * 'endsWith' => 5)) + ('Type' => 10 * 'equals' => 10)
            // Min ((80 + 50),  150) + 100 => Min (130, 150) + 100 => 130 + 100 => 230
            System.assertEquals(230, criteriaWeight, 'Weight should be 230');
        }
    }

    //HELPER
    
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

}
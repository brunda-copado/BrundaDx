@IsTest
private class ManualStepCtrlTest {

    @IsTest
    private static void getInstruction() {

        // Setup
        JobTemplate__c template = new JobTemplate__c(Name = 'Sample', Version__c = 1);
        insert template;

        JobExecution__c execution = new JobExecution__c(Template__c = template.Id);
        insert execution;

        JobStep__c step = new JobStep__c(Name = 'step1', JobExecution__c = execution.Id, Type__c = 'Manual');
        step.ConfigJson__c = '{"instructions": "ManualInstruction"}';
        insert step;


        // Exercise
        List<String> instructions = ManualStepCtrl.getInstruction(new List<Id> { step.Id });


        // Verify
        System.assertEquals(1, instructions.size());
        System.assertEquals('ManualInstruction', instructions[0]);
    }


    @IsTest
    private static void getInstructionWithInvalidJson() {

        // Setup
        JobTemplate__c template = new JobTemplate__c(Name = 'Sample', Version__c = 1);
        insert template;

        JobExecution__c execution = new JobExecution__c(Template__c = template.Id);
        insert execution;

        JobStep__c step = new JobStep__c(Name = 'step1', JobExecution__c = execution.Id, Type__c = 'Manual');
        step.ConfigJson__c = '["instructions", "ManualInstruction"]';
        insert step;


        // Exercise
        List<String> instructions = ManualStepCtrl.getInstruction(new List<Id> { step.Id });


        // Verify
        System.assertEquals(1, instructions.size());
        System.assertEquals(null, instructions[0]);
    }
}
public with sharing class FunctionCreditHelper implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    private static final Map<String, Decimal> WORKER_SIZE_CREDITS = new Map<String, Integer>{ 'S' => 1, 'M' => 2, 'L' => 4, 'XL' => 8 };
    Integer totalCreditsUsed = 0;

    // PUBLIC
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<Result__c> start(Database.BatchableContext context) {
        return [
            SELECT Id, Custom_Function_Used_Credits__c, CreditSyncStatus__c
            FROM Result__c
            WHERE CreditSyncStatus__c = 'Pending'
            WITH SECURITY_ENFORCED
        ];
    }

    public void execute(Database.BatchableContext context, List<Result__c> results) {
        Integer usedCredits = 0;
        for (Result__c result : results) {
            usedCredits += result.Custom_Function_Used_Credits__c == null ? 0 : (Integer) result.Custom_Function_Used_Credits__c;
            result.CreditSyncStatus__c = 'Success';
        }

        List<CustomFunctionUsage__c> usage = monthlyUsage();

        if (!usage.isEmpty()) {
            usedCredits += Integer.valueOf(usage[0].Credits__c);
        }

        totalCreditsUsed = usedCredits;

        // Note: DML on protected custom setting does not need CRUD check
        upsert new CustomFunctionUsage__c(Name = String.valueOf(Date.today()), Year_Month__c = Date.today(), Credits__c = usedCredits) Name;
        DML.safeUpdate(results, 'Failed to update credit sync status');
    }

    public void finish(Database.BatchableContext context) {
        if (totalCreditsUsed != 0) {
            FeatureManagement.setPackageIntegerValue('CustomFunctionCreditUsage', totalCreditsUsed);
        }
        FunctionResultMonitor.schedule();
    }

    public static Boolean hardLimitReached() {
        return FeatureManagement.checkPackageIntegerValue('CustomFunctionHardCreditLimit') <=
            FeatureManagement.checkPackageIntegerValue('CustomFunctionCreditUsage');
    }

    public static Integer usedMinutes(Datetime startDate) {
        Integer usedMinutes = 0;

        if (startDate != null) {
            Long startTime = startDate?.getTime();
            Long endTime = DateTime.now().getTime();
            Long seconds = (endTime - startTime) / 1000;

            usedMinutes = Math.ceil(seconds / 60).intValue() == 0 ? 1 : Math.ceil(seconds / 60).intValue();
        }

        return usedMinutes;
    }

    public static Integer usedCredits(Long minutes, String workerSize) {
        return String.isBlank(workerSize) || minutes == null ? 0 : Integer.valueOf(minutes * WORKER_SIZE_CREDITS.get(workerSize));
    }

    // PRIVATE

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static List<CustomFunctionUsage__c> monthlyUsage() {
        // protected system object, no security checks needed.
        return [
            SELECT Credits__c
            FROM CustomFunctionUsage__c
            WHERE CALENDAR_YEAR(Year_Month__c) = :Date.today().year() AND CALENDAR_MONTH(Year_Month__c) = :Date.today().month()
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
    }
}
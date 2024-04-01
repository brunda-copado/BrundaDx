public inherited sharing class CopadoLicensesSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return Copado_License__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ Copado_License__c.Id };
    }

    public CopadoLicensesSelector() {
        this(true);
    }

    public CopadoLicensesSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS);
    }

    public List<Copado_License__c> unused() {
        return (List<Copado_License__c>) Database.query(
            newQueryFactory()
                .setCondition(
                    'Enable_Copado__c = FALSE AND Enable_CCM__c = FALSE AND Enable_CST__c = FALSE AND Enable_CAD__c = FALSE AND Enable_CCH__c = FALSE AND Enable_ADD__c = FALSE'
                )
                .setLimit(1000)
                .toSOQL()
        );
    }
}
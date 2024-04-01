public with sharing class UserStoryAssignmentSetController {
	public List<User_Story__c> records {get;set;}
	public User_Story__c dummy {get;set;}
	public apexpages.standardsetcontroller con;
	public Boolean showLicenseError {get;set;}
	
	public UserStoryAssignmentSetController(apexpages.standardsetcontroller std){
		showLicenseError=false;
		isLicenseEnabled();
		if(!showLicenseError){
			con = std;
			records = (List<User_Story__c>)std.getSelected();
			dummy = new User_Story__c();
		}
	}

	public PageReference cancel(){
		return con.cancel();
	}

	public PageReference assign(){
		List<User_Story__c> updates = new List<User_Story__c>(); 
		for (User_Story__c us : records){
			us.Release__c=dummy.Release__c;
			updates.add(us);
		}
		if(updates.size()>0){
			Utilities.Secure_DML(updates, Utilities.DML_Action.UPD, schema.Sobjecttype.User_Story__c);
		}
		else{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.SELECT_AT_LEAST_ONE_RECORD));
			return null;
		}
		return new PageReference('/' + dummy.Release__c);
	}

	private void isLicenseEnabled() {
        if (!LicenseHelper.actionIsLicenseEnabled('userStoryAssignment')) {
            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.WARNING, Label.CE_License_Restriction.replace('__License__', Label.CCM_or_CAD_License))
            );
            showLicenseError = true;
        }
    }
}
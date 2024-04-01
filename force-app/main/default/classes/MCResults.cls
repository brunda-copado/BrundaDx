public with sharing class MCResults extends fflib_SObjectDomain {
  // CONSTRUCTOR

  public MCResults(List<MC_Result__e> records) {
    super(records);
  }

  // PUBLIC

  public override void onAfterInsert() {
    new HandleBackendResponse(records).execute();
  }

  // INNER

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new MCResults(records);
    }
  }
}
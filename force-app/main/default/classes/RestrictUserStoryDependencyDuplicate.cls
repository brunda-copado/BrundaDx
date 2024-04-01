// Referenced from class UserStoryDependencyTriggerHandler
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class RestrictUserStoryDependencyDuplicate {

    private List<Team_Dependency__c> dependencies;
    private Map<Id, Set<Id>> dependenciesByParentId;
    private Map<Id, Set<Id>> dependenciesByChildId;
    private Set<Id> parentUserStoryIds;
    private Set<Id> childUserStoryIds;
        

    // CONSTRUCTOR

    public RestrictUserStoryDependencyDuplicate(List<Team_Dependency__c> dependencies) {
        this.dependencies = dependencies;
    }

    public RestrictUserStoryDependencyDuplicate(List<Team_Dependency__c> dependencies, 
                                                Map<Id, Team_Dependency__c> oldRecords) {
        this.dependencies = filter(dependencies, oldRecords);
    }
       

    // PUBLIC
    public void execute() {
        prepareParentChildUserStorySets();
        prepareDependencyMaps();

        for (Team_Dependency__c dependency : dependencies) {
            if (isDuplicate(dependency)) {
                dependency.addError(Label.Duplicate_User_Story_Dependency_Error);
            }
        } 
    }

    // Filter
    private List<Team_Dependency__c> filter(List<Team_Dependency__c> records, Map<Id, Team_Dependency__c> oldRecords) {
        List<Team_Dependency__c> result = new List<Team_Dependency__c>();

        if(records != null) {
            for(Team_Dependency__c record : records) {
                Team_Dependency__c oldRecord = oldRecords?.get(record.Id);
                
                if(isParentOrChildUpdated(record, oldRecord)) {
                    result.add(record);
                }
            }   
        }

        return result;
    }

    // Check Parent or Child Updated
    private Boolean isParentOrChildUpdated(Team_Dependency__c record, Team_Dependency__c oldRecord) {
        Boolean hasParentChanged = record.Provider_User_Story__c != null && record.Provider_User_Story__c != oldRecord?.Provider_User_Story__c;
        Boolean hasChildChanged = record.Dependent_User_Story__c != null && record.Dependent_User_Story__c != oldRecord?.Dependent_User_Story__c;
        return (hasParentChanged || hasChildChanged);
    }

    // IS Duplicate Dependency
    private Boolean isDuplicate(Team_Dependency__c dependency) {
        Boolean hasExistingChildRelationship = dependency.Provider_User_Story__c != null 
                                    && dependenciesByParentId.containsKey(dependency.Provider_User_Story__c) 
                                    && dependenciesByParentId.get(dependency.Provider_User_Story__c).contains(dependency.Dependent_User_Story__c);
        
        Boolean hasExisingParentRelationship = dependency.Dependent_User_Story__c != null 
                                    && dependenciesByChildId.containsKey(dependency.Dependent_User_Story__c) 
                                    && dependenciesByChildId.get(dependency.Dependent_User_Story__c).contains(dependency.Provider_User_Story__c);

        return (hasExistingChildRelationship || hasExisingParentRelationship);  
    }

    // Prepare Sets
    private void prepareParentChildUserStorySets(){  
        parentUserStoryIds = new Set<Id>();
        childUserStoryIds = new Set<Id>();

        for (Team_Dependency__c dependency : dependencies) {
            if (dependency.Provider_User_Story__c != null) {
                parentUserStoryIds.add(dependency.Provider_User_Story__c);
            }
            if (dependency.Dependent_User_Story__c != null) {
                childUserStoryIds.add(dependency.Dependent_User_Story__c);
            }
        }
    }

    // Prepare Maps
    private void prepareDependencyMaps() {  
        dependenciesByParentId = new Map<Id, Set<Id>>();
        dependenciesByChildId = new Map<Id, Set<Id>>();
        
        for (Team_Dependency__c dependency : [SELECT Id, Provider_User_Story__c, Dependent_User_Story__c 
                                              FROM Team_Dependency__c 
                                              WHERE (Provider_User_Story__c IN :parentUserStoryIds
                                              OR Dependent_User_Story__c IN :childUserStoryIds)
                                              AND Id not in :dependencies]){
            if (!dependenciesByParentId.containsKey(dependency.Provider_User_Story__c)) {
                dependenciesByParentId.put(dependency.Provider_User_Story__c, new Set<Id>());
            }
            dependenciesByParentId.get(dependency.Provider_User_Story__c).add(dependency.Dependent_User_Story__c);

            if (!dependenciesByChildId.containsKey(dependency.Dependent_User_Story__c)) {
                dependenciesByChildId.put(dependency.Dependent_User_Story__c, new Set<Id>());
            }
            dependenciesByChildId.get(dependency.Dependent_User_Story__c).add(dependency.Provider_User_Story__c);
        }  
    }
}
public inherited sharing class UsersSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return User.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ User.Id, User.Name, User.Email };
    }

    public UsersSelector() {
        this(true);
    }

    public UsersSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS);
    }

    public List<User> byId(List<Id> recordIds) {
        return byId(new Set<Id>(recordIds));
    }

    public List<User> byId(Set<Id> recordIds) {
        return (List<User>) selectSObjectsById(recordIds);
    }

    public Map<Id, User> byIdWithFields(Set<Id> ids, Set<String> fields) {
        return new Map<Id, User>(
            (List<User>) Security.stripInaccessible(
                    AccessType.READABLE,
                    Database.query(newQueryFactory().setEnforceFLS(false).selectFields(fields).setCondition('id in :ids').toSOQL())
                )
                .getRecords()
        );
    }

    public List<User> byPartialNameExcludingSelected(String searchTerm, List<Id> selectedIds) {
        searchTerm = '%' + searchTerm + '%';
        return (List<User>) Database.query(newQueryFactory().setCondition('Name LIKE :searchTerm AND Id NOT IN :selectedIds').setLimit(5).toSOQL());
    }
}
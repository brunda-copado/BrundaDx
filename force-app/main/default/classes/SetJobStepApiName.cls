public inherited sharing class SetJobStepApiName {
    private List<JobStep__c> steps;

    private static final Map<SObjectType, SObjectField> FIELD_BY_PARENT_OBJECT = new Map<SObjectType, SObjectField>{
        JobTemplate__c.SObjectType => JobTemplate__c.ApiName__c,
        JobExecution__c.SObjectType => JobExecution__c.Name,
        User_Story__c.SObjectType => User_Story__c.Name
    };

    // CONSTRUCTOR

    public SetJobStepApiName(List<JobStep__c> steps) {
        this.steps = steps;
    }

    // PUBLIC

    public void execute() {
        Logger.trace('', 'SetJobStepApiName.execute', 'Steps: ', steps);
        Set<Id> parentIds = parentIds(steps);

        Map<Id, SObject> parentsById = new Map<Id, SObject>();
        parentsById.putAll(new JobExecutionsSelector().byId(parentIds));
        parentsById.putAll(new JobTemplatesSelector().byId(parentIds));
        parentsById.putAll(new UserStoriesSelector().byIds(parentIds));

        for (JobStep__c step : steps) {
            Id parent = parent(step);
            String parentName = String.valueOf(parentsById.get(parent)?.get(parentField(parent)));
            step.ApiName__c = String.isNotBlank(step.Name)
                ? (parentName + '_' + step.Name.trim().replaceAll('[^a-zA-Z0-9]+', '_').replaceAll(' ', '_') + '_' + Integer.valueOf(step.Order__c))
                : (parentName + '_' + step.Name + '_' + Integer.valueOf(step.Order__c));
        }
    }

    // PRIVATE

    private Set<Id> parentIds(List<JobStep__c> steps) {
        Set<Id> result = new Set<Id>();

        for (JobStep__c step : steps) {
            result.add(parent(step));
        }

        return result;
    }

    private Id parent(JobStep__c step) {
        Id parent;

        if (step.JobTemplate__c != null) {
            parent = step.JobTemplate__c;
        } else if (step.JobExecution__c != null) {
            parent = step.JobExecution__c;
        } else if (step.UserStory__c != null) {
            parent = step.UserStory__c;
        }

        return parent;
    }

    private SObjectField parentField(Id id) {
        return FIELD_BY_PARENT_OBJECT.get(id.getSobjectType());
    }
}
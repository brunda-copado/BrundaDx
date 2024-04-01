public with sharing class MatchAutomationRuleFilterCriteria {
    // PUBLIC
    public Boolean conditionMatches(Automation_Rule__c automationRule, User_Story__c userStory) {
        String whereCondition = new FindFilterCriteria().objectName(Schema.SObjectType.User_Story__c.getName()).fromAutomationRule(automationRule);
        return String.isNotBlank(whereCondition) && matches(userStory.Id, whereCondition);
    }

    //PRIVATE

    private Boolean matches(String userStoryId, String whereCondition) {
        List<User_Story__c> userStories = Database.query(getFormattedQuery(userStoryId, whereCondition));
        return !userStories.isEmpty();
    }

    private String getFormattedQuery(String userStoryId, String condition) {
        String query = 'SELECT {0} FROM {1} WHERE {2} = \'\'{3}\'\' AND ({4}) WITH USER_MODE LIMIT 1';

        return String.format(
            query,
            new List<String>{
                Schema.SObjectType.User_Story__c.fields.Id.getName(),
                Schema.SObjectType.User_Story__c.getName(),
                Schema.SObjectType.User_Story__c.fields.Id.getName(),
                String.escapeSingleQuotes(userStoryId),
                condition
            }
        );
    }

    // In future If User Story trigger will hit SOQL Query Limit, 
    // Uncomment following code and enhance it to work with every filter condition without query. 


    /*private Set<String> getUserStoryFields(String whereCondition) {
        Set<String> userStoryFields = new Set<String>();

        List<String> conditions = whereCondition.split('\\sAND\\s|\\sOR\\s');
        for (String condition : conditions) {
            List<String> elements = condition.split('\\s');
            userStoryFields.add(elements[0]);
        }

        return userStoryFields;
    }

    private Boolean verifyEachCondition(String whereCondition, String userStoryId) {
        Boolean result = true;

        Set<String> userStoryFields = getUserStoryFields(whereCondition);
        User_Story__c userStory = (User_Story__c) Database.query(getFormattedQuery(userStoryFields, userStoryId));

        List<String> conditions = whereCondition.split('\\sAND\\s|\\sOR\\s');
        for (String condition : conditions) {
            List<String> elements = condition.split('\\s');
            String fieldName = elements[0];
            String operator = elements[1];
            String value = elements[2];
            Schema.DisplayType displayType = fieldType(fieldName);
            if (displayType == Schema.DisplayType.String || displayType == Schema.DisplayType.REFERENCE && value.contains('\'')) {
                value = value.remove('\'');
            }
            result = valueMatch((String) userStory.get(fieldName), operator, value);
            if (!result) {
                break;
            }
        }
        return result;
    }

    private String getFormattedQuery(Set<String> userStoryFields, String userStoryId) {
        String query = 'SELECT {0} FROM {1} WHERE {2} = \'\'{3}\'\' WITH USER_MODE LIMIT 1';

        return String.format(
            query,
            new List<String>{
                String.join(new List<String>(this.userStoryFields), ','),
                Schema.SObjectType.User_Story__c.getName(),
                Schema.SObjectType.User_Story__c.fields.Id.getName(),
                String.escapeSingleQuotes(userStoryId)
            }
        );
    }

    private Boolean valueMatch(String candidate, String operator, String value) {
        Boolean result = false;
        switch on operator {
            when '=' {
                result = candidate == value;
            }
            when '!=' {
                result = candidate != value;
            }
            when '<' {
                result = candidate < value;
            }
            when '>' {
                result = candidate > value;
            }
            when '<=' {
                result = candidate <= value;
            }
            when '>=' {
                result = candidate >= value;
            }
            when 'LIKE' {
                result = candidate.contains(value);
            }
            when 'NOT LIKE' {
                result = !candidate.contains(value);
            }
        }
        return result;
    }

    private Schema.DisplayType fieldType(String fieldName) {
        SObjectType sObjectTypeInstance = ((SObject) (Type.forName('Schema.' + Schema.SObjectType.User_Story__c.getName()).newInstance()))
            .getSObjectType();
        DescribeSObjectResult describeResult = sObjectTypeInstance.getDescribe(SObjectDescribeOptions.DEFAULT);
        return describeResult.fields.getMap().get(fieldName).getDescribe().getType();
    }*/
}
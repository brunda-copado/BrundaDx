/**
 * This will be used as a controller for sprintWallUserStories LWC Component
 */
public with sharing class SprintWallUserStoriesCtrl {

    // CONSTANTS

    private static final String ID_FIELD = Schema.SObjectType.User_Story__c.fields.Id.getName();
    private static final String NAME_FIELD = Schema.SObjectType.User_Story__c.fields.Name.getName();
    private static final String SPRINT_FIELD = Schema.SObjectType.User_Story__c.fields.Sprint__c.getName();
    private static final String STATUS_FIELD = Schema.SObjectType.User_Story__c.fields.Status__c.getName();
    private static final String USER_STORY_OBJECT = Schema.SObjectType.User_Story__c.getName();
    private static final String RECORD_LIMIT = '200';
    private static final String FIELD_TYPE_REFERENCE = 'REFERENCE';
    private static final String OPERATOR = 'e';
    private static final String NONE = '--None--';
    private static final String CUSTOM_FIELD_PREFIX = '__c';

    private static final Set<String> USER_STORY_FIELDS = new Set<String> {
        Schema.SObjectType.User_Story__c.fields.Id.getName(),
        Schema.SObjectType.User_Story__c.fields.Name.getName(),
        Schema.SObjectType.User_Story__c.fields.RecordTypeId.getName(),
        Schema.SObjectType.User_Story__c.fields.User_Story_Title__c.getName(),
        Schema.SObjectType.User_Story__c.fields.Progress_Status__c.getName(),
        Schema.SObjectType.User_Story__c.fields.Progress__c.getName(),
        Schema.SObjectType.User_Story__c.fields.Developer__c.getName(),
        Schema.SObjectType.User_Story__c.fields.Story_Points_Other__c.getName(),
        Schema.SObjectType.User_Story__c.fields.Status__c.getName()
    };
    private static final String QUERY_TEMPLATE = 'SELECT {0} FROM {1} WHERE {2} = \'\'{3}\'\' WITH SECURITY_ENFORCED LIMIT {4}';

    private static final String PREVIOUS = '(previous)';
    private static final String CURRENT = '(current)';
    private static final String NEXT = '(next)';
    private static final String KANBAN_BOARD_NAME_TEMPLATE = 'Kanban Board For {0}';

    // NON CONSTANTS

    private static String sprintId = '';

    // PUBLIC 
    
    @AuraEnabled
    public static Boolean isUserStoriesTeamSame(String sprintId){
        Boolean result = true;
        if (String.isNotBlank(sprintId)) {
                List<User_Story__c> listOfUserStory = [SELECT Id,Team__c,Sprint__r.Team__c FROM User_Story__c WHERE Sprint__c =:sprintId  WITH SECURITY_ENFORCED];
                for (User_Story__c userStoryObj :listOfUserStory) {
                    if(userStoryObj.Team__c != userStoryObj.Sprint__r.Team__c ){
                        result = false;
                        break;
                    }
                    
                }
            
        }
        return result;
    }
	
  	/**
     * it is used to open kanban board for current sprint
     * @return PageReference URL to kanbanboard or List<UIDesignHelper.AlertWrapper>
     */
    @AuraEnabled
    public static KanbanWrapper getKanbanBoardUrl(String sprintRecordId) {
        KanbanWrapper result = new KanbanWrapper(null, null);
        List<UIDesignHelper.AlertWrapper> alerts = new List<UIDesignHelper.AlertWrapper>();
        try {
            Sprint__c sprint = [SELECT Id, Name FROM Sprint__c WHERE Id=:sprintRecordId WITH SECURITY_ENFORCED LIMIT 1];
            sprintId = sprint.Id;
            String kanbanBoardName = getFormattedKanbanName(sprint.Name);
            if (Schema.SObjectType.Kanban_Board__c.isQueryable() && Schema.SObjectType.Kanban_Board__c.isAccessible()) {
                String kanbanBoardId = getKanbanBoardId(kanbanBoardName);
                PageReference pReference = Page.KanbanBoardView;
                if (String.isNotBlank(kanbanBoardId)) {
                    pReference.getParameters().put(ID_FIELD, kanbanBoardId);
                }
                pReference.setRedirect(true);
                result.url = pReference.getUrl();
            } else {
                alerts.addAll(UIDesignHelper.warningAlertsOLSFLS(Schema.SObjectType.Kanban_Board__c.getLabel()));
                result.alerts = alerts;
            }
        } catch (Exception exceptions) {
            alerts.add(UIDesignHelper.genericWarningAlert(ApexPages.Severity.ERROR, exceptions.getMessage()));
            result.alerts = alerts;
        }
        return result;
    }

    // PRIVATE

    private static String getKanbanBoardId(String kanbanBoardName) {
        Kanban_Board__c kanbanBoard = new Kanban_Board__c();
        List<Kanban_Board__c> kanbanBoards = new List<Kanban_Board__c>([SELECT Id, Sprint__c FROM Kanban_Board__c WHERE Sprint__c = :sprintId OR (Sprint__c = null AND Name = :kanbanBoardName) WITH SECURITY_ENFORCED LIMIT 1]);
        if (!kanbanBoards.isEmpty()) {
            kanbanBoard = kanbanBoards.get(0);
            if (String.isBlank(kanbanBoard.Sprint__c)) {
                kanbanBoard.Sprint__c = sprintId;
                updateKanbanBoard(kanbanBoard);
            }
        } else {
            kanbanBoard = createKanbanBoard(kanbanBoardName);
            kanbanBoard = insertKanbanBoard(kanbanBoard);
        }
        return kanbanBoard.Id;
    }

    private static void updateKanbanBoard(Kanban_Board__c kanbanBoard) {
        Utilities.Secure_DML(kanbanBoard, Utilities.DML_Action.UPD, schema.SObjectType.Kanban_Board__c);
    }

    private static Kanban_Board__c createKanbanBoard(String kanbanBoardName) {
        Kanban_Board__c result = new Kanban_Board__c();
        String soqlQuery = getFormattedQuery();

        QueryEditor dummyQEditor = new QueryEditor();
        QueryEditor.SoqlWrapper dummySoqlJsonWrapper = new QueryEditor.SoqlWrapper();

        QueryEditor.CriteriaWrapper dummyCriteriaWrapper = new QueryEditor.CriteriaWrapper();
        dummyCriteriaWrapper.order = 1;
        dummyCriteriaWrapper.operatorSet = null;
        dummyCriteriaWrapper.operator = OPERATOR;
        dummyCriteriaWrapper.input = sprintId;
        dummyCriteriaWrapper.fieldType = FIELD_TYPE_REFERENCE;
        dummyCriteriaWrapper.fieldName = SPRINT_FIELD;
        dummyCriteriaWrapper.dateInput = null;
        dummyCriteriaWrapper.dateTimeInput = null;

        dummySoqlJsonWrapper.viewName = kanbanBoardName;
        dummySoqlJsonWrapper.selectedFields = new List<String>(USER_STORY_FIELDS);
        dummySoqlJsonWrapper.selectedFooterFields = new List<String>{};
        dummySoqlJsonWrapper.summarizeByList = new List<QueryEditor.SummarizeByWrapper>{};
        dummySoqlJsonWrapper.criteriaList = new List<QueryEditor.CriteriaWrapper>{ dummyCriteriaWrapper };
        dummySoqlJsonWrapper.orderByList = new List<String>{};
        dummySoqlJsonWrapper.queryLimit = RECORD_LIMIT;
        dummySoqlJsonWrapper.wholeSoql = soqlQuery;
        dummySoqlJsonWrapper.fieldToReadUpdate = STATUS_FIELD;
        dummySoqlJsonWrapper.headerField = NAME_FIELD;
        dummySoqlJsonWrapper.orderedIn = NONE;
        dummySoqlJsonWrapper.nullValues = NONE;
        dummySoqlJsonWrapper.sobjectTypeName = USER_STORY_OBJECT;
        dummySoqlJsonWrapper.enableFilterLogic = false;
        dummySoqlJsonWrapper.filterLogic = '';
        dummySoqlJsonWrapper.kanbanDescription = kanbanBoardName;
        dummySoqlJsonWrapper.userImageField = NONE;
        dummySoqlJsonWrapper.colorField = NONE;

        dummyQEditor.queryWrapper = dummySoqlJsonWrapper;

        result.Name = kanbanBoardName;
        result.Sprint__c = sprintId;
        result.Description__c = kanbanBoardName;
        result.Field_to_read_update__c = USER_STORY_OBJECT + '.' + STATUS_FIELD;
        result.SOQL_Query__c = soqlQuery;
        result.JSON_Settings__c = JSON.serialize(dummyQEditor);
        return result;
    }

    private static Kanban_Board__c insertKanbanBoard(Kanban_Board__c kanbanBoard) {
        Utilities.Secure_DML(kanbanBoard, Utilities.DML_Action.INS, schema.SObjectType.Kanban_Board__c);
        return kanbanBoard;
    }
    
    private static String getFormattedKanbanName(String sprintName) {
        sprintName = sprintName.replace(PREVIOUS, '').replace(CURRENT, '').replace(NEXT, '');
        return String.format(KANBAN_BOARD_NAME_TEMPLATE, new List<Object>{ sprintName });
    }
    
    private static String getFormattedQuery() {
        return String.format(QUERY_TEMPLATE, getParameters());
    }

    private static List<Object> getParameters() {
        return new List<Object>{ getSelectFields(USER_STORY_FIELDS), USER_STORY_OBJECT, SPRINT_FIELD, toSoqlString(sprintId), RECORD_LIMIT };
    }

    private static String getSelectFields(Set<String> fields) {
        return String.join(new List<String>(fields), ',');
    }

    private static String toSoqlString(String str) {
        return String.escapeSingleQuotes(str);
    }

    //WRAPPER

    public with sharing class KanbanWrapper {
        @AuraEnabled
        public String url { get; set; }
        @AuraEnabled
        public List<UIDesignHelper.AlertWrapper> alerts { get; set; }

        // CTOR

        public KanbanWrapper(String url, List<UIDesignHelper.AlertWrapper> alerts) {
            this.url = url;
            this.alerts = alerts;
        }
    }
}
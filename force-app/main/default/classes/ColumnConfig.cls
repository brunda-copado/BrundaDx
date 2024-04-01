/**
 * This class is used as a wrapper by DynamicDatatableCtrl
 */
public with sharing class ColumnConfig {
    @AuraEnabled
    public String actions;
    @AuraEnabled
    public CellAttributes cellAttributes;
    @AuraEnabled
    public Boolean editable;
    @AuraEnabled
    public String fieldName;
    @AuraEnabled
    public Integer fixedWidth;
    @AuraEnabled
    public Boolean hideDefaultActions;
    @AuraEnabled
    public String iconName;
    @AuraEnabled
    public String initialWidth;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public Boolean searchable;
    @AuraEnabled
    public Boolean sortable;
    @AuraEnabled
    public String type;
    @AuraEnabled
    public TypeAttributes typeAttributes;
    @AuraEnabled
    public Boolean wrapText;

    // Documentation states that Date and Datetime fields are no inline editable but it is not true
    // Types of number are not editable since they are passed as text and causing an exception
    private final static Set<DisplayType> NON_EDITABLE_TYPES = new Set<DisplayType>{
        DisplayType.ADDRESS,
        DisplayType.DOUBLE,
        DisplayType.INTEGER,
        DisplayType.LONG
    };

    private Map<DisplayType, String> formattingTypesByFieldType = new Map<DisplayType, String>{
        DisplayType.BOOLEAN => 'boolean',
        DisplayType.COMBOBOX => 'text',
        DisplayType.CURRENCY => 'currency',
        DisplayType.DATE => 'date',
        DisplayType.DATETIME => 'date',
        DisplayType.DOUBLE => 'number',
        DisplayType.EMAIL => 'url',
        DisplayType.ID => 'text',
        DisplayType.INTEGER => 'number',
        DisplayType.LONG => 'number',
        DisplayType.MULTIPICKLIST => 'text',
        DisplayType.PERCENT => 'percent',
        DisplayType.PHONE => 'phone',
        DisplayType.PICKLIST => 'text',
        DisplayType.STRING => 'text',
        DisplayType.TEXTAREA => 'text',
        DisplayType.TIME => 'date',
        DisplayType.URL => 'url',
        DisplayType.REFERENCE => 'reference'
    };

    // CTOR

    public ColumnConfig(FieldSetMember field, Boolean hideDefaultActions, Boolean sortable, Boolean editable, Boolean searchable) {
        this.hideDefaultActions = hideDefaultActions == null ? false : hideDefaultActions;
        this.sortable = sortable == null ? false : sortable;
        this.editable = editable == null ? false : editable;
        this.searchable = searchable == null ? false : searchable;
        initColumnConfig(field);
    }

    // PRIVATE

    private void initColumnConfig(FieldSetMember field) {
        String fieldPath = field.getFieldPath();
        label = getLabel(field);

        if (field.getType() == DisplayType.REFERENCE) {
            if (field.getFieldPath().endsWith('__c')) {
                fieldPath = field.getFieldPath().replace('__c', '__r.Name');
            } else if (field.getFieldPath().endsWith('Id')) {
                // Trick to no to replace other possible appearances of 'Id' in the field name
                fieldPath = field.getFieldPath() + '__';
                fieldPath = fieldPath.replace('Id__', '.Name');
            }
        }

        // TODO: Handle other non-name fields like CaseNumber
        if (fieldPath == 'Name' || fieldPath.endsWith('.Name')) {
            fieldName = fieldPath.replace('Name', 'LinkName');
            type = 'url';
            editable = false;
        } else {
            fieldName = fieldPath;
            DisplayType fieldType = field.getType();
            type = formattingTypesByFieldType.get(fieldType);
            // NOTE: By making a column editable, the show-row-number-column attribute is always true and the number column is displayed
            editable = editable && isUpdateable(field) && !NON_EDITABLE_TYPES.contains(fieldType);
        }

        if (type == 'url') {
            cellAttributes = new CellAttributes();
            typeAttributes = new TypeAttributes(fieldPath);
        }

        if (type == 'boolean') {
            searchable = false;
        }
    }

    private String getLabel(FieldSetMember fieldSetMember) {
        String result = fieldSetMember.getLabel();

        String fieldPath = fieldSetMember.getFieldPath();
        if (fieldPath.contains('.')) {
            result = getRelationalLabel(fieldPath);
        }

        return result;
    }

    // Note: currently using field sets, only one parent level is allowed, if in the future multiple levels are allowed, it should be a recursive method
    private String getRelationalLabel(String fieldPath) {
        String result = String.join(fieldPath.substringAfter('.').replace('__c', '').replace('_', '').splitByCharacterTypeCamelCase(), ' ');

        String relationObject = fieldPath.substringBefore('.').replace('__r', '__c');
        String relationField = fieldPath.substringAfter('.');

        String relationFieldLabel = fflib_SObjectDescribe.getDescribe(relationObject)
            ?.getSObjectType()
            .getDescribe()
            .fields.getMap()
            .get(relationField)
            ?.getDescribe()
            .getLabel();
        if (String.isNotBlank(relationFieldLabel)) {
            result = relationFieldLabel;
        }

        return result;
    }

    private Boolean isUpdateable(FieldSetMember field) {
        return field.getSObjectField().getDescribe().isUpdateable();
    }

    // INNER

    private with sharing class TypeAttributes {
        @AuraEnabled
        public Label label;
        @AuraEnabled
        public String target;

        // CTOR

        public TypeAttributes(String fieldName) {
            label = new Label(fieldName);
            target = '_blank';
        }
    }

    private with sharing class Label {
        @AuraEnabled
        public String fieldName;

        // CTOR

        public Label(String fieldName) {
            this.fieldName = fieldName;
        }
    }

    private with sharing class CellAttributes {
        @AuraEnabled
        public String alignment;

        // CTOR

        public CellAttributes() {
            alignment = 'left';
        }
    }
}
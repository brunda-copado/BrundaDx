public with sharing class DatatableConstants {
    public static final String COMMA = ',';
    public static final String SPACE = ' ';
    public static final String UNDERSCORE = '_';
    public static final String DOUBLE_UNDERSCORE = '__';
    public static final String CUSTOM_FIELD_PATH_END = '__c';
    public static final String REFERENCE_FIELD_PATH_END = '__r';
    public static final String CUSTOM_REFERENCE_FIELD_NAME = '__r.Name';
    public static final String STANDARD_REFERENCE_FIELD_NAME = '.Name';
    public static final String ID = 'Id';
    public static final String NAME = 'Name';
    public static final String LINKNAME = 'LinkName';
    public static final String TARGET_BLANK = '_blank';
    public static final String ALIGNMENT_LEFT = 'left';
    public static final String FIELDTYPE_REFERENCE = 'reference';
    public static final String FIELDTYPE_URL = 'url';
    public static final String FIELDTYPE_BOOLEAN = 'boolean';

    public static final Map<DisplayType, String> FORMATTING_TYPE_BY_FIELD_TYPE = new Map<DisplayType, String>{
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

    public static final String QUERY_TEMPLATE = 'SELECT {0} FROM {1} WHERE {2} WITH SECURITY_ENFORCED ORDER BY {3} LIMIT {4} OFFSET {5}';
}
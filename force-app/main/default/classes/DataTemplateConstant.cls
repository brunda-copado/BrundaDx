/**
 *  Copyright (C) 2023 Copado - All Rights Reserved
 * 
 *  Getter Constant class saves impactful heap consumption when large number of constants are present in a class
 *  NOTE: Underscored all caps naming convention shows up as unsupported in PMD.
 *  @Author - Pranjal [15th Sep 2023]
 */
@SuppressWarnings('PMD')
public with sharing class DataTemplateConstant {

    public static final String NONE {
        get {
            return '--None--';
        }
    }
    public static final String TEMPLATE_DETAIL {
        get {
            return 'Template Detail';
        }
    }
    public static final String ADD_DESCRIBE_SOBJECT {
        get {
            return 'ADD_Describe_SObject_Result';
        }
    }
    public static final String ADD_DESCRIBE_GLOBAL {
        get {
            return 'ADD_Describe_Global_Result';
        }
    }
    public static final String C_STRING {
        get {
            return 'STRING';
        }
    }
    @TestVisible
    public static final String C_ERROR {
        get {
            return 'error';
        }
    }
    public static final String C_WARNING {
        get {
            return 'warning';
        }
    }
    public static final String C_PERCENT {
        get {
            return 'PERCENT';
        }
    }
    public static final String C_DOUBLE {
        get {
            return 'DOUBLE';
        }
    }
    public static final String C_BOOLEAN {
        get {
            return 'BOOLEAN';
        }
    }
    public static final String C_INTEGER {
        get {
            return 'INTEGER';
        }
    }
    public static final String C_PHONE {
        get {
            return 'PHONE';
        }
    }
    public static final String C_EMAIL {
        get {
            return 'EMAIL';
        }
    }
    public static final String C_TEXT {
        get {
            return 'TEXT';
        }
    }
    public static final String C_TEXTAREA {
        get {
            return 'TEXTAREA';
        }
    }
    public static final String C_CURRENCY {
        get {
            return 'CURRENCY';
        }
    }
    public static final String C_INT {
        get {
            return 'INT';
        }
    }
    public static final String C_DATE {
        get {
            return 'DATE';
        }
    }
    public static final String C_DATETIME {
        get {
            return 'DATETIME';
        }
    }
    public static final String CUSTOM_DATE {
        get {
            return 'customDate';
        }
    }
    public static final String C_ADDRESS {
        get {
            return 'address';
        }
    }
    public static final String C_GEOLOCATION {
        get {
            return 'location';
        }
    }
    public static final String UTF_8 {
        get {
            return 'UTF_8';
        }
    }
    public static final String C_ORGANIZATION {
        get {
            return 'organization/';
        }
    }
    public static final String C_METADATA {
        get {
            return '/metadata/';
        }
    }
    public static final String C_ID {
        get {
            return 'Id';
        }
    }
    public static final String C_OWNER_ID {
        get {
            return 'OwnerId';
        }
    }
    public static final String EMPTY_STRING {
        get {
            return '';
        }
    }
    public static final String BLANK_SPACE {
        get {
            return ' ';
        }
    }
    public static final String CUSTOM_FILTER {
        get {
            return 'Custom Filter';
        }
    }
    public static final String RECORD_MATCHING {
        get {
            return 'recordMatching';
        }
    }
    public static final String C_NULL {
        get {
            return 'null';
        }
    }

}
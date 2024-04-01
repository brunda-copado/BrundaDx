import RunTests from '@salesforce/label/c.RunTests';
import TestType from '@salesforce/label/c.TestType';
import Tool from '@salesforce/label/c.Tool';
import Result from '@salesforce/label/c.Result';
import Status from '@salesforce/label/c.STATUS';
import TestName from '@salesforce/label/c.TEST_NAME';
import RunDate from '@salesforce/label/c.RUN_DATE';
import Search from '@salesforce/label/c.Search';
import NoDataToDisplay from '@salesforce/label/c.NODATATODISPLAY';
import NewTest from '@salesforce/label/c.NewTest';
import Tests from '@salesforce/label/c.Tests';
import TestAreNotExecutable from '@salesforce/label/c.TestAreNotExecutable';
import TestNotReadyMessage from '@salesforce/label/c.TestNotReadyMessage';
import InactiveExtensionConfigMessage from '@salesforce/label/c.InactiveExtensionConfigMessage';
import TestNotReadyInactiveExtensionConfigMessage from '@salesforce/label/c.TestNotReadyInactiveExtensionConfigMessage';
import TestCreatedSuccessfully from '@salesforce/label/c.TestCreatedSuccessfully';
import Refresh from '@salesforce/label/c.REFRESH';
import Close from '@salesforce/label/c.CLOSE';
import Save from '@salesforce/label/c.Save';
import Cancel from '@salesforce/label/c.Cancel';
import ReadyToRun from '@salesforce/label/c.Ready_to_Run';
import Run from '@salesforce/label/c.RUN';
import Delete from '@salesforce/label/c.DELETE';
import Promotion_Tests_Information from '@salesforce/label/c.Promotion_Tests_Information';
import User_Story_Tests_Information from '@salesforce/label/c.User_Story_Tests_Information';

import USER_STORY from '@salesforce/schema/User_Story__c';
import FEATURE from '@salesforce/schema/Application_Feature__c';
import APPLICATION from '@salesforce/schema/Application__c';
import TEST from '@salesforce/schema/Test__c';
import PROMOTION from '@salesforce/schema/Promotion__c';

import USERSTORY_FIELD from '@salesforce/schema/Test__c.User_Story__c';
import APPLICATION_FIELD from '@salesforce/schema/Test__c.Application__c';
import FEATURE_FIELD from '@salesforce/schema/Test__c.Feature__c';
import NAME_FIELD from '@salesforce/schema/Test__c.Name';
import EXTENSION_CONFIGURATION_FIELD from '@salesforce/schema/Test__c.ExtensionConfiguration__c';

export const label = {
    TestType,
    TestName,
    RunDate,
    RunTests,
    Tool,
    Result,
    Status,
    Search,
    NoDataToDisplay,
    NewTest,
    Tests,
    TestAreNotExecutable,
    TestNotReadyMessage,
    InactiveExtensionConfigMessage,
    TestNotReadyInactiveExtensionConfigMessage,
    TestCreatedSuccessfully,
    Refresh,
    Close,
    Save,
    Cancel,
    ReadyToRun,
    Run,
    Delete,
    Promotion_Tests_Information,
    User_Story_Tests_Information
};

export const schema = {
    USER_STORY,
    FEATURE,
    APPLICATION,
    TEST,
    PROMOTION,
    USERSTORY_FIELD: USERSTORY_FIELD.fieldApiName,
    APPLICATION_FIELD: APPLICATION_FIELD.fieldApiName,
    FEATURE_FIELD: FEATURE_FIELD.fieldApiName,
    NAME_FIELD: NAME_FIELD.fieldApiName,
    EXTENSION_CONFIGURATION_FIELD: EXTENSION_CONFIGURATION_FIELD.fieldApiName
};

export const columns = [
    {
        key: USER_STORY.objectApiName + PROMOTION.objectApiName,
        value: {
            label: label.TestName,
            fieldName: 'testUrl',
            type: 'url',
            hideDefaultActions: true,
            searchable: true,
            typeAttributes: {
                label: {
                    fieldName: 'name'
                },
                target: '_blank'
            },
            filterable: true,
            filtertype: 'text'
        }
    },
    {
        key: USER_STORY.objectApiName + PROMOTION.objectApiName,
        value: { label: label.TestType, fieldName: 'testType', hideDefaultActions: true, searchable: true, filterable: true, filtertype: 'text' }
    },
    {
        key: USER_STORY.objectApiName + PROMOTION.objectApiName,
        value: { label: label.Tool, fieldName: 'testTool', hideDefaultActions: true, searchable: true, filterable: true, filtertype: 'text' }
    },
    {
        key: USER_STORY.objectApiName,
        value: { label: label.RunDate, fieldName: 'runDate', hideDefaultActions: true, searchable: true, filterable: true, filtertype: 'range' }
    },
    {
        key: USER_STORY.objectApiName,
        value: {
            label: label.Result,
            fieldName: 'resultUrl',
            type: 'url',
            hideDefaultActions: true,
            searchable: true,
            typeAttributes: {
                label: {
                    fieldName: 'result'
                },
                target: '_blank'
            },
            filterable: true,
            filtertype: 'text'
        }
    },
    {
        key: USER_STORY.objectApiName,
        value: {
            label: label.Status,
            fieldName: 'status',
            type: 'icon',
            hideDefaultActions: true,
            searchable: true,
            fixedWidth: 80,
            typeAttributes: {
                message: { fieldName: 'message' }
            },
            filterable: true,
            filtertype: 'text'
        }
    },
    {
        key: PROMOTION.objectApiName,
        value: { label: label.ReadyToRun, fieldName: 'isReadyToRun', type: 'boolean', filterable: true, filtertype: 'boolean' }
    }
];
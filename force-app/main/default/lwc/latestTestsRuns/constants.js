import TestType from '@salesforce/label/c.TestType';
import Tool from '@salesforce/label/c.Tool';
import Result from '@salesforce/label/c.Result';
import Status from '@salesforce/label/c.STATUS';
import TestName from '@salesforce/label/c.TEST_NAME';
import RunDate from '@salesforce/label/c.RUN_DATE';
import Search from '@salesforce/label/c.Search';
import LatestTestsRuns from '@salesforce/label/c.LatestTestsRuns';
import NoDataToDisplay from '@salesforce/label/c.NODATATODISPLAY';
import Tests from '@salesforce/label/c.Tests';
import Refresh from '@salesforce/label/c.REFRESH';

import USER_STORY from '@salesforce/schema/User_Story__c';
import USER_STORY_COMMIT from '@salesforce/schema/User_Story_Commit__c';
import FEATURE from '@salesforce/schema/Application_Feature__c';
import APPLICATION from '@salesforce/schema/Application__c';
import TEST from '@salesforce/schema/Test__c';
import PROMOTION from '@salesforce/schema/Promotion__c';

import USERSTORY_FIELD from '@salesforce/schema/Test__c.User_Story__c';
import NAME_FIELD from '@salesforce/schema/Test__c.Name';
import EXTENSION_CONFIGURATION_FIELD from '@salesforce/schema/Test__c.ExtensionConfiguration__c';

export const label = {
    TestType,
    TestName,
    RunDate,
    Tool,
    Result,
    Status,
    Search,
    NoDataToDisplay,
    Tests,
    Refresh,
    LatestTestsRuns
};

export const schema = {
    USER_STORY,
    USER_STORY_COMMIT,
    FEATURE,
    APPLICATION,
    TEST,
    PROMOTION,
    USERSTORY_FIELD: USERSTORY_FIELD.fieldApiName,
    NAME_FIELD: NAME_FIELD,
    EXTENSION_CONFIGURATION_FIELD: EXTENSION_CONFIGURATION_FIELD.fieldApiName
};

export const columns = [
    {
        key: USER_STORY.objectApiName + USER_STORY_COMMIT.objectApiName + PROMOTION.objectApiName,
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
        key: USER_STORY.objectApiName + USER_STORY_COMMIT.objectApiName + PROMOTION.objectApiName,
        value: { label: label.TestType, fieldName: 'testType', hideDefaultActions: true, searchable: true, filterable: true, filtertype: 'text' }
    },
    {
        key: USER_STORY.objectApiName + USER_STORY_COMMIT.objectApiName + PROMOTION.objectApiName,
        value: { label: label.Tool, fieldName: 'testTool', hideDefaultActions: true, searchable: true, filterable: true, filtertype: 'text' }
    },
    {
        key: USER_STORY.objectApiName + USER_STORY_COMMIT.objectApiName + PROMOTION.objectApiName,
        value: { label: label.RunDate, fieldName: 'runDate', hideDefaultActions: true, searchable: true, filterable: true, filtertype: 'range' }
    },
    {
        key: USER_STORY.objectApiName + USER_STORY_COMMIT.objectApiName + PROMOTION.objectApiName,
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
        key: USER_STORY.objectApiName + USER_STORY_COMMIT.objectApiName + PROMOTION.objectApiName,
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
    }
];
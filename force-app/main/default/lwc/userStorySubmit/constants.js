import EDIT from '@salesforce/label/c.EDIT';
import CANCEL from '@salesforce/label/c.Cancel';
import CLOSE from '@salesforce/label/c.CLOSE';
import SUBMIT from '@salesforce/label/c.Submit';
import SUBMIT_USER_STORY from '@salesforce/label/c.Submit_User_Story';
import SUBMIT_USER_STORY_FOR_PROMOTION from '@salesforce/label/c.Submit_User_Story_For_Promotion';
import SUBMIT_USER_STORY_FOR_PROMOTION_WARNING from '@salesforce/label/c.Submit_User_Story_For_Promotion_Warning_Already_Marked';
import SUBMIT_USER_STORY_DEPLOY_CHANGES from '@salesforce/label/c.Submit_User_Story_Deploy_Changes';
import SUBMIT_USER_STORY_SKIP_CONTINUOUS_DELIVERY from '@salesforce/label/c.Submit_User_Story_Skip_Continuous_Delivery';
import USER_STORY_CAN_NOT_BE_SUBMITTED from '@salesforce/label/c.User_Story_Can_Not_Be_Submitted';
import USER_STORY_COULD_NOT_BE_SUBMITTED from '@salesforce/label/c.User_Story_Could_Not_Be_Submitted';
import USER_STORY_SUCCESSFULLY_SUBMITTED from '@salesforce/label/c.User_Story_Successfully_Submitted';

import SUBMIT_BEHAVIOUR_MANUALLY from '@salesforce/label/c.Submit_Behaviour_Manually';
import SUBMIT_BEHAVIOUR_IMMEDIATELY from '@salesforce/label/c.Submit_Behaviour_Immediately';
import SUBMIT_BEHAVIOUR_SCHEDULED_BY_THE_AUTOMATION from '@salesforce/label/c.Submit_Behaviour_Scheduled_By_The_Automation';
import SUBMIT_BEHAVIOUR_SCHEDULED_DATE_TIME from '@salesforce/label/c.Submit_Behaviour_Scheduled_Date_Time';

import READYTOPROMOTE from '@salesforce/schema/User_Story__c.Promote_Change__c';
import PROMOTEANDDEPLOY from '@salesforce/schema/User_Story__c.Promote_and_Deploy__c';

import AUTOMATION_EXECUTION_FIELD from '@salesforce/schema/Automation_Rule__c.Execution__c';

export const label = {
    EDIT,
    CANCEL,
    CLOSE,
    SUBMIT,
    SUBMIT_USER_STORY,
    SUBMIT_USER_STORY_FOR_PROMOTION,
    SUBMIT_USER_STORY_FOR_PROMOTION_WARNING,
    SUBMIT_USER_STORY_DEPLOY_CHANGES,
    SUBMIT_USER_STORY_SKIP_CONTINUOUS_DELIVERY,
    USER_STORY_CAN_NOT_BE_SUBMITTED,
    USER_STORY_COULD_NOT_BE_SUBMITTED,
    USER_STORY_SUCCESSFULLY_SUBMITTED,

    SUBMIT_BEHAVIOUR_MANUALLY,
    SUBMIT_BEHAVIOUR_IMMEDIATELY,
    SUBMIT_BEHAVIOUR_SCHEDULED_BY_THE_AUTOMATION,
    SUBMIT_BEHAVIOUR_SCHEDULED_DATE_TIME
};

export const schema = {
    READYTOPROMOTE,
    PROMOTEANDDEPLOY,
    AUTOMATION_EXECUTION_FIELD
};

export const constants = {
    AUTOMATION_EXECUTION_SCHEDULED: 'Scheduled',
    AUTOMATION_EXECUTION_IMMEDIATE: 'Immediate'
};
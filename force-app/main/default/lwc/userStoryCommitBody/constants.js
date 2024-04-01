import LOADING from '@salesforce/label/c.LOADING';
import GitOperations from '@salesforce/label/c.GitOperations';
import TypeCommitMessage from '@salesforce/label/c.TypeCommitMessage';
import Commit_Message from '@salesforce/label/c.Commit_Message';
import ReCreateFeatureBranch from '@salesforce/label/c.ReCreateFeatureBranch';
import ChangeBaseBranch from '@salesforce/label/c.ChangeBaseBranch';
import Enabled from '@salesforce/label/c.Enabled';
import Disabled from '@salesforce/label/c.Disabled';
import Yes from '@salesforce/label/c.YES';
import No from '@salesforce/label/c.NO';
import SelectBaseBranch from '@salesforce/label/c.SelectBaseBranch';
import SearchBranches from '@salesforce/label/c.SearchBranches';
import ReCreateFeatureHelpText from '@salesforce/label/c.ReCreate_Feature_Helptext';
import SelectBranchHelpText from '@salesforce/label/c.Select_Base_Branch_Helptext';

import NAME from '@salesforce/schema/User_Story__c.Name';
import TITLE from '@salesforce/schema/User_Story__c.User_Story_Title__c';

export const label = {
    LOADING,
    GitOperations,
    TypeCommitMessage,
    Commit_Message,
    ReCreateFeatureBranch,
    ChangeBaseBranch,
    Enabled,
    Disabled,
    Yes,
    No,
    SelectBaseBranch,
    SearchBranches,
    ReCreateFeatureHelpText,
    SelectBranchHelpText
};

export const schema = {
    NAME,
    TITLE
};
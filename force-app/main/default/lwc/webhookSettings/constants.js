import New from '@salesforce/label/c.NEW';
import Edit from '@salesforce/label/c.EDIT';
import Items from '@salesforce/label/c.Items';
import Delete from '@salesforce/label/c.DELETE';
import ApiKey from '@salesforce/label/c.API_KEY';
import CopyKey from '@salesforce/label/c.CopyKey';
import Expired from '@salesforce/label/c.Expired';
import Actions from '@salesforce/label/c.Actions';
import Username from '@salesforce/label/c.USERNAME';
import ExpiresOn from '@salesforce/label/c.ExpiresOn';
import Key_Expired from '@salesforce/label/c.Key_Expired';
import ActionApiKeys from '@salesforce/label/c.WebhooksKeys';
import Using_Api_Keys from '@salesforce/label/c.Using_Api_Keys';
import User_Api_Key_Changed from '@salesforce/label/c.User_Api_Key_Changed';
import Extend_Action_Api_Key from '@salesforce/label/c.Extend_Action_Api_Key';
import Actions_Api_Help_Text from '@salesforce/label/c.Actions_Api_Help_Text';
import Expired_Actions_Api_Key from '@salesforce/label/c.Expired_Actions_Api_Key';
import Regenerate_Action_Api_Key from '@salesforce/label/c.Regenerate_Action_Api_Key';
import Loading from '@salesforce/label/c.LOADING';

const actionsDocsLink = 'https://docs.copado.com/articles/#!copado-ci-cd-publication/copado-actions-api';
const actionsApiaryLink = 'https://copadomulticoudwebhooks.docs.apiary.io/#introduction/copado-multicloud-actions-api.-automated-actions-in-copado-multi-cloud-platform';

const Actions_Api_Help_Text_Body = Actions_Api_Help_Text.replaceAll('{0}', actionsDocsLink)
    .replaceAll('{1}', actionsApiaryLink);

export const columns = [
    { label: ApiKey, fieldName: 'key', searchable: true },
    { label: Actions, fieldName: 'actions', sortable: true, searchable: true },
    { label: Username, fieldName: 'username', sortable: true, searchable: true },
    { label: ExpiresOn, fieldName: 'formattedEndDate', searchable: true },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: Edit, name: 'edit' },
                { label: Delete, name: 'delete' },
                { label: CopyKey, name: 'copy' }
            ]
        }
    }
];

export const labels = {
    New,
    Items,
    Expired,
    Key_Expired,
    ActionApiKeys,
    Using_Api_Keys,
    User_Api_Key_Changed,
    Extend_Action_Api_Key,
    Expired_Actions_Api_Key,
    Regenerate_Action_Api_Key,
    Actions_Api_Help_Text_Body,
    Loading
};
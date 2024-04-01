import LightningDatatable from 'lightning/datatable';
import { loadStyle } from 'lightning/platformResourceLoader';
import USER_STORY_COMMIT_TABLE_RESOURCES from '@salesforce/resourceUrl/UserStoryCommitTableResources';

import operation from './operation.html';

export default class UserStoryCommitTable extends LightningDatatable {
    static customTypes = {
        operation: {
            template: operation,
            typeAttributes: ['rowId', 'options', 'readOnlyMode', 'selectedCount']
        }
    };

    renderedCallback() {
        super.renderedCallback();
        loadStyle(this, USER_STORY_COMMIT_TABLE_RESOURCES + '/css/style.css');
    }
}
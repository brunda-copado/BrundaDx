import Message_when_too_short from '@salesforce/label/c.Message_when_too_short';
import NEW from '@salesforce/label/c.NEW';
import Related_List_Error from '@salesforce/label/c.Related_List_Error';
import Search from '@salesforce/label/c.Search';
import Search_this_list from '@salesforce/label/c.Search_this_list';
import View_All from '@salesforce/label/c.View_All';

export const label = {
    Message_when_too_short,
    NEW,
    Related_List_Error,
    Search,
    Search_this_list,
    View_All
};

export const actions = [
    { label: 'View', name: 'view' },
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];
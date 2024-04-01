import LightningDatatable from 'lightning/datatable';
import icon from './icon.html';

export default class TestsTable extends LightningDatatable {
    static customTypes = {
        icon: {
            template: icon,
            typeAttributes: ['message'],
            standardCellLayout: true
        }
    };
}
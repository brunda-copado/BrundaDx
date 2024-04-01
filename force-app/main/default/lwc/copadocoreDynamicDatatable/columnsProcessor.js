export default class ColumnsProcessor {
    columns;
    actions;
    implementsDragAndDrop;

    constructor(columns, actions, implementsDragAndDrop) {
        this.columns = columns;
        this.actions = actions;
        this.implementsDragAndDrop = implementsDragAndDrop;
    }

    execute() {
        if (this.columns && this.columns.length > 0) {
            this._setActionsColumn();
            this._setDragAndDropColumn();
        }
        return this.columns;
    }

    _setActionsColumn() {
        if (this.actions && this.actions.length > 0) {
            this.columns = [
                ...this.columns,
                {
                    type: 'action',
                    fixedWidth: 62,
                    typeAttributes: { rowActions: this.actions }
                }
            ];
        }
    }

    _setDragAndDropColumn() {
        if (this.implementsDragAndDrop) {
            this.columns = [
                ...this.columns,
                {
                    hideDefaultActions: true,
                    fixedWidth: 62,
                    cellAttributes: { iconName: 'utility:drag_and_drop', iconAlternativeText: 'Drag and Drop' }
                }
            ];
        }
    }
}
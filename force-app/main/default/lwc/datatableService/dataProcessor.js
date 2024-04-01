/* eslint-disable guard-for-in */
export default class DataProcessor {
    data;

    constructor(data) {
        this.data = data;
    }

    execute() {
        return this._processData(this.data);
    }

    // PRIVATE

    _processData(records, path, ancestor) {
        const result = [];
        records.forEach((row) => {
            const record = JSON.parse(JSON.stringify(row));
            record.LinkName = '/' + record.Id;
            for (const propertyName in record) {
                const propertyValue = record[propertyName];
                if (typeof propertyValue === 'object') {
                    const newValue = propertyValue.Id ? '/' + propertyValue.Id : null;
                    this._flattenStructure(record, propertyName + '.', propertyValue);
                    if (newValue !== null) {
                        record[propertyName + '.LinkName'] = newValue;
                        const currentPath = path ? path + propertyName + '.' : propertyName + '.';
                        if (ancestor) {
                            ancestor[currentPath + 'LinkName'] = newValue;
                        }
                        this._processData([propertyValue], currentPath, record);
                    }
                }
            }
            result.push(record);
        });
        return result;
    }

    _flattenStructure(topObject, prefix, toBeFlattened) {
        for (const propertyName in toBeFlattened) {
            const propertyValue = toBeFlattened[propertyName];
            if (typeof propertyValue === 'object') {
                this._flattenStructure(topObject, prefix + propertyName + '.', propertyValue);
            } else {
                topObject[prefix + propertyName] = propertyValue;
            }
        }
    }
}
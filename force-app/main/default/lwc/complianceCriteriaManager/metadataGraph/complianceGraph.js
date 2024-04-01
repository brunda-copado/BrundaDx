export default class ComplianceGraph {
    constructor(baseGraph) {
        this._graph = baseGraph;
    }

    getMetadataTypeOptions() {
        let result = this._graph.getRootNodes().map((rootNode) => {
            return { label: rootNode.name, value: rootNode.name };
        });

        return this._sortComboboxList(result);
    }

    getNodeList(metadataType) {
        let result = [];

        if (metadataType) {
            result = this._graph.getRootEdges(metadataType).map((edge) => {
                return { label: edge.label, value: edge.label };
            });
            result = this._sortComboboxList(result);
        }

        return result;
    }

    getFieldList(node) {
        let result = this._graph.getLeafEdges(node).map((edge) => {
            return { label: edge.label, value: edge.label };
        });
        return this._sortComboboxList(result);
    }

    getValueType(node, field) {
        return this._graph.getEdge(field, node)[0].target.name.toUpperCase();
    }

    _sortComboboxList(list) {
        return list.sort((x, y) => x.label.localeCompare(y.label));
    }
}
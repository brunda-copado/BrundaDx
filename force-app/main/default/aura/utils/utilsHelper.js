({
    callApex : function(component, methodName, params) {
        return new Promise((resolve, reject) => {
            const action = component.get(methodName);
            if (params) {
                action.setParams(params);
            }
            action.setCallback(self, (response) => {
                const state = response.getState();
                switch (state) {
                    case 'SUCCESS':
                        resolve(response.getReturnValue());
                        break;
                    case 'ERROR':
                        reject(response.getError());
                        break;
                    default:
                }
            });
            $A.enqueueAction(action);
        })
    }
})
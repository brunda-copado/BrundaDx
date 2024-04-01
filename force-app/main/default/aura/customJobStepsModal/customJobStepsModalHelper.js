({
    init: function (component) {
        const getNamespace = component.get('c.getNamespace');

        getNamespace.setCallback(this, function (response) {
            const state = response.getState();

            if (state === 'SUCCESS') {
                const namespace = response.getReturnValue();
                component.set('v.namespace', namespace);
                this.initStep(component);
            } else if (state === 'ERROR') {
                this.showErrors(component, response.getError(), $A.get('$Label.c.Error_Retrieving_Namespace'));
            }
        });

        $A.enqueueAction(getNamespace);
    },

    initStep: function (component) {
        const recordId = component.get('v.recordId');
        const namespace = component.get('v.namespace');

        if (recordId) {
            const getStep = component.get('c.getStep');

            getStep.setParams({ stepId: component.get('v.recordId') });
            getStep.setCallback(this, function (response) {
                const state = response.getState();
                let configJson = {};
                if (state === 'SUCCESS') {
                    const step = response.getReturnValue();
                    configJson = step[namespace + 'ConfigJson__c'] ? JSON.parse(step[namespace + 'ConfigJson__c']) : {};
                    component.set('v.step', step);
                    component.set('v.stepName', step.Name);
                    component.set('v.stepType', step[namespace + 'Type__c']);
                    component.set(
                        'v.stepCustomType',
                        this.customType(step[namespace + 'CustomType__c']) || this.customType(step[namespace + 'Type__c'])
                    );
                    component.set('v.configJson', configJson);
                    component.set('v.resultViewerComponent', step[namespace + 'Result_Viewer_Component__c']);
                    component.set('v.resourceObservations', step[namespace + 'Resource_Observations__c']);
                    component.set('v.executionSequence', step[namespace + 'ExecutionSequence__c']);
                    component.set('v.sharedResource', configJson.sharedResource);
                    component.set('v.skipCondition', step[namespace + 'SkipCondition__c']);
                    if (step[namespace + 'UserStory__c'] && !component.get('v.parentApiName')) {
                        component.set('v.parentId', step[namespace + 'UserStory__c']);
                        component.set('v.parentApiName', namespace + 'User_Story__c');
                    }
                } else if (state === 'ERROR') {
                    this.showErrors(component, response.getError(), $A.get('$Label.c.Error_Retrieving_Step'));
                }
                this.initTypeOptions(component);
            });

            $A.enqueueAction(getStep);

            component.set('v.modalTitle', $A.get('$Label.c.Edit_Step'));
        } else {
            this.initTypeOptions(component);
            component.set('v.modalTitle', $A.get('$Label.c.Add_New_Step'));
        }
    },

    initObservationOptions: function (component) {
        const getObservationOptions = component.get('c.getObservationOptions');

        getObservationOptions.setCallback(this, function (response) {
            const state = response.getState();

            if (state === 'SUCCESS') {
                let options = [];
                const result = response.getReturnValue();

                result.forEach(option => {
                    options.push({ label: option.label, value: option.value });
                });

                component.set('v.observationOptions', options);
            } else if (state === 'ERROR') {
                this.showErrors(component, response.getError(), $A.get('$Label.c.Error_Loading_Step_Options'));
            }
        });

        $A.enqueueAction(getObservationOptions);
    },

    initRunValidationDeploymentCheckbox: function (component) {
        const validationEnabled = component.get('c.validationEnabled');
        validationEnabled.setParams({ recordId: component.get('v.parentId') });
        validationEnabled.setCallback(this, function (response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                const result = response.getReturnValue();
                component.set('v.showValidationCheckbox', result);
                if (result) {
                    const configJson = component.get('v.configJson');

                    component.set('v.runOnValidationDeployment', configJson && configJson.runOnValidationDeployment);
                }
            } else if (state === 'ERROR') {
                this.showErrors(component, response.getError(), $A.get('$Label.c.Error_Loading_Step_Options'));
            }
        });

        $A.enqueueAction(validationEnabled);
    },

    initSequenceOptions: function (component) {
        const getSequenceOptions = component.get('c.getSequenceOptions');

        getSequenceOptions.setCallback(this, function (response) {
            const state = response.getState();

            if (state === 'SUCCESS') {
                let options = [];
                const result = response.getReturnValue();

                result.forEach(option => {
                    options.push({ label: option.label, value: option.value });
                });

                component.set('v.sequenceOptions', options);
            } else if (state === 'ERROR') {
                this.showErrors(component, response.getError(), $A.get('$Label.c.Error_Loading_Step_Options'));
            }
        });

        $A.enqueueAction(getSequenceOptions);
    },

    initTypeOptions: function (component) {
        const getTypeOptions = component.get('c.getTypeOptions');

        getTypeOptions.setCallback(this, function (response) {
            const state = response.getState();

            if (state === 'SUCCESS') {
                let options = [];
                let componentsByType = new Map();
                const result = response.getReturnValue();

                result.forEach(option => {
                    options.push({ label: option.label, value: option.type });
                    componentsByType.set(option.type, option.component);
                });

                component.set('v.typeOptions', options);
                component.set('v.componentsByType', componentsByType);

                let type = component.get('v.stepCustomType');
                if (type) {
                    this.switchView(component);
                }

                const namespace = component.get('v.namespace');
                const parent = component.get('v.parentApiName');

                this.toggleResourceObservations(component, type);

                if (parent === namespace + 'User_Story__c') {
                    component.set('v.showSequence', true);
                    this.initSequenceOptions(component);
                    this.initRunValidationDeploymentCheckbox(component);
                }

                component.set('v.loading', false);
            } else if (state === 'ERROR') {
                this.showErrors(component, response.getError(), $A.get('$Label.c.Error_Loading_Step_Options'));
            }
        });

        $A.enqueueAction(getTypeOptions);
    },

    toggleResourceObservations: function (component, type) {
        let showObservations = true;
        let disableObservations = false;

        if (!component.get('v.observationOptions')) {
            this.initObservationOptions(component);
        }

        const recordId = component.get('v.recordId');
        const namespace = component.get('v.namespace');
        const parentApiName = component.get('v.parentApiName');
        if (recordId) {
            const step = component.get('v.step');
            component.set('v.resourceObservations', step[namespace + 'Resource_Observations__c']);

            if (step[namespace + 'UserStory__c']) {
                showObservations = false;
            } else if (step[namespace + 'JobExecution__c']) {
                disableObservations = true;
            }
        } else if (parentApiName === namespace + 'User_Story__c') {
            showObservations = false;
        } else if (parentApiName === namespace + 'JobExecution__c') {
            disableObservations = true;
        }

        component.set('v.showObservations', showObservations);
        component.set('v.disableObservations', disableObservations);
    },

    switchView: function (component) {
        component.set('v.loading', true);

        const type = component.get('v.stepCustomType');
        const componentsByType = component.get('v.componentsByType');
        const selectedComponent = componentsByType.get(type);

        this.toggleResourceObservations(component, type);

        if (selectedComponent) {
            $A.createComponent(selectedComponent, this.lwcConfig(component), (stepComponent, status, errorMessage) => {
                if (status === 'SUCCESS') {
                    component.set('v.componentBody', stepComponent);
                } else if (status === 'ERROR') {
                    console.error('Error', errorMessage.toString());
                    component.set('v.componentBody', undefined);
                }

                component.set('v.loading', false);
            });
        }
    },

    lwcConfig: function (component) {
        const behavior = this.behavior(component.get('v.stepCustomType'));

        return {
            isReadOnly: component.get('v.readOnly'),
            recordId: component.get('v.recordId'),
            configJson: component.get('v.configJson') ? JSON.stringify(component.get('v.configJson')) : '',
            resultViewerComponent: component.get('v.resultViewerComponent'),
            canAddParameters: behavior === 'Flow',
            editParameterValuesOnly: behavior === 'Function'
        };
    },

    saveStep: function (component, childComponent) {
        component.set('v.loading', true);
        const saveStep = component.get('c.saveStep');

        saveStep.setParams({ record: this.step(component, childComponent) });

        saveStep.setCallback(this, function (response) {
            const state = response.getState();

            if (state === 'SUCCESS') {
                this.showToast($A.get('$Label.c.SUCCESS'), 'success', $A.get('$Label.c.Step_Saved'));
                this.backToRecord(component);
            } else if (state === 'ERROR') {
                this.showErrors(component, response.getError(), $A.get('$Label.c.Error_Saving_Step'));
            }
            component.set('v.loading', false);
        });

        $A.enqueueAction(saveStep);
    },

    step: function (component, childComponent) {
        const recordId = component.get('v.recordId');
        const namespace = component.get('v.namespace');
        const stepType = this.getStepType(component, childComponent);
        const configJson = this.getConfigJson(component, childComponent);
        const resultViewerCmp = this.getResultViewerCmp(component, childComponent);
        configJson.sharedResource = component.get('v.sharedResource');
        configJson.runOnValidationDeployment = component.get('v.runOnValidationDeployment');

        let result = {
            Id: recordId,
            Name: component.get('v.stepName'),
            [namespace + 'ConfigJson__c']: JSON.stringify(configJson),
            [namespace + 'Result_Viewer_Component__c']: resultViewerCmp,
            [namespace + 'Type__c']: stepType,
            [namespace + 'CustomType__c']: component.get('v.stepCustomType'),
            [namespace + 'Resource_Observations__c']: component.get('v.resourceObservations'),
            [namespace + 'ExecutionSequence__c']: component.get('v.executionSequence'),
            [namespace + 'SkipCondition__c']: component.get('v.skipCondition')
        };

        if (!recordId) {
            const parent = component.get('v.parentApiName');
            const lookupField = this.lookupFieldFor(namespace, parent);
            result[lookupField] = component.get('v.parentId');
        }

        return result;
    },

    customType: function (behavior) {
        let result = '';

        if (behavior === 'Flow') {
            result = 'Salesforce Flow';
        } else if (behavior === 'Manual') {
            result = 'Manual Task';
        } else {
            result = behavior;
        }

        return result;
    },

    behavior: function (customType) {
        let result = '';

        if (customType === 'Salesforce Flow') {
            result = 'Flow';
        } else if (customType === 'Manual Task') {
            result = 'Manual';
        } else {
            result = customType;
        }

        return result;
    },

    lookupFieldFor: function (namespace, objectApiName) {
        const lookupFieldByObjectName = {
            [namespace + 'User_Story__c']: namespace + 'UserStory__c'
        };

        return lookupFieldByObjectName[objectApiName] || objectApiName;
    },

    showErrors: function (component, errors, label) {
        let errorMessage;
        if (errors && errors[0] && errors[0].message) {
            errorMessage = label + errors[0].message;
        } else {
            errorMessage = label + $A.get('$Label.c.Unexpected_Error_Occurred');
        }
        component.set('v.errorMessage', errorMessage);
    },

    showToast: function (title, type, message) {
        $A.get('e.force:showToast').fire({ title, type, message });
    },

    isValidConfig: function (component, childComponent) {
        let result = null;

        const dynamicExp = new RegExp(
            "\\{\\$?([a-zA-Z_][a-zA-Z0-9_]*)\\.?([a-zA-Z0-9_-]+\\.)*([a-zA-Z_][a-zA-Z0-9_]*)(\\.[a-zA-Z_][a-zA-Z0-9_]*)?(\\.(matches)\\s*\\(\\s*('|\")?[^']*('|\")?\\s*\\))?\\s*\\}",
            'i'
        );
        const matchesSubStr = new RegExp("(\\.(matches)\\s*\\(\\s*('|\")?[^']*('|\")?\\s*\\))\\s*\\}", 'i');

        const stepType = this.getStepType(component, childComponent);
        const config = this.getConfigJson(component, childComponent);
        const customType = component.get('v.stepCustomType');
        const name = component.find('step-name').get('v.value');
        const skipCondition = component.get('v.skipCondition');
        const skipConditionField = component.find('skip-condition');

        const childFormValid = childComponent.getAutoFormValidation ? childComponent.getAutoFormValidation() : true;

        if (childFormValid) {
            if (stepType === 'Function' && !config.functionName) {
                result = $A.get('$Label.c.RequiredFieldMissing') + ' ' + $A.get('$Label.c.Function') + ' ' + $A.get('$Label.c.NAME');
            } else if (stepType === 'Flow' && !config.flowName) {
                result = $A.get('$Label.c.RequiredFieldMissing') + ' ' + $A.get('$Label.c.Flow') + ' ' + $A.get('$Label.c.NAME');
            } /*else if(stepType === "Manual" && !this.hasOwner(config)) {
                result = $A.get("$Label.c.RequiredFieldMissing") + " Manual Task Owner"; // TO BE IMPLEMENTED IN THE WINTER RELEASE
            }*/ else if (!(name && name.trim() && customType && this.executionSequence(component))) {
                result = $A.get('$Label.c.FILL_REQUIRED_FIELDS');
            } else if (skipCondition && skipCondition.trim()) {
                if (!this.hasSingleDynamicExpression(skipCondition)) {
                    skipConditionField.setCustomValidity($A.get('$Label.c.MoreThanAllowedError'));
                } else if (!dynamicExp.test(skipCondition)) {
                    skipConditionField.setCustomValidity($A.get('$Label.c.InvalidSkipCondition'));
                } else if (skipCondition.toLowerCase().indexOf('.apex') === -1 && !matchesSubStr.test(skipCondition)) {
                    skipConditionField.setCustomValidity($A.get('$Label.c.MissingMatchesInExp'));
                } else {
                    skipConditionField.setCustomValidity('');
                }
            }

            if (result) {
                this.showToast($A.get('$Label.c.ERROR'), 'error', result);
            }
        }

        return !result && childFormValid && skipConditionField.reportValidity();
    },

    executionSequence: function (component) {
        let valid = true;
        const namespace = component.get('v.namespace');
        const parent = component.get('v.parentApiName');

        if (parent === namespace + 'User_Story__c') {
            const executionSequence = component.get('v.executionSequence');
            if (!executionSequence) {
                valid = false;
            }
        }

        return valid;
    },

    hasSingleDynamicExpression: function (skipCondition) {
        const expressions = skipCondition.split('}').filter(Boolean);
        return expressions.length === 1;
    },

    hasOwner: function (config) {
        const parameters = config.parameters || [];

        return parameters.some(parameter => parameter.name === 'ownerId' && parameter.value);
    },

    backToRecord: function (component) {
        if (this.isStepContext(component)) {
            $A.get('e.force:refreshView').fire();
            this.navigateToRecord(component);
            this.delayedRefresh();
        } else {
            $A.get('e.force:refreshView').fire();
            this.delayedRefresh();
            component.getEvent('closeModal').fire();
        }
    },

    navigateToRecord: function (component) {
        const navigation = component.find('navService');
        const pageRef = this.pageReference(component);

        navigation.navigate(pageRef, true);
    },

    delayedRefresh: function () {
        window.setTimeout(
            $A.getCallback(function () {
                $A.get('e.force:refreshView').fire();
            }),
            500
        );
    },

    isStepContext: function (component) {
        const context = this.context(component);
        const recordId = component.get('v.recordId');

        return context.Id === recordId;
    },

    context: function (component) {
        const context = this.pageReference(component);

        return {
            objectApiName: context ? context.attributes.objectApiName : '',
            Id: context ? context.attributes.recordId : ''
        };
    },

    pageReference: function (component) {
        const pageRef = component.get('v.pageReference');
        const state = pageRef ? pageRef.state : undefined;
        let base64Context = state ? state.inContextOfRef : undefined;

        if (base64Context && base64Context.startsWith('1.')) {
            base64Context = base64Context.substring(2);
        }

        return base64Context ? JSON.parse(window.atob(base64Context)) : undefined;
    },

    getStepType: function (component, childComponent) {
        return this.getConfig(childComponent).type || component.get('v.stepType');
    },

    getResultViewerCmp: function (component, childComponent) {
        return this.getConfig(childComponent).resultViewerCmp;
    },

    getConfigJson: function (component, childComponent) {
        return this.getConfig(childComponent).configJson || component.get('v.configJson');
    },

    getConfig: function (childComponent) {
        return childComponent.getConfig ? childComponent.getConfig() : {};
    }
});
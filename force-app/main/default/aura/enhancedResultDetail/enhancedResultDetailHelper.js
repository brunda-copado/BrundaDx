({
    intervalId: null,
    resultViewerHasContent: false,
    dynamicUISectionHasContent: false,
    namespace: null,

    init: function (component) {
        component.set('v.loading', true);

        if (!component.get('v.recordId')) {
            component.set('v.loading', false);
            this.showErrors(component, null, $A.get('$Label.c.NO_DATA_TO_DISPLAY'));
            return;
        }
        this.intervalId = setInterval($A.getCallback(() => this.getResultDetails(component)), 5000);
        return this.getResultDetails(component);
    },

    getResultDetails: function (component) {
        return new Promise(resolve => {
            const getDetails = component.get('c.getDetails');

            getDetails.setParams({ recordId: component.get('v.recordId') });

            getDetails.setCallback(this, (response) => {
                if (response.getState() === 'SUCCESS') {
                    const details = response.getReturnValue();
                    this.namespace = details.namespace;

                    if (!details.resultDetails) {
                        component.set('v.loading', false);
                        return;
                    }
                    const jobStepName = this.setResultInfo(component, details);
                    resolve(jobStepName);
                } else {
                    component.set('v.loading', false);
                    this.showErrors(component, response.getError(), $A.get('$Label.c.Error_Searching_Records'));
                }
            });

            $A.enqueueAction(getDetails);
        })
    },

    setResultInfo: function (component, details) {
        const result = details.resultDetails;
        const isConsolidated = component.get('v.isConsolidatedResult');
        const parentStep = this.getValue(result, 'JobStep__r.JobExecution__r.Job_Step__r');
        const resultStatus = this.getValue(result, 'Status__c');
        const jobStepName = (parentStep && isConsolidated) ? parentStep.Name : this.getValue(result, 'JobStep__r').Name;

        component.set('v.resultStatus', resultStatus);
        component.set('v.resultUrl', '/' + component.get('v.recordId'));
        component.set('v.viewResultLabel', $A.get('$Label.c.Result') + ' ' + $A.get('$Label.c.Record') + ' - ' + result.Name);

        component.set('v.progressStatus', this.getValue(result, 'Progress_Status__c'));
        component.set('v.resultExternalLink', this.getValue(result, 'Link__c'));
        component.set('v.resultErrorMessage', this.getValue(result, 'Error_Message__c'));
        component.set('v.resultErrorCode', this.getValue(result, 'Error_Code__c'));

        component.set('v.bannerClass', this.getBannerClass(resultStatus));
        component.set('v.iconName', this.getIconName(resultStatus));
        component.set('v.iconClass', resultStatus === 'In Progress' ? '' : 'icon');
        component.set('v.showErrorFields', resultStatus === 'Failed' || resultStatus === 'Cancelled');
        component.set('v.hasSubJob', isConsolidated);

        if (isConsolidated) {
            component.set('v.columns', this.columns());
            this.setSubJobSteps(component, details);
        } else {
            component.set('v.loading', false);
            component.set('v.subJobSteps', []);
            component.set('v.stepCount', 0);
            component.set('v.stepsTabHeader', `${$A.get('$Label.c.AllStepsInExecution')} (0)`);
        }

        if (resultStatus === 'Success' || resultStatus === 'Failed' || resultStatus === 'Cancelled') {
            clearInterval(this.intervalId);
            component.set('v.imageName', 'no_data:desert');
            component.set('v.illustrationTitle', $A.get('$Label.c.FinalStatusIllustrationTitle'));
            component.set('v.illustrationBody', $A.get('$Label.c.FinalStatusIllustrationBody'));
        }

        return jobStepName;
    },

    setSubJobSteps: function (component, details) {
        const steps = details.subJobExecutionSteps;

        if (!steps) {
            component.set('v.loading', false);
            component.set('v.subJobSteps', []);
            component.set('v.stepCount', 0);
            component.set('v.stepsTabHeader', `${$A.get('$Label.c.AllStepsInExecution')} (0)`);
            return;
        }

        const records = steps.map(step => {
            return {
                stepName: step.Name,
                stepUrl: '/' + step.Id,
                resultName: this.getValue(step, 'Result__c') ? this.getValue(step, 'Result__r').Name : '',
                resultUrl: this.getValue(step, 'Result__c') ? '/' + this.getValue(step, 'Result__c') : '',
                status: this.getValue(step, 'Result__c') ? this.getValue(step, 'Result__r.Status__c') : '',
                errorMessage: this.getValue(step, 'Result__c') ? this.getValue(step, 'Result__r.Error_Message__c') : ''
            };
        });

        component.set('v.subJobSteps', records);
        component.set('v.stepCount', records.length);
        component.set('v.stepsTabHeader', $A.get('$Label.c.AllStepsInExecution') + ' (' + records.length + ')');
        component.set('v.loading', false);
    },

    close: function (component) {
        component.set('v.recordId', null);
        component.set('v.showResultModal', false);
        component.set('v.hasSubJob', false);
        component.set('v.hasExecutionOutcome', false);
        component.set('v.errorMessage', null);
        clearInterval(this.intervalId);
    },

    handleRecordIdChange: function (component, event) {
        const newRecordId = event.getParam('value');
        if (newRecordId) {
            component.set('v.recordId', newRecordId);
        }
    },

    getValue: function (record, field) {
        let result = record;

        for (let key of field.split('.')) {
            if (result && result !== null) {
                result = result[this.namespace + key];
            } else {
                return null;
            }
        }

        return result;
    },

    columns: function () {
        return [
            {
                label: $A.get('$Label.c.JobStep'), fieldName: 'stepUrl', type: 'url', hideDefaultActions: true, typeAttributes: {
                    label: { fieldName: 'stepName' },
                    target: '_blank'
                }, sortable: 'true', initialWidth: 200
            },
            {
                label: $A.get('$Label.c.Result'), fieldName: 'resultUrl', type: 'url', hideDefaultActions: true, typeAttributes: {
                    label: { fieldName: 'resultName' },
                    target: '_blank', initialWidth: 90
                }
            },
            { label: $A.get('$Label.c.STATUS'), fieldName: 'status', type: 'text', hideDefaultActions: true, initialWidth: 90 },
            { label: $A.get('$Label.c.ERROR') + ' ' + $A.get('$Label.c.MESSAGE'), fieldName: 'errorMessage', type: 'text', hideDefaultActions: true, wrapText: true, initialWidth: 300 }
        ];
    },

    getBannerClass: function (resultStatus) {
        const baseClass = 'slds-scoped-notification slds-media slds-media_center';

        const bannerClassByStatus = {
            Success: `${baseClass} slds-theme_success`,
            Failed: `${baseClass} slds-theme_error`,
            Cancelled: `${baseClass} slds-scoped-notification_dark`,
            'In Progress': `${baseClass} slds-scoped-notification_light`
        };

        return bannerClassByStatus[resultStatus] || baseClass;
    },

    getIconName: function (resultStatus) {
        const iconByStatus = {
            Success: 'utility:success',
            Failed: 'utility:error',
            Cancelled: 'utility:ban',
            'In Progress': 'utility:info'
        };

        return iconByStatus[resultStatus];
    },

    handleSort: function (component) {
        const sortBy = 'stepName';
        const sortDirection = component.get('v.sortDirection') == 'asc' ? 'desc' : 'asc'

        component.set('v.sortedBy', sortBy);
        component.set('v.sortDirection', sortDirection);

        this.sortData(component, sortBy, sortDirection);
    },

    sortData: function (component, fieldName, sortDirection) {
        const data = component.get('v.subJobSteps');
        const key = function (a) { return a[fieldName]; }
        const reverse = sortDirection == 'asc' ? 1 : -1;

        data.sort((a, b) => {
            a = key(a) || '';
            b = key(b) || '';
            return reverse * ((a > b) - (b > a));
        });
        component.set('v.subJobSteps', data);
    },

    showErrors: function (component, errors, label) {
        let errorMessage;
        if (errors && errors[0] && errors[0].message) {
            errorMessage = label + errors[0].message;
        } else {
            errorMessage = label;
        }
        component.set('v.errorMessage', errorMessage);
    },

    showContent: function (component) {
        if (this.resultViewerHasContent || this.dynamicUISectionHasContent) {
            component.set('v.hasExecutionOutcome', true);
        }
    }
});
import { schema } from './constants';

export const createStageOptions = stagesById => {
    let result = [];
    for (const [id, stage] of Object.entries(stagesById)) {
        result.push({ label: stage.stage[schema.STAGE_DISPLAY_NAME.fieldApiName], value: id });
    }
    return result;
};

export const createEnvironmentOptions = (environmentsById, stageName) => {
    let result = [];
    for (const [id, environment] of Object.entries(environmentsById)) {
        let environmentLabel = environment.Name;
        if (stageName) {
            environmentLabel += ' (' + stageName + ')';
        }
        result.push({ label: environmentLabel, value: id });
    }
    return result;
};

export const createEnvironmentOptionsForStages = (selectedStageOptions, stagesById) => {
    let environmentOptionsForStages = [];
    selectedStageOptions.forEach(stageId => {
        const stage = stagesById[stageId];
        if (stage) {
            environmentOptionsForStages = [
                ...environmentOptionsForStages,
                ...createEnvironmentOptions(stage.environmentsById, stage.stage[schema.STAGE_DISPLAY_NAME.fieldApiName])
            ];
        }
    });
    return environmentOptionsForStages;
};

export const isTriggerValidationError = error => {
    let validationErrorMessage;
    if (
        error.body.output.errors &&
        error.body.output.errors.length &&
        error.body.output.errors[0].errorCode === 'FIELD_CUSTOM_VALIDATION_EXCEPTION'
    ) {
        validationErrorMessage = error.body.output.errors[0].message;
    }
    return validationErrorMessage;
};
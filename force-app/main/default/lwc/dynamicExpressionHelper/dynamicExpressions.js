import { label } from './labels';

const labels = label;

const fieldAPIOption = {
    label: labels.Field_API_Name,
    value: '',
    isFieldSelector: true,
    helpText: labels.FieldAPINameHelpText
};

const apexOption = {
    label: labels.APEX_CLASS,
    value: 'Apex',
    options: []
};

const systemPropertyOption = {
    label: labels.SystemProperty,
    value: 'Property',
    isFieldSelector: true,
    helpText: labels.SystemPropertyHelpText
};

export default {
    options: [
        {
            label: labels.Record,
            value: 'Context',
            options: [
                fieldAPIOption,
                {
                    label: 'Environment Field API Name',
                    value: 'Environment',
                    isFieldSelector: true,
                },
                {
                    label: labels.RepositoryCredential,
                    value: 'Repository.Credential'
                },
                {
                    label: labels.EnvironmentSessionId,
                    value: 'Credential.SessionId'
                },
                {
                    label: labels.EnvironmentEndpoint,
                    value: 'Credential.Endpoint'
                },
                {
                    label: labels.EnvironmentEndpointURL,
                    value: 'Credential.EndpointURL'
                },
                {
                    label: labels.BRANCH,
                    value: 'Branch'
                },
                apexOption,
                systemPropertyOption
            ]
        },
        {
            label: labels.SOURCE_ENVIRONMENT,
            value: 'Source',
            options: [
                fieldAPIOption,
                systemPropertyOption,
                {
                    label: labels.SessionId,
                    value: 'Credential.SessionId'
                },
                {
                    label: labels.Endpoint,
                    value: 'Credential.Endpoint'
                },
                {
                    label: labels.EndpointURL,
                    value: 'Credential.EndpointURL'
                },
                {
                    label: labels.BRANCH,
                    value: 'Branch'
                },
                apexOption
            ]
        },
        {
            label: labels.DESTINATION_ENVIRONMENT,
            value: 'Destination',
            options: [
                fieldAPIOption,
                systemPropertyOption,
                {
                    label: labels.SessionId,
                    value: 'Credential.SessionId'
                },
                {
                    label: labels.Endpoint,
                    value: 'Credential.Endpoint'
                },
                {
                    label: labels.EndpointURL,
                    value: 'Credential.EndpointURL'
                },
                {
                    label: labels.BRANCH,
                    value: 'Branch'
                },
                apexOption
            ]
        },
        {
            label: labels.DEPLOYMENT_FLOW,
            value: 'Pipeline',
            options: [fieldAPIOption, systemPropertyOption, apexOption]
        },
        {
            label: labels.Job,
            value: 'Job',
            options: [
                {
                    label: labels.Step,
                    value: 'Step',
                    isFieldSelector: true,
                    helpText: labels.StepHelpText
                },
                {
                    label: labels.ExecutionParent,
                    value: 'ExecutionParent',
                    isFieldSelector: true,
                    helpText: labels.ExecutionParentHelpText
                }
            ]
        },
        {
            label: labels.User,
            value: 'User',
            options: [fieldAPIOption, systemPropertyOption, apexOption]
        },
        {
            label: labels.Global,
            value: 'Global',
            options: [systemPropertyOption]
        },
        {
            label: labels.HierarchicalProperty,
            value: 'Property',
            isFieldSelector: true
        }
    ]
};
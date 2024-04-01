public with sharing class ValidateJobTemplateVolumeOption {
    private List<JobTemplate__c> records;

    // CONSTRUCTOR

    public ValidateJobTemplateVolumeOption(List<JobTemplate__c> records) {
        this.records = records;
    }

    // PUBLIC

    public void execute() {
        for(JobTemplate__c record : records) {
            try {
                validateVolumeOption(record);
            } catch (Exception ex) {
                record.addError(ex.getMessage());
            }
        }
    }


    // PRIVATE

    private void validateVolumeOption(JobTemplate__c record) {
        List<Parameter> volumeOptions = volumeOptions(record);
        Map<String, String> optionsByName = asMap(volumeOptions);
        Boolean volumeEnabled = optionsByName.containsKey('volumeEnabled') ?
                                    Boolean.ValueOf(optionsByName.get('volumeEnabled')) : false;

        if(volumeEnabled) {
            if((!optionsByName.containsKey('volumeTTL') || !optionsByName.containsKey('volumeSize'))) {
                record.addError(Label.MissingVolumeOptions);
            } else if(Integer.valueOf(optionsByName.get('volumeSize')) > Settings.maximumVolumeSize) {
                record.addError(String.format(Label.MaxVolumeSizeOptions, new List<String> { String.valueOf(Settings.maximumVolumeSize) }));
            } else if(Integer.valueOf(optionsByName.get('volumeTTL')) > Settings.MAX_VOLUME_TTL) {
                record.addError(String.format(Label.MaxVolumeTTLOptions, new List<String> { String.valueOf(Settings.MAX_VOLUME_TTL) }));
            } else if(Integer.valueOf(optionsByName.get('volumeTTL')) < Settings.MIN_VOLUME_TTL) {
                record.addError(String.format(Label.MinVolumeTTLOptions, new List<String> { String.valueOf(Settings.MIN_VOLUME_TTL) }));
            }
        }
    }

    private List<Parameter> volumeOptions(JobTemplate__c record) {
        List<Parameter> result = new List<Parameter>();

        if(String.isNotBlank(record.VolumeOptions__c)) {
            result = (List<Parameter>) JSON.deserialize(record.VolumeOptions__c, List<Parameter>.class);
        }

        return result;
    }


    private Map<String, String> asMap(List<Parameter> parameters) {
        Map<String, String> result = new Map<String, String>();

        for(Parameter parameter : parameters) {
            result.put(parameter.name, parameter.value);
        }

        return result;
    }
}
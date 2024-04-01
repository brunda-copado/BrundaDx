@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class GetConflictResolutionAttachments implements ParameterExpressionCallable {

    // GLOBAL 

    // Return a list of filenames that were already solved online, removing their prefixes
    // [{"fullname": "US-XXX force-app/main/default/classes/Demo1.cls", "attachmentId": "a1p1n000009XrOCAA0"}, ...]
    // contextId is the JobStep
    global String execute(Id contextId) {
        Id promotionId = [SELECT JobExecution__r.Promotion__c FROM JobStep__c WHERE Id = :contextId]?.JobExecution__r?.Promotion__c;
        List<ResolvedConflictFile> resolvedConflicts = new List<ResolvedConflictFile>();
        
        if(promotionId != null) {
            for (Attachment attachmentRecord : getResolvedAttachments(promotionId)) {
                ResolvedConflictFile record = new ResolvedConflictFile();
                record.attachmentId = attachmentRecord.Id;
                record.fullname = attachmentRecord.Name.replaceFirst('(AUTO )?RESOLVED ', '');
                resolvedConflicts.add(record);
            }
        }
        
        return JSON.serialize(resolvedConflicts);
    }


    // PRIVATE

    private List<Attachment> getResolvedAttachments(Id parentId) {
        return [
            SELECT Id, Name
            FROM Attachment
            WHERE ParentId = :parentId AND (Name LIKE 'AUTO RESOLVED%' OR Name LIKE 'RESOLVED%')
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate
            LIMIT 1000
        ];
    }


    // WRAPPER

    private class ResolvedConflictFile {
        Id attachmentId;
        String fullname;
    }
}
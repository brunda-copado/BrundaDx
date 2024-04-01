/**
 * Schedulable class to Execute CCD_BackPromotionBatch class for CCD back promotion
 *
 * @author Ümit Can Uçkan
 * @version 1.0
 * @since Copado v15
 */
public class CCD_BackPromotionSchedule implements Schedulable {
    String executerId;
    Integer batchSize;
    Set<Id> destEnvIds;
    Set<Id> sourceEnvIds;
    Boolean connectionBehaviorIsOnEnvironmentLevel;
    String scheduledConnectionBehaviorId;

    public CCD_BackPromotionSchedule(Integer batchSize) {
        executerId = UserInfo.getUserId();
        this.batchSize = batchSize;
    }

    public CCD_BackPromotionSchedule(Integer batchSize, Set<Id> sourceEnvIds, Set<Id> destEnvIds, Boolean connectionBehaviorIsOnEnvironmentLevel) {
        executerId = UserInfo.getUserId();
        this.batchSize = batchSize;
        this.sourceEnvIds = sourceEnvIds;
        this.destEnvIds = destEnvIds;
        this.connectionBehaviorIsOnEnvironmentLevel = connectionBehaviorIsOnEnvironmentLevel;
    }

    public CCD_BackPromotionSchedule(Integer batchSize, Set<Id> sourceEnvIds, Set<Id> destEnvIds, Boolean connectionBehaviorIsOnEnvironmentLevel, String scheduledConnectionBehaviorId) {
        executerId = UserInfo.getUserId();
        this.batchSize = batchSize;
        this.sourceEnvIds = sourceEnvIds;
        this.destEnvIds = destEnvIds;
        this.connectionBehaviorIsOnEnvironmentLevel = connectionBehaviorIsOnEnvironmentLevel;
        this.scheduledConnectionBehaviorId = scheduledConnectionBehaviorId;
    }

    public void execute(SchedulableContext sc) {
        Id ccd_BackPromotionScheduleId = Database.executeBatch(new CCD_BackPromotionBatch(this.executerId, sourceEnvIds, destEnvIds, connectionBehaviorIsOnEnvironmentLevel, scheduledConnectionBehaviorId), batchSize);
    }
}
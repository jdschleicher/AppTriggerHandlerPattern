
public with sharing class CaseTriggerHandler {

    public static Map<Id, String> getBeforeUpdateRecordTypeDeveloperNamesMap() {
        Map<Id, String> availableBeforeUpdateRecordTypeIdsByCasesMap= new Map<Id, String>();
        availableBeforeUpdateRecordTypeIdsByCasesMap.putAll(
            CaseRoundRobinService.getBeforeUpdateRoundRobinRecordTypeDeveloperNamesMap()
        );

        return availableBeforeUpdateRecordTypeIdsByCasesMap;
    }

    public static Map<Id, String> getAfterUpdateRecordTypeDeveloperNamesMap() {
        Map<Id, String> availableAfterUpdateRecordTypeIdsByCasesMap= new Map<Id, String>();
        availableAfterUpdateRecordTypeIdsByCasesMap.putAll(
            CaseRoundRobinService.getAfterUpdateRoundRobinRecordTypeDeveloperNamesMap()
        );

        return availableAfterUpdateRecordTypeIdsByCasesMap;
    }

    public static void applyBeforeUpdateStagingLogic(Case beforeUpdateCase) {
        CaseRoundRobinService.applyBeforeUpdateStagingLogicForhRoundRobinCases(beforeUpdateCase);
    }

    public static void postStagingDataRetrievalBeforeUpdate() {
        CaseRoundRobinService.postStagingDataRetrievalBeforeUpdateRoundRobin();
    }

    public static void applyBeforeUpdateLogic(Case beforeUpdateCase) {
        CaseRoundRobinService.applyBeforeUpdatehAndComplaintRoundRobinLogic(beforeUpdateCase);
    }

    public static void performDMLOperationsForBeforeUpdate() {
        CaseRoundRobinService.performhComplaintDMLOperationsForBeforeUpdate();
    }

    public static void applyAfterUpdateLogic(Map<Id, Case> oldCasesByIds, Case afterUpdateCase) {
        CaseRoundRobinService.applyAfterUpdateSLARecordTypeLogic(afterUpdateCase);
    }

    public static void performDMLOperationsForAfterUpdate() {
        CaseRoundRobinService.performAfterUpdateSlaTargetDateUpdate();
    }


}
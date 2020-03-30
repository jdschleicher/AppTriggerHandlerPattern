public with sharing class CaseTriggerHandler {

    public static Map<Id, List<Case>> beforeUpdateRecordTypeIdByCasesMap = new Map<Id, List<Case>>();
    public static Map<Id, List<Case>> afterUpdateRecordTypeIdByCasesMap = new Map<Id, List<Case>>();

    public CaseTriggerHandler() {
        getBeforeUpdateRecordTypeDeveloperNameMap(); // get record types that will be used for Before Update logic
        getAfterUpdateRecordTypeDeveloperNameMap();// get record types that will be used for After Update logic
    }

    // for every Case that should run into logic as part of the Before Update context,
    // add it's associated Record Type Developer Name to the below map
    public static Map<Id, String> availableBeforeUpdateRecordTypeIdsByCasesMap= new Map<Id, String>();
    private static void getBeforeUpdateRecordTypeDeveloperNameMap() {
        availableBeforeUpdateRecordTypeIdsByCasesMap.putAll(
            SpecicAppNameCaseTriggerHandler.getBeforeUpdateSpecicAppNameRecordTypeDeveloperNamesMap()
        );
    }

    // for every Case that should run into logic as part of the After Update context,
    // add it's associated Record Type Developer Name to the below map
    public static Map<Id, String> availableAfterUpdateRecordTypeDeveloperNames= new Map<Id, String>();
    private static void getAfterUpdateRecordTypeDeveloperNameMap() {
        availableAfterUpdateRecordTypeDeveloperNames.putAll(
            SpecicAppNameCaseTriggerHandler.getAfterUpdateSpecicAppNameRecordTypeDeveloperNamesMap()
        );
    }

    public void OnBeforeUpdate(List<Case> beforeUpdateCases, Map<Id, Case> oldCasesByIds) {
        buildBeforeUpdateRecordTypeDeveloperNameMap(beforeUpdateCases);
        if (beforeUpdateRecordTypeIdByCasesMap.size() > 0) {
            stageRelatedPropertiesForBeforeUpdate(beforeUpdateCases, oldCasesByIds);
            applyBeforeUpdateLogic(oldCasesByIds, beforeUpdateCases);
            performDMLOperationsForBeforeUpdate();
        }
    }

    private static void buildBeforeUpdateRecordTypeDeveloperNameMap(List<Case> beforeUpdateCases) {
        // This map will capture all Record Type Developer Names by Case and will be searchable to determine whether or not
//        // to run logic for Cases if they do not have populated RecordType map references

        for (Case beforeUpdateCase : beforeUpdateCases) {
            if (availableBeforeUpdateRecordTypeIdsByCasesMap.keySet().contains(beforeUpdateCase.RecordTypeId)) {
                if (beforeUpdateRecordTypeIdByCasesMap.containsKey(beforeUpdateCase.RecordTypeId)) {
                    beforeUpdateRecordTypeIdByCasesMap.get(beforeUpdateCase.RecordTypeId).add(beforeUpdateCase);
                } else {
                    List<Case> newCasesList = new List<Case>{beforeUpdateCase};
                    beforeUpdateRecordTypeIdByCasesMap.put(beforeUpdateCase.RecordTypeId, newCasesList);
                }
            }
        }
    }

    private static void stageRelatedPropertiesForBeforeUpdate(List<Case> beforeUpdateCases, Map<Id, Case> oldCasesByIds) {

        if (beforeUpdateRecordTypeIdByCasesMap.size() > 0) {

            for (Case beforeUpdateCase : beforeUpdateCases) {
                // Insert App TriggerHandler methods for specic Trigger Context
                SpecicAppNameCaseTriggerHandler.applyBeforeUpdateStagingLogic(beforeUpdateCase);
            }

            postStagingDataRetrievalBeforeUpdate();

        }

    }

    private static void postStagingDataRetrievalBeforeUpdate() {
        SpecicAppNameCaseTriggerHandler.postStagingDataRetrievalBeforeUpdate();
    }

    // oldCasesByIds is for future methods and record types that will leverage logic around old Cases
    private static void applyBeforeUpdateLogic(Map<Id, Case> oldCasesByIds, List<Case> beforeUpdateCases) {
        for (Case beforeUpdateCase : beforeUpdateCases) {
            SpecicAppNameCaseTriggerHandler.applyBeforeUpdateLogic(beforeUpdateCase);
        }
    }

    private static void performDMLOperationsForBeforeUpdate() {
        SpecicAppNameCaseTriggerHandler.performDMLOperationsForBeforeUpdate();
    }

    public void OnAfterUpdate(List<Case> afterUpdateCases, Map<Id, Case> oldCasesByIds) {
        buildAfterUpdateRecordTypeDeveloperNameMap(afterUpdateCases);
        if (afterUpdateRecordTypeIdByCasesMap.size() > 0) {
            stageRelatedPropertiesForAfterUpdate(afterUpdateCases, oldCasesByIds);
            applyAfterUpdateLogic(afterUpdateCases, oldCasesByIds);
            performDMLOperationsForAfterUpdate();
        }

    }

    private static void buildAfterUpdateRecordTypeDeveloperNameMap(List<Case> afterUpdateCases) {
        // This map will capture all Record Type Developer Names by Case and will be searchable to determine whether or not
//        // to run logic for Cases if they do not have populated RecordType map references

        for (Case afterUpdateCase : afterUpdateCases) {
            if (availableBeforeUpdateRecordTypeIdsByCasesMap.keySet().contains(afterUpdateCase.RecordTypeId)) {
                if (afterUpdateRecordTypeIdByCasesMap.containsKey(afterUpdateCase.RecordTypeId)) {
                    afterUpdateRecordTypeIdByCasesMap.get(afterUpdateCase.RecordTypeId).add(afterUpdateCase);
                } else {
                    List<Case> newCasesList = new List<Case>{afterUpdateCase};
                    afterUpdateRecordTypeIdByCasesMap.put(afterUpdateCase.RecordTypeId, newCasesList);
                }
            }
        }
    }

    private static void stageRelatedPropertiesForAfterUpdate(List<Case> afterUpdateCases, Map<Id, Case> oldCasesByIds) {
        // Staging methods for gathering related objects to be used in "apply business logic" methods
        if (afterUpdateRecordTypeIdByCasesMap.size() > 0) {

        }

    }

    private static void applyAfterUpdateLogic(List<Case> afterUpdateCases, Map<Id, Case> oldCasesByIds) {

        for (Case afterUpdateCase :  afterUpdateCases) {
            SpecicAppNameCaseTriggerHandler.applyAfterUpdateLogic(oldCasesByIds, afterUpdateCase);
        }

    }

    private static void performDMLOperationsForAfterUpdate() {
        SpecicAppNameCaseTriggerHandler.performDMLOperationsForAfterUpdate();
    }



}
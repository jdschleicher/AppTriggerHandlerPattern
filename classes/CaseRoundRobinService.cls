
public with sharing class CaseRoundRobinService {

    public static Map<Id, String> beforeUpdateRoundRobinRecordTypeDeveloperNamesMap;
    public static Map<Id, String> getBeforeUpdateRoundRobinRecordTypeDeveloperNamesMap() {
        beforeUpdateRoundRobinRecordTypeDeveloperNamesMap = new Map<Id, String> {
            Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Complaint').getRecordTypeId() => 'Complaint', //  Complaint Record Type
            Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Other_Complaint').getRecordTypeId() => 'Other_Complaint' //  Other Complaint Record Type
        };

        return beforeUpdateRoundRobinRecordTypeDeveloperNamesMap;
    }

    public static Map<Id, String> afterUpdateRoundRobinRecordTypeDeveloperNamesMap;
    public static Map<Id, String> getAfterUpdateRoundRobinRecordTypeDeveloperNamesMap() {
        afterUpdateRoundRobinRecordTypeDeveloperNamesMap = new Map<Id, String> {
            Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Complaint').getRecordTypeId() => 'Complaint', //  Complaint Record Type
            Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Other_Complaint').getRecordTypeId() => 'Other_Complaint' //  Other Complaint Record Type
        };

        return afterUpdateRoundRobinRecordTypeDeveloperNamesMap;
    }

    /******CASE ROUND ROBIN FUNCTIONALITY PROPERTIES *****/
        private static List<Id> roundRobinCaseOwnerIds = new List<Id>();
        private static List<Assignment_Groups__c> stagedGroupMembersAvailableForAssignment = new List<Assignment_Groups__c>();
        private static Map<Id, Assignment_Groups__c> groupMemberIdByGroupMemberToUpdateMap = new Map<Id, Assignment_Groups__c>();
        /****
         *  used to track the group member to assign Case ownership to in
         *  the assignGroupMemberOwnerToCaseOwnerAndUpdateLastAssignmentByIndexOfCase method
         */
        private static Integer groupMemberAssigneeTrackerIndex = 0;
        /****
         Several Iterations of the Case Trigger are made due to future methods of the Case Round Robin
         managed package causing a recursive invocation of the trigger logic.
         The roundRobinCasesOwnerLogicApplied flag captures en the specific h and  logic has been ran and prevents further updates
        ****/
        private static Boolean roundRobinCasesOwnerLogicApplied = false;
        /****
       *  List of Record Type Developer Names for Cases that use Round Robin logic
       */

    /****** END CASE ROUND ROBIN FUNCTIONALITY PROPERTIES *****/


    /****** CASE SLA TARGET DATE UPDATE PROPERTIES *****/
        private final static List<Case> casesToUpdateSlaTargetDate = new List<Case>();

        /****
           Several Iterations of the Case Trigger are made due to future methods of the Case Round Robin
           managed package causing a recursive invocation of the trigger logic.
           The hSlaTargetApplied flag captures en the specific h and  logic has been ran and prevents further updates
        ****/
        private static Boolean hSlaTargetApplied = false;

    /****** END CASE SLA TARGET DATE UPDATE PROPERTIES *****/


    public static void applyBeforeUpdatehAndComplaintRoundRobinLogic(Case beforeUpdateCase) {

        if ( caseHasRoundRobinCriteria(beforeUpdateCase) && !roundRobinCasesOwnerLogicApplied ) {

            if (roundRobinCaseOwnerIds.size() > 0 ) {
                assignGroupMemberOwnerToCaseOwnerAndUpdateLastAssignmentByIndexOfCase(beforeUpdateCase);
            }
        }

    }

    private static Boolean caseHasRoundRobinCriteria(Case updatedhCase) {
        Boolean caseHasRoundRobinCriteria = false;

        if (caseHasRoundRobinStatusCriteria(updatedhCase.Status)
            && (caseHasAcumenAdministration(updatedhCase.Administration__c) || caseHasTechCenterAdministration(updatedhCase.Administration__c)) ) {
            caseHasRoundRobinCriteria = true;
        }

        return caseHasRoundRobinCriteria;
    }

    private static Boolean caseNotClosedOrClosedDuplicate(String caseStatus) {
        String CLOSED = 'Closed';
        String CLOSED_DUPLICATE = 'Closed - Duplicate';
        return ( caseStatus != CLOSED && caseStatus != CLOSED_DUPLICATE );
    }

    private static Boolean caseHasAcumenAdministration(String caseAdministration) {
        return (caseAdministration == 'Acumen');
    }

    private static Boolean caseHasTechCenterAdministration(String caseAdministration) {
        return (caseAdministration == 'DasTechCenter');
    }

    public static void applyBeforeUpdateStagingLogicForhRoundRobinCases(Case beforeUpdateCase) {

        if (!roundRobinCasesOwnerLogicApplied && caseHasRoundRobinCriteria(beforeUpdateCase)) {
            roundRobinCaseOwnerIds.add(beforeUpdateCase.OwnerId);
        }

    }

    public static void postStagingDataRetrievalBeforeUpdateRoundRobin() {
        if (roundRobinCaseOwnerIds.size() > 0 && !roundRobinCasesOwnerLogicApplied) {
            setAssignmentGroupsToUpdateByRoundRobinCaseOwnerIds();
        }
    }


    private static void setAssignmentGroupsToUpdateByRoundRobinCaseOwnerIds() {

        List<Assignment_Group_Queues__c> assignmentGroupQueues = db_getAssignmentGroupQueuesByCaseOwnerIds(roundRobinCaseOwnerIds);

        List<Id> assignmentGroupIds = new List<Id>();
        for (Assignment_Group_Queues__c assignmentGroupQueue : assignmentGroupQueues) {
            assignmentGroupIds.add(assignmentGroupQueue.Assignment_Group_Name__c);
        }

        stagedGroupMembersAvailableForAssignment = db_getActiveAssignmentGroupMembersByGroupIds(assignmentGroupIds);
    }

    public static void assignGroupMemberOwnerToCaseOwnerAndUpdateLastAssignmentByIndexOfCase(Case caseToUpdate ) {
        if (stagedGroupMembersAvailableForAssignment.size() > 0 ) {

            Assignment_Groups__c groupMemberToUpdate = stagedGroupMembersAvailableForAssignment[groupMemberAssigneeTrackerIndex];
            setGroupMemberAssigneeTrackerIndexByAvailableGroupMembersAmount(stagedGroupMembersAvailableForAssignment.size());

            Datetime currentDatetime = Datetime.now();
            groupMemberToUpdate.Last_Assignment__c = currentDatetime;
            groupMemberToUpdate.Millisecond__c = currentDatetime.MillisecondGMT();

            adjustCaseOwnerIdFields(caseToUpdate, groupMemberToUpdate.User__c);

            if (groupMemberIdByGroupMemberToUpdateMap.containsKey(groupMemberToUpdate.Id)) {
                groupMemberIdByGroupMemberToUpdateMap.remove(groupMemberToUpdate.Id);
            }

            groupMemberIdByGroupMemberToUpdateMap.put(groupMemberToUpdate.Id, groupMemberToUpdate);

        }
    }

    private static void adjustCaseOwnerIdFields(Case caseToUpdate, Id newCaseOwnerId) {
        if (!roundRobinCasesOwnerLogicApplied) {
            caseToUpdate.TempOwnerId__c = '';
            caseToUpdate.OwnerId = newCaseOwnerId;
        }
    }

    private static void setGroupMemberAssigneeTrackerIndexByAvailableGroupMembersAmount(Integer availableGroupMembersCount) {
        if (groupMemberAssigneeTrackerIndex < (availableGroupMembersCount - 1)) {
            groupMemberAssigneeTrackerIndex++;
        } else {
            groupMemberAssigneeTrackerIndex = 0;
        }
    }

    private static List<Assignment_Group_Queues__c> db_getAssignmentGroupQueuesByCaseOwnerIds(LIst<Id> caseOwnerIds) {
        return [
                SELECT Id,
                        Assignment_Group_Name__c,
                        QueueId__c
                FROM Assignment_Group_Queues__c
                ERE QueueId__c in :caseOwnerIds
                AND Active__c = 'True'
        ];
    }

    private static List<Assignment_Groups__c> db_getActiveAssignmentGroupMembersByGroupIds(List<Id> groupNameIds) {
        return  [
                SELECT Group_Name__c,
                        User__c,
                        User__r.Name,
                        Last_Assignment__c,
                        Millisecond__c
                FROM Assignment_Groups__c
                ERE Group_Name__c in : groupNameIds
                AND Active__c = 'True'
                AND User_Active__c = 'True'
                ORDER BY Last_Assignment__c,
                        Millisecond__c
        ];
    }

    public static void performhComplaintDMLOperationsForBeforeUpdate() {
        if (groupMemberIdByGroupMemberToUpdateMap.size() > 0) {
            List<Assignment_Groups__c> assignmentGroupMembersToUpdate = groupMemberIdByGroupMemberToUpdateMap.values();
            if ( assignmentGroupMembersToUpdate.size() > 0 && !roundRobinCasesOwnerLogicApplied ) {
                update assignmentGroupMembersToUpdate;
                roundRobinCasesOwnerLogicApplied = true;
            }
        }
    }

    public static void applyAfterUpdateSLARecordTypeLogic(Case afterUpdateCase) {
         if ( caseHasRoundRobinStatusCriteria(afterUpdateCase.Status) &&
                (afterUpdateRoundRobinRecordTypeDeveloperNamesMap.keySet().contains(afterUpdateCase.RecordTypeId)) ) {
            casesToUpdateSlaTargetDate.add(afterUpdateCase);
        }
    }

    private static Boolean caseHasRoundRobinStatusCriteria(String caseStatus) {
        return (
            (caseStatus == 'Routed' || caseStatus == 'In Progress')
            && caseNotClosedOrClosedDuplicate(caseStatus)
        );

    }


    public static void performAfterUpdateSlaTargetDateUpdate() {

        if ( casesToUpdateSlaTargetDate.size() > 0 ) {
            CaseMilestoneUtils.populateSLATargetDate(caseIds);
        }

    }


}
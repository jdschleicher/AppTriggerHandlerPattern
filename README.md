# App Trigger Handler Pattern
Abstracted Trigger Handler Pattern based on App, to use with or without a Trigger Framework (such as https://github.com/kevinohara80/sfdc-trigger-framework)  to leverage.  Once in the trigger handler class for a specific app we can get further detailed into business domain logic and core functionality specific to that App.  

This pattern is intended to allow as many Apps to leverage a Trigger Handler as needed within an associated Salesforce org  

**Benefits**
  1.  Encourages abstraction per App
  1. "For-Loops" exist only on object trigger handler such as "CaseTriggerHandler" or "AccountTriggerHandler"

**The Flow**
  1. CaseTrigger context hit
  1. On initialization of CaseTriggerHandler, a Record Type Map (<Map<Id, String>) is added to a class property in the CaseTriggerHandler **availableBeforeUpdateRecordTypeIdsByCasesMap**.  
     These are the record types, determined by one-to-many app trigger handler classes, that will run as part of the constructor initialization of the CaseTriggerHandler class below
  
    public static Map<Id, List<Case>> beforeUpdateRecordTypeIdByCasesMap = new Map<Id, List<Case>>()

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
     
  1. A conditional captures specific trigger context and calls the associated CaseTriggerHandler trigger context method:
  
              trigger CaseTrigger on Case (before update, after update) {

                  CaseTriggerHandler caseTriggerHandlr = new CaseTriggerHandler();

                  if (Trigger.isBefore && Trigger.isUpdate) {
                      caseTriggerHandlr.OnBeforeUpdate(Trigger.new, Trigger.oldMap);
                  } else if (Trigger.isAfter && Trigger.isUpdate) {
                      caseTriggerHandlr.OnAfterUpdate(Trigger.new, Trigger.oldMap);
                  }

              }
              
  1. The CaseTriggerHandler trigger context method leverages the below method calling structure:
  
               public void OnBeforeUpdate(List<Case> beforeUpdateCases, Map<Id, Case> oldCasesByIds) {
                  buildBeforeUpdateRecordTypeDeveloperNameMap(beforeUpdateCases);
                   if (beforeUpdateRecordTypeIdByCasesMap.size() > 0) {
                        stageRelatedPropertiesForBeforeUpdate(beforeUpdateCases, oldCasesByIds);
                        applyBeforeUpdateLogic(oldCasesByIds, beforeUpdateCases);
                        performDMLOperationsForBeforeUpdate();
                    }
                }
                
  1. the *buildBeforeUpdateRecordTypeDeveloperNameMap()* method populates the class map property (Map<Id, List<Case>>): **beforeUpdateRecordTypeIdByCasesMap**
              
                  private static void buildBeforeUpdateRecordTypeDeveloperNameMap(List<Case> beforeUpdateCases) {
                      // This map will capture all Record Type Developer Names by Case and will be searchable to determine whether or not
                      // to run logic for Cases if they do not have populated RecordType map references

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
                  
      1. based on the record type map given in the constructor which populates the **availableBeforeUpdateRecordTypeIdsByCasesMap** class property of the CaseTriggerHandler, the **beforeUpdateRecordTypeIdByCasesMap** property gets populated with a list of Cases associated with their specifc record type Id

  
  1. We will cover the OnBeforeUpdate internal method calls below. The idea is that no other method abstracted/stemming from this inial trigger context handler will contain a for loop:
      1. **stageRelatedPropertiesForBeforeUpdate(beforeUpdateCases, oldCasesByIds);**
              
                private static void stageRelatedPropertiesForBeforeUpdate(List<Case> beforeUpdateCases, Map<Id, Case> oldCasesByIds) {
                    if (beforeUpdateRecordTypeIdByCasesMap.size() > 0) {
                        for (Case beforeUpdateCase : beforeUpdateCases) {
                            // Provide App TriggerHandler methods for specic Trigger Context
                            SpecicAppNameCaseTriggerHandler.applyBeforeUpdateStagingLogic(beforeUpdateCase);
                        }
                        postStagingDataRetrievalBeforeUpdate();
                    }
                }

          1. This method is only needed for if there is a specific scenario where related objects/data is needed in order to perform the necessary logic for the applyBeforeUpdateLogic method
          1. The *postStagingDataRetrievalBeforeUpdate* performs the DML **(primarily retrievals)** of associated data to be leveraged as business logic as part of the *applyBeforeUpdateLogic* method
                        private static void postStagingDataRetrievalBeforeUpdate() {
                            SpecicAppNameCaseTriggerHandler.postStagingDataRetrievalBeforeUpdate();
                        }
      1. **applyBeforeUpdateLogic(oldCasesByIds, beforeUpdateCases)**
              
                  private static void applyBeforeUpdateLogic(Map<Id, Case> oldCasesByIds, List<Case> beforeUpdateCases) {
                      for (Case beforeUpdateCase : beforeUpdateCases) {
                          // Provide App TriggerHandler methods for specic Trigger Context
                          SpecicAppNameCaseTriggerHandler.applyBeforeUpdateLogic(beforeUpdateCase);
                          // Other App Trigger Handlers go Here
                          // for example:
                          HereBeThatOtherAppCaseTriggerHandler.applyBeforeUpdateLogic(beforeUpdateCase);
                      }
                  }
                  
            1.  This is the main loop over the trigger context records
            1.  In this loop, there will be each App’s service call to adjust the record such as perpping records for DML or integrating associated data from the staging method to perform business logic. **No DML operations will be performed in any applyLogic trigger context method**
      1. **performDMLOperationsForBeforeUpdate()**
      
                      private static void performDMLOperationsForBeforeUpdate() {
                          SpecicAppNameCaseTriggerHandler.performDMLOperationsForBeforeUpdate();
                          HereBeThatOtherAppCaseTriggerHandler.performDMLOperationsForBeforeUpdate(beforeUpdateCase);
                      }
          
            1. This method will contain each App’s trigger context specific method to perform DML operations for that specific trigger context
            1. The abstracted service methods to be called will include a conditional to determine whether or not any DML calls needs to be performed, such as checking available class property list that would be populated by the *applyBeforeUpdateLogic* method 
    1.  After the trigger context is abstracted from the CaseTriggerHandler to the differnt App specific trigger handler classes there will be addition business logic specifc Utitlity and Service classes the 
    app specific trigger handler classes will leverage

                      



**THE BELOW IS IN PROGRESS/DRAFT**
Leverage Code Snippets
Leveraging the Trigger Context Scenarios:
#1 Adding a new Trigger Context 
#2 Leveraging an existing Trigger Context setup

#1 Adding a new Trigger Context 
if there isn't already a context that captures the specific trigger context needed to perform required business logic, then add the context structure
If trigger context doesn’t already exist, define trigger context to trigger initiation.  In the example of needing to add Before Update logic, we will add the following update to the **CaseTrigger**:
     
     trigger CaseTrigger on Case (before update) {
       CaseTriggerHandler caseTriggerHandlr = new CaseTriggerHandler();
        if (Trigger.isBefore && Trigger.isUpdate) {
           caseTriggerHandlr.OnBeforeUpdate(Trigger.new, Trigger.oldMap);
         }
        }
 
  We will need to add the associated trigger handler method to the *CaseTriggerHandler*
      




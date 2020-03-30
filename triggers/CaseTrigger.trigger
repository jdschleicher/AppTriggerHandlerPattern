trigger CaseTrigger on Case (before update, after update) {

    if (FeatureManagement.checkPermission('DisableTriggersFlag') == True) {
        // User has DisableTriggersFlag enabled so break out of the current method/trigger
        return;
    }

    CaseTriggerHandler caseTriggerHandlr = new CaseTriggerHandler();

    if (Trigger.isBefore && Trigger.isUpdate) {
        caseTriggerHandlr.OnBeforeUpdate(Trigger.new, Trigger.oldMap);
    } else if (Trigger.isAfter && Trigger.isUpdate) {
        caseTriggerHandlr.OnAfterUpdate(Trigger.new, Trigger.oldMap);
    }


}
trigger CaseTrigger on Case (before update, after update) {

    CaseTriggerHandler caseTriggerHandlr = new CaseTriggerHandler();

    if (Trigger.isBefore && Trigger.isUpdate) {
        caseTriggerHandlr.OnBeforeUpdate(Trigger.new, Trigger.oldMap);
    } else if (Trigger.isAfter && Trigger.isUpdate) {
        caseTriggerHandlr.OnAfterUpdate(Trigger.new, Trigger.oldMap);
    }


}

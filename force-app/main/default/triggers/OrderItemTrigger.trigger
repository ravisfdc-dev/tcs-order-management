trigger OrderItemTrigger on orderItem (after insert, after update, after delete, after undelete ) {

   OrderItemTriggerHandler.handleAfter();

}
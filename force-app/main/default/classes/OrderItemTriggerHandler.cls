/**
 * @description Trigger handler for OrderItem.
 * Recalculates the number of OrderItems associated
 * with affected Orders.
 */

public with sharing class OrderItemTriggerHandler {

    /**
     * @description Handles after-trigger contexts for OrderItem
     *              and delegates Order Item count recalculation.
     */
    
    public static void handleAfter() {
        if (Trigger.isInsert || Trigger.isUndelete) {
        
            recalculateOrderItemCount(Trigger.new, null);

        } else if (Trigger.isUpdate) {
        
            recalculateOrderItemCount(Trigger.new, Trigger.old);

        } else if (Trigger.isDelete) {
        
            recalculateOrderItemCount(null, Trigger.old);
        }
    }

    /**
     * @description Recalculates Order Item counts for affected Orders.
     * @param newList New versions of OrderItem records.
     * @param oldList Previous versions of OrderItem records.
     */

    public static void recalculateOrderItemCount(List<OrderItem> newList, List<OrderItem> oldList) {

        Set<Id> orderIds = getAffectedOrderIds(newList, oldList);

        if (orderIds.isEmpty()) {
            return;
        }

        Map<Id, Integer> countByOrderId = getOrderItemCounts(orderIds);

        updateOrderCounts(orderIds, countByOrderId);
    }

    private static Set<Id> getAffectedOrderIds(List<OrderItem> newList, List<OrderItem> oldList) {
         Set<Id> orderIds = new Set<Id>();

            addOrderIds(orderIds, newList);
            addOrderIds(orderIds, oldList);

            return orderIds;
    }

    private static void addOrderIds(Set<Id> orderIds, List<OrderItem> items) {
            
        if (items == null) {
            return;
        }

        for (OrderItem item : items) {
            if (item.OrderId != null) {
            orderIds.add(item.OrderId);
            }
        }
    }

    private static Map<Id, Integer> getOrderItemCounts(Set<Id> orderIds) {
        Map<Id, Integer> countByOrderId = new Map<Id, Integer>();

        for (AggregateResult ar : [
        SELECT OrderId ordId, COUNT(Id) itemCount
        FROM OrderItem
        WHERE OrderId IN :orderIds
        WITH USER_MODE
        GROUP BY OrderId]) {
        
            countByOrderId.put(
            (Id) ar.get('ordId'),
            (Integer) ar.get('itemCount'));
        }

        return countByOrderId;
    }

    private static void updateOrderCounts(Set<Id> orderIds, Map<Id, Integer> countByOrderId) {
    
        List<Order> ordersToUpdate = new List<Order>();

    
        for (Id orderId : orderIds) {
        
        
            Integer itemCount = countByOrderId.containsKey(orderId) ? countByOrderId.get(orderId) : 0;

        
            ordersToUpdate.add( new Order(
                Id = orderId,
                Order_Item_Count__c = itemCount));
        }

    
        if (!ordersToUpdate.isEmpty()) {
        
            Database.update(ordersToUpdate, AccessLevel.USER_MODE);
        }
    }

}

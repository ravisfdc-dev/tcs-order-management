/**
 * @description Unit tests for OrderItemTrigger and
 *              OrderItemTriggerHandler.
 */
@isTest
public with sharing class OrderItemTriggerHandlerTest {

    /**
 * @description Creates reusable Account, Product, PricebookEntry,
 *              and Order records for OrderItem trigger tests.
 */
    @TestSetup
    static void setupData() {

        Account account = new Account(
            Name = 'Test Customer'
        );

        Database.insert(account, AccessLevel.SYSTEM_MODE);

        Product2 product = new Product2(
            Name = 'Test Product',
            IsActive = true
        );

        Database.insert(product, AccessLevel.SYSTEM_MODE);

        Id standardPricebookId = Test.getStandardPricebookId();

        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = product.Id,
            UnitPrice = 1000,
            IsActive = true
        );

        Database.insert(pricebookEntry, AccessLevel.SYSTEM_MODE);

        Order orderRecord = new Order(
            AccountId = account.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = standardPricebookId
        );
        
        Database.insert(orderRecord, AccessLevel.SYSTEM_MODE);
    }

/**
 * @description Verifies that inserting one OrderItem
 *              updates the parent Order item count to 1.
 */
    @IsTest
    static void testOrderItemInsertUpdatesCount() {

        Order orderRecord = [
            SELECT Id, Order_Item_Count__c
            FROM Order
            LIMIT 1
        ];

        PricebookEntry pricebookEntry = [
            SELECT Id
            FROM PricebookEntry
            WHERE IsActive = true
            LIMIT 1
        ];

        OrderItem orderItem = new OrderItem(
            OrderId = orderRecord.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 1,
            UnitPrice = 1000
        );

        Test.startTest();

        Database.insert(
            orderItem,
            AccessLevel.SYSTEM_MODE
        );

        Test.stopTest();

        Order updatedOrder = [SELECT Order_Item_Count__c
                              FROM Order
                              WHERE Id = :orderRecord.Id];

        System.assertEquals(1, updatedOrder.Order_Item_Count__c,
            'Order Item Count should be 1 after inserting one OrderItem.');
    }

/**
 * @description Verifies that restoring a deleted OrderItem
 *              recalculates the parent Order Item Count.
 */
    @IsTest
    static void testOrderItemUndeleteUpdatesCount() {

        Order orderRecord = [
            SELECT Id
            FROM Order
            WITH USER_MODE
            LIMIT 1
        ];

        PricebookEntry pricebookEntry = [
            SELECT Id
            FROM PricebookEntry
            WHERE IsActive = true
            WITH USER_MODE
            LIMIT 1
        ];

        OrderItem orderItem = new OrderItem(
            OrderId = orderRecord.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 1,
            UnitPrice = 1000
        );

        Database.insert(orderItem, AccessLevel.SYSTEM_MODE);

        Database.delete(orderItem, AccessLevel.SYSTEM_MODE);

        Order orderAfterDelete = [
            SELECT Order_Item_Count__c
            FROM Order
            WHERE Id = :orderRecord.Id
            WITH USER_MODE
        ];

        System.assertEquals(
            0,
            orderAfterDelete.Order_Item_Count__c,
            'Count should be 0 after deleting the OrderItem.'
        );

        Test.startTest();

        Database.undelete(orderItem, AccessLevel.SYSTEM_MODE);

        Test.stopTest();

        Order orderAfterUndelete = [
            SELECT Order_Item_Count__c
            FROM Order
            WHERE Id = :orderRecord.Id
            WITH USER_MODE
        ];

        System.assertEquals(
            1,
            orderAfterUndelete.Order_Item_Count__c,
            'Count should return to 1 after undeleting the OrderItem.'
        );
    }

/**
 * @description Verifies bulk insertion of OrderItems updates
 *              the parent Order Item Count correctly.
 */
    @IsTest
    static void testBulkOrderItemInsertUpdatesCount() {

        Order orderRecord = [
            SELECT Id
            FROM Order
            WITH USER_MODE
            LIMIT 1
        ];

        PricebookEntry pricebookEntry = [
            SELECT Id
            FROM PricebookEntry
            WHERE IsActive = true
            WITH USER_MODE
            LIMIT 1
        ];

        List<OrderItem> orderItems = new List<OrderItem>();

        for (Integer i = 0; i < 200; i++) {
            orderItems.add(
                new OrderItem(
                    OrderId = orderRecord.Id,
                    PricebookEntryId = pricebookEntry.Id,
                    Quantity = 1,
                    UnitPrice = 1000
                )
            );
        }

        Test.startTest();

        Database.insert(
            orderItems,
            AccessLevel.SYSTEM_MODE
        );

        Test.stopTest();

        Order updatedOrder = [
            SELECT Order_Item_Count__c
            FROM Order
            WHERE Id = :orderRecord.Id
            WITH USER_MODE
        ];

        System.assertEquals(
            200,
            updatedOrder.Order_Item_Count__c,
            'Order Item Count should be 200 after bulk inserting 200 OrderItems.'
        );
    }

}

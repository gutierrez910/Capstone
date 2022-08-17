public class OrderHandler {
    public static void restrictStage(list<Order> ordlist, map<Id,Order> oldmap){
        for(Order o : ordlist){
            if(o.MyStage__c != oldmap.get(o.Id).MyStage__c){
                if(oldmap.get(o.Id).MyStage__c == 'Cancelled' || oldmap.get(o.Id).MyStage__c == 'Delivered')
                {o.addError('Stage cannot be changed after delivery or cancellation');}
                if(oldmap.get(o.Id).MyStage__c == 'Delivery in Plan'){
                    if(o.MyStage__c != 'Cancelled' || o.MyStage__c != 'Delivered'){
                        o.addError('Cannot revert Stage');
                    }
                }
                else if (oldmap.get(o.Id).MyStage__c == 'Payment Received'){
                    if(o.MyStage__c != 'Cancelled' || o.MyStage__c !='Delivered' || o.MyStage__c != 'Delivery in Plan'){
                        o.addError('Cannot revert Stage');
                    }
                }
                else if (oldmap.get(o.Id).MyStage__c == 'Invoice Generated'){
                    if(o.MyStage__c == 'Created' || o.MyStage__c == 'In process'){
                        o.addError('Cannot revert Stage');
                    }
                }
                else if(oldmap.get(o.Id).MyStage__c == 'In process'){
                    if(o.MyStage__c == 'Created'){
                        o.addError('Cannot revert Stage');
                    }
                }
            }
        }
    }

    public static void CreateInvoiceData(list<Order> ordlist){
        Id myInvoiceID;
        integer index = 0;

        List<OrderItem> ordItemList = [select Id from orderitem where OrderId IN :ordlist];
        List<My_Invoice__c> invoiceList = new List<My_Invoice__c>();
        List<My_Invoice_Line__c> invLineList = new List<My_Invoice_Line__c>();

        for(Order ord: ordlist){
            if(ord.MyStage__c == 'Invoice Generated'){
                invoiceList.add(new My_Invoice__c(
                    Order__c = ord.id,
                    Invoice_Date__c = ord.EffectiveDate
                ));
           }           
        }    

        database.insert(invoiceList, false);

        for(Order ord: ordlist){
            if(ord.MyStage__c == 'Invoice Generated'){
                myInvoiceID = invoiceList[index].id;
                index++;

                for(OrderItem item: ordItemList) {
                    invLineList.add(new My_Invoice_Line__c(
                        My_Invoice__c = myInvoiceID,
                        Product__c = item.Id
                    ));
                    System.Debug('CreateInvoiceData    CONTENTS    ' + myInvoiceID + '    '+ invLineList);

                }
            }
        }
        database.insert(invLineList,false);

    }
}
trigger InvoiceFillDataTrigger on ORDER (after update) {
    
    OrderHandler.CreateInvoiceData(trigger.new);


}
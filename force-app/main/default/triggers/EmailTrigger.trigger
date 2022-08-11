trigger EmailTrigger on Order (after insert, after update) {
    if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
        
        list<Contact> conList = new list<Contact>([select Id,Name,Email,Email_Opt_Out__c from Contact where AccountId=:trigger.new[0].AccountId]);
        
        list<Account> acc = new list<Account>([select Id, Email_Opt_Out__c from Account where Id=:trigger.new[0].AccountId limit 1]);
        
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        if(trigger.isInsert || (trigger.isUpdate && (trigger.new[0].Stage__c != trigger.old[0].Stage__c)))
        {
            if(acc[0].Email_Opt_Out__c == false)
            {
                
                for(Contact con : conList){
                    
                    if(con.Email_Opt_Out__c == false){
                        
                        Messaging.SingleEmailMessage mail =  new Messaging.SingleEmailMessage();
                        
                        List<String> sendTo = new List<String>();
                        sendTo.add(con.Email);
                        mail.setToAddresses(sendTo);
                        
                        mail.setReplyTo('adarshsingh5180@gmail.com');
                        mail.setSenderDisplayName('Adarsh Singh');
                        
                        mail.setSubject('Order Status Notification');
                        
                        String body = 'Order Id : ' + trigger.new[0].Id
                            + ' Order Number : ' + trigger.new[0].OrderNumber
                            + ' Order stage : ' + trigger.new[0].Stage__c;
                        mail.setHtmlBody(body);
                        
                        mails.add(mail);
                        System.debug(sendTo);
                    }
                }
            }
        }
        Messaging.sendEmail(mails);
    }
}
trigger AccountLimitTrigger on Account (before insert, before update) {
    if(trigger.isBefore && (trigger.isInsert||trigger.isUpdate)){
        list<Account> totalAccounts= new list<Account>();
        for(Account a: trigger.new){
            totalAccounts=[select id from account where ownerId=:userinfo.getuserId()];
            if(totalAccounts.size() >=5)
                a.addError('A sales user can only own 5 accounts!' );
        }
    }
}
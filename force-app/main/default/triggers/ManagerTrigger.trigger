trigger ManagerTrigger on User (before insert) {
	 if(trigger.isBefore && trigger.isInsert){
        list<User> mangid = [select id from User where managerId =: trigger.new[0].managerId];
        if(mangid.size()>=2){
            trigger.new[0].addError('A user can act as a manager only for 2 users');
        }        
    }
}
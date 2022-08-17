public with sharing class OrderManagerController {

    public OrderManagerController() {

    }

    class ProductDetail{
        public String Id;
        public String Name;
        public String ProductCode;
        public String Brand;
        public String StockQuantity;
        public String Quantity;
        public String ListPrice;
        public String UnitPrice;
        public String Discount;
        public String PriceBookEntryId;
    }

    @AuraEnabled
    public static string getRecordId(){
        list<Order> recId = [SELECT Id FROM Order ORDER BY CreatedDate DESC LIMIT 1];
        String rId = '' + recId[0].Id;
        return rId;
    }

    @AuraEnabled
    public static string getProducts(String rbVal, String searchText, String pbId, Integer minPrice, Integer maxPrice){
        System.debug('Inside controller method getProducts');
        map<Id,Product2> prodList= new map<Id,Product2>();
        if(rbVal.equals('Name')){
            prodList.putAll([select Id,ProductCode,Name,Brand__c,Stock_Quantity__c from Product2 where Name LIKE :'%'+searchText+'%' AND Stock_Quantity__c>0]);
            System.debug('prodList created');
        }
        else if(rbVal.equals('Brand__c')){
            prodList.putAll([select Id,ProductCode,Name,Brand__c,Stock_Quantity__c from Product2 where Brand__c LIKE :'%'+searchText+'%' AND Stock_Quantity__c>0]);
        }
        else{
            prodList.putAll([select Id,ProductCode,Name,Brand__c,Stock_Quantity__c from Product2 where Id In (select Product2Id from PricebookEntry where UnitPrice >=:minPrice AND UnitPrice <=:maxPrice) AND Stock_Quantity__c>0]);
        }
        list<PricebookEntry> pbeList=[select Id,Product2Id,UnitPrice from PricebookEntry where Product2Id IN :prodList.keySet() AND Pricebook2Id=:pbId];
        map<Id,String> priceBookList=new map<Id,String>();
        map<Id,Decimal> unitPriceList=new map<Id,Decimal>();
        for(PricebookEntry item:pbeList){
            priceBookList.put(item.Product2Id,item.Id);
            unitPriceList.put(item.Product2Id,item.UnitPrice);
        }
        System.debug(priceBookList);
        System.debug(pbeList);
        System.debug(unitPriceList);
        String str='[';
        for(Id key:prodList.keySet()){
            str+='{"Id":"'+key+'","'+'Name":"'+prodList.get(key).Name+'","'+'ProductCode":"'+prodList.get(key).ProductCode+'","'+'ListPrice":"'+unitPriceList.get(key)+'","'+'Quantity":"","Brand__c":"'+prodList.get(key).Brand__c+'","'+'Stock_Quantity__c":"'+prodList.get(key).Stock_Quantity__c+'","'+'PriceBookEntryId":"'+priceBookList.get(key)+'"}'+',';
        }
        str = str.substring(0, str.length()-1);
        str+=']';
        System.debug(str);
        if(str.equals(']')){
            str='';
        }
        return str;
    }

    @AuraEnabled
    public static string createOrderProducts(String selectedProducts,String priceBookId, String orderId){
        list<ProductDetail> productList=new list<ProductDetail>();
        JSONParser parser = JSON.createParser(selectedProducts);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        ProductDetail pd = (ProductDetail)parser.readValueAs(ProductDetail.class);
                        system.debug('Id:' + pd.Id + ' Name:' + pd.Name);
                        productList.add(pd);
                    }
                }
            }
        }
        Order order=[Select Id,MyStage__c,Pricebook2Id from Order where Id=:orderId];
        order.Pricebook2Id = priceBookId;
        
        System.debug('UPDATE ERROR:    ' + order.Pricebook2Id + '   '+order);
        order.MyStage__c = 'Created';
        update order;
        System.debug('order detail '+order);

        list<OrderItem> orderItemList = new list<OrderItem>();
        list<Product2> newProductList = new list<Product2>();
        list<Product2> tempProducts = new list<Product2>([Select Id,Stock_Quantity__c from Product2]);
        for(ProductDetail product:productList){
            orderItemList.add(new OrderItem(OrderId=orderId,Product2Id=product.Id,Quantity=Decimal.valueOf(product.Quantity),UnitPrice=Decimal.valueOf(product.UnitPrice),PricebookEntryId=product.PriceBookEntryId));
            Product2 productId = new Product2();
            for(Product2 p:tempProducts){
                if(p.Id==product.Id){
                    productId = p;
                    break;
                }
            }
            // Free Items!! If customer buys more than 10 units
            if(Decimal.valueOf(product.Quantity)>10){
                //orderItemList.add(new OrderItem(OrderId=orderId,Product2Id=product.Id,Quantity=1,UnitPrice=0,PricebookEntryId=product.PriceBookEntryId));
                newProductList.add(new Product2(Id=product.Id, Stock_Quantity__c=productId.Stock_Quantity__c-Integer.valueOf(product.Quantity)));
            }else{
                newProductList.add(new Product2(Id=product.Id, Stock_Quantity__c=productId.Stock_Quantity__c-Integer.valueOf(product.Quantity)));
            }
            //Product2 productId = [Select Stock_Quantity__c from Product2 where Id=:product.Id];
            
        }
        insert orderItemList;
        order.MyStage__c = 'In process';
        update order;
        update newProductList;

        order = [Select TotalAmount from Order where Id=:orderId];
        return ''+order.TotalAmount;
    }

    @AuraEnabled
    public static string cancelOrder(String recordId){
        Order order=[Select Id,MyStage__c from Order where Id=:recordId];
        order.MyStage__c = 'Cancelled';
        update order;
        return 'Successful';
    }

}
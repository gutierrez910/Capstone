import { LightningElement, track } from 'lwc';
import getProducts from '@salesforce/apex/OrderManagerController.getProducts';
import getRecordId from '@salesforce/apex/OrderManagerController.getRecordId';
import createOrderProducts from '@salesforce/apex/OrderManagerController.createOrderProducts';
import cancelOrder from '@salesforce/apex/OrderManagerController.cancelOrder';

export default class OrderManager extends LightningElement {

    @track recordId = '';
    @track orderAmount = '';
    @track singleValue = true;
    minValue = 0;
    maxValue = 0;
    orderCreated = false;
    displayList = false;
    selectedItems = false;
    showFinalTable = false;
    @track value = '';
    @track openmodel = false;
    productList;
    desiredQuantity = 0;
    error;
    selectedProductsList = [];


    get options() {
        return [
            { label: 'Product Name', value: 'Name' },
            { label: 'Product Brand', value: 'Brand__c' },
            { label: 'MRP', value: 'UnitPrice' }
        ];
    }

    setCategory(event) {
        this.value = event.target.value;
        if (this.value === 'Name' || this.value === 'Brand__c') {
            this.singleValue = true;
        } else {
            this.singleValue = false;
        }
    }

    setMinValue(event) {
        this.minValue = event.target.value;
        this.maxValue = this.minValue + 1;
    }

    setMaxValue(event) {
        this.maxValue = event.target.value;
    }

    handleSuccess(event) {
        alert('Order Created');
        this.orderCreated = true;
        if (this.orderCreated) {
            getRecordId()
                .then(result => {
                    this.recordId = result;
                    console.log(this.recordId);
                })
        }
    }

    searchProducts(event) {
        var searchValue = event.target.value;
        console.log('inside get products list');
        if (searchValue.length > 0) {
            getProducts({ rbVal: this.value, searchText: searchValue, pbId: '01s5i000007wCP8AAM', minPrice: this.minValue, maxPrice: this.maxValue })
                .then(result => {
                    console.log(result);
                    console.log('inside get products success 1');
                    this.productList = JSON.parse(result);
                    console.log('inside get products success 2');
                    this.displayList = true;
                    console.log(this.productList);
                })
                .catch(error => {
                    console.log('inside get products error');
                    this.error = error;
                });

        } else {
            this.displayList = false;
        }
    }

    addProduct(event) {
        if (this.recordId == null || this.recordId == '') {
            alert('Please create a record first');
        } else if (this.desiredQuantity < 0) {
            alert('Please enter a valid value');
        } else {
            this.selectedItems = false;
            var pId = event.target.value;
            var index = -1;
            var selectedProduct = new Object();
            for (var product of this.productList) {
                index++;
                if (pId == product.Id) {
                    selectedProduct.Id = product.Id;
                    selectedProduct.Name = product.Name;
                    selectedProduct.ProductCode = product.ProductCode;
                    selectedProduct.Brand__c = product.Brand__c;
                    selectedProduct.Stock_Quantity__c = product.Stock_Quantity__c;
                    selectedProduct.Quantity = 0;
                    selectedProduct.UnitPrice = 0;
                    selectedProduct.ListPrice = product.ListPrice;
                    selectedProduct.Discount = 0;
                    selectedProduct.PriceBookEntryId = product.PriceBookEntryId;
                    break;
                }
            }
            if (!this.selectedProductsList.some(prod => prod.Id === selectedProduct.Id)) {
                this.selectedProductsList.push(selectedProduct);
            }
            this.selectedItems = true;
        }
    }

    removeProduct(event) {
        var id = event.target.value;
        for (var product of this.selectedProductsList) {
            if (id == product.Id) {
                const index = this.selectedProductsList.indexOf(product);
                this.selectedProductsList.splice(index, 1);
            }
        }
        this.selectedItems = false;
        this.selectedItems = true;
    }

    updateQuantity(event) {

        var index = -1;
        for (var product of this.selectedProductsList) {
            index++;
            if (event.target.name == product.Id) {
                break;
            }
        }
        // temp
        if(event.target.value>0)
            this.selectedProductsList[index].Quantity = event.target.value;
    }

    updateDiscount(event) {
        var index = -1;
        for (var product of this.selectedProductsList) {
            index++;
            if (event.target.name == product.Id) {
                break;
            }
        }
        this.selectedProductsList[index].Discount = event.target.value;
    }

    saveOrderProducts(event) {
        for (var product of this.selectedProductsList) {
            product.UnitPrice = product.ListPrice - (product.ListPrice * product.Discount / 100);
        }

        createOrderProducts({ selectedProducts: JSON.stringify(this.selectedProductsList), priceBookId: '01s5i000007wCP8AAM', orderId: this.recordId })
            .then(result => {
                console.log('Order Id : ' + result);
                this.orderAmount = result;
            })
            .catch(error => {
                console.log(error);
            });
        this.showFinalTable = true;
        this.openmodel = true;
    }

    cancelOrder() {
        cancelOrder({ recordId: this.recordId })
            .then(result => {
                console.log('Order cancelled' + result);
                alert('Order Cancelled');
            })
            .catch(error => {
                console.log('Unsuccessful');
                console.log(error);
            })
    }

    closeModal() {
        this.openmodel = false;
        const formFields = this.template.querySelectorAll('lightning-input-field');
        if (formFields) {
            formFields.forEach((field) => {
                field.reset();
            })
        }

        this.recordId = '';
        this.orderAmount = '';
        this.singleValue = true;
        this.minValue = 0;
        this.maxValue = 0;
        this.orderCreated = false;
        this.displayList = false;
        this.selectedItems = false;
        this.showFinalTable = false;
        this.value = '';
        this.openmodel = false;
        this.desiredQuantity = 0;
        this.selectedProductsList = [];
    }

}
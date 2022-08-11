import { LightningElement, track } from 'lwc';

export default class ComboboxBasic extends LightningElement {
    value = 'Choose Residency';
    @track isShowModal = false;

    get options() {
        return [
            { label: 'Yes', value: 'yes' },
            { label: 'No', value: 'no' },
        ];
    }

    handleChange(event) {
        this.value = event.detail.value;
        
    }

    openModal(){        
        if(this.value == 'yes'){
            this.isShowModal = true;
        }
        else
            this.isShowModal = false;
    }
    
    closeModal(){
        this.isShowModal = false;
    }
}
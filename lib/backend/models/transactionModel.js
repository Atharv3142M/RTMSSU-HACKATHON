import mongoose from "mongoose";

const transactionSchema = new mongoose.Schema(
    {
        userId : {
            type : mongoose.Schema.Types.ObjectId,
            ref : "Users",
            required : true,
        },
       transactionDate:{
        type : Date,
        required : true,
       },
       isExpense : {
        type : Boolean,
        required : true,
       },
       amount : {
        type : Number,
        required : true,
       },
       description : {
        type : String,
        required : true,
       },
       category : {
        type : String,
        requeuired : true,
       },
       merchant : {
        type : String,
        required : false, 
       }
       
    }
);

const Transactions = mongoose.model("Transactions", transactionSchema);

export default Transactions;
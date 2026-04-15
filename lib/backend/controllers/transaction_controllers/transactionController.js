import Transactions from "../../models/transactionModel.js";
import mongoose from "mongoose";

export const addTransaction = async (req, res) => {
    console.log('Backend: Received add transaction request');
    console.log('Backend: Request body:', req.body);
    
    const { userId, transactionDate, isExpense, amount, description, category } = req.body;

    try {
        // Validate required fields
        if (!userId || !transactionDate || isExpense === undefined || !amount || !description) {
            console.log('Backend: Missing required fields');
            return res.status(400).json({ 
                message: "Missing required fields",
                required: ['userId', 'transactionDate', 'isExpense', 'amount', 'description'],
                received: { userId, transactionDate, isExpense, amount, description, category }
            });
        }

        // Validate userId format
        if (!mongoose.Types.ObjectId.isValid(userId)) {
            console.log('Backend: Invalid userId format:', userId);
            return res.status(400).json({ message: "Invalid user ID format" });
        }

        console.log('Backend: Creating new transaction with data:', {
            userId,
            transactionDate,
            isExpense,
            amount,
            description,
            category
        });

        const newTransaction = new Transactions({
            userId,
            transactionDate,
            isExpense,
            amount,
            description,
            category,
            merchant: req.body.merchant || "",  
        });

        console.log('Backend: Saving transaction to database...');
        const savedTransaction = await newTransaction.save();
        console.log('Backend: Transaction saved successfully:', savedTransaction);
        
        res.status(201).json(savedTransaction);
    } catch (error) {
        console.error("Backend: Error adding transaction:", error);
        console.error("Backend: Error details:", error.message);
        res.status(500).json({ 
            message: "Internal server error",
            error: error.message 
        });
    }
}

export const getTransactions = async (req, res) => {
    const { userId } = req.params;

    try{
        const transactions = await Transactions.find({ userId }).sort({ transactionDate: -1 });
        res.status(200).json(transactions);
    }catch (error) {
        console.error("Error fetching transactions:", error);
        res.status(500).json({ message: "Internal server error" });
    }
};

export const deleteTransaction = async (req, res) => {
    
    const { transactionId } = req.params;
    
    try {
        const deletedTransaction = await Transactions.findByIdAndDelete(transactionId);
        
        if (!deletedTransaction) {
            return res.status(404).json({ message: "Transaction not found" });
        }
        
        res.status(200).json({ message: "Transaction deleted successfully" });
    }
    catch (error) {
        console.error("Error deleting transaction:", error);
        res.status(500).json({ message: error.message || "Internal server error"});
    }
};
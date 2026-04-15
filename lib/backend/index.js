import mongoose from "mongoose";
import dotenv from "dotenv";
import cors from "cors";
import userRoutes from "./routes/user_routes/userRoutes.js";
import transactionRoutes from "./routes/transaction_routes/transactionRoutes.js";
import goalRoutes from "./routes/goal_routes/goalRoutes.js";
import pdfRoutes from "./routes/pdf_routes/pdfRoutes.js";
import express from "express";

// Load environment variables from .env file
dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;
const MONGODB_CONNECTION_STRING = process.env.MONGODB_CONNECTION_STRING;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true })); // Add this for form data
app.use(cors({
    origin: '*', // Allow all origins for now
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// Health check endpoint
app.get("/health", (req, res) => {
    res.status(200).json({
        status: "OK",
        message: "Server is running",
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || "development"
    });
});

// Test PDF endpoint
app.get("/test-pdf", (req, res) => {
    res.status(200).json({
        message: "PDF endpoint is accessible",
        timestamp: new Date().toISOString()
    });
});

// Routes
app.use("/api/users", userRoutes);
app.use("/api/transactions", transactionRoutes);
app.use("/api/goals", goalRoutes);
app.use("/api/pdf", pdfRoutes);

// MongoDB Connection
mongoose.connect(MONGODB_CONNECTION_STRING)
    .then(() => {
        console.log("MongoDB connected!");
        // Start server only after DB connection
        app.listen(PORT, () => {
            console.log(`Server running on port ${PORT}`);
        });
    })
    .catch((err) => {
        console.error("MongoDB connection error:", err);
    });
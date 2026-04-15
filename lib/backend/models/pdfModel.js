import mongoose from "mongoose";

const pdfSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Users",
        required: true,
    },
    filename: {
        type: String,
        required: true,
    },
    originalName: {
        type: String,
        required: true,
    },
    filePath: {
        type: String,
        required: true,
    },
    fileSize: {
        type: Number,
        required: true,
    },
    mimetype: {
        type: String,
        default: "application/pdf",
    },
    uploadedAt: {
        type: Date,
        default: Date.now,
    },
    // Optional: Add metadata about the financial report
    reportType: {
        type: String,
        default: "financial_analysis",
    },
    reportPeriod: {
        type: String,
        // e.g., "monthly", "quarterly", "yearly", "custom"
    },
    totalIncome: {
        type: Number,
    },
    totalExpenses: {
        type: Number,
    },
    netAmount: {
        type: Number,
    },
}, {
    timestamps: true,
});

// Create index for faster queries
pdfSchema.index({ userId: 1, uploadedAt: -1 });

const PdfModel = mongoose.model("Pdf", pdfSchema);

export default PdfModel;
import multer from "multer";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
import { dirname } from "path";
import PdfModel from "../../models/pdfModel.js";
import mongoose from "mongoose";
import axios from "axios";

// Get current directory
const __filename = fileURLToPath(
    import.meta.url);
const __dirname = dirname(__filename);

// Configure multer for file upload
const storage = multer.diskStorage({
    destination: function(req, file, cb) {
        // Use process.cwd() for more reliable path resolution
        const uploadDir = path.join(process.cwd(), "uploads", "pdfs");
        console.log("Upload directory:", uploadDir);

        try {
            if (!fs.existsSync(uploadDir)) {
                fs.mkdirSync(uploadDir, { recursive: true });
                console.log("Created upload directory:", uploadDir);
            }
            cb(null, uploadDir);
        } catch (error) {
            console.error("Error creating upload directory:", error);
            cb(error);
        }
    },
    filename: function(req, file, cb) {
        // Generate unique filename with timestamp
        const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
        const ext = path.extname(file.originalname);
        cb(null, `financial_report_${uniqueSuffix}${ext}`);
    },
});

// File filter to only allow PDF files
const fileFilter = (req, file, cb) => {
    console.log("File upload attempt:", {
        originalname: file.originalname,
        mimetype: file.mimetype,
        fieldname: file.fieldname
    });

    // Check both mimetype and file extension
    const isPdfMimeType = file.mimetype === "application/pdf";
    const isPdfExtension = file.originalname.toLowerCase().endsWith('.pdf');

    if (isPdfMimeType || isPdfExtension) {
        cb(null, true);
    } else {
        cb(new Error(`Only PDF files are allowed! Received: ${file.mimetype} with name: ${file.originalname}`), false);
    }
};

// Configure multer upload
const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 10 * 1024 * 1024, // 10MB limit
    },
    // This ensures form fields are processed
    preservePath: true
});

// Upload PDF controller
export const uploadPdf = async(req, res) => {
    console.log("PDF upload request received");
    console.log("Request headers:", req.headers);
    console.log("Content-Type:", req.headers['content-type']);

    try {
        // Use multer middleware to handle file upload
        upload.single("file")(req, res, async(err) => {
            if (err) {
                console.error("Multer error:", err);
                return res.status(400).json({
                    success: false,
                    message: "File upload error: " + err.message,
                });
            }

            // Log form fields after Multer has processed them
            console.log("Form fields available:", req.body);

            // Access individual fields
            const userId = req.body.userId;
            const totalIncome = req.body.totalIncome;
            const totalExpenses = req.body.totalExpenses;
            const netAmount = req.body.netAmount;

            console.log("Extracted fields:", { userId, totalIncome, totalExpenses, netAmount });

            // Get user email if userId is provided
            let userEmail = null;
            if (userId) {
                try {
                    const Users = (await
                        import ("../../models/userModel.js")).default;
                    const user = await Users.findById(userId);
                    if (user && user.email) {
                        userEmail = user.email;
                        console.log("Found user email:", userEmail);
                    } else {
                        console.log("User not found or email not available");
                    }
                } catch (error) {
                    console.error("Error fetching user email:", error);
                }
            }

            // Check if file was uploaded
            if (!req.file) {
                return res.status(400).json({
                    success: false,
                    message: "No file uploaded. Please select a PDF file.",
                });
            }

            // Get file information
            const fileInfo = {
                originalName: req.file.originalname,
                filename: req.file.filename,
                path: req.file.path,
                size: req.file.size,
                mimetype: req.file.mimetype,
                uploadedAt: new Date(),
            };

            console.log("PDF uploaded successfully:", fileInfo);

            // Save file information to database if userId is provided
            let pdfRecord = null;
            if (req.body.userId) {
                try {
                    pdfRecord = new PdfModel({
                        userId: req.body.userId,
                        filename: fileInfo.filename,
                        originalName: fileInfo.originalName,
                        filePath: fileInfo.path,
                        fileSize: fileInfo.size,
                        uploadedAt: fileInfo.uploadedAt,
                        // Optional: Add financial data if provided
                        totalIncome: req.body.totalIncome ? parseFloat(req.body.totalIncome) : undefined,
                        totalExpenses: req.body.totalExpenses ? parseFloat(req.body.totalExpenses) : undefined,
                        netAmount: req.body.netAmount ? parseFloat(req.body.netAmount) : undefined,
                    });
                    await pdfRecord.save();
                    console.log("PDF record saved to database:", pdfRecord._id);
                    // Send webhook notification to n8n
                    try {
                        console.log("Sending PDF to n8n webhook...");
                        console.log("File path:", fileInfo.path);
                        console.log("File exists check:", fs.existsSync(fileInfo.path) ? "File exists" : "File not found");
                        console.log("User email:", userEmail || "user@example.com");

                        // Read file as base64 instead of using form data
                        const fileBuffer = fs.readFileSync(fileInfo.path);
                        const fileBase64 = fileBuffer.toString('base64');

                        // IMPORTANT: Make sure this is the correct webhook URL from n8n
                        // The URL should be the "Production" URL from your n8n webhook node
                        const webhookUrl = "https://dhruv-chotai-10.app.n8n.cloud/webhook-test/send-financial-report";
                        console.log("Webhook URL:", webhookUrl);

                        // Send JSON payload with base64 file data
                        const webhookResponse = await axios.post(
                            webhookUrl, {
                                email: userEmail || "user@example.com",
                                filename: fileInfo.filename,
                                fileType: "application/pdf",
                                fileSize: fileInfo.size,
                                fileData: fileBase64, // Send file as base64
                                uploadTime: new Date().toISOString(),
                                financialData: {
                                    totalIncome: req.body.totalIncome ? parseFloat(req.body.totalIncome) : 0,
                                    totalExpenses: req.body.totalExpenses ? parseFloat(req.body.totalExpenses) : 0,
                                    netAmount: req.body.netAmount ? parseFloat(req.body.netAmount) : 0
                                }
                            }, {
                                headers: {
                                    'Content-Type': 'application/json',
                                    'Accept': 'application/json'
                                },
                                timeout: 30000
                            }
                        );

                        console.log("n8n webhook triggered successfully:", webhookResponse.status);
                        console.log("n8n response:", webhookResponse.data);
                    } catch (webhookError) {
                        console.error("Failed to trigger n8n webhook:", webhookError.message);
                        console.error("Error details:", webhookError);
                        if (webhookError.response) {
                            console.error("Response status:", webhookError.response.status);
                            console.error("Response data:", webhookError.response.data);
                        }
                        // Continue processing - webhook failure shouldn't stop the upload
                    }
                } catch (dbError) {
                    console.error("Error saving PDF record to database:", dbError);
                    // Continue without database save - file is still uploaded
                }
            }


            // Create a download URL for the file
            const baseUrl = process.env.BASE_URL || 'https://ml-based-personal-finance-optimizer.onrender.com';
            const downloadUrl = `${baseUrl}/api/pdf/download/${fileInfo.filename}`;

            // Return success response with email and file info including download URL
            res.status(200).json({
                success: true,
                message: "PDF uploaded successfully!",
                file: {
                    filename: fileInfo.filename,
                    originalName: fileInfo.originalName,
                    size: fileInfo.size,
                    uploadedAt: fileInfo.uploadedAt,
                    downloadUrl: downloadUrl,
                    filePath: fileInfo.path
                },
                user: {
                    userId: userId || "No user ID provided",
                    email: userEmail || "Email not found for user ID: " + (userId || "none"),
                },
                financialData: {
                    totalIncome: totalIncome ? parseFloat(totalIncome) : 0,
                    totalExpenses: totalExpenses ? parseFloat(totalExpenses) : 0,
                    netAmount: netAmount ? parseFloat(netAmount) : 0
                }
            });
        });
    } catch (error) {
        console.error("PDF upload error:", error);
        res.status(500).json({
            success: false,
            message: "Internal server error: " + error.message,
        });
    }
};

// Get all PDFs for a specific user
export const getUserPdfs = async(req, res) => {
    try {
        const { userId } = req.params;

        // Validate MongoDB ObjectId
        if (!mongoose.Types.ObjectId.isValid(userId)) {
            return res.status(400).json({
                success: false,
                message: "Invalid user ID format",
            });
        }

        const pdfs = await PdfModel.find({ userId })
            .sort({ uploadedAt: -1 }) // Most recent first
            .select("-filePath"); // Exclude file path for security

        res.status(200).json({
            success: true,
            count: pdfs.length,
            pdfs: pdfs,
        });
    } catch (error) {
        console.error("Error fetching user PDFs:", error);
        res.status(500).json({
            success: false,
            message: "Internal server error: " + error.message,
        });
    }
};

// Get specific PDF by ID
export const getPdfById = async(req, res) => {
    try {
        const { id } = req.params;

        // Validate MongoDB ObjectId
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                success: false,
                message: "Invalid PDF ID format",
            });
        }

        const pdf = await PdfModel.findById(id).select("-filePath"); // Exclude file path

        if (!pdf) {
            return res.status(404).json({
                success: false,
                message: "PDF not found",
            });
        }

        res.status(200).json({
            success: true,
            pdf: pdf,
        });
    } catch (error) {
        console.error("Error fetching PDF:", error);
        res.status(500).json({
            success: false,
            message: "Internal server error: " + error.message,
        });
    }
};

// Delete PDF by ID
export const deletePdf = async(req, res) => {
    try {
        const { id } = req.params;

        // Validate MongoDB ObjectId
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                success: false,
                message: "Invalid PDF ID format",
            });
        }

        const pdf = await PdfModel.findById(id);

        if (!pdf) {
            return res.status(404).json({
                success: false,
                message: "PDF not found",
            });
        }

        // Delete the physical file
        try {
            if (fs.existsSync(pdf.filePath)) {
                fs.unlinkSync(pdf.filePath);
                console.log("Physical file deleted:", pdf.filePath);
            }
        } catch (fileError) {
            console.error("Error deleting physical file:", fileError);
            // Continue with database deletion even if file deletion fails
        }

        // Delete from database
        await PdfModel.findByIdAndDelete(id);

        res.status(200).json({
            success: true,
            message: "PDF deleted successfully",
        });
    } catch (error) {
        console.error("Error deleting PDF:", error);
        res.status(500).json({
            success: false,
            message: "Internal server error: " + error.message,
        });
    }
};
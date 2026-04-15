import express from "express";
import { uploadPdf, getUserPdfs, deletePdf, getPdfById } from "../../controllers/pdf_controllers/pdfController.js";
import fs from "fs";
import path from "path";

const router = express.Router();

// Test endpoint to verify route is working
router.get("/test", (req, res) => {
    res.status(200).json({
        success: true,
        message: "PDF route is working!",
        timestamp: new Date().toISOString()
    });
});

// Test endpoint for form data
router.post("/test-form", (req, res) => {
    console.log("Form test endpoint hit!");
    console.log("Headers:", req.headers);
    console.log("Body:", req.body);
    console.log("Files:", req.files);

    res.status(200).json({
        success: true,
        message: "Form data received!",
        receivedFields: req.body,
        hasFiles: !!req.files,
        timestamp: new Date().toISOString()
    });
});

// Test endpoint for n8n webhook
router.get("/test-n8n", async(req, res) => {
    try {
        const axios = (await
            import ("axios")).default;
        const FormData = (await
            import ("form-data")).default;
        const fs = (await
            import ("fs")).default;
        const path = (await
            import ("path")).default;

        console.log("Testing n8n webhook...");

        // Create a test PDF file path
        const testPdfPath = path.join(process.cwd(), "uploads", "test-pdf.pdf");
        let fileExists = false;

        // Check if test file exists
        try {
            await fs.promises.access(testPdfPath);
            fileExists = true;
        } catch (error) {
            console.log("Test PDF file not found, creating dummy file...");

            // Create directory if it doesn't exist
            await fs.promises.mkdir(path.join(process.cwd(), "uploads"), { recursive: true });

            // Create a simple PDF-like file (not a real PDF, just for testing)
            await fs.promises.writeFile(testPdfPath, "%PDF-1.5\nTest PDF file for n8n webhook");
            fileExists = true;
        }

        if (fileExists) {
            // Create form data
            const form = new FormData();
            form.append("email", "test@example.com");
            form.append("file", fs.createReadStream(testPdfPath), {
                filename: "test-pdf.pdf",
                contentType: "application/pdf"
            });

            // Send to n8n webhook
            const response = await axios.post(
                "https://dhruv-chotai-10.app.n8n.cloud/webhook/send-financial-report",
                form, {
                    headers: {
                        ...form.getHeaders(),
                        "Accept": "application/json"
                    },
                    timeout: 15000
                }
            );

            res.status(200).json({
                success: true,
                message: "n8n webhook test successful!",
                response: response.data,
                status: response.status
            });
        } else {
            res.status(500).json({
                success: false,
                message: "Could not create test PDF file"
            });
        }
    } catch (error) {
        console.error("Error testing n8n webhook:", error);
        res.status(500).json({
            success: false,
            message: "Error testing n8n webhook: " + error.message,
            error: error.toString()
        });
    }
});

// Upload PDF file
router.post("/upload", uploadPdf);

// Get all PDFs for a user
router.get("/user/:userId", getUserPdfs);

// Get specific PDF by ID
router.get("/:id", getPdfById);

// Delete PDF by ID
router.delete("/:id", deletePdf);

// Download PDF by filename
router.get("/download/:filename", async(req, res) => {
    try {
        const { filename } = req.params;

        // Sanitize the filename to prevent directory traversal attacks
        const sanitizedFilename = path.basename(filename);

        // Construct the file path
        const filePath = path.join(process.cwd(), "uploads", "pdfs", sanitizedFilename);

        console.log(`Download request for file: ${sanitizedFilename}`);
        console.log(`Looking for file at: ${filePath}`);

        // Check if file exists
        if (!fs.existsSync(filePath)) {
            console.error(`File not found: ${filePath}`);
            return res.status(404).json({
                success: false,
                message: "File not found"
            });
        }

        // Get file information
        const stat = fs.statSync(filePath);

        // Set response headers
        res.setHeader('Content-Length', stat.size);
        res.setHeader('Content-Type', 'application/pdf');
        res.setHeader('Content-Disposition', `attachment; filename=${sanitizedFilename}`);

        // Stream the file to the response
        const fileStream = fs.createReadStream(filePath);
        fileStream.pipe(res);

        console.log(`File download started: ${sanitizedFilename}`);
    } catch (error) {
        console.error(`Error downloading file: ${error.message}`);
        res.status(500).json({
            success: false,
            message: "Error downloading file: " + error.message
        });
    }
});

export default router;
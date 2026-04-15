import axios from 'axios';
import FormData from 'form-data';
import fs from 'fs';
import path from 'path';

// Create a simple test PDF file
const createTestPdf = async() => {
    const testDir = path.join(process.cwd(), 'test-files');
    const testPdfPath = path.join(testDir, 'test-webhook.pdf');

    // Create directory if it doesn't exist
    if (!fs.existsSync(testDir)) {
        fs.mkdirSync(testDir, { recursive: true });
    }

    // Create a simple PDF-like file
    fs.writeFileSync(testPdfPath, '%PDF-1.5\nThis is a test PDF file for n8n webhook testing.\n');

    console.log(`Test PDF created at: ${testPdfPath}`);
    return testPdfPath;
};

// Test the webhook directly
const testWebhookDirectly = async() => {
    try {
        console.log('Testing n8n webhook directly...');

        // Create test PDF file
        const testPdfPath = await createTestPdf();
        console.log(`File exists: ${fs.existsSync(testPdfPath)}`);
        console.log(`File size: ${fs.statSync(testPdfPath).size} bytes`);

        // Read file as base64
        const fileBuffer = fs.readFileSync(testPdfPath);
        const fileBase64 = fileBuffer.toString('base64');

        console.log('File converted to base64');
        console.log('Base64 length:', fileBase64.length);

        // Send to n8n webhook
        console.log('Sending request to n8n webhook...');
        // Use the correct webhook URL from n8n (Production URL)
        const webhookUrl = 'https://dhruv-chotai-10.app.n8n.cloud/webhook-test/send-financial-report';

        const response = await axios.post(
            webhookUrl, {
                email: 'test@example.com',
                filename: 'test-webhook.pdf',
                fileType: 'application/pdf',
                fileSize: fs.statSync(testPdfPath).size,
                fileData: fileBase64,
                uploadTime: new Date().toISOString(),
                financialData: {
                    totalIncome: 1000,
                    totalExpenses: 500,
                    netAmount: 500
                }
            }, {
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                timeout: 30000
            }
        );

        console.log('✅ Webhook triggered successfully!');
        console.log('Status:', response.status);
        console.log('Response:', response.data);

    } catch (error) {
        console.error('❌ Error testing webhook:', error.message);
        if (error.response) {
            console.error('Status:', error.response.status);
            console.error('Data:', error.response.data);
        } else {
            console.error('Full error:', error);
        }
    }
};

// Run the test
testWebhookDirectly();
import axios from 'axios';
import fs from 'fs';
import path from 'path';

const BASE_URL = 'https://ml-based-personal-finance-optimizer.onrender.com';

// Test the download endpoint
const testDownloadEndpoint = async() => {
    try {
        console.log('Testing PDF download endpoint...');

        // First, create a test PDF file
        const testDir = path.join(process.cwd(), 'uploads', 'pdfs');
        const testFileName = `test-download-${Date.now()}.pdf`;
        const testFilePath = path.join(testDir, testFileName);

        // Create directory if it doesn't exist
        if (!fs.existsSync(testDir)) {
            fs.mkdirSync(testDir, { recursive: true });
            console.log(`Created directory: ${testDir}`);
        }

        // Create a simple PDF-like file
        fs.writeFileSync(testFilePath, '%PDF-1.5\nThis is a test PDF file for download testing.\n');
        console.log(`Created test file: ${testFilePath}`);

        // Construct download URL
        const downloadUrl = `${BASE_URL}/api/pdf/download/${testFileName}`;
        console.log(`Download URL: ${downloadUrl}`);

        // Test the download endpoint
        console.log('Sending GET request to download endpoint...');
        const response = await axios.get(downloadUrl, {
            responseType: 'arraybuffer'
        });

        // Save the downloaded file
        const downloadedFilePath = path.join(process.cwd(), 'test-files', 'downloaded.pdf');

        // Create directory if it doesn't exist
        if (!fs.existsSync(path.dirname(downloadedFilePath))) {
            fs.mkdirSync(path.dirname(downloadedFilePath), { recursive: true });
        }

        fs.writeFileSync(downloadedFilePath, response.data);

        console.log('✅ Download successful!');
        console.log(`Downloaded file saved to: ${downloadedFilePath}`);
        console.log(`File size: ${fs.statSync(downloadedFilePath).size} bytes`);

    } catch (error) {
        console.error('❌ Error testing download endpoint:', error.message);
        if (error.response) {
            console.error('Status:', error.response.status);
            console.error('Data:', error.response.data);
        } else {
            console.error('Full error:', error);
        }
    }
};

// Run the test
testDownloadEndpoint();
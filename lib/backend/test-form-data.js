import axios from 'axios';
import FormData from 'form-data';
import fs from 'fs';
import path from 'path';

const BASE_URL = 'https://ml-based-personal-finance-optimizer.onrender.com';

async function testFormData() {
    try {
        console.log('Testing form data submission...\n');

        // Create a simple PDF file for testing
        const testPdfPath = path.join(process.cwd(), 'test-pdf.pdf');

        // Create form data
        const form = new FormData();
        form.append('userId', '12345');
        form.append('totalIncome', '1000');
        form.append('totalExpenses', '500');
        form.append('netAmount', '500');
        form.append('_appData', 'true');

        // Add test file if it exists, otherwise skip file upload
        if (fs.existsSync(testPdfPath)) {
            form.append('file', fs.createReadStream(testPdfPath));
            console.log('Added test PDF file to form data');
        } else {
            console.log('No test PDF file found, skipping file upload');
        }

        console.log('Form data created with fields:', {
            userId: '12345',
            totalIncome: '1000',
            totalExpenses: '500',
            netAmount: '500',
            _appData: 'true'
        });

        // Send the form data
        console.log('Sending form data to server...');
        const response = await axios.post(`${BASE_URL}/api/pdf/test-form`, form, {
            headers: {
                ...form.getHeaders(),
            },
        });

        console.log('✅ Server response:', response.data);
        console.log('\n🎉 Form data test completed successfully!');

    } catch (error) {
        console.error('❌ Test failed:', error.message);
        if (error.response) {
            console.error('Status:', error.response.status);
            console.error('Data:', error.response.data);
        }
    }
}

testFormData();
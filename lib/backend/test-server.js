import axios from 'axios';

const BASE_URL = 'https://ml-based-personal-finance-optimizer.onrender.com';

async function testServer() {
    try {
        console.log('Testing server...');

        // Test health endpoint
        const healthResponse = await axios.get(`${BASE_URL}/health`);
        console.log('✅ Health check passed:', healthResponse.data);

        // Test PDF test endpoint
        const pdfTestResponse = await axios.get(`${BASE_URL}/api/pdf/test`);
        console.log('✅ PDF test endpoint passed:', pdfTestResponse.data);

        console.log('🎉 Server is working correctly!');

    } catch (error) {
        console.error('❌ Server test failed:', error.message);
        if (error.response) {
            console.error('Status:', error.response.status);
            console.error('Data:', error.response.data);
        }
    }
}

testServer();
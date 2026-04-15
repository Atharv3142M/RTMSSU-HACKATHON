import axios from 'axios';
import FormData from 'form-data';
import fs from 'fs';
import path from 'path';

const BASE_URL = 'https://ml-based-personal-finance-optimizer.onrender.com';

async function testN8nWebhook() {
    try {
        console.log('Testing n8n webhook integration...\n');

        // First, test if the server is up
        console.log('1. Testing server health...');
        const healthResponse = await axios.get(`${BASE_URL}/health`);
        console.log('✅ Server is up:', healthResponse.data);

        // Test the n8n webhook test endpoint
        console.log('\n2. Testing n8n webhook endpoint...');
        const n8nTestResponse = await axios.get(`${BASE_URL}/api/pdf/test-n8n`);
        console.log('✅ n8n webhook test successful!');
        console.log('Response:', n8nTestResponse.data);

        console.log('\n🎉 n8n webhook integration test completed successfully!');

    } catch (error) {
        console.error('❌ Test failed:', error.message);
        if (error.response) {
            console.error('Status:', error.response.status);
            console.error('Data:', error.response.data);
        }
    }
}

testN8nWebhook();
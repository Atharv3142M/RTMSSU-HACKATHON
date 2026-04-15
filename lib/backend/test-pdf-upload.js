import axios from 'axios';
import FormData from 'form-data';
import fs from 'fs';
import path from 'path';

const BASE_URL = 'https://ml-based-personal-finance-optimizer.onrender.com';

async function testPdfUpload() {
    try {
        console.log('Testing PDF upload...\n');

        // Test health endpoint first
        console.log('1. Testing health endpoint...');
        const healthResponse = await axios.get(`${BASE_URL}/health`);
        console.log('✅ Health check passed:', healthResponse.data);

        // Test PDF test endpoint
        console.log('\n2. Testing PDF test endpoint...');
        const pdfTestResponse = await axios.get(`${BASE_URL}/api/pdf/test`);
        console.log('✅ PDF test endpoint passed:', pdfTestResponse.data);

        // Test simple GET endpoint
        console.log('\n3. Testing simple test endpoint...');
        const simpleTestResponse = await axios.get(`${BASE_URL}/test-pdf`);
        console.log('✅ Simple test endpoint passed:', simpleTestResponse.data);

        console.log('\n🎉 All endpoints are working! Server is ready for PDF uploads.');

    } catch (error) {
        console.error('❌ Test failed:', error.message);
        if (error.response) {
            console.error('Status:', error.response.status);
            console.error('Data:', error.response.data);
        }
    }
}

testPdfUpload();
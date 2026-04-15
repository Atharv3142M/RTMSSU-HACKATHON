// import axios from 'axios';

// // Test the n8n webhook with minimal data
// const testMinimalWebhook = async() => {
//     try {
//         console.log('Testing n8n webhook with minimal data...');

//         // Use the correct webhook URL from n8n
//         const webhookUrl = 'https://dhruv-chotai-10.app.n8n.cloud/webhook-test/send-financial-report';

//         // Send a simple JSON payload (no file)
//         const response = await axios.post(
//             webhookUrl, {
//                 email: 'test@example.com',
//                 message: 'This is a test message',
//                 timestamp: new Date().toISOString()
//             }, {
//                 headers: {
//                     'Content-Type': 'application/json',
//                     'Accept': 'application/json'
//                 },
//                 timeout: 10000
//             }
//         );

//         console.log('✅ Webhook triggered successfully!');
//         console.log('Status:', response.status);
//         console.log('Response:', response.data);

//     } catch (error) {
//         console.error('❌ Error testing webhook:', error.message);
//         if (error.response) {
//             console.error('Status:', error.response.status);
//             console.error('Data:', error.response.data);
//         } else {
//             console.error('Full error:', error);
//         }
//     }
// };

// // Run the test
// testMinimalWebhook();
// import axios from 'axios';

// // Use the correct webhook URL from n8n (Production URL)
// const webhookUrl = 'https://dhruv-chotai-10.app.n8n.cloud/webhook-test/send-financial-report';

// // Test if the webhook endpoint is accessible
// const checkWebhookStatus = async() => {
//     try {
//         console.log(`Testing webhook endpoint: ${webhookUrl}`);

//         // First, try a simple OPTIONS request to check CORS
//         console.log('Testing CORS with OPTIONS request...');
//         try {
//             const optionsResponse = await axios({
//                 method: 'OPTIONS',
//                 url: webhookUrl,
//                 headers: {
//                     'Origin': 'https://ml-based-personal-finance-optimizer.onrender.com'
//                 }
//             });
//             console.log('✅ OPTIONS request successful');
//             console.log('Status:', optionsResponse.status);
//             console.log('Headers:', optionsResponse.headers);
//         } catch (corsError) {
//             console.error('❌ OPTIONS request failed:', corsError.message);
//             if (corsError.response) {
//                 console.error('Status:', corsError.response.status);
//                 console.error('Headers:', corsError.response.headers);
//             }
//         }

//         // Try a simple GET request to check if endpoint exists
//         console.log('\nTesting with GET request...');
//         try {
//             const getResponse = await axios.get(webhookUrl);
//             console.log('✅ GET request successful');
//             console.log('Status:', getResponse.status);
//             console.log('Response:', getResponse.data);
//         } catch (getError) {
//             console.error('❌ GET request failed:', getError.message);
//             if (getError.response) {
//                 console.error('Status:', getError.response.status);
//                 console.error('Data:', getError.response.data);

//                 // This might be normal - n8n webhooks often only accept POST
//                 if (getError.response.status === 405) {
//                     console.log('✅ This is normal - n8n webhooks typically only accept POST requests');
//                 }
//             }
//         }

//         // Try a simple POST request with minimal data
//         console.log('\nTesting with simple POST request...');
//         try {
//             const postResponse = await axios.post(webhookUrl, {
//                 test: true,
//                 message: 'Testing webhook accessibility'
//             });
//             console.log('✅ POST request successful');
//             console.log('Status:', postResponse.status);
//             console.log('Response:', postResponse.data);
//         } catch (postError) {
//             console.error('❌ POST request failed:', postError.message);
//             if (postError.response) {
//                 console.error('Status:', postError.response.status);
//                 console.error('Data:', postError.response.data);
//             }
//         }

//         console.log('\nWebhook status check complete');

//     } catch (error) {
//         console.error('❌ Error checking webhook status:', error.message);
//     }
// };

// // Run the test
// checkWebhookStatus();
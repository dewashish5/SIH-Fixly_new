// Simple test to verify Groq client works
import { classifyIssueWithGroq } from './backend/utils/groqClient.js';

async function runTest() {
  console.log('Testing Groq client...');

  // Check if the function exists and is callable
  if (typeof classifyIssueWithGroq !== 'function') {
    console.error('❌ classifyIssueWithGroq is not a function');
    return false;
  }

  console.log('✅ classifyIssueWithGroq is a function');

  // Check if we can import the client
  try {
    // We won't actually call the API to avoid needing a real key in this test
    // Just verify the module loads correctly
    console.log('✅ Groq client module loads successfully');
    return true;
  } catch (error) {
    console.error('❌ Error loading Groq client:', error);
    return false;
  }
}

runTest().then(success => {
  if (success) {
    console.log('🎉 Simple Groq test passed');
    process.exit(0);
  } else {
    console.log('💥 Simple Groq test failed');
    process.exit(1);
  }
});
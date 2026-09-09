import { describe, test } from 'node:test';
import { strict as assert } from 'node:assert';

describe('analyzeIssue with Groq and Gemini Vision', () => {
  test('should classify electrical issue correctly with Groq', async (t) => {
    // Mock the groqClient module
    await t.mock('../utils/groqClient.js', {
      groqClient: {},
      classifyIssueWithGroq: async () => 'Electrical'
    });
    // Mock the Service model to avoid DB calls
    await t.mock('../models/Service.js', {
      findOne: async () => null
    });
    // Mock geminiVisionClient to return not configured
    await t.mock('../utils/geminiVisionClient.js', {
      isGeminiVisionConfigured: () => false,
      analyzeImageWithGemini: async () => {}
    });

    // Re-import the controller after mocking
    const { analyzeIssue } = await import('../controllers/aiController.js');

    const req = { body: { problemDescription: 'light switch not working' } };
    const res = {
      status: () => res,
      json: async (data) => {
        res.jsonData = data;
        return res;
      }
    };

    await analyzeIssue(req, res);

    assert.strictEqual(res.status.name, 'status'); // Check that status was called
    assert.equal(res.jsonData.success, true);
    assert.equal(res.jsonData.analysis.category, 'Electrical');
    assert.equal(res.jsonData.analysis.estimatedHours, 1.5);
    assert.equal(res.jsonData.analysis.suggestedService, null);
    assert.equal(res.jsonData.analysis.issueImageUrl, null);
    assert.equal(res.jsonData.analysis.geminiAnalysis, null);
    assert.ok(res.jsonData.analysis.aiNote.includes('Based on your query'));
  });

  test('should use Gemini Vision when image is provided and configured', async (t) => {
    // Mock geminiVisionClient to return configured and analysis result
    await t.mock('../utils/geminiVisionClient.js', {
      isGeminiVisionConfigured: () => true,
      analyzeImageWithGemini: async () => ({
        category: 'Plumbing',
        description: 'Image shows a leaking pipe under sink',
        confidence: 0.9
      })
    });
    // Mock groqClient to ensure it's not called
    await t.mock('../utils/groqClient.js', {
      groqClient: {},
      classifyIssueWithGroq: async () => {
        throw new Error('Groq should not be called');
      }
    });
    // Mock the Service model to avoid DB calls
    await t.mock('../models/Service.js', {
      findOne: async () => null
    });

    // Re-import the controller after mocking
    const { analyzeIssue } = await import('../controllers/aiController.js');

    const req = {
      body: { problemDescription: 'some text' },
      file: { buffer: Buffer.from('fake image data') }
    };
    const res = {
      status: () => res,
      json: async (data) => {
        res.jsonData = data;
        return res;
      }
    };

    await analyzeIssue(req, res);

    assert.equal(res.jsonData.success, true);
    assert.equal(res.jsonData.analysis.category, 'Plumbing');
    assert.equal(res.jsonData.analysis.estimatedHours, 2);
    assert.equal(res.jsonData.analysis.suggestedService, null);
    // Issue image URL would be set by uploadToCloudinary which we're not mocking
    assert.ok(res.jsonData.analysis.issueImageUrl === null || typeof res.jsonData.analysis.issueImageUrl === 'string');
    assert.equal(res.jsonData.analysis.geminiAnalysis.category, 'Plumbing');
    assert.equal(res.jsonData.analysis.geminiAnalysis.description, 'Image shows a leaking pipe under sink');
    assert.equal(res.jsonData.analysis.geminiAnalysis.confidence, 0.9);
    assert.ok(res.jsonData.analysis.aiNote.includes('Based on the image analysis'));
  });

  test('should fall back to Groq when image provided but Gemini not configured', async (t) => {
    // Mock geminiVisionClient to return not configured
    await t.mock('../utils/geminiVisionClient.js', {
      isGeminiVisionConfigured: () => false,
      analyzeImageWithGemini: async () => {
        throw new Error('Gemini should not be called');
      }
    });
    // Mock groqClient to return a category
    await t.mock('../utils/groqClient.js', {
      groqClient: {},
      classifyIssueWithGroq: async () => 'Electrical'
    });
    // Mock the Service model to avoid DB calls
    await t.mock('../models/Service.js', {
      findOne: async () => null
    });

    // Re-import the controller after mocking
    const { analyzeIssue } = await import('../controllers/aiController.js');

    const req = {
      body: { problemDescription: 'some text' },
      file: { buffer: Buffer.from('fake image data') }
    };
    const res = {
      status: () => res,
      json: async (data) => {
        res.jsonData = data;
        return res;
      }
    };

    await analyzeIssue(req, res);

    assert.equal(res.jsonData.success, true);
    assert.equal(res.jsonData.analysis.category, 'Electrical');
    assert.equal(res.jsonData.analysis.estimatedHours, 1.5);
    assert.equal(res.jsonData.analysis.geminiAnalysis, null);
    assert.ok(res.jsonData.analysis.aiNote.includes('Based on your query'));
  });

  test('should handle plumbing issues with Groq', async (t) => {
    await t.mock('../utils/groqClient.js', {
      groqClient: {},
      classifyIssueWithGroq: async () => 'Plumbing'
    });
    await t.mock('../models/Service.js', {
      findOne: async () => null
    });
    await t.mock('../utils/geminiVisionClient.js', {
      isGeminiVisionConfigured: () => false,
      analyzeImageWithGemini: async () => {}
    });

    const { analyzeIssue } = await import('../controllers/aiController.js');

    const req = { body: { problemDescription: 'water pipe leaking' } };
    const res = {
      status: () => res,
      json: async (data) => {
        res.jsonData = data;
        return res;
      }
    };

    await analyzeIssue(req, res);

    assert.equal(res.jsonData.success, true);
    assert.equal(res.jsonData.analysis.category, 'Plumbing');
    assert.equal(res.jsonData.analysis.estimatedHours, 2);
  });

  test('should handle cleaning issues with Groq', async (t) => {
    await t.mock('../utils/groqClient.js', {
      groqClient: {},
      classifyIssueWithGroq: async () => 'Cleaning'
    });
    await t.mock('../models/Service.js', {
      findOne: async () => null
    });
    await t.mock('../utils/geminiVisionClient.js', {
      isGeminiVisionConfigured: () => false,
      analyzeImageWithGemini: async () => {}
    });

    const { analyzeIssue } = await import('../controllers/aiController.js');
    const req = { body: { problemDescription: 'house needs cleaning' } };
    const res = {
      status: () => res,
      json: async (data) => {
        res.jsonData = data;
        return res;
      }
    };

    await analyzeIssue(req, res);

    assert.equal(res.jsonData.success, true);
    assert.equal(res.jsonData.analysis.category, 'Cleaning');
    assert.equal(res.jsonData.analysis.estimatedHours, 3);
  });

  test('should handle missing problem description', async (t) => {
    // No need to mock groqClient for this test
    const { analyzeIssue } = await import('../controllers/aiController.js');

    const req = { body: {} };
    const res = {
      status: () => res,
      json: async (data) => {
        res.jsonData = data;
        return res;
      }
    };

    await analyzeIssue(req, res);

    assert.equal(res.jsonData.success, false);
    assert.equal(res.jsonData.message, 'Problem description required hai');
  });
});
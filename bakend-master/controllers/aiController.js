import Service from '../models/Service.js';

// Screen 4: AI Issue Analyzer
export const analyzeIssue = async (req, res) => {
    try {
        const { problemDescription } = req.body;
        if (!problemDescription) {
            return res.status(400).json({ success: false, message: 'Problem description required hai' });
        }

        const text = problemDescription.toLowerCase();
        let detectedCategory = 'Plumbing';
        let estimatedHours = 1;

        if (text.includes('wire') || text.includes('spark') || text.includes('switch') || text.includes('light')) {
            detectedCategory = 'Electrical';
            estimatedHours = 1.5;
        } else if (text.includes('pipe') || text.includes('leak') || text.includes('tap') || text.includes('water')) {
            detectedCategory = 'Plumbing';
            estimatedHours = 2;
        } else if (text.includes('clean') || text.includes('dust') || text.includes('sofa')) {
            detectedCategory = 'Cleaning';
            estimatedHours = 3;
        }

        const suggestedService = await Service.findOne({ category: detectedCategory, isActive: true }).lean();

        return res.status(200).json({
            success: true,
            analysis: {
                category: detectedCategory,
                estimatedHours,
                suggestedService: suggestedService || null,
                aiNote: `Based on your query "${problemDescription}", we recommend a ${detectedCategory} specialist.`
            }
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
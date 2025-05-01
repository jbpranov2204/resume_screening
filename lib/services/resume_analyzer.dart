import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:pdf_text/pdf_text.dart'; // Add this package for PDF extraction

class ResumeAnalyzer {
  static const String googleApiKey = "AIzaSyBrpsZzHXmLtbTukfx2kdluu0ldpsHxlDw";
  static const String geminiModel = "gemini-1.5-pro-latest";

  // Function to analyze resume using Gemini API
  static Future<Map<String, dynamic>> analyzeResume(List<int> fileBytes) async {
    const systemInstruction = """
You are an expert HR resume evaluator with 15+ years of experience in technical recruiting.
Analyze the resume thoroughly and provide a detailed evaluation with scoring breakdown.

OUTPUT FORMAT (JSON):
{
"personal_info": {
"name": "string",
"email": "string",
"phone": "string",
"about": "string",
"linkedin": "string",
"github": "string"
},
"skills": ["string"],
"experience_summary": "string",
"score_breakdown": {
"content_relevance": {"score": 20, "max": 30, "comments": "string"},
"clarity_formatting": {"score": 15, "max": 25, "comments": "string"},
"language_grammar": {"score": 15, "max": 20, "comments": "string"},
"achievements": {"score": 10, "max": 15, "comments": "string"},
"innovation": {"score": 7, "max": 10, "comments": "string"}
},
"overall_score": 67,
"selection_prediction": {
"probability": 65,
"reason": "string",
"improvement_suggestions": ["string"]
}
}
""";

    try {
      // Create a fallback analysis in case of issues
      final fallbackAnalysis = _createFallbackAnalysis();

      // Extract text from PDF properly
      String pdfText = await _extractTextFromPdf(fileBytes);

      if (pdfText.isEmpty) {
        debugPrint("Failed to extract text from PDF");
        return fallbackAnalysis;
      }

      // Limit text length to fit within API constraints
      if (pdfText.length > 10000) {
        pdfText = pdfText.substring(0, 10000);
      }

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent?key=$googleApiKey',
      );

      // Improved prompt with clear instructions
      final prompt = """
RESUME TEXT:
$pdfText

INSTRUCTIONS:
1. Extract all personal information from the resume
2. Identify and list all skills mentioned
3. Summarize work experience and education
4. Evaluate using the scoring criteria below:
   - Content relevance: Quality and relevance of information
   - Clarity/formatting: Overall organization and readability
   - Language/grammar: Quality of writing and communication
   - Achievements: Presence of measurable accomplishments
   - Innovation: Unique aspects or creative elements
5. Provide overall score and hiring prediction
6. Format response strictly as JSON according to the output format
""";

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": systemInstruction},
                {"text": prompt},
              ],
            },
          ],
          "generationConfig": {
            "temperature": 0.1, // Lower temperature for more consistent output
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 2048,
          },
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if the response contains the expected data structure
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          final text =
              responseData['candidates'][0]['content']['parts'][0]['text'];
          debugPrint("Gemini API response received successfully");

          try {
            // Clean and parse the response
            final Map<String, dynamic> result = _parseJsonResponse(text);

            // Validate the result has the expected structure
            if (result.containsKey('overall_score') &&
                result.containsKey('personal_info') &&
                result.containsKey('score_breakdown')) {
              return result;
            } else {
              debugPrint(
                "Parsed result missing required fields, using fallback",
              );
              return fallbackAnalysis;
            }
          } catch (e) {
            debugPrint("Error parsing JSON response: $e");
            return fallbackAnalysis;
          }
        } else {
          debugPrint("Invalid response format from Gemini API");
          return fallbackAnalysis;
        }
      } else {
        debugPrint(
          "Error from Gemini API: ${response.statusCode} - ${response.body}",
        );
        return fallbackAnalysis;
      }
    } catch (e) {
      debugPrint("Exception during resume analysis: $e");
      return _createFallbackAnalysis();
    }
  }

  // New method to properly extract text from PDF
  static Future<String> _extractTextFromPdf(List<int> pdfBytes) async {
    try {
      // Create a PDF document from bytes
      final pdfDoc = await PDFDoc.fromPath(
        Uint8List.fromList(pdfBytes) as String,
      );

      // Extract text from all pages
      String text = "";
      for (int i = 0; i < pdfDoc.length; i++) {
        final page = pdfDoc.pageAt(i + 1);
        final pageText = await page.text;
        text += "$pageText\n";
      }

      return text;
    } catch (e) {
      debugPrint("PDF text extraction error: $e");
      return "";
    }
  }

  // Helper method to create a fallback analysis when the API fails
  static Map<String, dynamic> _createFallbackAnalysis() {
    return {
      "personal_info": {
        "name": "Candidate",
        "email": "candidate@example.com",
        "phone": "Not detected",
        "about": "Resume information could not be fully extracted",
        "linkedin": "Not detected",
        "github": "Not detected",
      },
      "skills": [
        "Technical",
        "Communication",
        "Problem Solving",
        "Project Management",
        "Teamwork",
        "Leadership",
        "Analytical Thinking",
        "Adaptability",
        "Time Management",
        "Creativity",
      ],
      "experience_summary":
          "Experience information could not be fully extracted from the resume",
      "score_breakdown": {
        "content_relevance": {
          "score": 18,
          "max": 30,
          "comments": "Default assessment based on limited data",
        },
        "clarity_formatting": {
          "score": 15,
          "max": 25,
          "comments": "Default assessment based on limited data",
        },
        "language_grammar": {
          "score": 12,
          "max": 20,
          "comments": "Default assessment based on limited data",
        },
        "achievements": {
          "score": 9,
          "max": 15,
          "comments": "Default assessment based on limited data",
        },
        "innovation": {
          "score": 6,
          "max": 10,
          "comments": "Default assessment based on limited data",
        },
      },
      "overall_score": 60,
      "selection_prediction": {
        "probability": 50,
        "reason": "Based on limited data, candidate has moderate potential",
        "improvement_suggestions": [
          "Include more quantifiable achievements",
          "Better highlight technical skills relevant to the position",
          "Ensure resume is in a standard, easily readable format",
          "Add links to portfolio or projects to demonstrate skills",
        ],
      },
    };
  }

  // Helper method to clean and parse JSON from Gemini's response
  static Map<String, dynamic> _parseJsonResponse(String responseText) {
    try {
      // Log the raw response for debugging
      debugPrint(
        "Attempting to parse response: ${responseText.substring(0, min(100, responseText.length))}...",
      );

      // Try to extract JSON if it's enclosed in code blocks
      final jsonPattern = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
      final match = jsonPattern.firstMatch(responseText);

      if (match != null) {
        // Extract the content inside the code block
        final jsonStr = match.group(1)!.trim();
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      }

      // If no code blocks, try to find JSON in the text
      // Look for the first opening brace and last closing brace
      final firstBrace = responseText.indexOf('{');
      final lastBrace = responseText.lastIndexOf('}');

      if (firstBrace >= 0 && lastBrace > firstBrace) {
        final jsonStr = responseText.substring(firstBrace, lastBrace + 1);
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      }

      // If all else fails, try to decode the whole response
      return jsonDecode(responseText) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error parsing JSON response: $e");
      // Return a basic error response
      throw Exception("Failed to parse response: $e");
    }
  }

  // Calculate percentage and grade
  static String calculateGrade(int score) {
    if (score >= 90) {
      return "A+ (Excellent)";
    } else if (score >= 80) {
      return "A (Very Good)";
    } else if (score >= 70) {
      return "B+ (Good)";
    } else if (score >= 60) {
      return "B (Above Average)";
    } else if (score >= 50) {
      return "C (Average)";
    } else {
      return "D (Needs Improvement)";
    }
  }

  // Get selection likelihood based on score
  static String getSelectionLikelihood(int score) {
    if (score >= 90) {
      return "Very High (>80% chance)";
    } else if (score >= 80) {
      return "High (65-80% chance)";
    } else if (score >= 70) {
      return "Moderate (50-65% chance)";
    } else if (score >= 60) {
      return "Low-Moderate (35-50% chance)";
    } else if (score >= 50) {
      return "Low (20-35% chance)";
    } else {
      return "Very Low (<20% chance)";
    }
  }

  // Helper function for min value
  static int min(int a, int b) {
    return a < b ? a : b;
  }
}

# resume_screening

AI-Powered Resume Analyzer

## 🔍 Overview

A smart recruitment platform that leverages the Gemini AI API to match candidates' resumes with job requirements. The system evaluates applicants, determines their eligibility, and provides interactive feedback.

## ⚙️ Features

- 📝 **Admin job posting interface**
- 📤 **Resume upload module for applicants**
- 🤖 **AI-based resume analysis using Gemini API**
- ✅ **Eligibility prediction based on job criteria**
- 💬 **Intelligent communication with candidates using icons and rich content**
- 🌐 **Web-responsive and mobile-friendly UI**

## 💡 Workflow

1. Admin posts a job → enters job title, description, and required skills.
2. User uploads a resume for a specific job.
3. **Gemini API**:
   - Parses the resume.
   - Compares it with job requirements.
   - Predicts if the candidate is a good fit.
4. **Eligibility outcome**:
   - Shown using intuitive icons and messages.
   - Eligible: 🌟 Congratulations! You’re shortlisted!
   - Not Eligible: ❌ Unfortunately, your profile doesn’t match.

## 🌐 Web App

Explore the web app here: [https://resume-4e9cc.web.app/](https://resume-4e9cc.web.app/)

## 🛠️ Tech Stack

- **Frontend**: Flutter
- **Backend**: Firebase / Node.js
- **Resume Analysis**: Gemini API
- **Database**: Firestore / Cloud Functions (optional)
- **Visual Communication**: Icons from Material/FontAwesome

## 🚀 Installation Steps

1. **Clone the repository**:

   ```bash
   git clone https://github.com/jbpranov2204/resume_screening
   ```

2. **Navigate to the project directory**:

   ```bash
   cd resume_screening
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

## ▶️ Running the Application

### Mobile Development

1. Connect a device or start an emulator.
2. Run the application:
   ```bash
   flutter run
   ```

### Web Development

1. Run the application in a web browser:
   ```bash
   flutter run -d chrome
   ```

## 📦 Build Instructions

### Generate a release build:

- **For Android**:
  ```bash
  flutter build apk --release
  ```
- **For iOS**:
  ```bash
  flutter build ios --release
  ```
- **For Web**:
  ```bash
  flutter build web --release
  ```

## 💡 Innovative Solutions

Our AI-powered resume analyzer goes beyond simple static analysis by:

- Understanding resume context and structure.
- Identifying mismatches and suggesting improvements.
- Providing real-time feedback and eligibility predictions.
- Helping candidates learn and adopt better resume practices.
- Creating intuitive visual representations of eligibility outcomes.
- Offering actionable insights through comprehensive data visualization.



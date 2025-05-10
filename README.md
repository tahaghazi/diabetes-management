# 🩺 Diabetes Management

A **smart, AI-powered mobile application** that helps individuals manage diabetes efficiently. The app enables real-time health tracking, personalized reminders, emergency alerts, and seamless doctor-patient communication — all in one intuitive platform.

---

## 🚀 Features

* **📊 Blood Sugar Monitoring**
  Log and analyze glucose levels and upload lab reports or blood test images.

* **⏰ Personalized Reminders**
  Custom alerts for medication schedules, insulin doses water intake.

* **👨‍⚕️ Doctor-Patient Interaction**
  A structured follow-up system where doctors can monitor their connected patients, view health updates, and send personalized advice or guidance based on the patient’s condition.

* **🤖 AI-Powered Risk Prediction**
  Advanced machine learning models support two key areas:

   - Diabetes Risk Prediction: Analyze user health metrics to assess the likelihood of developing diabetes and provide preventive recommendations.

   - Alternative Medication Suggestions: Offer AI-driven alternatives for prescribed medications based on availability, affordability, or user-specific considerations — enhancing treatment flexibility.



---

## 🛠️ Tech Stack

* **Frontend:** Flutter
* **Backend:** Django + Django REST Framework
* **AI/ML:** Machine Learning for risk prediction
* **Database:** PostgreSQL / SQLite (development)
* **Authentication:** JWT (via dj-rest-auth & allauth)
---

## 📦 Installation & Setup

### 🔁 Clone the Repository

```bash
git clone https://github.com/mohamedmostafa33/diabetes-management.git
cd diabetes-management
```

### 📱 Flutter Frontend

```bash
cd flutter
flutter pub get
flutter run
```

### 🖥️ Django Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

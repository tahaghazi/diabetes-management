import pickle
import pandas as pd
import numpy as np
import os

# Get the base directory of the Django project
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Load the trained model and scaler
try:
    with open(os.path.join(BASE_DIR, "models", "diabetes.pkl"), "rb") as file:
        model = pickle.load(file)
    with open(os.path.join(BASE_DIR, "models", "scaler.pkl"), "rb") as file:
        scaler = pickle.load(file)
except FileNotFoundError:
    raise FileNotFoundError("Model or scaler file not found. Ensure 'diabetes.pkl' and 'scaler.pkl' are in the 'models' directory.")

# Define the feature columns (same as in training)
numerical_cols = ['Pregnancies', 'Glucose', 'BloodPressure', 'SkinThickness', 'Insulin', 
                  'BMI', 'DiabetesPedigreeFunction', 'Age']
categorical_cols = ['NewBMI_Obesity 1', 'NewBMI_Obesity 2', 'NewBMI_Obesity 3', 
                   'NewBMI_Overweight', 'NewBMI_Underweight', 'NewInsulinScore_Normal', 
                   'NewGlucose_Low', 'NewGlucose_Normal', 'NewGlucose_Overweight', 'NewGlucose_Secret']

# Function to preprocess the input data
def preprocess_input(data):
    df = pd.DataFrame([data])
    
    # Create categorical features
    bmi = df['BMI'].iloc[0]
    df['NewBMI_Obesity 1'] = 1 if 29.9 < bmi <= 34.9 else 0
    df['NewBMI_Obesity 2'] = 1 if 34.9 < bmi <= 39.9 else 0
    df['NewBMI_Obesity 3'] = 1 if bmi > 39.9 else 0
    df['NewBMI_Overweight'] = 1 if 24.9 < bmi <= 29.9 else 0
    df['NewBMI_Underweight'] = 1 if bmi < 18.5 else 0
    
    insulin = df['Insulin'].iloc[0]
    df['NewInsulinScore_Normal'] = 1 if 16 <= insulin <= 166 else 0
    
    glucose = df['Glucose'].iloc[0]
    df['NewGlucose_Low'] = 1 if glucose <= 70 else 0
    df['NewGlucose_Normal'] = 1 if 70 < glucose <= 99 else 0
    df['NewGlucose_Overweight'] = 1 if 99 < glucose <= 126 else 0
    df['NewGlucose_Secret'] = 1 if glucose > 126 else 0
    
    # Ensure all expected columns are present
    for col in categorical_cols:
        if col not in df.columns:
            df[col] = 0
    
    # Reorder columns to match training data
    df = df[numerical_cols + categorical_cols]
    
    return df

# Function to scale numerical features
def scale_features(df):
    # Scale numerical features
    numerical_data = df[numerical_cols]
    scaled_data = scaler.transform(numerical_data)
    # Combine scaled numerical features with categorical features
    scaled_df = np.hstack([scaled_data, df[categorical_cols].values])
    return scaled_df

# Function to predict diabetes
def predict_diabetes(data):
    processed_data = preprocess_input(data)
    scaled_data = scale_features(processed_data)
    
    # Make prediction
    prediction = model.predict(scaled_data)
    probability = model.predict_proba(scaled_data)[0]
    
    # Prepare the result
    result = "Positive" if prediction[0] == 1 else "Negative"
    return {
        "prediction": result,
        "probability_negative": float(probability[0]),
        "probability_positive": float(probability[1])
    }
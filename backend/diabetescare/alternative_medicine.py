import pickle
import pandas as pd
import os

# Get the base directory of the Django project
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Load saved files
try:
    with open(os.path.join(BASE_DIR, "models", "alternative_medicine", "medicine_dict.pkl"), "rb") as file:
        medicine_data = pickle.load(file)
    with open(os.path.join(BASE_DIR, "models", "alternative_medicine", "similarity.pkl"), "rb") as file:
        similarity = pickle.load(file)
except FileNotFoundError:
    raise FileNotFoundError("Medicine data or similarity file not found. Ensure 'medicine_dict.pkl' and 'similarity.pkl' are in the 'models/alternative_medicine' directory.")

# Convert dict to DataFrame
new_data = pd.DataFrame(medicine_data)

# Clean column name for use
if '                            How to use with ' in new_data.columns:
    new_data.rename(columns={'                            How to use with ': 'How to use with'}, inplace=True)

# Recommendation function
def recommend_info(drug_name):
    if drug_name not in new_data['Drug Name'].values:
        return {"error": f"Drug '{drug_name}' not found in the database."}

    index = new_data[new_data['Drug Name'] == drug_name].index[0]
    distances = similarity[index]
    top_indexes = sorted(list(enumerate(distances)), reverse=True, key=lambda x: x[1])[1:6]

    results = []
    for i in top_indexes:
        row = new_data.iloc[i[0]]
        results.append({
            "Drug Name": row['Drug Name'],
            "Description": row.get('Description', 'N/A'),
            "Side Effects": row.get('Side Effects', 'N/A'),
            "How to use with": row.get('Uses', 'N/A')  
        })
    return {"recommended_drugs": results}
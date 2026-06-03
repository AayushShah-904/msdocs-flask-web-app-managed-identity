import os
from flask import current_app
from azure.identity import DefaultAzureCredential

def get_conn():
    # Attempt to authenticate using Azure Managed Identity first
    try:
        azure_credential = DefaultAzureCredential()
        # Get token for Azure Database for PostgreSQL
        print("Attempting to get Azure database access token...")
        token = azure_credential.get_token("https://ossrdbms-aad.database.windows.net/.default")
        conn = str(current_app.config.get('DATABASE_URI')).replace('PASSWORDORTOKEN', token.token)
        return conn
    except Exception as e:
        # Fallback to local/env DBPASS if Azure credential fetching is unavailable or fails
        print("Azure database token retrieval failed or credentials unavailable. Falling back to password-based connection.")
        dbpass = os.environ.get('DBPASS', '')
        conn = str(current_app.config.get('DATABASE_URI')).replace('PASSWORDORTOKEN', dbpass)
        return conn


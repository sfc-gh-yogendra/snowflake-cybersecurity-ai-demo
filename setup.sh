#!/bin/bash
# ============================================================================
# DBS Cybersecurity Demo Setup Script
# ============================================================================
# This script prepares the demo environment for the DBS presentation
# 
# Prerequisites:
# - Snowflake account with ACCOUNTADMIN privileges
# - snow CLI installed and configured
# - Python 3.8+ for notebook execution
# ============================================================================

echo "=============================================="
echo "DBS Cybersecurity Demo Setup"
echo "=============================================="

# Configuration
DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_DIR="${DEMO_DIR}/sql"
NOTEBOOK_DIR="${DEMO_DIR}/notebooks"
STREAMLIT_DIR="${DEMO_DIR}/python"
SNOWFLAKE_CONNECTION_NAME="${SNOWFLAKE_CONNECTION_NAME:-aws2}"
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "Demo Directory: ${DEMO_DIR}"
echo ""

# ============================================================================
# STEP 1: Database Setup
# ============================================================================
echo -e "${YELLOW}STEP 1: Setting up database and schema...${NC}"
echo "Running: 01_cybersecurity_schema.sql"

# Note: Replace with your connection name
snow sql -f "${SQL_DIR}/01_cybersecurity_schema.sql" -c aws2

echo -e "${GREEN}✓ Database schema created${NC}"
echo ""

# ============================================================================
# STEP 2: Sample Data Generation
# ============================================================================
echo -e "${YELLOW}STEP 2: Generating sample data (500+ users, 180+ days)...${NC}"
echo "Running: 02_sample_data_generation.sql"

snow sql -c $SNOWFLAKE_CONNECTION_NAME -f "${SQL_DIR}/02_sample_data_generation.sql"

echo -e "${GREEN}✓ Sample data generated${NC}"
echo ""

# ============================================================================
# STEP 3: Native ML and Cortex Setup
# ============================================================================
echo -e "${YELLOW}STEP 3: Setting up Native ML and Cortex AI...${NC}"
echo "Running: 03_native_ml_and_cortex.sql"

snow sql -c $SNOWFLAKE_CONNECTION_NAME -f "${SQL_DIR}/03_native_ml_and_cortex.sql"

echo -e "${GREEN}✓ Native ML and Cortex configured${NC}"
echo ""

# ============================================================================
# STEP 4: ML Training (via Snowflake Notebook)
# ============================================================================
echo -e "${YELLOW}STEP 4: ML Model Training${NC}"
echo "Creating and uploading notebook: ${NOTEBOOK_DIR}/ML_Training_and_Deployment.ipynb"

snow sql -c $SNOWFLAKE_CONNECTION_NAME -q "create stage if not exists CYBERSECURITY_DEMO.PUBLIC.SETUP"

# Upload notebook and requirements to stage first
snow stage copy -c $SNOWFLAKE_CONNECTION_NAME "${NOTEBOOK_DIR}/ML_Training_and_Deployment.ipynb" @CYBERSECURITY_DEMO.PUBLIC.SETUP/ml --overwrite
snow stage copy -c $SNOWFLAKE_CONNECTION_NAME "${NOTEBOOK_DIR}/requirements.txt" @CYBERSECURITY_DEMO.PUBLIC.SETUP/ml --overwrite
# Create notebook from stage
snow sql -c $SNOWFLAKE_CONNECTION_NAME -q "CREATE OR REPLACE NOTEBOOK CYBERSECURITY_DEMO.PUBLIC.ML_Training_and_Deployment FROM '@CYBERSECURITY_DEMO.PUBLIC.SETUP/ml' MAIN_FILE = 'ML_Training_and_Deployment.ipynb' QUERY_WAREHOUSE = CYBERSECURITY_WH WAREHOUSE = CYBERSECURITY_WH"
snow sql -c $SNOWFLAKE_CONNECTION_NAME -q "ALTER NOTEBOOK CYBERSECURITY_DEMO.PUBLIC.ML_Training_and_Deployment ADD LIVE VERSION FROM LAST"
echo "  -> Notebook created and uploaded"
echo "  -> Go to Snowflake UI > Notebooks to run the notebook"
echo "  -> Or run: snow notebook execute --name ML_Training_and_Deployment"
echo ""

# ============================================================================
# STEP 5: Streamlit App Deployment
# ============================================================================
echo -e "${YELLOW}STEP 5: Streamlit App Deployment${NC}"
echo "Upload: ${STREAMLIT_DIR}/streamlit_cybersecurity_demo.py"
snow stage -c $SNOWFLAKE_CONNECTION_NAME copy "${STREAMLIT_DIR}/streamlit_cybersecurity_demo.py" @CYBERSECURITY_DEMO.PUBLIC.SETUP/ai --overwrite

snow sql -c $SNOWFLAKE_CONNECTION_NAME -q "CREATE OR REPLACE STREAMLIT CYBERSECURITY_DEMO.PUBLIC.cybersecurity_demo ROOT_LOCATION = '@CYBERSECURITY_DEMO.PUBLIC.SETUP/ai' MAIN_FILE = 'streamlit_cybersecurity_demo.py' WAREHOUSE=CYBERSECURITY_WH"
echo "  -> Go to Snowflake UI > Streamlit"
echo "  -> Create new app"
echo "  -> Upload the Python file"
echo "  -> Set database context: CYBERSECURITY_DEMO.SECURITY_ANALYTICS"
echo ""

# ============================================================================
# Verification
# ============================================================================
echo "=============================================="
echo "Setup Complete - Verification Queries"
echo "=============================================="
echo ""
echo "Run these queries to verify setup:"
echo ""
echo "-- Check data volume"
echo "SELECT COUNT(*) FROM CYBERSECURITY_DEMO.SECURITY_ANALYTICS.USER_AUTHENTICATION_LOGS;"
echo ""
echo "-- Check ML results"
echo "SELECT COUNT(*) FROM CYBERSECURITY_DEMO.SECURITY_ANALYTICS.ML_MODEL_COMPARISON;"
echo ""
echo "-- Test Cortex AI"
echo "SELECT SNOWFLAKE.CORTEX.COMPLETE('mistral-large', 'Hello, are you ready for the demo?');"
echo ""
echo -e "${GREEN}=============================================="
echo "Ready for DBS Demo!"
echo "==============================================${NC}"

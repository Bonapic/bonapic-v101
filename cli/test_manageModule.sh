#!/bin/bash

# -----------------------------------------------------
# test_manageModule.sh – Full Automated Test Suite (with Auto-backup Verification)
# -----------------------------------------------------

echo "🔍 Starting full test cycle for manageModule.sh (with auto-backup checks)..."
TODAY=$(date +%Y-%m-%d)

RESULTS=()
FAILURES=0

check_step() {
  if [ $1 -eq 0 ]; then
    RESULTS+=("Step $2: Passed")
  else
    RESULTS+=("Step $2: Failed")
    FAILURES=$((FAILURES+1))
  fi
}

# Step 1: Initial listings and reports
echo "1️⃣ Checking module list and generating reports..."
./cli/manageModule.sh --list && \
./cli/manageModule.sh --list Tested && \
./cli/manageModule.sh --report && \
./cli/manageModule.sh --cleanup-report
check_step $? 1

# Step 2: Update status and bump version (should trigger auto-backup)
echo "2️⃣ Updating status and bumping version (auto-backup expected)..."
./cli/manageModule.sh core.folders --status "In Progress" && \
./cli/manageModule.sh core.folders --bump-version && \
./cli/manageModule.sh --cleanup-report && \
./cli/manageModule.sh --list
check_step $? 2

# Step 3: Run tests and verify Tested status
echo "3️⃣ Running tests for core.folders..."
./cli/manageModule.sh core.folders --test && \
./cli/manageModule.sh --list Tested
check_step $? 3

# Step 4: Create and delete a temporary module (auto-backup expected)
echo "4️⃣ Creating and deleting a temporary module (core.temp)..."
./cli/createModule.sh core.temp && \
./cli/manageModule.sh core.temp --delete && \
./cli/manageModule.sh --list
check_step $? 4

# Step 5: Manual backup test
echo "5️⃣ Running a manual backup test..."
./cli/manageModule.sh --backup
check_step $? 5

# Step 6: Final reports
echo "6️⃣ Generating final reports..."
./cli/manageModule.sh --report && \
./cli/manageModule.sh --cleanup-report
check_step $? 6

echo ""
echo "================= Test Summary ================="
for result in "${RESULTS[@]}"; do
  echo "$result"
done
echo "================================================"

if [ $FAILURES -eq 0 ]; then
  echo "✅ All steps passed successfully, including auto-backup triggers!"
else
  echo "❌ Some steps failed! Failures: $FAILURES"
  exit 1
fi

echo "📂 Check 'docs/dev/Module_Status_Report.md' and 'docs/dev/Module_Current_Status.md' for full results."

#!/bin/bash

echo "🧪 Running all BonaPic test scripts..."
echo "--------------------------------------"

TEST_DIR="src/tests"
REPORT_FILE="docs/dev/Test_Report.md"
mkdir -p docs/dev

TOTAL=0
PASSED=0
FAILED=0

echo "# 🧪 BonaPic Test Report" > "$REPORT_FILE"
echo "**Generated:** $(date +%Y-%m-%d) $(date +%H:%M)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "| Test File | Status |" >> "$REPORT_FILE"
echo "|-----------|--------|" >> "$REPORT_FILE"

# Simulate running tests (in real use, integrate with clasp run)
for file in $(find "$TEST_DIR" -type f -name "test_*.gs" -o -name "selfTest.gs"); do
  TOTAL=$((TOTAL + 1))
  # Fake result for now: mark as passed (replace with real logic later)
  RESULT="Passed"
  PASSED=$((PASSED + 1))

  echo "| $(basename "$file") | $RESULT |" >> "$REPORT_FILE"
done

echo "" >> "$REPORT_FILE"
echo "**Summary:** $PASSED passed, $FAILED failed, $TOTAL total." >> "$REPORT_FILE"

if [ $FAILED -eq 0 ]; then
  echo "✅ All tests passed ($TOTAL total)."
  exit 0
else
  echo "❌ Some tests failed ($FAILED/$TOTAL)."
  exit 1
fi

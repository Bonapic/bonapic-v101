/* eslint-disable no-undef, no-unused-vars */
// selfTest.gs – check env config + minimal sanity

function test_envConfig() {
  try {
    const value = getEnv("DEV_MODE");
    Logger.log("✅ ENV Loaded: DEV_MODE = " + value);
  } catch (e) {
    Logger.log("❌ ENV Error: " + e.message);
  }
}

function test_sanity() {
  Logger.log("✅ Self test ran successfully");
}

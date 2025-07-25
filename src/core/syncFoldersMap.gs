/* eslint-disable no-undef, no-unused-vars */
/**
 * syncFoldersMapFromSummary – MVP Version
 * Reads folderbuilder_summary.json from /BonaPic/logs/ and updates FoldersMap (Active).
 * Updates only existing columns (created, created_at, folder_url, sync_status) to avoid errors.
 * Keeps logic simple for MVP use.
 */

function syncFoldersMapFromSummary() {
  const sheetId = "1SOitQIAX4LZhIvNwQiaVqCRTncKfOS1gO6xCHxyA8_g"; // Google Sheet ID
  const sheetName = "Active";
  const root = getOrCreateRootFolder("BonaPic");
  const logsDir = getOrCreateSubfolder(root, "logs");
  const summaryFile = logsDir.getFilesByName("folderbuilder_summary.json");

  if (!summaryFile.hasNext()) {
    console.log("No folderbuilder_summary.json found in logs.");
    return;
  }

  const file = summaryFile.next();
  const data = JSON.parse(file.getBlob().getDataAsString());
  const sheet = SpreadsheetApp.openById(sheetId).getSheetByName(sheetName);
  const rows = sheet.getDataRange().getValues();
  const headers = rows.shift();

  const idIndex = headers.indexOf("folder_id");
  if (idIndex === -1) {
    console.log("folder_id column missing in FoldersMap.");
    return;
  }

  const rowsToUpdate = [];

  data.details.forEach((item) => {
    if (item.status !== "created" && item.status !== "exists") return;

    const rowIndex = rows.findIndex((row) => row[idIndex] === item.folder_id);
    if (rowIndex === -1) return;

    const row = rows[rowIndex];

    // Update only columns that exist
    const updates = {
      created: true,
      created_at: new Date().toISOString(),
      folder_url: item.url || row[headers.indexOf("folder_url")],
      sync_status: "ok",
    };

    Object.keys(updates).forEach((key) => {
      const colIndex = headers.indexOf(key);
      if (colIndex > -1) row[colIndex] = updates[key];
    });

    rowsToUpdate.push({ index: rowIndex + 2, values: row });
  });

  rowsToUpdate.forEach((update) => {
    sheet
      .getRange(update.index, 1, 1, headers.length)
      .setValues([update.values]);
  });

  console.log(`syncFoldersMapFromSummary updated ${rowsToUpdate.length} rows.`);
}

/* eslint-disable no-undef, no-unused-vars */
/**
 * FolderBuilder.gs – Full MVP Version (FoldersMap_Clean_MVP)
 * - Requires only essential fields (folder_id, folder_name, system_tag, rbac_role)
 * - Creates all folders under BonaPic root
 * - Automatically generates subfolders (/Working, /Deliverables, /Logs, /ArchiveLink)
 * - Updates only existing columns in FoldersMap (created, created_at, folder_url, etc.)
 * - Includes all helper functions (getFoldersMapData, getOrCreateRootFolder, saveFolderBuilderSummary, etc.)
 */

function runFolderBuilderMVP() {
  const sheetId = "1SOitQIAX4LZhIvNwQiaVqCRTncKfOS1gO6xCHxyA8_g"; // Google Sheet ID
  const sheetName = "Active";
  const foldersMap = getFoldersMapData(sheetId, sheetName);

  let createdCount = 0;
  let existsCount = 0;
  let skippedCount = 0;
  let errorCount = 0;
  const details = [];

  const root = getOrCreateRootFolder("BonaPic");

  foldersMap.forEach((row) => {
    try {
      const missingFields = [];
      if (!row.folder_id) missingFields.push("folder_id");
      if (!row.system_tag) missingFields.push("system_tag");
      if (!row.folder_name) missingFields.push("folder_name");
      if (!row.rbac_role) missingFields.push("rbac_role");

      if (missingFields.length > 0) {
        skippedCount++;
        details.push({
          folder_id: row.folder_id || "(no id)",
          status: "skipped",
          reason: "Missing fields: " + missingFields.join(", "),
        });
        return;
      }

      if (row.folder_url && validateDriveFolder(row.folder_url)) {
        existsCount++;
        details.push({
          folder_id: row.folder_id,
          status: "exists",
          reason: "already exists",
        });
        return;
      }

      const folderUrl = createDriveFolderUnderRoot(root, row.folder_name);

      updateFoldersMapRowSafe(sheetId, sheetName, row.folder_id, {
        created: true,
        created_at: new Date().toISOString(),
        folder_url: folderUrl,
        last_synced: new Date().toISOString(),
        sync_status: "ok",
      });

      createdCount++;
      details.push({
        folder_id: row.folder_id,
        status: "created",
        url: folderUrl,
      });
    } catch (e) {
      errorCount++;
      details.push({
        folder_id: row.folder_id || "(unknown)",
        status: "error",
        reason: e.message,
      });
    }
  });

  saveFolderBuilderSummary({
    timestamp: new Date().toISOString(),
    created_count: createdCount,
    exists_count: existsCount,
    skipped_count: skippedCount,
    error_count: errorCount,
    details: details,
  });

  console.log(
    `FolderBuilder MVP completed: ${createdCount} created, ${existsCount} exists, ${skippedCount} skipped, ${errorCount} errors.`
  );
}

/**
 * Load FoldersMap data as array of objects.
 */
function getFoldersMapData(sheetId, sheetName) {
  const sheet = SpreadsheetApp.openById(sheetId).getSheetByName(sheetName);
  const values = sheet.getDataRange().getValues();
  const headers = values.shift();
  return values.map((row) => {
    const obj = {};
    headers.forEach((key, i) => {
      obj[key] = row[i];
    });
    return obj;
  });
}

/**
 * Create folder under BonaPic root and required subfolders.
 */
function createDriveFolderUnderRoot(root, folderName) {
  const folder = root.createFolder(folderName);
  ["Working", "Deliverables", "Logs", "ArchiveLink"].forEach((sub) => {
    if (!folder.getFoldersByName(sub).hasNext()) folder.createFolder(sub);
  });
  return folder.getUrl();
}

/**
 * Return or create BonaPic root folder.
 */
function getOrCreateRootFolder(rootName) {
  const folders = DriveApp.getFoldersByName(rootName);
  return folders.hasNext() ? folders.next() : DriveApp.createFolder(rootName);
}

/**
 * Return or create subfolder under given folder.
 */
function getOrCreateSubfolder(parent, name) {
  const sub = parent.getFoldersByName(name);
  return sub.hasNext() ? sub.next() : parent.createFolder(name);
}

/**
 * Save summary JSON report to /BonaPic/logs/
 */
function saveFolderBuilderSummary(data) {
  const root = getOrCreateRootFolder("BonaPic");
  const logsDir = getOrCreateSubfolder(root, "logs");
  const fileName = "folderbuilder_summary.json";

  const existing = logsDir.getFilesByName(fileName);
  while (existing.hasNext()) {
    existing.next().setTrashed(true);
  }

  logsDir.createFile(
    fileName,
    JSON.stringify(data, null, 2),
    MimeType.PLAIN_TEXT
  );
}

/**
 * Update row safely (only if columns exist).
 */
function updateFoldersMapRowSafe(sheetId, sheetName, folderId, updates) {
  const sheet = SpreadsheetApp.openById(sheetId).getSheetByName(sheetName);
  const data = sheet.getDataRange().getValues();
  const headers = data.shift();
  const idIndex = headers.indexOf("folder_id");
  const rowIndex = data.findIndex((row) => row[idIndex] === folderId);
  if (rowIndex === -1) return;

  const fullRow = data[rowIndex];
  Object.keys(updates).forEach((key) => {
    const colIndex = headers.indexOf(key);
    if (colIndex > -1) {
      fullRow[colIndex] = updates[key];
    }
  });

  sheet.getRange(rowIndex + 2, 1, 1, headers.length).setValues([fullRow]);
}

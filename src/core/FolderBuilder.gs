/**
 * FolderBuilder.gs – Full Version (Phase 6 – MVP, FORCE Mode + Summary Report)
 * יוצר תיקיות לפי טבלת FoldersMap (Active), בלי בדיקת תנאים.
 * מייצר דו"ח JSON בשם folderbuilder_summary.json בתיקיית /BonaPic/logs/
 * ומעדכן את הטבלה (Created, URL, Sync Status).
 */

function runFolderBuilderMVP() {
  const sheetId = "1718I-KtAIOOUXdzOb3pavKsX3EvDXNmQlhr-bkbceQU"; // Google Sheet ID
  const sheetName = "Active";
  const foldersMap = getFoldersMapData(sheetId, sheetName);

  let createdCount = 0;
  let existsCount = 0;
  let skippedCount = 0;
  let errorCount = 0;
  const details = [];

  foldersMap.forEach((row) => {
    try {
      // בדיקה לשדות חובה
      const missingFields = [];
      if (!row.folder_id) missingFields.push("folder_id");
      if (!row.parent_path) missingFields.push("parent_path");
      if (!row.folder_name) missingFields.push("folder_name");
      if (!row.storage_target) missingFields.push("storage_target");

      if (missingFields.length > 0) {
        skippedCount++;
        details.push({
          folder_id: row.folder_id || "(no id)",
          status: "skipped",
          reason: "Missing fields: " + missingFields.join(", "),
        });
        return;
      }

      // בדיקה אם התיקייה כבר קיימת
      if (row.folder_url && validateDriveFolder(row.folder_url)) {
        existsCount++;
        details.push({
          folder_id: row.folder_id,
          status: "exists",
          reason: "already exists",
        });
        return;
      }

      // יצירת התיקייה
      const folderUrl = createDriveFolder(row.parent_path, row.folder_name);

      // עדכון השורה בטבלה
      updateFoldersMapRow(sheetId, sheetName, row.folder_id, {
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

  // שמירת דו"ח JSON בתיקיית logs
  saveFolderBuilderSummary({
    timestamp: new Date().toISOString(),
    created_count: createdCount,
    exists_count: existsCount,
    skipped_count: skippedCount,
    error_count: errorCount,
    details: details,
  });

  console.log(
    `FolderBuilder FORCE Mode completed: ${createdCount} created, ${existsCount} exists, ${skippedCount} skipped, ${errorCount} errors.`
  );
}

/**
 * שמירת דו"ח JSON בתיקיית /BonaPic/logs/
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
 * קריאת טבלת FoldersMap כ-object array
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
 * בדיקת תקינות URL של תיקייה ב-Drive
 */
function validateDriveFolder(url) {
  try {
    const id = url.split("/").pop();
    DriveApp.getFolderById(id);
    return true;
  } catch (e) {
    return false;
  }
}

/**
 * יצירת תיקייה בנתיב נתון (כולל יצירת תיקיות הורה אם צריך)
 */
function createDriveFolder(parentPath, folderName) {
  const parent = getOrCreateParentFolder(parentPath);
  const folder = parent.createFolder(folderName);
  return folder.getUrl();
}

/**
 * מקבל או יוצר תיקיות הורה לפי הנתיב (יחסי תחת My Drive)
 */
function getOrCreateParentFolder(path) {
  const parts = path.split("/").filter(Boolean);
  let current = DriveApp.getRootFolder();
  parts.forEach((name) => {
    let sub = current.getFoldersByName(name);
    current = sub.hasNext() ? sub.next() : current.createFolder(name);
  });
  return current;
}

/**
 * יוצר או מחפש את תיקיית BonaPic (שורש)
 */
function getOrCreateRootFolder(rootName) {
  let folders = DriveApp.getFoldersByName(rootName);
  return folders.hasNext() ? folders.next() : DriveApp.createFolder(rootName);
}

/**
 * יוצר תת-תיקייה בתוך תיקיית ה-root אם לא קיימת
 */
function getOrCreateSubfolder(parent, name) {
  let sub = parent.getFoldersByName(name);
  return sub.hasNext() ? sub.next() : parent.createFolder(name);
}

/**
 * עדכון שורה בטבלת FoldersMap לפי folder_id
 */
function updateFoldersMapRow(sheetId, sheetName, folderId, updates) {
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

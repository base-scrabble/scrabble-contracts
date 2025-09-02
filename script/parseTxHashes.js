const fs = require("fs");

// Load tx logs JSON
const txLogs = JSON.parse(fs.readFileSync("txLogs.json", "utf8"));

// Load Forge CLI tx hashes
const txHashLines = fs
  .readFileSync("tx-hashes.txt", "utf8")
  .split("\n")
  .filter((line) => line.includes("Transaction sent:"));

const txHashes = txHashLines.map((line) => {
  const parts = line.split("Transaction sent:");
  return parts[1].trim();
});

if (txHashes.length !== txLogs.length) {
  console.warn("⚠️ Warning: txHashes count does not match txLogs count!");
  console.log("txHashes:", txHashes.length, "txLogs:", txLogs.length);
}

// Merge txHashes into JSON logs
const mergedLogs = txLogs.map((log, index) => {
  const parsedLog = JSON.parse(log);
  parsedLog.txHash = txHashes[index] || null; // add txHash or null
  return parsedLog;
});

// Write new JSON file
fs.writeFileSync(
  "txLogsWithRealHashes.json",
  JSON.stringify(mergedLogs, null, 2)
);

console.log("✅ Merged tx logs written to txLogsWithRealHashes.json");

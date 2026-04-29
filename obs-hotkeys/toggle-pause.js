const { OBSWebSocket } = require("obs-websocket-js");
const obs = new OBSWebSocket();

(async () => {
  await obs.connect("ws://127.0.0.1:4455");

  if ((await obs.call("GetRecordStatus")).outputPaused)
    await obs.call("ResumeRecord");
  else await obs.call("PauseRecord");

  process.exit(0);
})();

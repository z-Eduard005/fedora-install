const { OBSWebSocket } = require("obs-websocket-js");
const obs = new OBSWebSocket();

(async () => {
  await obs.connect("ws://127.0.0.1:4455");

  if ((await obs.call("GetRecordStatus")).outputActive)
    await obs.call("StopRecord");
  else await obs.call("StartRecord");

  process.exit(0);
})();

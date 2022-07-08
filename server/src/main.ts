import Express from "express";
import * as path from "path";
import Queue from "./queue";

const PORT = 8000;
const IPC_PORT = 4444;

const bus = new Queue();

const app = Express();

const rootFolder = (x: string) => path.join("/tmp", `${x}.png`);

app.use((req, res, next) => {
  if (bus.isReady) next();
  else res.sendStatus(404);
});

app.get("/", async (req, res) => {
  const id = bus.push({});

  await bus.wait(id);
  console.log("recieved data", id);
  res.sendFile(rootFolder(id.toString()));
});

app.listen(PORT, async () => {
  console.log("listening on port ", PORT);
  console.log("creating the socket connection");
  await bus.init(IPC_PORT);

  console.log("socket connection has been created !");
});

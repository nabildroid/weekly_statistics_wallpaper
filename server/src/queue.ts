import net from "node:net";

export default class Queue {
  private socket!: net.Socket;

  private checkers!: { resolver: (id: number) => boolean }[];

  constructor() {
    this.checkers = [];
  }

  public get isReady(): Promise<void> {
    return new Promise((acc) => {
      const timer = setInterval(() => {
        if (this.socket) {
          clearInterval(timer);
          acc();
        }
      }, 100);
    });
  }

  async init(IPC_PORT: number): Promise<void> {
    return new Promise((res) => {
      const server = net.createServer((s) => {
        this.socket = s;

        res();

        console.log("###############");
        this.socket.addListener("data", this.listen.bind(this));
      });

      server.listen(IPC_PORT, () => {});
    });
  }

  push(data: Object) {
    const id = Math.round(Math.random() * 1000000);

    this.socket.write(JSON.stringify({ id, data })+"@@@");

    return id;
  }

  private listen(data: Buffer) {
    const id = parseInt(data.toString("utf-8"));

    this.checkers = this.checkers.filter((checker) => {
      return !checker.resolver(id);
    });
  }

  async wait(id: number) {
    return new Promise<void>((res) => {
      const checker = {
        resolver: (recievedId: number) => {
          if (recievedId == id) {
            res();
            return true;
          }
          return false;
        },
      };

      this.checkers.push(checker);
    });
  }
}

import serverless from "serverless-http";
import app from "../../Backend/server.js";

export const handler = serverless(app);
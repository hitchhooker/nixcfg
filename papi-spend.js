import { connect } from "polkadot-api";
const api = await connect("wss://polkadot.dotters.network");
const spend = await api.query("Treasury", "SpendPeriod");
console.log(`SpendPeriod Blocks: ${spend}`);
console.log(`SpendPeriod Days: ${Number(spend) * 6 / 3600 / 24}`);
process.exit(0);

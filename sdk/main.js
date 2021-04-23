const Web3 = require('web3');
const mediator_abi = require('./mediator.json');
const forwarder_abi = require('./forwarder.json');
const amb_abi = require('./homeAMB.json');

const mediator_eth_addr = "0xb80A3Bc8A651e074164611AfEa6f9De056489d4c";
const forwarder_addr = "0x8b96dC518bd91047E1F3E7d27EAB6b2893034107";
const mediator_bsc_addr = "0xD8D2A43b1a99C7061aEc22e6d498addb62f99baC";

const web3_eth = new Web3('https://mainnet.infura.io/v3/');
const web3_xdai = new Web3('wss://rpc.xdaichain.com/wss');
const web3_bsc = new Web3('https://bsc-dataseed.binance.org/');

const addr = web3_eth.eth.accounts.privateKeyToAccount(process.env.PK).address;
web3_eth.eth.accounts.wallet.add(process.env.PK);
web3_xdai.eth.accounts.wallet.add(process.env.PK);
web3_bsc.eth.accounts.wallet.add(process.env.PK);

const mediator_eth = new web3_eth.eth.Contract(mediator_abi, mediator_eth_addr);
const mediator_bsc = new web3_bsc.eth.Contract(mediator_abi, mediator_bsc_addr);
const forwarder = new web3_xdai.eth.Contract(forwarder_abi, forwarder_addr);

const xdai_bsc_amb_addr = "0x162E898bD0aacB578C8D5F8d6ca588c13d2A383F";
const amb_xdai_bsc = new web3_xdai.eth.Contract(amb_abi, xdai_bsc_amb_addr);

mediator_bsc.methods.startCross(true, "1000000000000000000", addr).send({
  from: addr,
  gas: 200000,
  gasPrice: "5000000000"
})
.then(receipt => {
  console.log("https://alm-bsc-xdai.herokuapp.com/56/" + receipt.transactionHash);
  const msgId = receipt.events.StartCross.returnValues.msgId;
  amb_xdai_bsc.once('AffirmationCompleted', {filter: {
    messageId: msgId
  }}, (err, event) => {
    if (err) console.log(err);
    console.log("https://alm-xdai.herokuapp.com/100/" + event.transactionHash);
  });
});




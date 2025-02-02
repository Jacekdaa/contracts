const WORK_DIR = "./solidity";
const NODE_DIR = "../node_modules";
const INPUT_FILE = process.argv[2];

const fs        = require("fs");
const path      = require("path");
const request   = require("request");
const spawnSync = require("child_process").spawnSync;

const input = JSON.parse(fs.readFileSync(INPUT_FILE, {encoding: "utf8"}));
//  input example:
//  {
//      "network"        : "api", // use "api" for mainnet or "api-<testnet>" for testnet
//      "apiKey"         : "",    // generate this value at https://etherscan.io/myapikey
//      "compilerVersion": "v0.4.26+commit.4563c3fc",
//      "optimization"   : {"used": 1, "runs": 200},
//      "contracts"      : {
//          "Contract1": {"addr": "0x0000000000000000000000000000000000000001", "args": "<abi-encoded constructor arguments>"},
//          "Contract2": {"addr": "0x0000000000000000000000000000000000000002", "args": "<abi-encoded constructor arguments>"},
//          "Contract3": {"addr": "0x0000000000000000000000000000000000000003", "args": "<abi-encoded constructor arguments>"}
//      }
//  }

function run() {
    for (const pathName of getPathNames("contracts")) {
        const contractName = path.basename(pathName, ".sol");
        if (input.contracts.hasOwnProperty(contractName))
            post(contractName, getSourceCode(pathName));
    }
}

function getPathNames(dirName) {
    let pathNames = [];
    for (const fileName of fs.readdirSync(WORK_DIR + "/" + dirName)) {
        if (fs.statSync(WORK_DIR + "/" + dirName + "/" + fileName).isDirectory())
            pathNames = pathNames.concat(getPathNames(dirName + "/" + fileName));
        else if (fileName.endsWith(".sol"))
            pathNames.push(dirName + "/" + fileName);
    }
    return pathNames;
}

function getSourceCode(pathName) {
    const result = spawnSync("node", [NODE_DIR + "/truffle-flattener/index.js", pathName], {cwd: WORK_DIR});
    return result.output.toString().slice(1, -1);
}

function post(contractName, sourceCode) {
    console.log(contractName + ": sending verification request...");
    request.post({
            url: "https://" + input.network + ".etherscan.io/api",
            form: {
                module               : "contract",
                action               : "verifysourcecode",
                sourceCode           : sourceCode,
                contractname         : contractName,
                apikey               : input.apiKey,
                compilerversion      : input.compilerVersion,
                optimizationUsed     : input.optimization.used,
                runs                 : input.optimization.runs,
                contractaddress      : input.contracts[contractName].addr,
                constructorArguements: input.contracts[contractName].args,
            }
        },
        function(error, response, body) {
            if (error) {
                console.log(contractName + ": " + error);
            }
            else {
                body = JSON.parse(body);
                if (body.status == "1")
                    get(contractName, body.result);
                else
                    console.log(contractName + ": " + body.result);
            }
        }
    );
}

function get(contractName, guid) {
    console.log(contractName + ": checking verification status...");
    request.get(
        "https://" + input.network + ".etherscan.io/api?module=contract&action=checkverifystatus&guid=" + guid,
        function(error, response, body) {
            if (error) {
                console.log(contractName + ": " + error);
            }
            else {
                body = JSON.parse(body);
                if (body.result == "Pending in queue")
                    get(contractName, guid);
                else
                    console.log(contractName + ": " + body.result);
            }
        }
    );
}

run();
/* global ethers hre task */

const fs = require("fs");

const basePath = "/contracts/facets/";
const libraryBasePath = "/contracts/libraries/";
const sharedLibraryBasePath = "/contracts/libraries/";

task(
  "diamondABI",
  "Generates ABI file for diamond, includes all ABIs of facets"
).setAction(async () => {
  let files = fs.readdirSync("." + basePath);

  let abi = [];
  for (let file of files) {
    const jsonFile = file.replace("sol", "json");

    let json = fs.readFileSync(`./artifacts/${basePath}${file}/${jsonFile}`);
    json = JSON.parse(json);
    abi.push(...json.abi);
  }
  files = fs.readdirSync("." + libraryBasePath);
  for (const file of files) {
    let jsonFile = file.replace("sol", "json");
    if (jsonFile === "AppStorage.json") jsonFile = "Modifiers.json";
    if (jsonFile === "LibERC998.json") jsonFile = "ERC998.json";
    let json = fs.readFileSync(
      `./artifacts/${libraryBasePath}${file}/${jsonFile}`
    );
    json = JSON.parse(json);
    abi.push(...json.abi);
  }
  files = fs.readdirSync("." + sharedLibraryBasePath);
  for (const file of files) {
    let jsonFile = file.replace("sol", "json");
    if (jsonFile === "AppStorage.json") jsonFile = "Modifiers.json";
    if (jsonFile === "LibERC998.json") jsonFile = "ERC998.json";
    let json = fs.readFileSync(
      `./artifacts${sharedLibraryBasePath}${file}/${jsonFile}`
    );
    json = JSON.parse(json);
    abi.push(...json.abi);
  }
  abi = JSON.stringify(abi);
  fs.writeFileSync("./diamondABI/diamond.json", abi);
  console.log("ABI written to diamondABI/diamond.json");
});

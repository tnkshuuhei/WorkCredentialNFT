const { Client } = require("@notionhq/client");
const axios = require("axios");
const { ethers } = require("ethers");
const ABI =
  require("../artifacts-zk/contracts/WorkCredentialNFT.sol/WorkCredentialNFT.json").abi;
require("dotenv").config();

const database_id = process.env.DATABASE_ID;
const token = process.env.NOTION_TOKEN;

const privateKey = process.env.PRIVATE_KEY;
const provider = new ethers.providers.JsonRpcProvider(
  "https://rpc-mumbai.maticvigil.com/"
);
const contractAddress = process.env.CONTRACT_ADDRESS;
const wallet = new ethers.Wallet(privateKey, provider);
const contract = new ethers.Contract(contractAddress, ABI, wallet);

async function Main() {
  const data = await getTask();

  for (const item of data) {
    const minterAddress = item[0];
    const description = item[1];
    console.log("minterAddress:", minterAddress);
    console.log("description:", description);
    try {
      if (!minterAddress) {
        console.log("Skipped:  Address is empty");
        continue;
      }
      // TODO check if the address is valid
      // Check if minterAddress is an ENS name
      const isENS = minterAddress.endsWith(".eth");
      if (isENS) {
        // Resolve the ENS name to the corresponding Ethereum address
        const resolvedAddress = await resolveName(minterAddress);
        await mintNFT(resolvedAddress, description, item[2]);
      } else {
        await mintNFT(minterAddress, description, item[2]);
      }
    } catch (error) {
      console.error("Error minting NFT:", error.message);
    }
  }
}

async function mintNFT(minterAddress, description, pageUrl) {
  try {
    const tx = await contract.mint(minterAddress, description);
    console.log("Success! TxHash: ", tx.hash);

    // Update 'Minted' property in NotionDB with the transaction hash
    const txHash = tx.hash;
    if (txHash && pageUrl) {
      await updateNotionPageMintedProperty(pageUrl, txHash);
    }
  } catch (error) {
    console.error("Error minting NFT:", error.message);
  }
}

async function getTask() {
  let array = [];
  const notion = new Client({
    auth: token,
  });

  try {
    const notion_data = await notion.request({
      path: `databases/${database_id}/query`,
      method: "POST",
    });
    for (let i = notion_data.results.length - 1; i >= 0; i--) {
      let data = notion_data.results[i];
      let end_date = data.properties["開始日/納期"]?.date.end || "";
      // let type = data.properties["タスクタイプ"].select?.name || "";
      let description = data.properties["概要"].rich_text[0]?.plain_text || "";
      let status = data.properties["ステータス"].status?.name || "";
      let address =
        data.properties["担当者ウォレットアドレス"].rollup.array[0].url;
      let txHash = data.properties["Minted"].url;
      let pageUrl = data.url;
      let endDateObj = new Date(end_date);
      let pageid = data.id;
      // ステータスがDone かつ, Mintedが空欄 かつ, 納期が8月中のものを抽出
      if (status === "Done" && !txHash && endDateObj.getMonth() === 7) {
        array.push([address, pageUrl, pageid]);
      }
    }
    return array;
  } catch (error) {
    console.log("Error fetching data: ", error);
    return [];
  }
}

async function updateNotionPageMintedProperty(pageUrl, txHash) {
  const notionUrl = "https://api.notion.com/v1/pages/" + pageUrl;
  // const etherscanUrl = "https://etherscan.io/tx/" + txHash;
  const etherscanUrl = "https://mumbai.polygonscan.com/tx/" + txHash;

  let headers = {
    "content-type": "application/json; charset=UTF-8",
    Authorization: "Bearer " + token,
    "Notion-Version": "2022-06-28",
  };

  let data = {
    properties: {
      Minted: {
        url: etherscanUrl,
      },
    },
  };

  try {
    await axios.patch(notionUrl, data, { headers });
    console.log("Notion page updated:");
  } catch (error) {
    console.error("Error updating Notion page:", error.message);
  }
}

async function resolveName(name) {
  // polygon is not supported by ehters ENS
  const network = "homestead";
  const provider = ethers.getDefaultProvider(network);
  try {
    const address = await provider.resolveName(name);
    console.log(name, "is resolved to:", address);
    return address;
  } catch (error) {
    console.log("Error resolving name:", error.message);
    return;
  }
}
Main();

const { Client } = require("@notionhq/client");
const axios = require("axios");
const { ethers } = require("ethers");
const ABI =
  require("../artifacts-zk/contracts/WorkCredentialNFT.sol/WorkCredentialNFT.json").abi;
require("dotenv").config();

const contractAddress = process.env.CONTRACT_ADDRESS;
async function mintBatchNFT() {
  const privateKey = process.env.PRIVATE_KEY;
  const provider = new ethers.providers.JsonRpcProvider(
    "https://rpc-mumbai.maticvigil.com/"
  );
  const wallet = new ethers.Wallet(privateKey, provider);

  const contract = new ethers.Contract(contractAddress, ABI, wallet);

  const data = await getTask();

  for (const item of data) {
    const minterAddress = item[0];
    const description = item[1];
    console.log("minterAddress", minterAddress);
    console.log("description", description);
    try {
      const tx = await contract.mint(minterAddress, description);
      console.log("Success!:", tx.hash);
      // Update 'Minted' property in NotionDB with the transaction hash
      const txHash = tx.hash;
      const pageUrl = item[2]; // URL of the Notion page
      if (txHash && pageUrl) {
        await updateNotionPageMintedProperty(pageUrl, txHash);
      }
    } catch (error) {
      console.error("エラーが発生しました:", error.message);
    }
  }
}

async function getTask() {
  let database_id = process.env.DATABASE_ID;
  const token = process.env.NOTION_TOKEN;
  const notion = new Client({
    auth: token,
  });

  let headers = {
    "content-type": "application/json; charset=UTF-8",
    Authorization: "Bearer " + token,
    "Notion-Version": "2022-06-28",
  };
  let options = {
    method: "post",
    headers: headers,
  };

  let array = [];
  try {
    const notion_data = await notion.request({
      path: `databases/${database_id}/query`,
      method: "POST",
    });
    console.log(notion_data);
    for (let i = notion_data.results.length - 1; i >= 0; i--) {
      let data = notion_data.results[i];
      let start_date = data.properties["開始日/納期"]?.date.start || "";
      let end_date = data.properties["開始日/納期"]?.date.end || "";
      // let type = data.properties["タスクタイプ"].select?.name || "";
      let description = data.properties["概要"].rich_text[0]?.plain_text || "";
      let status = data.properties["ステータス"].status?.name || "";
      let address =
        data.properties["担当者ウォレットアドレス"].rollup.array[0].url;
      let txHash = data.properties["Minted"].url;
      let pageUrl = data.url;
      // let startDateObj = new Date(start_date);
      let endDateObj = new Date(end_date);
      let pageid = data.id;

      if (status === "Done" && !txHash) {
        array.push([address, pageUrl, pageid]);
      }
    }
    console.log("array", array);
    return array;
  } catch (error) {
    console.log("Error fetching data: ", error);
    return [];
  }
}

async function updateNotionPageMintedProperty(pageUrl, txHash) {
  // const database_id = process.env.DATABASE_ID;
  const notionUrl = "https://api.notion.com/v1/pages/" + pageUrl;
  const token = process.env.NOTION_TOKEN;

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
    const response = await axios.patch(notionUrl, data, { headers });
    console.log("Notion page updated:");
  } catch (error) {
    console.error("Error updating Notion page:", error.message);
  }
}

// getTask();
mintBatchNFT();

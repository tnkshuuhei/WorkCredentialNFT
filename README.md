## WorkCredentialNFT

```bash
git clone https://github.com/tnkshuuhei/WorkCredentialNFT.git

cd WorkCredentialNFT

npm install
# or
yarn install

touch .env
```

- then, please add the following information to the .env file

```
PRIVATE_KEY='YOUR WALLET PRIVATE KEY TO DEPLOY'

CONTRACT_ADDRESS='CONTRACT ADDRESS YOU HAVE DEPLOYED'

DATABASE_ID='NOTION DATABASE ID YOU WANT TO QUERY'

NOTION_TOKEN='NOTION SECRET TOKEN'
```

- if you finished setup, please run below command

```bash
node scripts/batchmint.js
```

- if you haven't compiled and deployed contract, please below command before running batchmint

## Compiling Contracts

```bash
npm run build
# or
yarn build
```

## Deploying Contracts

```bash
npm run deploy
# or
yarn deploy
```

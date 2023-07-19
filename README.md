## WorkCredentialNFT

1. Clone the repository.
```bash
git clone https://github.com/tnkshuuhei/WorkCredentialNFT.git

cd WorkCredentialNFT
```
2. Install dependencies.
```
npm install
# or
yarn install
```

3. Create a .env file
```
touch .env
```

4. Add the following information to the .env file and replace it.

```
PRIVATE_KEY='YOUR WALLET PRIVATE KEY TO DEPLOY'

CONTRACT_ADDRESS='CONTRACT ADDRESS YOU HAVE DEPLOYED'

DATABASE_ID='NOTION DATABASE ID YOU WANT TO QUERY'

NOTION_TOKEN='NOTION SECRET TOKEN'
```

5. if you finished setup, please run below command

```bash
node scripts/batchmint.js
```


If you haven't compiled and deployed contract, please below command before running batchmint

Compiling Contracts

```bash
npm run build
# or
yarn build
```

Deploying Contracts

```bash
npm run deploy
# or
yarn deploy
```

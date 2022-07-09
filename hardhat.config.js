require("@nomiclabs/hardhat-waffle");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async(taskArgs, hre) => {
    const accounts = await hre.ethers.getSigners();

    for (const account of accounts) {
        console.log(account.address);
    }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
    solidity: {
        compilers: [{
                version: "0.8.15"
            },
            {
                version: "0.6.6"
            },
            {
                version: "0.5.16"
            }
        ]
    },


    // solidity: "0.8.15",
    network: {
        hardhat: {
            chainId: 31337,
            forking: {
                // Using Alchemy
                url: `https://mainnet.infura.io/v3/31a345975dc8409eb4e7b061b7980f5d`, // url to RPC node, ${ALCHEMY_KEY} - must be your API key
                // Using Infura
                // url: `https://mainnet.infura.io/v3/${INFURA_KEY}`, // ${INFURA_KEY} - must be your API key
                blockNumber: 15109967, // a specific block number with which you want to work
            },
        }
    },
};
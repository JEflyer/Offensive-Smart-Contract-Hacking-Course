const { ethers } = require("hardhat");
const { expect } = require("chai")
const uniFactoryABI = require("../node_modules/@uniswap/v2-core/build/UniswapV2Factory.json").abi
const uniFactoryBYTECODE = require("../node_modules/@uniswap/v2-core/build/UniswapV2Factory.json").bytecode
const uniRouterABI = require("../node_modules/@uniswap/v2-periphery/build/UniswapV2Router02.json").abi
const uniRouterBYTECODE = require("../node_modules/@uniswap/v2-periphery/build/UniswapV2Router02.json").bytecode


let pool, Pool
let dao, DAO
let unirouter, UniRouter
let unifactory, UniFactory
let tokenA, TokenA
let tokenB, TokenB
let weth
let lender

let TokenA_ETH_Pair

let deployer, attacker

let initBal

//Initial Token A in A & B pool 
const INIT_TOKEN_A_BAL_IN_POOL = ethers.utils.parseEther("10000")

//Initial Token B in A & B pool
const INIT_TOKEN_B_BAL_IN_POOL = ethers.utils.parseEther("1000000")

//Initial Ethereum in ETH & A Pool
const INIT_ETH_BAL_IN_ETH_POOL = ethers.utils.parseEther("10000")

//Initial Token A in A & ETH pool
const INIT_TOKEN_A_BAL_IN_ETH_POOL = ethers.utils.parseEther("10000")

//Initial Token B in the DAO contract
const INIT_TOKEN_B_IN_DAO = ethers.utils.parseEther("250000")

//Initial Token A in the Lender contract
const INIT_TOKEN_A_BAL_IN_LENDER = ethers.utils.parseEther("25000")


describe("Setting up", () => {

    //Scenario conditions that must be set before the exploit is run
    before(async() => {

        //Get the signers for deployer & attacker
        [deployer, attacker] = await ethers.getSigners();

        //Build the contract factories for the Uniswap V2 Router & Factory with their ABI's, BYTECODE's & deployer signer 
        unifactory = new ethers.ContractFactory(uniFactoryABI, uniFactoryBYTECODE, deployer)
        unirouter = new ethers.ContractFactory(uniRouterABI, uniRouterBYTECODE, deployer)

        //Short hand deployment
        //Get & Deploy WETH contract
        weth = await (await ethers.getContractFactory('WETH9', deployer)).deploy();

        //Wait until deployed
        await weth.deployed()

        //Deploy the Uniswap V2 Factory with the deployers address passed through
        UniFactory = await unifactory.deploy(deployer.address)

        //Wait until deployed
        await UniFactory.deployed()

        //Deploy the Uniswap V2 Router with the factory address & WETH address
        UniRouter = await unirouter.deploy(UniFactory.address, weth.address)

        //Wait until deployed
        await UniRouter.deployed()

        //Get the contract factories for both tokens with the deployer signer
        tokenA = await ethers.getContractFactory("TokenA", deployer)
        tokenB = await ethers.getContractFactory("TokenB", deployer)

        //Deploy token with a limit of 1M tokens being sent to the deployer
        TokenA = await tokenA.deploy("", "", ethers.utils.parseEther("100000"))

        //Wait until deployed
        await TokenA.deployed()

        //Deploy token with a limit of 10M tokens being sent to the deployer
        TokenB = await tokenB.deploy("", "", ethers.utils.parseEther("10000000"))

        //Wait until deployed
        await TokenB.deployed()

        //Shorthand get & deploye of DAO with deployer signer & deploying with token B address
        dao = await (await ethers.getContractFactory("DAO4", deployer)).deploy(TokenB.address)

        //Wait until deployed
        await dao.deployed()

        //Transfer token B to DAO
        await TokenB.transfer(dao.address, INIT_TOKEN_B_IN_DAO)

        //Super shorthand get, deploy & set, wait till deployed
        //Deploy the Lender pool from deployer with Token A address 
        await (lender = await (await ethers.getContractFactory("Lender4", deployer)).deploy(TokenA.address)).deployed()

        //Transfer tokens to Lender
        await TokenA.transfer(lender.address, INIT_TOKEN_A_BAL_IN_LENDER)

        //Approve the Uniswap V2 Router to spend the deployers tokens
        await TokenA.approve(UniRouter.address, INIT_TOKEN_A_BAL_IN_POOL)
        await TokenB.approve(UniRouter.address, INIT_TOKEN_B_BAL_IN_POOL)

        //Set the ETH balance of the deployer to 1M ETH
        await ethers.provider.send("hardhat_setBalance", [
            deployer.address,
            ethers.utils.parseEther("100000").toHexString(),
        ]);

        //Set the balance of the attacker to 20 ETH
        await ethers.provider.send("hardhat_setBalance", [
            attacker.address,
            "0x1158e460913d00000", // 20 ETH
        ]);

        //Get the last block number
        let num = await ethers.provider.getBlockNumber()

        //Get the last block
        let block = await ethers.provider.getBlock(num)

        //Add token A & B to a pool
        // function addLiquidity(
        //     address tokenA,
        //     address tokenB,
        //     uint amountADesired,
        //     uint amountBDesired,
        //     uint amountAMin,
        //     uint amountBMin,
        //     address to,
        //     uint deadline
        await UniRouter.addLiquidity(
            TokenA.address,
            TokenB.address,
            INIT_TOKEN_A_BAL_IN_POOL,
            INIT_TOKEN_B_BAL_IN_POOL,
            0,
            0,
            deployer.address,
            block.timestamp + 200
        )

        //Get last block number
        num = await ethers.provider.getBlockNumber()

        //Get last block
        block = await ethers.provider.getBlock(num)

        //Approve the router to spend token A
        await TokenA.approve(UniRouter.address, INIT_TOKEN_A_BAL_IN_ETH_POOL);

        //Add token A & ETH to a pool
        // function addLiquidityETH(
        //     address token,
        //     uint amountTokenDesired,
        //     uint amountTokenMin,
        //     uint amountETHMin,
        //     address to,
        //     uint deadline
        await UniRouter.addLiquidityETH(
            TokenA.address,
            INIT_TOKEN_A_BAL_IN_ETH_POOL,
            0,
            0,
            deployer.address,
            block.timestamp + 200, { value: INIT_ETH_BAL_IN_ETH_POOL }
        )

        //Get pair address
        TokenA_ETH_Pair = await UniFactory.getPair(weth.address, TokenA.address)

        //Get initial balance of the attacker
        initBal = await ethers.provider.getBalance(attacker.address)
    })

    it("Should allow you to drain all ETH from token A - ETH LP pool", async() => {
        //Execute your exploit here

        //Get the contract factory for the attack contract with the attacker signer
        let factory = await ethers.getContractFactory("Attack4", attacker)

        // constructor(
        //     address _router,
        //     address _pool,
        //     address _DAO,
        //     address _tokenA,
        //     address _tokenB,
        //     address _weth
        //Deploy the attack contract
        let contract = await factory.deploy(
            UniRouter.address,
            lender.address,
            dao.address,
            TokenA.address,
            TokenB.address,
            weth.address
        )

        //Wait until deployed
        await contract.deployed()

        //Call the attack function 
        await contract.attack()
    })

    //Once our explout has been ran
    after(async() => {

        //Check that the ETH balance of the attacker has increased
        expect(await ethers.provider.getBalance(attacker.address))
            .to.be.gt(initBal)

        //Check that the ETH balance of the token pair is less than 50 ETH
        expect(
            await ethers.provider.getBalance(
                TokenA_ETH_Pair
            )
        ).to.be.lt("50")

    })

})
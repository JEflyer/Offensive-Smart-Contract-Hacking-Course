const { ethers } = require("hardhat")
const { expect } = require("chai")

let deployer, attacker
let pool, Pool
let dao, DAO

let initBal

describe("Setting Up", () => {

    //Scenario conditions that must be set before the exploit is run
    before(async() => {

        //Get the signers for deployer & attacker
        [deployer, attacker] = await ethers.getSigners()

        //Build contract factories for Lender & DAO with deployer signer attached
        pool = await ethers.getContractFactory("Lender3", deployer)
        dao = await ethers.getContractFactory("DAO3", deployer)

        //Deploy the lender pool
        Pool = await pool.deploy()

        //Wait until deployed
        await Pool.deployed()

        //Deploy the DAO
        DAO = await dao.deploy()

        //Wait until deployed
        await DAO.deployed()

        //The deployer deposits 500 ETH into the Pool
        await Pool.connect(deployer).deposit({ value: ethers.utils.parseEther("500") })

        //The deployer deposits 50 ETH into the DAO
        await DAO.connect(deployer).deposit({ value: ethers.utils.parseEther("50") })

        //Get the intial balance of the attacker wallet
        initBal = await ethers.provider.getBalance(attacker.address)

        //Check that the balance od the pool contract before starting is equal to 500 ETH
        expect(
            await ethers.provider.getBalance(Pool.address)
        ).to.be.equal(ethers.utils.parseEther("500"))

        //Check that the balance of the DAO contract before starting is equal to 50 ETH
        expect(
            await ethers.provider.getBalance(DAO.address)
        ).to.be.equal(ethers.utils.parseEther("50"))
    })


    it("Should allow the attacker to steal all the funds from the DAO", async() => {
        //Put your exploit here

        //Build the contract factory for the attack contract with the attacker signer
        let factory = await ethers.getContractFactory("Attack3", attacker)

        //Deploy the attack contract with the DAO & Pool addresses 
        let contract = await factory.deploy(
            DAO.address,
            Pool.address
        )

        //Wait until deployed
        await contract.deployed()

        //Call the attack function on the attack contract
        await contract.attack()
    })


    //Once our explout has been ran
    after(async() => {

        //Check that the balance of the DAO equals 0
        expect(
            await ethers.provider.getBalance(DAO.address)
        ).to.be.equal("0")

        //Check that the attackers balance has increased
        expect(
            await ethers.provider.getBalance(attacker.address)
        ).to.be.gt(initBal)
    })
})
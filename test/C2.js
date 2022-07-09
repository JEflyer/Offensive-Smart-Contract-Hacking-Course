const { ethers } = require("hardhat");
const { expect } = require("chai")

let lender, Lender

let deployer, attacker

let initBal

describe("Setting Up", () => {

    //Scenario conditions that must be set before the exploit is run
    before(async() => {

        //Get the signers for deployer & attacker
        [deployer, attacker] = await ethers.getSigners()

        //Get the contract factory for the Lender pool with the deployer signer
        lender = await ethers.getContractFactory("Lender2", deployer)

        //Deploy the lender contract
        Lender = await lender.deploy()

        //Wait until the lender contract is deployed
        await Lender.deployed()

        //The deployer deposits 500 ETH into the Lender pool
        await Lender.deposit({ value: ethers.utils.parseEther("500") })

        //Get the initial balance of the attacker
        initBal = await ethers.provider.getBalance(attacker.address)

    })

    it("Should allow the attacker to steal all 500 ETH", async() => {
        //Put your exploit here

        //Build contract factory of the attack contract with the attacker signer attached
        let factory = await ethers.getContractFactory("Attack2", attacker)

        //Deploy the attack contract with the Lender pools address
        let theContract = await factory.deploy(Lender.address)

        //Wait until the attack contract is deployed
        await theContract.deployed()

        //Call the attack function
        await theContract.attack()
    })

    //Once our explout has been ran
    after(async() => {

        //Check that the balance of the attacker has been increased
        expect(
            await ethers.provider.getBalance(attacker.address)
        ).to.be.gt(initBal)

        //Check that the balance of the Lender pool equals 0
        expect(
            await ethers.provider.getBalance(Lender.address)
        ).to.be.equal("0")

    })
})
const { ethers } = require("hardhat");
const { expect } = require("chai")

let stake, Stake

let deployer, attacker

let initBal

describe("Setting up", () => {

    //Scenario conditions that must be set before the exploit is run
    before(async() => {

        //Get the signers for deployer & attacker
        [deployer, attacker] = await ethers.getSigners();

        //Build the Contract Factory & assign the deployer as the wallet that will be used to deploy it
        stake = await ethers.getContractFactory("Stake1", deployer)

        //Deploy the staking contract
        Stake = await stake.deploy()

        //Wait until the staking contract is deployed
        await Stake.deployed()

        //Deployer stakes 100 eth in the staking contract 
        await Stake.connect(deployer).stake({ value: ethers.utils.parseEther("100") })

        //Get the intial balance of the attacker
        initBal = await ethers.provider.getBalance(attacker.address)
    })

    it("Should allow you to take all 100 eth from the staking contract", async() => {
        //Execute your exploit here

        //Build Factory with the attacker signer
        let factory = await ethers.getContractFactory("Attack1", attacker)

        //deploye the attack contract with the staking contract address being passed in
        let contract = await factory.deploy(
            Stake.address
        )

        //Wait until the attack contract is deployed
        await contract.deployed()

        //Call the attack function on the attack contract with a value of 1 ETH
        await contract.attack({ value: ethers.utils.parseEther("1") })

    })

    //Once our explout has been ran
    after(async() => {
        //Check that the attackers ETH balance has increased 
        expect(await ethers.provider.getBalance(attacker.address))
            .to.be.gt(initBal)

        //Check that the balance of the staking contract has fallen to 0 ETH
        expect(
            await ethers.provider.getBalance(
                Stake.address
            )
        ).to.be.equal("0")
    })
})
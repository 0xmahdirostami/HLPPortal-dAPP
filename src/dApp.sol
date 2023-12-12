// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {console2} from "forge-std/Test.sol";
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface portal {
    function convert(address _token, uint256 _minReceived, uint256 _deadline) external;
    function getPendingRewards(address _rewarder) external view returns(uint256 claimableReward);
    function claimRewardsHLPandHMX() external;
    function claimRewardsManual(address[] memory _pools, address[][] memory _rewarders) external;
}

interface AggregatorV3Interface{
    function latestRoundData() external view returns(uint80,int,uint,uint,uint80);
}

interface ISwapRouter{
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

interface IWeth is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

error ExpectedProfitToLow(uint256);
error FinancialLoss(uint256);
error NotProfitable(uint256);

//////////////////////////////////////////////////////////
//                wrote by mahdi rostami                //
//      if you found any issue, please let me know.     //
//                twitter: 0xmahdirostami               //
//////////////////////////////////////////////////////////

// Feel free to contribute
// todo
// 1. price oracle for PSM
// 2. another price orcale for ARB
// 3. price oracle for USDCe
// 4. events
// 5. more errors
// 6. Accept WETH

contract dApp {

    address public constant USDCE = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address public constant ARB = 0x912CE59144191C1204E64559FE8253a0e49E6548;
    address public constant PSM = 0x17A8541B82BF67e10B0874284b4Ae66858cb1fd5;
    address public constant WETH9 = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    address constant HLP_PORTAL_ADDRESS = 0x24b7d3034C711497c81ed5f70BEE2280907Ea1Fa;
    address constant USDCE_REWARDER = 0x665099B3e59367f02E5f9e039C3450E31c338788;
    address constant ARB_POOL = 0xbE8f8AF5953869222eA8D39F1Be9d03766010B1C;
    address constant ARB_REWARDER = 0x238DAF7b15342113B00fA9e3F3E60a11Ab4274fD;
    address constant SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant DATA_FEED = 0xb2A824043730FE05F3DA2efaFa1CBbe83fa548D6;

    uint256 constant AMOUNT = 100000000000000000000000; // 100k
    uint256 constant ONE = 100;
    uint256 constant USDCE_DECIMALS = 10**6;
    uint256 constant USDCE_REMAIN_DECIMALS = 10**12;
    uint256 constant DECIMALS = 10**18;
    uint256 constant PRICE_FEED_DECIMALS = 10**8;

    ISwapRouter constant swapRouter = ISwapRouter(SWAP_ROUTER);
    portal constant HLP_PORTAL = portal(HLP_PORTAL_ADDRESS);
    AggregatorV3Interface constant ARB_DATA_FEED = AggregatorV3Interface(DATA_FEED); //8 Decimals
    IWeth constant WETH = IWeth(WETH9);

    uint48 public fee = 20;
    uint48 public minProfit;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    // @_price = Worth of 100K PSM in dollar
    // @_expectedprofit = expected profit in dollar
    function convertUSDCE(uint256 _price, uint256 _expectedprofit) public {
        (uint256 total, uint256 profit) = _checkProfit(USDCE, _price, _expectedprofit);
        HLP_PORTAL.claimRewardsHLPandHMX();
        IERC20(PSM).transferFrom(msg.sender, address(this), AMOUNT);
        IERC20(PSM).approve(HLP_PORTAL_ADDRESS, AMOUNT);
        HLP_PORTAL.convert(USDCE, total/USDCE_REMAIN_DECIMALS, block.timestamp);
        _swapOut(USDCE);
    }
    // @_price = Worth of 100K PSM in dollar
    // @_expectedprofit = expected profit in dollar
    function convertARB(uint256 _price, uint256 _expectedprofit) public {
        (uint256 total, uint256 profit) = _checkProfit(ARB, _price, _expectedprofit);
        address[] memory pools = new address[](1);
        pools[0] = ARB_POOL;
        address[][] memory rewarders = new address[][](1);
        rewarders[0] = new address[](1);
        rewarders[0][0] = ARB_REWARDER;
        HLP_PORTAL.claimRewardsManual(pools, rewarders);
        IERC20(PSM).transferFrom(msg.sender, address(this), AMOUNT);
        IERC20(PSM).approve(HLP_PORTAL_ADDRESS, AMOUNT);
        HLP_PORTAL.convert(ARB, total, block.timestamp);
        _swapOut(ARB);
    }
    function _checkProfit(address _token, uint256 _price, uint256 _expectedprofit) public view returns(uint256 total, uint256 profit){
        if(_expectedprofit < minProfit){revert ExpectedProfitToLow(minProfit);}
        if (_token == USDCE){
            (profit, total) = checkUSDCE(_price);
        } else if (_token == ARB){
            (profit, total) = checkARB(_price);
        } else {
            revert();
        }
        if(profit < _expectedprofit*DECIMALS){revert NotProfitable(profit/DECIMALS);}
        return (total, profit);
    }
    // @_price = Worth of 100K PSM in dollar
    function checkUSDCE(uint256 _price) public view returns(uint256 profit, uint256 total){
        // uint256 psmWorth = psmWorth(); todo remove _price and fetch PSM price
        uint256 psmWorth = _price*DECIMALS;
        uint256 balance = IERC20(USDCE).balanceOf(HLP_PORTAL_ADDRESS);
        uint256 pending = HLP_PORTAL.getPendingRewards(USDCE_REWARDER);
        total = balance + pending;
        total = total*USDCE_REMAIN_DECIMALS;
        if(total < psmWorth){revert FinancialLoss(total/DECIMALS);}
        profit = total - psmWorth; 
    }
    // @_price = Worth of 100K PSM in dollar
    function checkARB(uint256 _price) public view returns(uint256 profit, uint256 total){
        // uint256 psmWorth = psmWorth(); todo remove _price and fetch PSM price
        uint256 psmWorth = _price*DECIMALS;
        uint256 balance = IERC20(ARB).balanceOf(HLP_PORTAL_ADDRESS);
        uint256 pending = HLP_PORTAL.getPendingRewards(ARB_REWARDER);
        total = balance + pending;
        uint256 ARBprice = getARBPriceChainLink();
        uint256 worth = ARBprice * total / PRICE_FEED_DECIMALS; //(8 decimals + 18 decimals) - (8 decimal) = 18 decimals 
        if(worth < psmWorth){revert FinancialLoss(worth/DECIMALS);}
        profit = worth - psmWorth; 
    }   
    function getARBPriceChainLink() public view returns(uint256){
        (,int answer,,,) = ARB_DATA_FEED.latestRoundData();
        return uint256(answer);
    }
    // todo remove _price and fetch PSM price
    // function psmWorth() public view returns(uint265){
    //     uint256 psmPrice = ...;
    //     retun(psmPrice * AMOUNT / pricefeeddecimals);
    // }
    function _swapOut(address _token) public returns(uint256 amountOut){
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).approve(SWAP_ROUTER, balance);
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _token,
                tokenOut: WETH9,
                fee: 500,
                recipient: owner,
                deadline: block.timestamp,
                amountIn: balance,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

    // owner functions
    function getTOKEN(address _token) public onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner, balance);
    }
    function getETH() public payable onlyOwner {
        payable(owner).call{value: address(this).balance};
    }
    function changeFee(uint48 _fee) public onlyOwner {
        require(_fee < ONE/2);
        fee = _fee;
    }
    function changeMinProfit(uint48 _minProfit) public onlyOwner {
        require(_minProfit >= 1);
        minProfit = _minProfit;
    }    
    function changeOwner(address _owner) public onlyOwner {
        owner = _owner;
    }
    receive() external payable {} 
}

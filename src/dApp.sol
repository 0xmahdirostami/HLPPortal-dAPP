// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

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

contract dApp {

    address constant HLPPORTAL = 0x24b7d3034C711497c81ed5f70BEE2280907Ea1Fa;
    address constant USDCE = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant ARB = 0x912CE59144191C1204E64559FE8253a0e49E6548;
    address constant PSM = 0x17A8541B82BF67e10B0874284b4Ae66858cb1fd5;
    address constant USDCEREWARDER = 0x665099B3e59367f02E5f9e039C3450E31c338788;
    address constant ARBPOOL = 0xbE8f8AF5953869222eA8D39F1Be9d03766010B1C;
    address constant ARBREWARDER = 0x238DAF7b15342113B00fA9e3F3E60a11Ab4274fD;

    uint256 constant AMOUNT = 100000000000000000000000; // 100k 
    uint256 constant ONE = 100;
    uint256 constant USDCEDECIMALS = 10**6;
    uint256 constant ARBDECIMALS = 10**18;
    uint256 constant PRICEFEEDDECIMALS = 10**8;

    portal constant HLPport = portal(0x24b7d3034C711497c81ed5f70BEE2280907Ea1Fa);
    AggregatorV3Interface  constant ARBPDATAFEED = AggregatorV3Interface(0xb2A824043730FE05F3DA2efaFa1CBbe83fa548D6); //8 Decimals

    uint256 public fee;
    address public owner;


    constructor(){
        owner = msg.sender;
        fee = 25;
    }

    // _price = Worth of 100K PSM in dollar
    function convertUSDCE(uint256 _price, uint256 _expectedprofit) public {
        (uint256 profit, uint256 total) = checkUSDCE(_price);
        require(profit > _expectedprofit*USDCEDECIMALS);
        HLPport.claimRewardsHLPandHMX();
        IERC20(PSM).transferFrom(msg.sender, address(this), AMOUNT);
        IERC20(PSM).approve(HLPPORTAL, AMOUNT);
        HLPport.convert(USDCE, total, block.timestamp);
        uint256 protocolFee = profit * fee / ONE;
        IERC20(USDCE).transfer(owner, protocolFee);
        IERC20(USDCE).transfer(msg.sender, IERC20(USDCE).balanceOf(address(this)));
    }
    function checkUSDCE(uint256 _price) public view returns(uint256 profit, uint256 total){
        uint256 psmWorth = _price*USDCEDECIMALS;
        uint256 balance = IERC20(USDCE).balanceOf(HLPPORTAL);
        uint256 pending = HLPport.getPendingRewards(USDCEREWARDER);
        total = balance + pending;
        require(total >= psmWorth, "Financial loss");
        profit = total - psmWorth; 
    }
    // _price = Worth of 100K PSM in dollar
    function convertARB(uint256 _price, uint256 _expectedprofit) public {
        (uint256 profit, uint256 total) = checkARB(_price);
        require(profit > _expectedprofit*ARBDECIMALS);
        address[] memory pools = new address[](1);
        pools[0] = ARBPOOL;
        address[][] memory rewarders = new address[][](1);
        rewarders[0] = new address[](1);
        rewarders[0][0] = ARBREWARDER;
        HLPport.claimRewardsManual(pools, rewarders);
        IERC20(PSM).transferFrom(msg.sender, address(this), AMOUNT);
        IERC20(PSM).approve(HLPPORTAL, AMOUNT);
        HLPport.convert(ARB, total, block.timestamp);
        uint256 protocolFee = profit * fee / ONE;
        IERC20(ARB).transfer(owner, protocolFee);
        IERC20(ARB).transfer(msg.sender, IERC20(ARB).balanceOf(address(this)));
    }
    function checkARB(uint256 _price) public view returns(uint256 profit, uint256 total){
        uint256 psmWorth = _price*ARBDECIMALS;
        uint256 balance = IERC20(ARB).balanceOf(HLPPORTAL);
        uint256 pending = HLPport.getPendingRewards(ARBREWARDER);
        total = balance + pending;
        uint256 ARBprice = getARBPrice();
        uint256 worth = ARBprice * total / PRICEFEEDDECIMALS; //(8 decimals + 18 decimals) - (8 decimal) = 18 decimals 
        require(worth >= psmWorth, "Financial loss");
        profit = worth - psmWorth; 
    }   
    function getARBPrice() public view returns(uint256){
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = ARBPDATAFEED.latestRoundData();
        return uint256(answer);
    }
    function getTOKEN(address _token) public {
        require(msg.sender == owner);
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner, balance);
    }
    function getETH() public {
        require(msg.sender == owner);
        payable(owner).call{value: address(this).balance};
    }
    function changeFee(uint256 _fee) public {
        require(msg.sender == owner);
        require(_fee < ONE/2);
        fee = _fee;
    }
    function changeOwner(address _owner) public {
        require(msg.sender == owner);
        owner = _owner;
    }
    receive() external payable {} 


}

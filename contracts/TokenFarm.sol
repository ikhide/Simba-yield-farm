// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; 

contract TokenFarm is Ownable {
    mapping(address => mapping(address => uint256)) public stakingBalance;    //mapping token address -> staked address -> amount staked
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenPriceFeedMapping;
    address [] allowedTokens;
    address [] emptyArray;
    address [] public stakers;
    address [] public newStakers;
    IERC20 public simbaToken;

    // stakeTokens - 
    // addAllowedTokens -
    // unStakeTokens 
    // IssueRewardTokens  -
    // getEthValue - 
    
    constructor(address _simbaTokenAddress) {
        simbaToken = IERC20(_simbaTokenAddress); //set default reward token
    }

    //MAIN FUNCTIONS
    function stakeTokens(uint256 _amount, address _token) public {
        //what tokens can they stake?
        //how much can they stake?
        require(_amount> 0,"Amount must be more than zero");
        require(tokenIsAllowed(_token),"Token is not allowed");
        //use transferFrom Function because we do not own the tokens. We also need the token abi from IERC20 interface
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        //add to stakers
        updateUniqueTokensStaked(msg.sender, _token);
        //add to stakingBalance
        stakingBalance[_token][msg.sender] += _amount;

        // This a staker's first token, add to staker's list
        if(uniqueTokensStaked[msg.sender] == 1){
            stakers.push(msg.sender);
        }
    }

    function addAllowedToken(address _token) public onlyOwner{
        //add token to allowedTokens
        require(_token != address(0),"Token must be a valid address");
        require(!tokenIsAllowed(_token),"Token already added");
        allowedTokens.push(_token);
    }

    function issueTokens() public onlyOwner {
        // reward all stakers based on amount staked
        for(uint256 stakersIndex=0; stakersIndex<stakers.length; stakersIndex++ ){
            address recipient = stakers[stakersIndex];
            uint userTotalValue = getUserTotalValue(recipient);
            //send them their token reward
            //get their eqivalent value in simbaToken
            simbaToken.transfer(recipient, userTotalValue);
        }
    }

    function untakeTokens(address _token) public  {
        //check if token is allowed
        require(tokenIsAllowed(_token),"Token is not allowed");
        //get amount staked
        uint256 amountStaked = stakingBalance[_token][msg.sender];
        //check if token is staked
        require(amountStaked > 0,"Token is not staked");
        //unstake tokens
        IERC20(_token).transferFrom(msg.sender, address(this), amountStaked);
        //remove from stakingBalance
        stakingBalance[_token][msg.sender] = 0;
        //remove from uniqueTokensStaked
        uniqueTokensStaked[msg.sender] -= 1;
        //remove from stakers
        removeStaker(msg.sender);
    }
    

    // HELPER FUNCTION

    function updateUniqueTokensStaked(address _user, address _token) internal{
        if(stakingBalance[_token][_user] <= 0){
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    function removeStaker(address _user) internal {
        //remove from stakers if they have no tokens staked
        for(uint256 tokenIndex=0; tokenIndex<allowedTokens.length; tokenIndex++){
            if(stakingBalance[allowedTokens[tokenIndex]][_user] > 0){
                return;
            }
        }

        //if function has not returned, this means staker has no staked tokens, loop through stakers and remove _user
        for(uint256 stakerIndex=0; stakerIndex<stakers.length; stakerIndex++){
            if(stakers[stakerIndex] != _user){
                newStakers.push(stakers[stakerIndex]);
            }
        }
        stakers = newStakers;
        // empty newStakers
        newStakers = emptyArray;
    }

    function tokenIsAllowed(address _token) public returns(bool){
        for (uint256 tokenIndex=0; tokenIndex<allowedTokens.length; tokenIndex++){
            if(allowedTokens[tokenIndex]==_token){
                return true;
            } else {
                return false;
            }
        }
    }

    function getUserTotalValue(address _user) public view returns(uint256){
        uint256 totalValue = 0;
        require(_user != address(0),"User must be a valid address");
        require(uniqueTokensStaked[_user] > 0,"User has no tokens staked");
        for(uint256 tokenIndex=0; tokenIndex<allowedTokens.length; tokenIndex++){
            totalValue += getUserSingleTokenUsdValue(_user, allowedTokens[tokenIndex]);
        }
        return totalValue;
    }

    function getUserSingleTokenUsdValue(address _user, address _token)
    public
    view returns (uint256){
        // Get amount in dollars user has staked
        if(uniqueTokensStaked[_user] <= 0){
            return 0;
        }
        //get token price in dollars X stakingBalance[_token][user]
        //decimals in the number of extra zeros this comes with. In this case. So we have to remove it to get the actual value
    ( uint tokenPrice, uint decimals) = getTokenPrice(_token);
    return (tokenPrice * stakingBalance[_token][_user]/10**decimals);
    }

    function getTokenPrice(address _token) public view returns(uint256,uint256) {
        //price feed address
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
         (,int price,,,) =  priceFeed.latestRoundData();
         uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price),decimals); 
    }

    function setPriceFeedContract(address _token, address _priceFeed) public onlyOwner{
        require(_token != address(0),"Token must be a valid address");
        require(_priceFeed != address(0),"Price feed must be a valid address");
        require(tokenIsAllowed(_token),"Token is not allowed");
        tokenPriceFeedMapping[_token] = _priceFeed;
    }
}
pragma solidity 0.8.0;
// SPDX-License-Identifier: MIT

import "./PolyInterface.sol";
import "./UnilendFlashLoanReceiverBase.sol";
import "./IERC20.sol";
import "./TokenSwap.sol";





contract Flashloan is UnilendFlashLoanReceiverBase{
    using SafeMath for uint256;
    
    constructor() {}
    
    address betAddress = 0x9Fad71370AE14Ef15dbd1A1767633C8e53d01A44;
    address zero = 0x0000000000000000000000000000000000000000;
    address private constant UNISWAP_V2_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    
    //address of WETH token.  This is needed because some times it is better to trade through WETH.  
    //you might get a better price using WETH.  
    //example trading from token A to WETH then WETH to token B might result in a better price
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

   function fallback () external payable {}

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    )
        external
    {
        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance, was the flashLoan successful?");
        _params;
        IWETH(WETH).withdraw(4000000000000000000);

 
    

    //this swap function is used to trade from one token to another
    //the inputs are self explainatory
    //token in = the token address you want to trade out of
    //token out = the token address you want as the output of this trade
    //amount in = the amount of tokens you are sending in
    //amount out Min = the minimum amount of tokens you want out of the trade
    //to = the address you want the tokens to be sent to
    
   
    
       //this function will return the minimum amount from a swap
       //input the 3 parameters below and it will return the minimum amount out
       //this is needed for the swap function above
   
        poly(betAddress).placeBet{value:4000000000000000000}(2,2,zero);
        IWETH(WETH).deposit{value:4000000000000000000}();

        
        //
        // Your logic goes here.
        // !! Ensure that *this contract* has enough of `_reserve` funds to payback the `_fee` !!
        //
        
        
        uint totalDebt = _amount.add(_fee);
        transferInternal(getUnilendCoreAddress(), _reserve, totalDebt);
    }
    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to) external {
      
    //first we need to transfer the amount in tokens from the msg.sender to this contract
    //this contract will have the amount of in tokens
    // IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
    
    //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
    //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract 
    IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

    //path is an array of addresses.
    //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
    //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
    address[] memory path;
    if (_tokenIn == WETH || _tokenOut == WETH) {
      path = new address[](2);
      path[0] = _tokenIn;
      path[1] = _tokenOut;
    } else {
      path = new address[](3);
      path[0] = _tokenIn;
      path[1] = WETH;
      path[2] = _tokenOut;
    }
        //then we will call swapExactTokensForTokens
        //for the deadline we will pass in block.timestamp
        //the deadline is the latest time the trade is valid for
        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
    }
      function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) {

       //path is an array of addresses.
       //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
       //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }
        
        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);
        return amountOutMins[path.length -1];  
    }  

    
    function flashloan(address _asset, uint _amount) payable external {
        bytes memory data;
        
        flashLoan(address(this), _asset, _amount, data);
    }
    function withdraw()public  {
        payable(msg.sender).transfer(address(this).balance);

    }
    function withdrawToken(address _tokenContract, uint256 _amount) public {
        IERC20 tokenContract = IERC20(_tokenContract);
        
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, _amount);
    }
}


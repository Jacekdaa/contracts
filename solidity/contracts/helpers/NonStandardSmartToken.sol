pragma solidity 0.4.26;
import './NonStandardERC20Token.sol';
import './interfaces/INonStandardSmartToken.sol';
import '../utility/Owned.sol';

/*
    Smart Token v0.3

    'Owned' is specified here for readability reasons
*/
contract NonStandardSmartToken is INonStandardSmartToken, Owned, NonStandardERC20Token {
    using SafeMath for uint256;


    string public version = '0.3';

    bool public transfersEnabled = true;    // true if transfer/transferFrom are enabled, false if not

    // triggered when a smart token is deployed - the _token address is defined for forward compatibility, in case we want to trigger the event from a factory
    event NewSmartToken(address _token);
    // triggered when the total supply is increased
    event Issuance(uint256 _amount);
    // triggered when the total supply is decreased
    event Destruction(uint256 _amount);

    /**
      * @dev initializes a new NonStandardSmartToken instance
      * 
      * @param _name       token name
      * @param _symbol     token short symbol, minimum 1 character
      * @param _decimals   for display purposes only
    */
    constructor(string _name, string _symbol, uint8 _decimals)
        public
        NonStandardERC20Token(_name, _symbol, _decimals)
    {
        emit NewSmartToken(address(this));
    }

    // allows execution only when transfers aren't disabled
    modifier transfersAllowed {
        assert(transfersEnabled);
        _;
    }

    /**
      * @dev disables/enables transfers
      * can only be called by the contract owner
      * 
      * @param _disable    true to disable transfers, false to enable them
    */
    function disableTransfers(bool _disable) public ownerOnly {
        transfersEnabled = !_disable;
    }

    /**
      * @dev increases the token supply and sends the new tokens to an account
      * can only be called by the contract owner
      * 
      * @param _to         account to receive the new amount
      * @param _amount     amount to increase the supply by
    */
    function issue(address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_to)
        notThis(_to)
    {
        totalSupply = totalSupply.add(_amount);
        balanceOf[_to] = balanceOf[_to].add(_amount);

        emit Issuance(_amount);
        emit Transfer(this, _to, _amount);
    }

    /**
      * @dev removes tokens from an account and decreases the token supply
      * can be called by the contract owner to destroy tokens from any account or by any holder to destroy tokens from his/her own account
      * 
      * @param _from       account to remove the amount from
      * @param _amount     amount to decrease the supply by
    */
    function destroy(address _from, uint256 _amount) public {
        require(msg.sender == _from || msg.sender == owner); // validate input

        balanceOf[_from] = balanceOf[_from].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

        emit Transfer(_from, this, _amount);
        emit Destruction(_amount);
    }

    // ERC20 standard method overrides with some extra functionality

    /**
      * @dev send coins
      * throws on any error rather then return a false flag to minimize user errors
      * in addition to the standard checks, the function throws if transfers are disabled
      * 
      * @param _to      target address
      * @param _value   transfer amount
    */
    function transfer(address _to, uint256 _value) public transfersAllowed {
        super.transfer(_to, _value);
    }

    /**
      * @dev an account/contract attempts to get the coins
      * throws on any error rather then return a false flag to minimize user errors
      * in addition to the standard checks, the function throws if transfers are disabled
      * 
      * @param _from    source address
      * @param _to      target address
      * @param _value   transfer amount
    */
    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed {
        super.transferFrom(_from, _to, _value);
    }
}

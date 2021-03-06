pragma solidity ^0.4.21;

import "../registry/contracts/HasRegistry.sol";
import "./modularERC20/ModularBurnableToken.sol";
import "./modularERC20/ModularMintableToken.sol";

// This allows for transaction fees to be assessed on transfer, burn, and mint.
// The fee upon burning n tokens (other fees computed similarly) is:
// (n * burnFeeNumerator / burnFeeDenominator) + burnFeeFlat
// Note that what you think of as 1 TrueUSD token is internally represented
// as 10^18 units, so e.g. a one-penny fee for burnFeeFlat would look like
// burnFeeFlat = 10^16
// The fee for transfers is paid by the recipient.
contract TokenWithFees is ModularMintableToken, ModularBurnableToken, HasRegistry {
    string public constant NO_FEES = "noFees";
    uint256 public transferFeeNumerator = 0;
    uint256 public transferFeeDenominator = 10000;
    uint256 public mintFeeNumerator = 0;
    uint256 public mintFeeDenominator = 10000;
    uint256 public mintFeeFlat = 0;
    uint256 public burnFeeNumerator = 0;
    uint256 public burnFeeDenominator = 10000;
    uint256 public burnFeeFlat = 0;
    // All transaction fees are paid to this address.
    address public staker;

    event ChangeStaker(address indexed addr);
    event ChangeStakingFees(uint256 transferFeeNumerator,
                            uint256 transferFeeDenominator,
                            uint256 mintFeeNumerator,
                            uint256 mintFeeDenominator,
                            uint256 mintFeeFlat,
                            uint256 burnFeeNumerator,
                            uint256 burnFeeDenominator,
                            uint256 burnFeeFlat);

    function TokenWithFees() public {
        staker = msg.sender;
    }

    function burnAllArgs(address _burner, uint256 _value) internal {
        uint256 fee = payStakingFee(_burner, _value, burnFeeNumerator, burnFeeDenominator, burnFeeFlat, address(0));
        uint256 remaining = _value.sub(fee);
        super.burnAllArgs(_burner, remaining);
    }

    function mint(address _to, uint256 _value) onlyOwner public returns (bool) {
        super.mint(_to, _value);
        payStakingFee(_to, _value, mintFeeNumerator, mintFeeDenominator, mintFeeFlat, address(0));
    }

    // transfer and transferFrom both call this function, so pay staking fee here.
    function transferAllArgs(address _from, address _to, uint256 _value) internal {
        super.transferAllArgs(_from, _to, _value);
        payStakingFee(_to, _value, transferFeeNumerator, transferFeeDenominator, 0, _from);
    }

    function payStakingFee(address _payer, uint256 _value, uint256 _numerator, uint256 _denominator, uint256 _flatRate, address _otherParticipant) private returns (uint256) {
        // This check allows accounts to be whitelisted and not have to pay transaction fees.
        if (registry.hasAttribute(_payer, NO_FEES) || registry.hasAttribute(_otherParticipant, NO_FEES)) {
            return 0;
        }
        uint256 stakingFee = _value.mul(_numerator).div(_denominator).add(_flatRate);
        if (stakingFee > 0) {
            super.transferAllArgs(_payer, staker, stakingFee);
        }
        return stakingFee;
    }

    function changeStakingFees(uint256 _transferFeeNumerator,
                               uint256 _transferFeeDenominator,
                               uint256 _mintFeeNumerator,
                               uint256 _mintFeeDenominator,
                               uint256 _mintFeeFlat,
                               uint256 _burnFeeNumerator,
                               uint256 _burnFeeDenominator,
                               uint256 _burnFeeFlat) public onlyOwner {
        require(_transferFeeNumerator < _transferFeeDenominator);
        require(_mintFeeNumerator < _mintFeeDenominator);
        require(_burnFeeNumerator < _burnFeeDenominator);
        transferFeeNumerator = _transferFeeNumerator;
        transferFeeDenominator = _transferFeeDenominator;
        mintFeeNumerator = _mintFeeNumerator;
        mintFeeDenominator = _mintFeeDenominator;
        mintFeeFlat = _mintFeeFlat;
        burnFeeNumerator = _burnFeeNumerator;
        burnFeeDenominator = _burnFeeDenominator;
        burnFeeFlat = _burnFeeFlat;
        emit ChangeStakingFees(transferFeeNumerator,
                               transferFeeDenominator,
                               mintFeeNumerator,
                               mintFeeDenominator,
                               mintFeeFlat,
                               burnFeeNumerator,
                               burnFeeDenominator,
                               burnFeeFlat);
    }

    function changeStaker(address _newStaker) public onlyOwner {
        require(_newStaker != address(0));
        staker = _newStaker;
        emit ChangeStaker(_newStaker);
    }
}

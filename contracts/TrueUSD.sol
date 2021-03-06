pragma solidity ^0.4.21;

import "./modularERC20/ModularPausableToken.sol";
import "openzeppelin-solidity/contracts/ownership/NoOwner.sol";
import "./CanDelegate.sol";
import "./BurnableTokenWithBounds.sol";
import "./CompliantToken.sol";
import "./TokenWithFees.sol";
import "./StandardDelegate.sol";
import "./WithdrawalToken.sol";

// This is the top-level ERC20 contract, but most of the interesting functionality is
// inherited - see the documentation on the corresponding contracts.
contract TrueUSD is ModularPausableToken, NoOwner, BurnableTokenWithBounds, CompliantToken, TokenWithFees, WithdrawalToken, StandardDelegate, CanDelegate {
    string public name = "TrueUSD";
    string public symbol = "TUSD";
    uint8 public constant decimals = 18;

    event ChangeTokenName(string newName, string newSymbol);

    function TrueUSD() public {
        totalSupply_ = 0;
        burnMin = 10000 * 10**uint256(decimals);
        burnMax = 20000000 * 10**uint256(decimals);
    }

    function changeTokenName(string _name, string _symbol) onlyOwner public {
        name = _name;
        symbol = _symbol;
        emit ChangeTokenName(_name, _symbol);
    }

    // disable most onlyOwner functions upon delegation, since the owner should
    // use the new version of the contract
    modifier onlyWhenNoDelegate() {
        require(address(delegate) == address(0));
        _;
    }

    function mint(address _to, uint256 _value) onlyWhenNoDelegate public returns (bool) {
        super.mint(_to, _value);
    }
    function setBalanceSheet(address _sheet) onlyWhenNoDelegate public {
        super.setBalanceSheet(_sheet);
    }
    function setAllowanceSheet(address _sheet) onlyWhenNoDelegate public {
        super.setAllowanceSheet(_sheet);
    }
    function setBurnBounds(uint256 _min, uint256 _max) onlyWhenNoDelegate public {
        super.setBurnBounds(_min, _max);
    }
    function setRegistry(Registry _registry) onlyWhenNoDelegate public {
        super.setRegistry(_registry);
    }
    function changeStaker(address _newStaker) onlyWhenNoDelegate public {
        super.changeStaker(_newStaker);
    }
    function wipeBlacklistedAccount(address _account) onlyWhenNoDelegate public {
        super.wipeBlacklistedAccount(_account);
    }
    function changeStakingFees(
        uint256 _transferFeeNumerator,
        uint256 _transferFeeDenominator,
        uint256 _mintFeeNumerator,
        uint256 _mintFeeDenominator,
        uint256 _mintFeeFlat,
        uint256 _burnFeeNumerator,
        uint256 _burnFeeDenominator,
        uint256 _burnFeeFlat
    ) onlyWhenNoDelegate public {
        super.changeStakingFees(
            _transferFeeNumerator,
            _transferFeeDenominator,
            _mintFeeNumerator,
            _mintFeeDenominator,
            _mintFeeFlat,
            _burnFeeNumerator,
            _burnFeeDenominator,
            _burnFeeFlat
        );
    }

    // this contract is initially owned by a contract that itself extends parts
    // of NoOwner, so we use these instead of the normal NoOwner functions.
    // Note that we *do* inherit reclaimContract from NoOwner: This contract
    // does have to own contracts, but it also has to be able to relinquish them.
    function reclaimEther(address _to) external onlyOwner {
        assert(_to.send(address(this).balance));
    }

    function reclaimToken(ERC20Basic token, address _to) external onlyOwner {
        uint256 balance = token.balanceOf(this);
        token.safeTransfer(_to, balance);
    }
}

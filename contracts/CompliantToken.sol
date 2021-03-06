pragma solidity ^0.4.21;

import "../registry/contracts/HasRegistry.sol";
import "./modularERC20/ModularBurnableToken.sol";
import "./modularERC20/ModularMintableToken.sol";

contract CompliantToken is ModularMintableToken, ModularBurnableToken, HasRegistry {
    // In order to deposit USD and receive newly minted TrueUSD, or to burn TrueUSD to
    // redeem it for USD, users must first go through a KYC/AML check (which includes proving they
    // control their ethereum address using AddressValidation.sol).
    string constant HAS_PASSED_KYC_AML = "hasPassedKYC/AML";
    // Redeeming ("burning") TrueUSD tokens for USD requires a separate flag since
    // users must not only be KYC/AML'ed but must also have bank information on file.
    string constant CAN_BURN = "canBurn";
    // Addresses can also be blacklisted, preventing them from sending or receiving
    // TrueUSD. This can be used to prevent the use of TrueUSD by bad actors in
    // accordance with law enforcement. See [TrueCoin Terms of Use](https://www.trusttoken.com/trueusd/terms-of-use)
    string constant IS_BLACKLISTED = "isBlacklisted";
    // Only KYC/AML'ed accounts can interact with addresses affiliated with a
    // restricted exchange.
    string constant IS_RESTRICTED_EXCHANGE = "isRestrictedExchange";

    event WipeBlacklistedAccount(address indexed account, uint256 balance);

    function burnAllArgs(address _burner, uint256 _value) internal {
        require(registry.hasAttribute(_burner, CAN_BURN));
        require(!registry.hasAttribute(_burner, IS_BLACKLISTED));
        super.burnAllArgs(_burner, _value);
    }

    function mint(address _to, uint256 _value) onlyOwner public returns (bool) {
        require(registry.hasAttribute(_to, HAS_PASSED_KYC_AML));
        require(!registry.hasAttribute(_to, IS_BLACKLISTED));
        super.mint(_to, _value);
    }

    // A blacklisted address can't call transferFrom
    function transferFromAllArgs(address _from, address _to, uint256 _value, address _spender) internal {
        require(!registry.hasAttribute(_spender, IS_BLACKLISTED));
        require(!registry.hasAttribute(_spender, IS_RESTRICTED_EXCHANGE) || (registry.hasAttribute(_from, HAS_PASSED_KYC_AML) && registry.hasAttribute(_to, HAS_PASSED_KYC_AML)));
        require((!registry.hasAttribute(_to, IS_RESTRICTED_EXCHANGE) && !registry.hasAttribute(_from, IS_RESTRICTED_EXCHANGE)) || registry.hasAttribute(_spender, HAS_PASSED_KYC_AML));
        super.transferFromAllArgs(_from, _to, _value, _spender);
    }

    // transfer and transferFrom both call this function, so check blacklist here.
    function transferAllArgs(address _from, address _to, uint256 _value) internal {
        require(!registry.hasAttribute(_from, IS_BLACKLISTED));
        require(!registry.hasAttribute(_to, IS_BLACKLISTED));
        require(!registry.hasAttribute(_to, IS_RESTRICTED_EXCHANGE) || registry.hasAttribute(_from, HAS_PASSED_KYC_AML));
        require(!registry.hasAttribute(_from, IS_RESTRICTED_EXCHANGE) || registry.hasAttribute(_to, HAS_PASSED_KYC_AML));
        super.transferAllArgs(_from, _to, _value);
    }

    // Destroy the tokens owned by a blacklisted account
    function wipeBlacklistedAccount(address _account) public onlyOwner {
        require(registry.hasAttribute(_account, IS_BLACKLISTED));
        uint256 oldValue = balanceOf(_account);
        balances.setBalance(_account, 0);
        totalSupply_ = totalSupply_.sub(oldValue);
        emit WipeBlacklistedAccount(_account, oldValue);
    }
}

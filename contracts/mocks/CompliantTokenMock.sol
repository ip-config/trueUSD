pragma solidity ^0.4.21;

import "../CompliantToken.sol";

contract CompliantTokenMock is CompliantToken {
    function CompliantTokenMock(address initialAccount, uint256 initialBalance) public {
        balances = new BalanceSheet();
        allowances = new AllowanceSheet();
        balances.setBalance(initialAccount, initialBalance);
        totalSupply_ = initialBalance;
    }
}

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from starkware.cairo.common.math import assert_not_zero

from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_check,
)


@storage_var
func ERC20_symbol() -> (symbol: felt):
end

@storage_var
func ERC20_total_supply() -> (total_supply: Uint256):
end

@storage_var
func ERC20_allowances(owner: felt, spender: felt) -> (allowance: Uint256):
end

@storage_var
func ERC20_balances(account: felt) -> (balance: Uint256):
end

@storage_var
func allowlist_levels(account: felt) -> (level: felt):
end

#
# Constructor
#
@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        symbol: felt, 
        initial_supply: Uint256,
    ):
    ERC20_symbol.write(symbol)
    ERC20_total_supply.write(initial_supply)
    return ()
end

#
# Getters
#
@view
func symbol{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (symbol: felt):
    let (symbol) = ERC20_symbol.read()
    return (symbol)
end

@view
func totalSupply{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (total_supply: Uint256):
    let (total_supply) = ERC20_total_supply.read()
    return (total_supply)
end

@view
func balanceOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(account: felt) -> (balance: Uint256):
    let (balance) = ERC20_balances.read(account)
    return (balance)
end

@view 
func allowance{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(owner: felt, spender: felt) -> (remaining: Uint256):
    let (remaining) = ERC20_allowances.read(owner, spender)
    return (remaining)
end

@view
func allowlist_level{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(account : felt) -> (level : felt):
    let (level) = allowlist_levels.read(account)
    return (level)
end

#
# Externals
#
@external
func approve{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(spender: felt, amount: Uint256) -> (success: felt):
    let (caller) = get_caller_address()
    assert_not_zero(caller)
    assert_not_zero(spender)
    uint256_check(amount)
    ERC20_allowances.write(caller, spender, amount)
    return (1)
end

@external
func get_tokens{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (amount : Uint256):
    let (caller) = get_caller_address()
    let (level) = allowlist_levels.read(caller)
    if 0 == level:
        return (Uint256(0,0))
    end
    if 1 == level:
        let amount = Uint256(160000000000000000, 0)
        ERC20_mint(caller, amount)
        return (amount)
    end
    let amount = Uint256(260000000000000000, 0)
    ERC20_mint(caller, amount)
    return (amount)
end

@external
func request_allowlist{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (level_granted : felt):
    alloc_locals
    let (caller) = get_caller_address()
    local level_granted: felt = 1
    allowlist_levels.write(caller, level_granted)
    return (level_granted)
end

@external
func request_allowlist_level{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(level_requested : felt) -> (level_granted : felt):
    let (caller) = get_caller_address()
    let level_granted = level_requested
    allowlist_levels.write(caller, level_requested)
    return (level_granted)
end
#
# Internals
#
func ERC20_mint{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(recipient: felt, amount: Uint256):
    alloc_locals
    assert_not_zero(recipient)
    uint256_check(amount)

    let (balance: Uint256) = ERC20_balances.read(account=recipient)
    # overflow is not possible because sum is guaranteed to be less than total supply
    # which we check for overflow below
    let (new_balance, _: Uint256) = uint256_add(balance, amount)
    ERC20_balances.write(recipient, new_balance)

    let (local supply: Uint256) = ERC20_total_supply.read()
    let (local new_supply: Uint256, is_overflow) = uint256_add(supply, amount)
    assert (is_overflow) = 0

    ERC20_total_supply.write(new_supply)
    return ()
end

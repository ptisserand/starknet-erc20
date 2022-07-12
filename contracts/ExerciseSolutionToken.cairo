%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from starkware.cairo.common.math import assert_not_zero

from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_check,
    uint256_le,
    uint256_sub,
)

from contracts.token.ERC20.ERC20_base import (
    ERC20_name,
    ERC20_symbol,
    ERC20_totalSupply,
    ERC20_decimals,
    ERC20_balanceOf,
    ERC20_allowance,
    ERC20_mint,
    ERC20_burn,

    ERC20_initializer,
    ERC20_approve,
    ERC20_increaseAllowance,
    ERC20_decreaseAllowance,
    ERC20_transfer,
    ERC20_transferFrom
)


@storage_var
func minter_list(account: felt) -> (enable: felt):
end

@storage_var
func owner_storage() -> (owner: felt):
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
        name: felt,
        symbol: felt, 
        initial_supply: Uint256,
        owner: felt
    ):
    owner_storage.write(owner)
    ERC20_initializer(name, symbol, initial_supply, owner)
    return ()
end

#
# Getters
#
@view
func name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name: felt):
    let (name) = ERC20_name()
    return (name)
end

@view
func symbol{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (symbol: felt):
    let (symbol) = ERC20_symbol()
    return (symbol)
end

@view
func totalSupply{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (total_supply: Uint256):
    let (total_supply) = ERC20_totalSupply()
    return (total_supply)
end

@view
func balanceOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(account: felt) -> (balance: Uint256):
    let (balance) = ERC20_balanceOf(account)
    return (balance)
end

@view 
func allowance{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(owner: felt, spender: felt) -> (remaining: Uint256):
    let (remaining) = ERC20_allowance(owner, spender)
    return (remaining)
end

@view
func owner{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (owner: felt):
    let (owner) = owner_storage.read()
    return (owner)
end

@view
func is_minter{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(account: felt) -> (enable: felt):
    let (enable) = minter_list.read(account)
    return (enable)
end

#
# Externals
#
@external
func transfer{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(recipient: felt, amount: Uint256) -> (success: felt):
    ERC20_transfer(recipient, amount)
    # Cairo equivalent to 'return (true)'
    return (1)
end

@external
func transferFrom{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        sender: felt, 
        recipient: felt, 
        amount: Uint256
    ) -> (success: felt):
    ERC20_transferFrom(sender, recipient, amount)
    # Cairo equivalent to 'return (true)'
    return (1)
end

@external
func approve{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(spender: felt, amount: Uint256) -> (success: felt):
    ERC20_approve(spender, amount)
    return (1)
end

@external
func mint{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(recipient: felt, amount: Uint256) -> (success: felt):
    let (caller) = get_caller_address()
    let (enable: felt) = is_minter(caller)
    if 0 == enable:
        return (0)
    end
    ERC20_mint(recipient, amount)
   return (1)
end

@external
func burn{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(amount: Uint256) -> (sucess: felt):
    let (caller) = get_caller_address()
    ERC20_burn(caller, amount)
    return (1)
end

@external
func add_minter{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(account: felt) -> (sucess: felt):
    let (caller) = get_caller_address()
    let (owner) = owner_storage.read()
    if caller == owner:
        minter_list.write(account, 1)
        return (1)
    end
    return (0)
end

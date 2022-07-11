%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from starkware.cairo.common.math import assert_not_zero

from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_check,
    uint256_sub,
)

from contracts.token.ERC20.IDTKERC20 import IDTKERC20


#
# Declaring storage vars
# Storage vars are by default not visible through the ABI. They are similar to "private" variables in Solidity
#
@storage_var
func dummy_token_address_storage() -> (dummy_token_address_storage: felt):
end

@storage_var
func tokens_in_custody_storage(account: felt) -> (tokens_in_custody_storage: Uint256):
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
        dummy_token_address: felt
    ):
    dummy_token_address_storage.write(dummy_token_address)
    return ()
end

#
# Getters
#
@view
func dummy_token_address{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (address: felt):
    let (address) = dummy_token_address_storage.read()
    return (address)
end

@view
func tokens_in_custody{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(account : felt) -> (amount : Uint256):
    let (amount) = tokens_in_custody_storage.read(account)
    return (amount)
end

#
# Externals
#
@external
func get_tokens_from_contract{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (amount : Uint256):
    let (caller) = get_caller_address()
    let (contract) = get_contract_address()
    let dummy_token_address: felt = dummy_token_address_storage.read()
    let (old_amount: Uint256) = IDTKERC20.balanceOf(dummy_token_address, contract)
    let (success: felt) = IDTKERC20.faucet(dummy_token_address)
    let (new_amount: Uint256) = IDTKERC20.balanceOf(dummy_token_address, contract)
    let (amount: Uint256) = uint256_sub(new_amount, old_amount)
    let (old_amount) = tokens_in_custody_storage.read(caller)
    let (new_amount, _) = uint256_add(old_amount, amount)
    tokens_in_custody_storage.write(caller, new_amount)
    return (amount)
end

@external
func withdraw_all_tokens{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (amount : Uint256):
    let (caller) = get_caller_address()
    let dummy_token_address: felt = dummy_token_address_storage.read()
    let (amount: Uint256) = tokens_in_custody_storage.read(caller)
    IDTKERC20.transfer(dummy_token_address, caller, amount)
    tokens_in_custody_storage.write(caller, Uint256(0,0))
    return (amount)
end

@external
func deposit_tokens{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(amount : Uint256) -> (total_amount : Uint256):
    let (caller) = get_caller_address()
    let (contract) = get_contract_address()
    let dummy_token_address: felt = dummy_token_address_storage.read()
    IDTKERC20.transferFrom(dummy_token_address, caller, contract, amount)
    let (old_amount) = tokens_in_custody_storage.read(caller)
    let (new_amount, _) = uint256_add(old_amount, amount)
    tokens_in_custody_storage.write(caller, new_amount)
    return (new_amount)
end
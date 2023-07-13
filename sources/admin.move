module vault::admin {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    // =================== Error =================

    const EWrongOwner: u64 = 0;
    const EWrongFreeze: u64 = 1;
    const EWrongPointsRate: u64 = 2;

    // =================== Struct =================

    /// Contract config
    struct Contract has key, store {
        id: UID,
        // Contract admin address
        owner: address,
        // Fee account
        fee_account: address,
        // Fee points rate
        points_rate: u64,
        // Contract freeze state
        freeze: bool,
    }

    // =================== Function =================

    /// Initial admin contract
    fun init(ctx: &mut TxContext) {
        transfer::share_object(Contract {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            fee_account: tx_context::sender(ctx),
            points_rate: 500,
            freeze: false,
        });
    }

    /// Get signer public key
    public fun get_fee_account(contract: &Contract): address {
        contract.fee_account
    }

    /// Get points rate
    public fun get_points_rate(contract: &Contract): u64 {
        contract.points_rate
    }

    /// Check must be owner
    public fun assert_owner(contract: &Contract, ctx: &mut TxContext) {
        assert!(
            contract.owner == tx_context::sender(ctx), EWrongOwner,
        );
    }

    /// Check contract not freeze
    public fun assert_not_freeze(contract: &Contract) {
        assert!(!contract.freeze, EWrongFreeze);
    }

    /// Set owner address
    public entry fun set_contract_owner(
        contract: &mut Contract,
        new_owner: address,
        ctx: &mut TxContext
    ) {
        assert_owner(contract, ctx);
        contract.owner = new_owner;
    }

    /// Set fee account
    public entry fun set_fee_account(
        contract: &mut Contract,
        fee_account: address,
        ctx: &mut TxContext
    ) {
        assert_owner(contract, ctx);
        contract.fee_account = fee_account;
    }

    /// Set points rate
    public entry fun set_points_rate(
        contract: &mut Contract,
        points_rate: u64,
        ctx: &mut TxContext
    ) {
        assert_owner(contract, ctx);
        assert!(points_rate >= 0 && points_rate < 10000, EWrongPointsRate);
        contract.points_rate = points_rate;
    }

    /// Freezen contract / Unfreeze contract
    public entry fun toggle_contract_freeze(contract: &mut Contract, ctx: &mut TxContext) {
        assert_owner(contract, ctx);
        contract.freeze = !contract.freeze;
    }
}

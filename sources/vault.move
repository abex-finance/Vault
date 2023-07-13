module vault::vault {
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::event::emit;
    use sui::object::{Self, ID, UID, uid_to_inner};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use vault::admin::{assert_not_freeze, assert_owner, Contract, get_fee_account, get_points_rate};

    // =================== Error =================

    const EWrongAmount: u64 = 0;
    const EWrongBalance: u64 = 1;

    // =================== Struct =================

    /// Case
    struct Case has key, store {
        id: UID,
        // Case id
        case_id: u64,
        // White hat
        white_hat: address,
        // Balance
        balance: Balance<SUI>,
    }

    /// Case count
    struct CaseCount has key, store {
        id: UID,
        // Case count
        count: u64,
    }

    // ===================   Event  =================

    struct AddCaseEvent has copy, drop {
        id: ID,
        case_id: u64,
        white_hat: address,
    }

    struct DepositEvent has copy, drop {
        case_id: u64,
        depositor: address,
        amount: u64,
    }

    struct PayEvent has copy, drop {
        case_id: u64,
        sender: address,
        white_hat: address,
        amount: u64,
    }

    // =================== Function =================

    /// Initial case count
    fun init(ctx: &mut TxContext) {
        transfer::share_object(CaseCount {
            id: object::new(ctx),
            count: 0,
        });
    }

    /// Add case
    public entry fun add_case(
        contract: &Contract,
        case_count: &CaseCount,
        white_hat: address,
        ctx: &mut TxContext
    ) {
        assert_owner(contract, ctx);
        let count = case_count.count;
        let case_id = count + 1;
        let uid = object::new(ctx);

        emit(AddCaseEvent {
            id: uid_to_inner(&uid),
            case_id,
            white_hat,
        });

        transfer::share_object(Case {
            id: uid,
            case_id,
            white_hat,
            balance: balance::zero(),
        });
    }

    /// Deposit
    public entry fun deposit(
        case: &mut Case,
        amount: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(coin::value(&amount) > 0, EWrongAmount);

        emit(DepositEvent {
            case_id: case.case_id,
            depositor: tx_context::sender(ctx),
            amount: coin::value(&amount),
        });

        balance::join(&mut case.balance, coin::into_balance(amount));
    }

    /// White hat claim
    public entry fun pay_to_white_hat(
        case: &mut Case,
        amount: u64,
        contract: &Contract,
        ctx: &mut TxContext
    ) {
        assert_not_freeze(contract);
        assert!(amount > 0, EWrongAmount);
        assert!(balance::value(&case.balance) >= amount, EWrongBalance);

        let fee = 0;
        let points_rate = get_points_rate(contract);
        if (points_rate > 0) {
            fee = amount * points_rate / 10000;
        };
        if (fee > 0) {
            let fee_coin = coin::take(&mut case.balance, fee, ctx);
            transfer::public_transfer(fee_coin, get_fee_account(contract));
        };

        let coin = coin::take(&mut case.balance, amount - fee, ctx);
        transfer::public_transfer(coin, case.white_hat);

        emit(PayEvent {
            case_id: case.case_id,
            sender: tx_context::sender(ctx),
            white_hat: case.white_hat,
            amount,
        });
    }
}

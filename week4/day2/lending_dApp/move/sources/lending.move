module lending_dApp::lending {

    use std::signer;
    use std::table::{Table, new, add, contains, borrow_mut};
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    struct LenderInfo has copy, drop, store {
        amount: u64,
    }

    struct BorrowerInfo has copy, drop, store {
        amount: u64,
    }

    struct LendingPool has key {
        total_deposits: u64,
        total_borrowed: u64,
        lenders: Table<address, LenderInfo>,
        borrowers: Table<address, BorrowerInfo>,
    }

    public entry fun init(account: &signer) {
        let lenders_table = new<address, LenderInfo>();
        let borrowers_table = new<address, BorrowerInfo>();
        let pool = LendingPool {
            total_deposits: 0,
            total_borrowed: 0,
            lenders: lenders_table,
            borrowers: borrowers_table,
        };
        move_to(account, pool);
    }

    public entry fun deposit(account: &signer, amount: u64) acquires LendingPool {
        let pool = borrow_global_mut<LendingPool>(signer::address_of(account));
        let coins = coin::withdraw<AptosCoin>(account, amount);
        coin::deposit<AptosCoin>(signer::address_of(account), coins);

        pool.total_deposits = pool.total_deposits + amount;

        let addr = signer::address_of(account);
        if (contains(&pool.lenders, addr)) {
            let info = borrow_mut(&mut pool.lenders, addr);
            info.amount = info.amount + amount;
        } else {
            add(&mut pool.lenders, addr, LenderInfo { amount });
        }
    }

    public entry fun borrow(account: &signer, amount: u64) acquires LendingPool {
        let pool = borrow_global_mut<LendingPool>(signer::address_of(account));

        assert!(amount <= pool.total_deposits - pool.total_borrowed, 100);

        let coins = coin::withdraw<AptosCoin>(account, amount);
        coin::deposit<AptosCoin>(signer::address_of(account), coins);

        pool.total_borrowed = pool.total_borrowed + amount;

        let addr = signer::address_of(account);
        if (contains(&pool.borrowers, addr)) {
            let info = borrow_mut(&mut pool.borrowers, addr);
            info.amount = info.amount + amount;
        } else {
            add(&mut pool.borrowers, addr, BorrowerInfo { amount });
        }
    }

    public entry fun repay(account: &signer, amount: u64) acquires LendingPool {
    let sender = signer::address_of(account);
    let pool = borrow_global_mut<LendingPool>(@0x3bb90ddb7d977a70d0ab459f94736a812c6b9974cefc7987d2c59b735d4fdc6f);
    
    let current_borrow = borrow_mut(&mut pool.borrowers, sender);
    assert!(current_borrow.amount >= amount, 100); // Repay amount cannot exceed borrowed

     // Withdraw tokens from user and deposit them to pool address
    let coins = coin::withdraw<AptosCoin>(account, amount);
    coin::deposit<AptosCoin>(@0x3bb90ddb7d977a70d0ab459f94736a812c6b9974cefc7987d2c59b735d4fdc6f, coins);
    
    current_borrow.amount = current_borrow.amount - amount;
    pool.total_borrowed = pool.total_borrowed - amount;
}

   public entry fun debug_total_liquidity(account: address) acquires LendingPool {
    let pool = borrow_global<LendingPool>(account);
    let liquidity = pool.total_deposits - pool.total_borrowed;
    aptos_std::debug::print(&liquidity);
}



}

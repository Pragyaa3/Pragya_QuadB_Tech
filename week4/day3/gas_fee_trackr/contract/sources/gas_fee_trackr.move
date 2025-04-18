module gas_fee_trackr::gas_fee_trackr {
    use std::signer;
    use std::string;
    use aptos_std::table;

    struct Storage has key {
        data: table::Table<address, string::String>,
    }

    public entry fun init(account: &signer) {
        let tbl = table::new<address, string::String>();
        move_to(account, Storage {
            data: tbl,
        });
    }

    public entry fun store_data(account: &signer, value: string::String) acquires Storage {
        let addr = signer::address_of(account);
        let storage = borrow_global_mut<Storage>(addr);
        table::add(&mut storage.data, addr, value);
    }

    public entry fun delete_data(account: &signer) acquires Storage {
        let addr = signer::address_of(account);
        let storage = borrow_global_mut<Storage>(addr);
        let _ = table::remove(&mut storage.data, addr);
    }
}

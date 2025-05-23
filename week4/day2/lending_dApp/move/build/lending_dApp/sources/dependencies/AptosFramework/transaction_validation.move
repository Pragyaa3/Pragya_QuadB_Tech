module aptos_framework::transaction_validation {
    use std::bcs;
    use std::error;
    use std::features;
    use std::option;
    use std::option::Option;
    use std::signer;
    use std::vector;

    use aptos_framework::account;
    use aptos_framework::aptos_account;
    use aptos_framework::account_abstraction;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::chain_id;
    use aptos_framework::coin;
    use aptos_framework::create_signer;
    use aptos_framework::permissioned_signer;
    use aptos_framework::system_addresses;
    use aptos_framework::timestamp;
    use aptos_framework::transaction_fee;

    friend aptos_framework::genesis;

    /// This holds information that will be picked up by the VM to call the
    /// correct chain-specific prologue and epilogue functions
    struct TransactionValidation has key {
        module_addr: address,
        module_name: vector<u8>,
        script_prologue_name: vector<u8>,
        // module_prologue_name is deprecated and not used.
        module_prologue_name: vector<u8>,
        multi_agent_prologue_name: vector<u8>,
        user_epilogue_name: vector<u8>,
    }

    struct GasPermission has copy, drop, store {}

    /// MSB is used to indicate a gas payer tx
    const MAX_U64: u128 = 18446744073709551615;

    /// Transaction exceeded its allocated max gas
    const EOUT_OF_GAS: u64 = 6;

    /// Prologue errors. These are separated out from the other errors in this
    /// module since they are mapped separately to major VM statuses, and are
    /// important to the semantics of the system.
    const PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY: u64 = 1001;
    const PROLOGUE_ESEQUENCE_NUMBER_TOO_OLD: u64 = 1002;
    const PROLOGUE_ESEQUENCE_NUMBER_TOO_NEW: u64 = 1003;
    const PROLOGUE_EACCOUNT_DOES_NOT_EXIST: u64 = 1004;
    const PROLOGUE_ECANT_PAY_GAS_DEPOSIT: u64 = 1005;
    const PROLOGUE_ETRANSACTION_EXPIRED: u64 = 1006;
    const PROLOGUE_EBAD_CHAIN_ID: u64 = 1007;
    const PROLOGUE_ESEQUENCE_NUMBER_TOO_BIG: u64 = 1008;
    const PROLOGUE_ESECONDARY_KEYS_ADDRESSES_COUNT_MISMATCH: u64 = 1009;
    const PROLOGUE_EFEE_PAYER_NOT_ENABLED: u64 = 1010;
    const PROLOGUE_PERMISSIONED_GAS_LIMIT_INSUFFICIENT: u64 = 1011;

    /// Permission management
    ///
    /// Master signer grant permissioned signer ability to consume a given amount of gas in octas.
    public fun grant_gas_permission(
        master: &signer,
        permissioned: &signer,
        gas_amount: u64
    ) {
        permissioned_signer::authorize_increase(
            master,
            permissioned,
            (gas_amount as u256),
            GasPermission {}
        )
    }

    /// Removing permissions from permissioned signer.
    public fun revoke_gas_permission(permissioned: &signer) {
        permissioned_signer::revoke_permission(permissioned, GasPermission {})
    }

    /// Only called during genesis to initialize system resources for this module.
    public(friend) fun initialize(
        aptos_framework: &signer,
        script_prologue_name: vector<u8>,
        // module_prologue_name is deprecated and not used.
        module_prologue_name: vector<u8>,
        multi_agent_prologue_name: vector<u8>,
        user_epilogue_name: vector<u8>,
    ) {
        system_addresses::assert_aptos_framework(aptos_framework);

        move_to(aptos_framework, TransactionValidation {
            module_addr: @aptos_framework,
            module_name: b"transaction_validation",
            script_prologue_name,
            // module_prologue_name is deprecated and not used.
            module_prologue_name,
            multi_agent_prologue_name,
            user_epilogue_name,
        });
    }

    // TODO: can be removed after features have been rolled out.
    inline fun allow_missing_txn_authentication_key(transaction_sender: address): bool {
        // aa verifies authentication itself
        features::is_derivable_account_abstraction_enabled()
            || (features::is_account_abstraction_enabled() && account_abstraction::using_dispatchable_authenticator(transaction_sender))
    }

    fun prologue_common(
        sender: &signer,
        gas_payer: &signer,
        txn_sequence_number: u64,
        txn_authentication_key: Option<vector<u8>>,
        txn_gas_price: u64,
        txn_max_gas_units: u64,
        txn_expiration_time: u64,
        chain_id: u8,
        is_simulation: bool,
    ) {
        assert!(
            timestamp::now_seconds() < txn_expiration_time,
            error::invalid_argument(PROLOGUE_ETRANSACTION_EXPIRED),
        );
        assert!(chain_id::get() == chain_id, error::invalid_argument(PROLOGUE_EBAD_CHAIN_ID));

        let transaction_sender = signer::address_of(sender);
        let gas_payer_address = signer::address_of(gas_payer);

        if (
            transaction_sender == gas_payer_address
                || account::exists_at(transaction_sender)
                || !features::sponsored_automatic_account_creation_enabled()
                || txn_sequence_number > 0
        ) {
            assert!(account::exists_at(transaction_sender), error::invalid_argument(PROLOGUE_EACCOUNT_DOES_NOT_EXIST));
            if (!features::transaction_simulation_enhancement_enabled() ||
                !skip_auth_key_check(is_simulation, &txn_authentication_key)) {
                if (option::is_some(&txn_authentication_key)) {
                    assert!(
                        txn_authentication_key == option::some(account::get_authentication_key(transaction_sender)),
                        error::invalid_argument(PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY)
                    );
                } else {
                    assert!(
                        allow_missing_txn_authentication_key(transaction_sender),
                        error::invalid_argument(PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY)
                    )
                };
            };
            let account_sequence_number = account::get_sequence_number(transaction_sender);
            assert!(
                txn_sequence_number < (1u64 << 63),
                error::out_of_range(PROLOGUE_ESEQUENCE_NUMBER_TOO_BIG)
            );

            assert!(
                txn_sequence_number >= account_sequence_number,
                error::invalid_argument(PROLOGUE_ESEQUENCE_NUMBER_TOO_OLD)
            );

            assert!(
                txn_sequence_number == account_sequence_number,
                error::invalid_argument(PROLOGUE_ESEQUENCE_NUMBER_TOO_NEW)
            );
        } else {
            // In this case, the transaction is sponsored and the account does not exist, so ensure
            // the default values match.
            assert!(
                txn_sequence_number == 0,
                error::invalid_argument(PROLOGUE_ESEQUENCE_NUMBER_TOO_NEW)
            );

            if (!features::transaction_simulation_enhancement_enabled() ||
                    !skip_auth_key_check(is_simulation, &txn_authentication_key)) {
                if (option::is_some(&txn_authentication_key)) {
                    assert!(
                        txn_authentication_key == option::some(bcs::to_bytes(&transaction_sender)),
                        error::invalid_argument(PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY),
                    );
                } else {
                    assert!(
                        allow_missing_txn_authentication_key(transaction_sender),
                        error::invalid_argument(PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY)
                    );
                }
            };
        };

        let max_transaction_fee = txn_gas_price * txn_max_gas_units;

        if (!features::transaction_simulation_enhancement_enabled() || !skip_gas_payment(
            is_simulation,
            gas_payer_address
        )) {
            assert!(
                permissioned_signer::check_permission_capacity_above(
                    gas_payer,
                    (max_transaction_fee as u256),
                    GasPermission {}
                ),
                error::permission_denied(PROLOGUE_PERMISSIONED_GAS_LIMIT_INSUFFICIENT)
            );
            if (features::operations_default_to_fa_apt_store_enabled()) {
                assert!(
                    aptos_account::is_fungible_balance_at_least(gas_payer_address, max_transaction_fee),
                    error::invalid_argument(PROLOGUE_ECANT_PAY_GAS_DEPOSIT)
                );
            } else {
                assert!(
                    coin::is_balance_at_least<AptosCoin>(gas_payer_address, max_transaction_fee),
                    error::invalid_argument(PROLOGUE_ECANT_PAY_GAS_DEPOSIT)
                );
            }
        }
    }

    fun script_prologue(
        sender: signer,
        txn_sequence_number: u64,
        txn_public_key: vector<u8>,
        txn_gas_price: u64,
        txn_max_gas_units: u64,
        txn_expiration_time: u64,
        chain_id: u8,
        _script_hash: vector<u8>,
    ) {
        // prologue_common with is_simulation set to false behaves identically to the original script_prologue function.
        prologue_common(
            &sender,
            &sender,
            txn_sequence_number,
            option::some(txn_public_key),
            txn_gas_price,
            txn_max_gas_units,
            txn_expiration_time,
            chain_id,
            false,
        )
    }

    // This function extends the script_prologue by adding a parameter to indicate simulation mode.
    // Once the transaction_simulation_enhancement feature is enabled, the Aptos VM will invoke this function instead.
    // Eventually, this function will be consolidated with the original function once the feature is fully enabled.
    fun script_prologue_extended(
        sender: signer,
        txn_sequence_number: u64,
        txn_public_key: vector<u8>,
        txn_gas_price: u64,
        txn_max_gas_units: u64,
        txn_expiration_time: u64,
        chain_id: u8,
        _script_hash: vector<u8>,
        is_simulation: bool,
    ) {
        prologue_common(
            &sender,
            &sender,
            txn_sequence_number,
            option::some(txn_public_key),
            txn_gas_price,
            txn_max_gas_units,
            txn_expiration_time,
            chain_id,
            is_simulation,
        )
    }

    fun multi_agent_script_prologue(
        sender: signer,
        txn_sequence_number: u64,
        txn_sender_public_key: vector<u8>,
        secondary_signer_addresses: vector<address>,
        secondary_signer_public_key_hashes: vector<vector<u8>>,
        txn_gas_price: u64,
        txn_max_gas_units: u64,
        txn_expiration_time: u64,
        chain_id: u8,
    ) {
        // prologue_common and multi_agent_common_prologue with is_simulation set to false behaves identically to the
        // original multi_agent_script_prologue function.
        prologue_common(
            &sender,
            &sender,
            txn_sequence_number,
            option::some(txn_sender_public_key),
            txn_gas_price,
            txn_max_gas_units,
            txn_expiration_time,
            chain_id,
            false,
        );
        multi_agent_common_prologue(
            secondary_signer_addresses,
            vector::map(secondary_signer_public_key_hashes, |x| option::some(x)),
            false
        );
    }

    // This function extends the multi_agent_script_prologue by adding a parameter to indicate simulation mode.
    // Once the transaction_simulation_enhancement feature is enabled, the Aptos VM will invoke this function instead.
    // Eventually, this function will be consolidated with the original function once the feature is fully enabled.
    fun multi_agent_script_prologue_extended(
        sender: signer,
        txn_sequence_number: u64,
        txn_sender_public_key: vector<u8>,
        secondary_signer_addresses: vector<address>,
        secondary_signer_public_key_hashes: vector<vector<u8>>,
        txn_gas_price: u64,
        txn_max_gas_units: u64,
        txn_expiration_time: u64,
        chain_id: u8,
        is_simulation: bool,
    ) {
        prologue_common(
            &sender,
            &sender,
            txn_sequence_number,
            option::some(txn_sender_public_key),
            txn_gas_price,
            txn_max_gas_units,
            txn_expiration_time,
            chain_id,
            is_simulation,
        );
        multi_agent_common_prologue(
            secondary_signer_addresses,
            vector::map(secondary_signer_public_key_hashes, |x| option::some(x)),
            is_simulation
        );
    }

    fun multi_agent_common_prologue(
        secondary_signer_addresses: vector<address>,
        secondary_signer_public_key_hashes: vector<Option<vector<u8>>>,
        is_simulation: bool,
    ) {
        let num_secondary_signers = vector::length(&secondary_signer_addresses);
        assert!(
            vector::length(&secondary_signer_public_key_hashes) == num_secondary_signers,
            error::invalid_argument(PROLOGUE_ESECONDARY_KEYS_ADDRESSES_COUNT_MISMATCH),
        );

        let i = 0;
        while ({
            // spec {
            //     invariant i <= num_secondary_signers;
            //     invariant forall j in 0..i:
            //         account::exists_at(secondary_signer_addresses[j]);
            //     invariant forall j in 0..i:
            //         secondary_signer_public_key_hashes[j] == account::get_authentication_key(secondary_signer_addresses[j]) ||
            //             (features::spec_simulation_enhancement_enabled() && is_simulation && vector::is_empty(secondary_signer_public_key_hashes[j]));
            //         account::account_resource_exists_at(secondary_signer_addresses[j])
            //         && secondary_signer_public_key_hashes[j]
            //             == account::get_authentication_key(secondary_signer_addresses[j])
            //             || features::account_abstraction_enabled() && account_abstraction::using_native_authenticator(
            //             secondary_signer_addresses[j]
            //         ) && option::spec_some(secondary_signer_public_key_hashes[j]) == account_abstraction::native_authenticator(
            //         account::exists_at(secondary_signer_addresses[j])
            //         && secondary_signer_public_key_hashes[j]
            //             == account::spec_get_authentication_key(secondary_signer_addresses[j])
            //             || features::spec_account_abstraction_enabled() && account_abstraction::using_native_authenticator(
            //             secondary_signer_addresses[j]
            //         ) && option::spec_some(
            //             secondary_signer_public_key_hashes[j]
            //         ) == account_abstraction::spec_native_authenticator(
            //             secondary_signer_addresses[j]
            //         );
            // };
            (i < num_secondary_signers)
        }) {
            let secondary_address = *vector::borrow(&secondary_signer_addresses, i);
            assert!(account::exists_at(secondary_address), error::invalid_argument(PROLOGUE_EACCOUNT_DOES_NOT_EXIST));
            let signer_public_key_hash = *vector::borrow(&secondary_signer_public_key_hashes, i);
            if (!features::transaction_simulation_enhancement_enabled() ||
                !skip_auth_key_check(is_simulation, &signer_public_key_hash)) {
                if (option::is_some(&signer_public_key_hash)) {
                    assert!(
                        signer_public_key_hash == option::some(account::get_authentication_key(secondary_address)),
                        error::invalid_argument(PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY)
                    );
                } else {
                    assert!(
                        allow_missing_txn_authentication_key(secondary_address),
                        error::invalid_argument(PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY)
                    )
                };
            };

            i = i + 1;
        }
    }

    fun fee_payer_script_prologue(
        sender: signer,
        txn_sequence_number: u64,
        txn_sender_public_key: vector<u8>,
        secondary_signer_addresses: vector<address>,
        secondary_signer_public_key_hashes: vector<vector<u8>>,
        fee_payer_address: address,
        fee_payer_public_key_hash: vector<u8>,
        txn_gas_price: u64,
        txn_max_gas_units: u64,
        txn_expiration_time: u64,
        chain_id: u8,
    ) {
        assert!(features::fee_payer_enabled(), error::invalid_state(PROLOGUE_EFEE_PAYER_NOT_ENABLED));
        // prologue_common and multi_agent_common_prologue with is_simulation set to false behaves identically to the
        // original fee_payer_script_prologue function.
        prologue_common(
            &sender,
            &create_signer::create_signer(fee_payer_address),
            txn_sequence_number,
            option::some(txn_sender_public_key),
            txn_gas_price,
            txn_max_gas_units,
            txn_expiration_time,
            chain_id,
            false,
        );
        multi_agent_common_prologue(
            secondary_signer_addresses,
            vector::map(secondary_signer_public_key_hashes, |x| option::some(x)),
            false
        );
        assert!(
            fee_payer_public_key_hash == account::get_authentication_key(fee_payer_address),
            error::invalid_argument(PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY),
        );
    }

    // This function extends the fee_payer_script_prologue by adding a parameter to indicate simulation mode.
    // Once the transaction_simulation_enhancement feature is enabled, the Aptos VM will invoke this function instead.
    // Eventually, this function will be consolidated with the original function once the feature is fully enabled.
    fun fee_payer_script_prologue_extended(
        sender: signer,
        txn_sequence_number: u64,
        txn_sender_public_key: vector<u8>,
        secondary_signer_addresses: vector<address>,
        secondary_signer_public_key_hashes: vector<vector<u8>>,
        fee_payer_address: address,
        fee_payer_public_key_hash: vector<u8>,
        txn_gas_price: u64,
        txn_max_gas_units: u64,
        txn_expiration_time: u64,
        chain_id: u8,
        is_simulation: bool,
    ) {
        assert!(features::fee_payer_enabled(), error::invalid_state(PROLOGUE_EFEE_PAYER_NOT_ENABLED));
        prologue_common(
            &sender,
            &create_signer::create_signer(fee_payer_address),
            txn_sequence_number,
            option::some(txn_sender_public_key),
            txn_gas_price,
            txn_max_gas_units,
            txn_expiration_time,
            chain_id,
            is_simulation,
        );
        multi_agent_common_prologue(
            secondary_signer_addresses,
            vector::map(secondary_signer_public_key_hashes, |x| option::some(x)),
            is_simulation
        );
        if (!features::transaction_simulation_enhancement_enabled() ||
            !skip_auth_key_check(is_simulation, &option::some(fee_payer_public_key_hash))) {
            assert!(
                fee_payer_public_key_hash == account::get_authentication_key(fee_payer_address),
                error::invalid_argument(PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY),
            )
        }
    }

    /// Epilogue function is run after a transaction is successfully executed.
    /// Called by the Adapter
    fun epilogue(
        account: signer,
        storage_fee_refunded: u64,
        txn_gas_price: u64,
        txn_max_gas_units: u64,
        gas_units_remaining: u64,
    ) {
        let addr = signer::address_of(&account);
        epilogue_gas_payer(
            account,
            addr,
            storage_fee_refunded,
            txn_gas_price,
            txn_max_gas_units,
            gas_units_remaining
        );
    }

    // This function extends the epilogue by adding a parameter to indicate simulation mode.
    // Once the transaction_simulation_enhancement feature is enabled, the Aptos VM will invoke this function instead.
    // Eventually, this function will be consolidated with the original function once the feature is fully enabled.
    fun epilogue_extended(
        account: signer,
        storage_fee_refunded: u64,
        txn_gas_price: u64,
        txn_max_gas_units: u64,
        gas_units_remaining: u64,
        is_simulation: bool,
    ) {
        let addr = signer::address_of(&account);
        epilogue_gas_payer_extended(
            account,
            addr,
            storage_fee_refunded,
            txn_gas_price,
            txn_max_gas_units,
            gas_units_remaining,
            is_simulation
        );
    }

    /// Epilogue function with explicit gas payer specified, is run after a transaction is successfully executed.
    /// Called by the Adapter
    fun epilogue_gas_payer(
        account: signer,
        gas_payer: address,
        storage_fee_refunded: u64,
        txn_gas_price: u64,
        txn_max_gas_units: u64,
        gas_units_remaining: u64
    ) {
        // epilogue_gas_payer_extended with is_simulation set to false behaves identically to the original
        // epilogue_gas_payer function.
        epilogue_gas_payer_extended(
            account,
            gas_payer,
            storage_fee_refunded,
            txn_gas_price,
            txn_max_gas_units,
            gas_units_remaining,
            false,
        );
    }

    // This function extends the epilogue_gas_payer by adding a parameter to indicate simulation mode.
    // Once the transaction_simulation_enhancement feature is enabled, the Aptos VM will invoke this function instead.
    // Eventually, this function will be consolidated with the original function once the feature is fully enabled.
    fun epilogue_gas_payer_extended(
        account: signer,
        gas_payer: address,
        storage_fee_refunded: u64,
        txn_gas_price: u64,
        txn_max_gas_units: u64,
        gas_units_remaining: u64,
        is_simulation: bool,
    ) {
        assert!(txn_max_gas_units >= gas_units_remaining, error::invalid_argument(EOUT_OF_GAS));
        let gas_used = txn_max_gas_units - gas_units_remaining;

        assert!(
            (txn_gas_price as u128) * (gas_used as u128) <= MAX_U64,
            error::out_of_range(EOUT_OF_GAS)
        );
        let transaction_fee_amount = txn_gas_price * gas_used;

        // it's important to maintain the error code consistent with vm
        // to do failed transaction cleanup.
        if (!features::transaction_simulation_enhancement_enabled() || !skip_gas_payment(is_simulation, gas_payer)) {
            if (features::operations_default_to_fa_apt_store_enabled()) {
                assert!(
                    aptos_account::is_fungible_balance_at_least(gas_payer, transaction_fee_amount),
                    error::out_of_range(PROLOGUE_ECANT_PAY_GAS_DEPOSIT),
                );
            } else {
                assert!(
                    coin::is_balance_at_least<AptosCoin>(gas_payer, transaction_fee_amount),
                    error::out_of_range(PROLOGUE_ECANT_PAY_GAS_DEPOSIT),
                );
            };

            if (transaction_fee_amount > storage_fee_refunded) {
                let burn_amount = transaction_fee_amount - storage_fee_refunded;
                transaction_fee::burn_fee(gas_payer, burn_amount);
            } else if (transaction_fee_amount < storage_fee_refunded) {
                let mint_amount = storage_fee_refunded - transaction_fee_amount;
                transaction_fee::mint_and_refund(gas_payer, mint_amount);
            };
        };

        // Increment sequence number
        let addr = signer::address_of(&account);
        account::increment_sequence_number(addr);
    }

    inline fun skip_auth_key_check(is_simulation: bool, auth_key: &Option<vector<u8>>): bool {
        is_simulation && (option::is_none(auth_key) || vector::is_empty(option::borrow(auth_key)))
    }

    inline fun skip_gas_payment(is_simulation: bool, gas_payer: address): bool {
        is_simulation && gas_payer == @0x0
    }

    ///////////////////////////////////////////////////////////
    /// new set of functions
    ///////////////////////////////////////////////////////////

    fun unified_prologue(
        sender: signer,
        // None means no need to check, i.e. either AA (where it is already checked) or simulation
        txn_sender_public_key: Option<vector<u8>>,
        txn_sequence_number: u64,
        secondary_signer_addresses: vector<address>,
        secondary_signer_public_key_hashes: vector<Option<vector<u8>>>,
        txn_gas_price: u64,
        txn_max_gas_units: u64,
        txn_expiration_time: u64,
        chain_id: u8,
        is_simulation: bool,
    ) {
        prologue_common(
            &sender,
            &sender,
            txn_sequence_number,
            txn_sender_public_key,
            txn_gas_price,
            txn_max_gas_units,
            txn_expiration_time,
            chain_id,
            is_simulation,
        );
        multi_agent_common_prologue(secondary_signer_addresses, secondary_signer_public_key_hashes, is_simulation);
    }

    /// If there is no fee_payer, fee_payer = sender
    fun unified_prologue_fee_payer(
        sender: signer,
        fee_payer: signer,
        // None means no need to check, i.e. either AA (where it is already checked) or simulation
        txn_sender_public_key: Option<vector<u8>>,
        // None means no need to check, i.e. either AA (where it is already checked) or simulation
        fee_payer_public_key_hash: Option<vector<u8>>,
        txn_sequence_number: u64,
        secondary_signer_addresses: vector<address>,
        secondary_signer_public_key_hashes: vector<Option<vector<u8>>>,
        txn_gas_price: u64,
        txn_max_gas_units: u64,
        txn_expiration_time: u64,
        chain_id: u8,
        is_simulation: bool,
    ) {
        prologue_common(
            &sender,
            &fee_payer,
            txn_sequence_number,
            txn_sender_public_key,
            txn_gas_price,
            txn_max_gas_units,
            txn_expiration_time,
            chain_id,
            is_simulation,
        );
        multi_agent_common_prologue(secondary_signer_addresses, secondary_signer_public_key_hashes, is_simulation);
        if (!features::transaction_simulation_enhancement_enabled() ||
            !skip_auth_key_check(is_simulation, &fee_payer_public_key_hash)) {
            let fee_payer_address = signer::address_of(&fee_payer);
            if (option::is_some(&fee_payer_public_key_hash)) {
                assert!(
                    fee_payer_public_key_hash == option::some(account::get_authentication_key(fee_payer_address)),
                    error::invalid_argument(PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY)
                );
            } else {
                assert!(
                    allow_missing_txn_authentication_key(fee_payer_address),
                    error::invalid_argument(PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY)
                )
            };
        }
    }

    fun unified_epilogue(
        account: signer,
        gas_payer: signer,
        storage_fee_refunded: u64,
        txn_gas_price: u64,
        txn_max_gas_units: u64,
        gas_units_remaining: u64,
        is_simulation: bool,
    ) {
        assert!(txn_max_gas_units >= gas_units_remaining, error::invalid_argument(EOUT_OF_GAS));
        let gas_used = txn_max_gas_units - gas_units_remaining;

        assert!(
            (txn_gas_price as u128) * (gas_used as u128) <= MAX_U64,
            error::out_of_range(EOUT_OF_GAS)
        );
        let transaction_fee_amount = txn_gas_price * gas_used;

        let gas_payer_address = signer::address_of(&gas_payer);
        // it's important to maintain the error code consistent with vm
        // to do failed transaction cleanup.
        if (!features::transaction_simulation_enhancement_enabled() || !skip_gas_payment(
            is_simulation,
            gas_payer_address
        )) {
            if (features::operations_default_to_fa_apt_store_enabled()) {
                assert!(
                    aptos_account::is_fungible_balance_at_least(gas_payer_address, transaction_fee_amount),
                    error::out_of_range(PROLOGUE_ECANT_PAY_GAS_DEPOSIT),
                );
            } else {
                assert!(
                    coin::is_balance_at_least<AptosCoin>(gas_payer_address, transaction_fee_amount),
                    error::out_of_range(PROLOGUE_ECANT_PAY_GAS_DEPOSIT),
                );
            };

            if (transaction_fee_amount > storage_fee_refunded) {
                let burn_amount = transaction_fee_amount - storage_fee_refunded;
                transaction_fee::burn_fee(gas_payer_address, burn_amount);
                permissioned_signer::check_permission_consume(
                    &gas_payer,
                    (burn_amount as u256),
                    GasPermission {}
                );
            } else if (transaction_fee_amount < storage_fee_refunded) {
                let mint_amount = storage_fee_refunded - transaction_fee_amount;
                transaction_fee::mint_and_refund(gas_payer_address, mint_amount);
                permissioned_signer::increase_limit(
                    &gas_payer,
                    (mint_amount as u256),
                    GasPermission {}
                );
            };
        };

        // Increment sequence number
        let addr = signer::address_of(&account);
        account::increment_sequence_number(addr);
    }
}

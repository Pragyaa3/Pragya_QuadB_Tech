module gas_fee_trackr::gas_fee_tracker_helper {
    use aptos_std::event;
    use aptos_std::guid;

    // Event to log state creation
    struct StateCreationEvent has store {
        sender: address,
        operation: vector<u8>, // Use vector<u8> to represent the string
        gas_used: u64,
    }

    // Event to log state deletion
    struct StateDeletionEvent has store {
        sender: address,
        operation: vector<u8>, // Use vector<u8> to represent the string
        gas_used: u64,
    }

    // Log an event for state creation
    public fun log_state_creation(sender: address, operation: vector<u8>, gas_used: u64) {
        let guid_sender: guid::GUID = guid::create_guid(sender);
        let handle: event::EventHandle<StateCreationEvent> = event::new_event_handle<StateCreationEvent>(guid_sender);

        // Emit the event using the handle and the data
        event::emit_event<StateCreationEvent>(&mut handle, StateCreationEvent {
            sender: sender,
            operation: operation,
            gas_used: gas_used,
        });
    }

    // Log an event for state deletion
    public fun log_state_deletion(sender: address, operation: vector<u8>, gas_used: u64) {
        let guid_sender: guid::GUID = guid::create_guid(sender);
        let handle: event::EventHandle<StateDeletionEvent> = event::new_event_handle<StateDeletionEvent>(guid_sender);

        // Emit the event using the handle and the data
        event::emit_event<StateDeletionEvent>(&mut handle, StateDeletionEvent {
            sender: sender,
            operation: operation,
            gas_used: gas_used,
        });
    }
}

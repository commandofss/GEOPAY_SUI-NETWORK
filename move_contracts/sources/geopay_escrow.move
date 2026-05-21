
module geopay::geopay_escrow {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::dynamic_field;

    // ======== States ========
    const STATE_PENDING: u8 = 0;
    const STATE_SUBMITTED: u8 = 1;
    const STATE_APPROVED: u8 = 2;   // NEW: SURCON approved on-chain
    const STATE_COMPLETED: u8 = 3;
    const STATE_CANCELLED: u8 = 4;
    const STATE_EXPIRED: u8 = 5;
    const STATE_DISPUTED: u8 = 6;   // NEW: dispute raised

    // ======== Errors ========
    const ENotAuthorized: u64 = 1;
    const EInvalidState: u64 = 2;
    const EInsufficientPayment: u64 = 3;
    const EDeadlineNotReached: u64 = 4;
    const EDeadlineExceeded: u64 = 5;
    const EInvalidLandType: u64 = 6;
    const ENotRegulatoryBody: u64 = 7;   // NEW
    const EAlreadyApproved: u64 = 8;     // NEW
    const ENotApproved: u64 = 9;         // NEW: client must wait for SURCON approval
    const EInvalidSplitPercent: u64 = 10; // NEW: partial refund validation
    const EDisputeAlreadyRaised: u64 = 11; // NEW

    // ======== Time Lock (7 days in milliseconds) ========
    const DEADLINE_MS: u64 = 7 * 24 * 60 * 60 * 1000;

    // ======== Private Land Fees (MIST) ========
    const P1:  u64 = 150_000_000;
    const P2:  u64 = 190_000_000;
    const P3:  u64 = 210_000_000;
    const P4:  u64 = 230_000_000;
    const P5:  u64 = 250_000_000;
    const P6:  u64 = 265_000_000;
    const P7:  u64 = 275_000_000;
    const P8:  u64 = 295_000_000;
    const P9:  u64 = 315_000_000;
    const P10: u64 = 335_000_000;
    const P11: u64 = 420_000_000;
    const P12: u64 = 505_000_000;
    const P13: u64 = 580_000_000;
    const P14: u64 = 665_000_000;
    const P15: u64 = 750_000_000;
    const P16: u64 = 835_000_000;
    const P17: u64 = 920_000_000;
    const P18: u64 = 995_000_000;
    const P19: u64 = 1_060_000_000;
    const P20: u64 = 1_145_000_000;
    const P_PER_HA: u64 = 15_000_000;

    // ======== Commercial Land Fees (MIST) ========
    const C1:  u64 = 225_000_000;
    const C2:  u64 = 285_000_000;
    const C3:  u64 = 315_000_000;
    const C4:  u64 = 345_000_000;
    const C5:  u64 = 375_000_000;
    const C6:  u64 = 397_500_000;
    const C7:  u64 = 412_500_000;
    const C8:  u64 = 442_500_000;
    const C9:  u64 = 472_500_000;
    const C10: u64 = 502_500_000;
    const C11: u64 = 630_000_000;
    const C12: u64 = 757_500_000;
    const C13: u64 = 870_000_000;
    const C14: u64 = 997_500_000;
    const C15: u64 = 1_125_000_000;
    const C16: u64 = 1_252_500_000;
    const C17: u64 = 1_380_000_000;
    const C18: u64 = 1_492_500_000;
    const C19: u64 = 1_590_000_000;
    const C20: u64 = 1_717_500_000;
    const C_PER_HA: u64 = 22_500_000;

    // ======== Events ========
    public struct EscrowCreated has copy, drop {
        escrow_id: address,
        client: address,
        surveyor: address,
        fee: u64,
        deadline: u64,
    }

    public struct RedCopySubmitted has copy, drop {
        escrow_id: address,
        surveyor: address,
        regulatory_body: address,
        file_name: vector<u8>,
        file_format: vector<u8>,
        storage_url: vector<u8>,
        file_hash: vector<u8>,
    }

    public struct EscrowApproved has copy, drop {        // NEW
        escrow_id: address,
        regulatory_body: address,
        approved_at: u64,
    }

    public struct EscrowCompleted has copy, drop {
        escrow_id: address,
        surveyor_amount: u64,
        regulatory_amount: u64,
    }

    public struct EscrowRefunded has copy, drop {
        escrow_id: address,
        client: address,
        amount: u64,
        reason: vector<u8>,
    }

    public struct ExcessRefunded has copy, drop {       // NEW
        escrow_id: address,
        client: address,
        excess_amount: u64,
    }

    public struct DisputeRaised has copy, drop {        // NEW
        escrow_id: address,
        raised_by: address,
        reason: vector<u8>,
    }

    public struct PartialRefundIssued has copy, drop {  // NEW
        escrow_id: address,
        client_amount: u64,
        surveyor_amount: u64,
    }

    // ======== Dynamic Field Keys & Values ========
    public struct DocumentFieldsKey has copy, drop, store {}
    public struct UpgradeDeadlineKey has copy, drop, store {}
    public struct DisputeReasonKey has copy, drop, store {}  // NEW

    public struct DocumentFields has store, drop {
        file_hash: vector<u8>,
        file_name: vector<u8>,
        file_format: vector<u8>,
        storage_url: vector<u8>,
    }

    // ======== Main Struct ========
    public struct SurveyEscrow has key, store {
        id: UID,
        client: address,
        surveyor: address,
        regulatory_body: address,
        job_id: vector<u8>,
        description: vector<u8>,
        land_area_m2: u64,
        land_type: u8,
        state: u8,
        payment: Coin<SUI>,
        red_copy_hash: vector<u8>,
    }

    // ======== Fee Calculator ========
    public fun calculate_fee(area_m2: u64, land_type: u8): u64 {
        assert!(land_type == 0 || land_type == 1, EInvalidLandType);
        if (land_type == 0) {
            if      (area_m2 <= 690)    { P1  }
            else if (area_m2 <= 1160)   { P2  }
            else if (area_m2 <= 1620)   { P3  }
            else if (area_m2 <= 2090)   { P4  }
            else if (area_m2 <= 2550)   { P5  }
            else if (area_m2 <= 3020)   { P6  }
            else if (area_m2 <= 3480)   { P7  }
            else if (area_m2 <= 3950)   { P8  }
            else if (area_m2 <= 4410)   { P9  }
            else if (area_m2 <= 4880)   { P10 }
            else if (area_m2 <= 7200)   { P11 }
            else if (area_m2 <= 10000)  { P12 }
            else if (area_m2 <= 20000)  { P13 }
            else if (area_m2 <= 50000)  { P14 }
            else if (area_m2 <= 100000) { P15 }
            else if (area_m2 <= 150000) { P16 }
            else if (area_m2 <= 200000) { P17 }
            else if (area_m2 <= 300000) { P18 }
            else if (area_m2 <= 400000) { P19 }
            else if (area_m2 <= 500000) { P20 }
            else { (area_m2 / 10000) * P_PER_HA }
        } else {
            if      (area_m2 <= 690)    { C1  }
            else if (area_m2 <= 1160)   { C2  }
            else if (area_m2 <= 1620)   { C3  }
            else if (area_m2 <= 2090)   { C4  }
            else if (area_m2 <= 2550)   { C5  }
            else if (area_m2 <= 3020)   { C6  }
            else if (area_m2 <= 3480)   { C7  }
            else if (area_m2 <= 3950)   { C8  }
            else if (area_m2 <= 4410)   { C9  }
            else if (area_m2 <= 4880)   { C10 }
            else if (area_m2 <= 7200)   { C11 }
            else if (area_m2 <= 10000)  { C12 }
            else if (area_m2 <= 20000)  { C13 }
            else if (area_m2 <= 50000)  { C14 }
            else if (area_m2 <= 100000) { C15 }
            else if (area_m2 <= 150000) { C16 }
            else if (area_m2 <= 200000) { C17 }
            else if (area_m2 <= 300000) { C18 }
            else if (area_m2 <= 400000) { C19 }
            else if (area_m2 <= 500000) { C20 }
            else { (area_m2 / 10000) * C_PER_HA }
        }
    }

    // ======== FIX #6: get_fee_tier now returns the correct tier (1-20, 0=over 50Ha) ========
    public fun get_fee_tier(area_m2: u64, land_type: u8): u8 {
        assert!(land_type == 0 || land_type == 1, EInvalidLandType);
        if      (area_m2 <= 690)    { 1  }
        else if (area_m2 <= 1160)   { 2  }
        else if (area_m2 <= 1620)   { 3  }
        else if (area_m2 <= 2090)   { 4  }
        else if (area_m2 <= 2550)   { 5  }
        else if (area_m2 <= 3020)   { 6  }
        else if (area_m2 <= 3480)   { 7  }
        else if (area_m2 <= 3950)   { 8  }
        else if (area_m2 <= 4410)   { 9  }
        else if (area_m2 <= 4880)   { 10 }
        else if (area_m2 <= 7200)   { 11 }
        else if (area_m2 <= 10000)  { 12 }
        else if (area_m2 <= 20000)  { 13 }
        else if (area_m2 <= 50000)  { 14 }
        else if (area_m2 <= 100000) { 15 }
        else if (area_m2 <= 150000) { 16 }
        else if (area_m2 <= 200000) { 17 }
        else if (area_m2 <= 300000) { 18 }
        else if (area_m2 <= 400000) { 19 }
        else if (area_m2 <= 500000) { 20 }
        else { 0 } // 0 = per-hectare rate above 50Ha
    }

    // ======== V1 Create Escrow ========
    // FIX #4: Refunds excess payment back to client immediately
    public fun create_escrow(
        mut payment: Coin<SUI>,
        surveyor: address,
        regulatory_body: address,
        job_id: vector<u8>,
        description: vector<u8>,
        land_area_m2: u64,
        land_type: u8,
        ctx: &mut TxContext
    ) {
        let fee = calculate_fee(land_area_m2, land_type);
        let paid = coin::value(&payment);
        assert!(paid >= fee, EInsufficientPayment);

        // FIX #4: Refund any excess above the required fee
        if (paid > fee) {
            let excess = coin::split(&mut payment, paid - fee, ctx);
            let escrow_id_preview = tx_context::sender(ctx); // temp ref for event
            event::emit(ExcessRefunded {
                escrow_id: escrow_id_preview,
                client: tx_context::sender(ctx),
                excess_amount: paid - fee,
            });
            transfer::public_transfer(excess, tx_context::sender(ctx));
        };

        let escrow_uid = object::new(ctx);
        let escrow_id = object::uid_to_address(&escrow_uid);

        let escrow = SurveyEscrow {
            id: escrow_uid,
            client: tx_context::sender(ctx),
            surveyor,
            regulatory_body,
            job_id,
            description,
            land_area_m2,
            land_type,
            state: STATE_PENDING,
            payment,
            red_copy_hash: b"",
        };

        event::emit(EscrowCreated {
            escrow_id,
            client: tx_context::sender(ctx),
            surveyor,
            fee,
            deadline: 0,
        });

        transfer::share_object(escrow);
    }

    // ======== V2 Create Escrow (with deadline) ========
    // FIX #4: Also refunds excess payment
    public fun create_escrow_v2(
        mut payment: Coin<SUI>,
        surveyor: address,
        regulatory_body: address,
        job_id: vector<u8>,
        description: vector<u8>,
        land_area_m2: u64,
        land_type: u8,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let fee = calculate_fee(land_area_m2, land_type);
        let paid = coin::value(&payment);
        assert!(paid >= fee, EInsufficientPayment);

        // FIX #4: Refund excess
        if (paid > fee) {
            let excess = coin::split(&mut payment, paid - fee, ctx);
            transfer::public_transfer(excess, tx_context::sender(ctx));
        };

        let now = clock::timestamp_ms(clock);
        let deadline = now + DEADLINE_MS;

        let escrow_uid = object::new(ctx);
        let escrow_id = object::uid_to_address(&escrow_uid);

        let mut escrow = SurveyEscrow {
            id: escrow_uid,
            client: tx_context::sender(ctx),
            surveyor,
            regulatory_body,
            job_id,
            description,
            land_area_m2,
            land_type,
            state: STATE_PENDING,
            payment,
            red_copy_hash: b"",
        };

        dynamic_field::add(&mut escrow.id, UpgradeDeadlineKey {}, deadline);

        event::emit(EscrowCreated {
            escrow_id,
            client: tx_context::sender(ctx),
            surveyor,
            fee,
            deadline,
        });

        transfer::share_object(escrow);
    }

    // ======== V1 Submit Red Copy ========
    public fun submit_red_copy(
        escrow: &mut SurveyEscrow,
        red_copy_hash: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(escrow.state == STATE_PENDING, EInvalidState);
        assert!(tx_context::sender(ctx) == escrow.surveyor, ENotAuthorized);

        escrow.red_copy_hash = red_copy_hash;
        escrow.state = STATE_SUBMITTED;
        let escrow_id = object::uid_to_address(&escrow.id);

        event::emit(RedCopySubmitted {
            escrow_id,
            surveyor: escrow.surveyor,
            regulatory_body: escrow.regulatory_body,
            file_name: b"",
            file_format: b"",
            storage_url: b"",
            file_hash: red_copy_hash,
        });
    }

    // ======== V2 Submit Red Copy (full metadata + deadline check) ========
    public fun submit_red_copy_v2(
        escrow: &mut SurveyEscrow,
        file_hash: vector<u8>,
        file_name: vector<u8>,
        file_format: vector<u8>,
        storage_url: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(escrow.state == STATE_PENDING, EInvalidState);
        assert!(tx_context::sender(ctx) == escrow.surveyor, ENotAuthorized);

        if (dynamic_field::exists_(&escrow.id, UpgradeDeadlineKey {})) {
            let deadline = *dynamic_field::borrow<UpgradeDeadlineKey, u64>(&escrow.id, UpgradeDeadlineKey {});
            assert!(clock::timestamp_ms(clock) <= deadline, EDeadlineExceeded);
        };

        let docs = DocumentFields {
            file_hash,
            file_name,
            file_format,
            storage_url,
        };

        dynamic_field::add(&mut escrow.id, DocumentFieldsKey {}, docs);
        escrow.red_copy_hash = file_hash;
        escrow.state = STATE_SUBMITTED;

        let escrow_id = object::uid_to_address(&escrow.id);

        event::emit(RedCopySubmitted {
            escrow_id,
            surveyor: escrow.surveyor,
            regulatory_body: escrow.regulatory_body,
            file_name,
            file_format,
            storage_url,
            file_hash,
        });
    }

    // ======== FIX #7: NEW — SURCON approves document on-chain ========
    // Only the regulatory_body address stored in the escrow can call this.
    // Moves state from SUBMITTED → APPROVED, unlocking client's ability to release.
    public fun regulatory_approve(
        escrow: &mut SurveyEscrow,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(escrow.state == STATE_SUBMITTED, EInvalidState);
        assert!(tx_context::sender(ctx) == escrow.regulatory_body, ENotRegulatoryBody);

        escrow.state = STATE_APPROVED;
        let escrow_id = object::uid_to_address(&escrow.id);

        event::emit(EscrowApproved {
            escrow_id,
            regulatory_body: escrow.regulatory_body,
            approved_at: clock::timestamp_ms(clock),
        });
    }

    // ======== FIX #7: confirm_and_release now requires SURCON approval first ========
    public fun confirm_and_release(
        escrow: &mut SurveyEscrow,
        ctx: &mut TxContext
    ) {
        // Must be APPROVED by regulatory body before client can release
        assert!(escrow.state == STATE_APPROVED, ENotApproved);
        assert!(tx_context::sender(ctx) == escrow.client, ENotAuthorized);

        let total = coin::value(&escrow.payment);

        // 30% to Surveyor
        let surveyor_amount = (total * 30) / 100;
        let surveyor_coin = coin::split(&mut escrow.payment, surveyor_amount, ctx);
        transfer::public_transfer(surveyor_coin, escrow.surveyor);

        // Remaining 70% to Regulatory Body
        let regulatory_amount = coin::value(&escrow.payment);
        let regulatory_coin = coin::split(&mut escrow.payment, regulatory_amount, ctx);
        transfer::public_transfer(regulatory_coin, escrow.regulatory_body);

        escrow.state = STATE_COMPLETED;

        event::emit(EscrowCompleted {
            escrow_id: object::uid_to_address(&escrow.id),
            surveyor_amount,
            regulatory_amount,
        });
    }

    // ======== FIX #2: NEW — Raise a dispute ========
    // Either client or surveyor can raise a dispute when escrow is SUBMITTED or APPROVED.
    // Freezes the escrow — only regulatory body can resolve it via partial_refund.
    public fun raise_dispute(
        escrow: &mut SurveyEscrow,
        reason: vector<u8>,
        ctx: &mut TxContext
    ) {
        // Can be raised from SUBMITTED or APPROVED state
        assert!(
            escrow.state == STATE_SUBMITTED || escrow.state == STATE_APPROVED,
            EInvalidState
        );
        // Only client or surveyor can raise a dispute
        let sender = tx_context::sender(ctx);
        assert!(
            sender == escrow.client || sender == escrow.surveyor,
            ENotAuthorized
        );
        // Cannot raise dispute twice
        assert!(!dynamic_field::exists_(&escrow.id, DisputeReasonKey {}), EDisputeAlreadyRaised);

        dynamic_field::add(&mut escrow.id, DisputeReasonKey {}, reason);
        escrow.state = STATE_DISPUTED;

        event::emit(DisputeRaised {
            escrow_id: object::uid_to_address(&escrow.id),
            raised_by: sender,
            reason,
        });
    }

    // ======== FIX #3: NEW — Partial refund to resolve dispute ========
    // Only the regulatory body can call this to resolve a disputed escrow.
    // surveyor_percent = 0–100. Remainder goes to client.
    // e.g. surveyor_percent=20 means surveyor gets 20%, client gets 80%.
    public fun resolve_dispute(
        escrow: &mut SurveyEscrow,
        surveyor_percent: u64,
        ctx: &mut TxContext
    ) {
        assert!(escrow.state == STATE_DISPUTED, EInvalidState);
        assert!(tx_context::sender(ctx) == escrow.regulatory_body, ENotRegulatoryBody);
        assert!(surveyor_percent <= 100, EInvalidSplitPercent);

        let total = coin::value(&escrow.payment);

        // Surveyor gets their agreed portion
        let surveyor_amount = (total * surveyor_percent) / 100;
        if (surveyor_amount > 0) {
            let surveyor_coin = coin::split(&mut escrow.payment, surveyor_amount, ctx);
            transfer::public_transfer(surveyor_coin, escrow.surveyor);
        };

        // Client gets the remainder
        let client_amount = coin::value(&escrow.payment);
        if (client_amount > 0) {
            let client_coin = coin::split(&mut escrow.payment, client_amount, ctx);
            transfer::public_transfer(client_coin, escrow.client);
        };

        escrow.state = STATE_COMPLETED;

        event::emit(PartialRefundIssued {
            escrow_id: object::uid_to_address(&escrow.id),
            client_amount,
            surveyor_amount,
        });
    }

    // ======== Client Cancels (PENDING only) ========
    public fun cancel_escrow(
        escrow: &mut SurveyEscrow,
        ctx: &mut TxContext
    ) {
        assert!(escrow.state == STATE_PENDING, EInvalidState);
        assert!(tx_context::sender(ctx) == escrow.client, ENotAuthorized);

        let total = coin::value(&escrow.payment);
        let refund = coin::split(&mut escrow.payment, total, ctx);
        transfer::public_transfer(refund, escrow.client);

        escrow.state = STATE_CANCELLED;

        event::emit(EscrowRefunded {
            escrow_id: object::uid_to_address(&escrow.id),
            client: escrow.client,
            amount: total,
            reason: b"cancelled",
        });
    }

    // ======== Claim Refund After Deadline ========
    public fun claim_expired_refund(
        escrow: &mut SurveyEscrow,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(escrow.state == STATE_PENDING, EInvalidState);
        assert!(tx_context::sender(ctx) == escrow.client, ENotAuthorized);

        assert!(dynamic_field::exists_(&escrow.id, UpgradeDeadlineKey {}), EInvalidState);
        let deadline = *dynamic_field::borrow<UpgradeDeadlineKey, u64>(&escrow.id, UpgradeDeadlineKey {});
        assert!(clock::timestamp_ms(clock) > deadline, EDeadlineNotReached);

        let total = coin::value(&escrow.payment);
        let refund = coin::split(&mut escrow.payment, total, ctx);
        transfer::public_transfer(refund, escrow.client);

        escrow.state = STATE_EXPIRED;

        event::emit(EscrowRefunded {
            escrow_id: object::uid_to_address(&escrow.id),
            client: escrow.client,
            amount: total,
            reason: b"expired",
        });
    }

    // ======== Getters ========
    public fun get_state(escrow: &SurveyEscrow): u8 { escrow.state }
    public fun get_balance(escrow: &SurveyEscrow): u64 { coin::value(&escrow.payment) }
    public fun get_client(escrow: &SurveyEscrow): address { escrow.client }
    public fun get_surveyor(escrow: &SurveyEscrow): address { escrow.surveyor }
    public fun get_regulatory_body(escrow: &SurveyEscrow): address { escrow.regulatory_body }
    public fun get_job_id(escrow: &SurveyEscrow): vector<u8> { escrow.job_id }
    public fun get_land_area(escrow: &SurveyEscrow): u64 { escrow.land_area_m2 }
    public fun get_land_type(escrow: &SurveyEscrow): u8 { escrow.land_type }
    public fun is_disputed(escrow: &SurveyEscrow): bool { escrow.state == STATE_DISPUTED }
    public fun is_approved(escrow: &SurveyEscrow): bool { escrow.state == STATE_APPROVED }

    public fun get_deadline(escrow: &SurveyEscrow): u64 {
        if (dynamic_field::exists_(&escrow.id, UpgradeDeadlineKey {})) {
            *dynamic_field::borrow<UpgradeDeadlineKey, u64>(&escrow.id, UpgradeDeadlineKey {})
        } else {
            0
        }
    }

    public fun get_storage_url(escrow: &SurveyEscrow): vector<u8> {
        if (dynamic_field::exists_(&escrow.id, DocumentFieldsKey {})) {
            let docs = dynamic_field::borrow<DocumentFieldsKey, DocumentFields>(&escrow.id, DocumentFieldsKey {});
            docs.storage_url
        } else {
            b""
        }
    }

    public fun get_file_format(escrow: &SurveyEscrow): vector<u8> {
        if (dynamic_field::exists_(&escrow.id, DocumentFieldsKey {})) {
            let docs = dynamic_field::borrow<DocumentFieldsKey, DocumentFields>(&escrow.id, DocumentFieldsKey {});
            docs.file_format
        } else {
            b""
        }
    }

    public fun get_file_name(escrow: &SurveyEscrow): vector<u8> {
        if (dynamic_field::exists_(&escrow.id, DocumentFieldsKey {})) {
            let docs = dynamic_field::borrow<DocumentFieldsKey, DocumentFields>(&escrow.id, DocumentFieldsKey {});
            docs.file_name
        } else {
            b""
        }
    }

    public fun get_file_hash(escrow: &SurveyEscrow): vector<u8> {
        if (dynamic_field::exists_(&escrow.id, DocumentFieldsKey {})) {
            let docs = dynamic_field::borrow<DocumentFieldsKey, DocumentFields>(&escrow.id, DocumentFieldsKey {});
            docs.file_hash
        } else {
            escrow.red_copy_hash
        }
    }

    public fun get_dispute_reason(escrow: &SurveyEscrow): vector<u8> {
        if (dynamic_field::exists_(&escrow.id, DisputeReasonKey {})) {
            *dynamic_field::borrow<DisputeReasonKey, vector<u8>>(&escrow.id, DisputeReasonKey {})
        } else {
            b""
        }
    }
}

use dep::std::hash::poseidon;

const MERKLE_HEIGHT: u32 = 32;
const BURN_ADDRESS: Field = 0x000000000000000000000000000000000000dEaD;

fn compute_merkle_root(path: [Field; MERKLE_HEIGHT], mut index: u32, leaf: Field) -> Field {
    let mut current = leaf;

    for i in 0..MERKLE_HEIGHT {
        let sibling = path[i];
        if (index & 1u32) == 0u32 {
            current = poseidon([current, sibling]);
        } else {
            current = poseidon([sibling, current]);
        }
        index = index >> 1u32;
    }

    current
}

fn main(
    pub burn_root: Field,
    pub amount: Field,
    leaf_index: u32,
    merkle_path: [Field; MERKLE_HEIGHT],
    sender: Field,
    tx_hash_hi: Field,
    tx_hash_lo: Field,
    timestamp: Field,
    salt: Field,
    amount_private: Field,
) -> pub Field {
    assert(amount_private != 0);
    assert(amount == amount_private);

    // Ensure the burn destination is the canonical burn address
    let leaf_inputs: [Field; 6] = [
        sender,
        BURN_ADDRESS,
        tx_hash_hi,
        tx_hash_lo,
        amount_private,
        timestamp,
    ];
    let burn_leaf = poseidon(leaf_inputs);

    let computed_root = compute_merkle_root(merkle_path, leaf_index, burn_leaf);
    assert(computed_root == burn_root);

    let nullifier_inputs: [Field; 4] = [sender, tx_hash_hi, tx_hash_lo, salt];
    let computed_nullifier = poseidon(nullifier_inputs);

    computed_nullifier
}

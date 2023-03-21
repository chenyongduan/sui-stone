module stone::stone {
  use sui::tx_context::{ Self, TxContext };
  use sui::object::{ Self, UID };
  use sui::url::{Self, Url};
  use sui::transfer;
  use std::hash::sha3_256 as hash;
  use sui::bcs;
  use std::string::{ Self, String };
  use std::vector as vec;

  struct Attribute has store, copy, drop {
    name: String,
    value: u64,
  }

  struct Stone has key, store {
    id: UID,
    url: Url,
    attributes: vector<Attribute>,
  }

  struct StoneRegister has key {
    id:  UID,
    stone_born: u64,
  }

  const LOGO_URL: vector<u8> = b"https://gstatic.97kid.com/sui/stone/logo.png";

  // slot count
  const BACKGROUND_COUNT: u64 = 10;
  const BODY_COUNT: u64 = 10;
  const CLOTHES_COUNT: u64 = 10;
  const EARRING_COUNT: u64 = 6;
  const GLASS_COUNT: u64 = 10;
  const HEAD_COUNT: u64 = 10;
  const MOUTH_COUNT: u64 = 8;
  const NECKLACE_COUNT: u64 = 7;
  const ONLY_COUNT: u64 = 10;

  // only slot probability
  const ONLY_PROBABILITY: u8 = 2;

  fun init(ctx: &mut TxContext) {
    let id = object::new(ctx);

    transfer::share_object(StoneRegister {
      id,
      stone_born: 0,
    });
  }

  #[test_only]
  public fun init_test(ctx: &mut TxContext) {
    init(ctx);
  }

  fun getSlotIndex(seed: &vector<u8>, slotLen: u64): (u64, vector<u8>) {
    let sequence = hash(*seed);
    let bcs_bytes = bcs::new(sequence);
    let slot_idx = bcs::peel_u64(&mut bcs_bytes) % slotLen;
    (slot_idx, sequence)
  }

  public entry fun create_stone(reg: &mut StoneRegister, ctx: &mut TxContext) {
    let id = object::new(ctx);

    let (background_idx, sequence1) = getSlotIndex(&object::uid_to_bytes(&id), BACKGROUND_COUNT);
    let (body_idx, sequence2) = getSlotIndex(&sequence1, BODY_COUNT);
    let (clothes_idx, sequence3) = getSlotIndex(&sequence2, CLOTHES_COUNT);
    let (earring_idx, sequence4) = getSlotIndex(&sequence3, EARRING_COUNT);
    let (head_idx, sequence5) = getSlotIndex(&sequence4, HEAD_COUNT);
    let (glass_idx, sequence6) = getSlotIndex(&sequence5, GLASS_COUNT);
    let (necklace_idx, sequence7) = getSlotIndex(&sequence6, NECKLACE_COUNT);
    let (mouth_idx, _) = getSlotIndex(&sequence7, MOUTH_COUNT);

    let attributes = vec::empty();
    vec::push_back(&mut attributes, Attribute { name:  string::utf8(b"background"), value: background_idx });
    vec::push_back(&mut attributes, Attribute { name:  string::utf8(b"body"), value: body_idx });
    vec::push_back(&mut attributes, Attribute { name:  string::utf8(b"clothes"), value: clothes_idx });
    vec::push_back(&mut attributes, Attribute { name:  string::utf8(b"earring"), value: earring_idx });
    vec::push_back(&mut attributes, Attribute { name:  string::utf8(b"head"), value: head_idx });
    vec::push_back(&mut attributes, Attribute { name:  string::utf8(b"glass"), value: glass_idx });
    vec::push_back(&mut attributes, Attribute { name:  string::utf8(b"necklace"), value: necklace_idx });
    vec::push_back(&mut attributes, Attribute { name:  string::utf8(b"mouth"), value: mouth_idx });

    let stone = Stone {
      id,
      url:  url::new_unsafe_from_bytes(LOGO_URL),
      attributes,
    };

    transfer::transfer(stone, tx_context::sender(ctx));

    reg.stone_born = reg.stone_born + 1;
  }

  // #[test] 
  // public fun test_module_init() {
  //   use sui::test_scenario;
  //   use std::debug;

  //   let admin = @0xBABE;

  //   let scenario_val = test_scenario::begin(admin);
  //   let scenario = &mut scenario_val;
  //   {
  //     init(test_scenario::ctx(scenario));
  //   };

  //   test_scenario::next_tx(scenario, admin);
  //   {
  //     let stoneReg = test_scenario::take_shared<StoneRegister>(scenario);
  //     create_stone(&mut stoneReg, test_scenario::ctx(scenario));
  //     test_scenario::return_shared(stoneReg);
  //   };

  //   test_scenario::next_tx(scenario, admin);
  //   {
  //     let stone = test_scenario::take_from_sender<Stone>(scenario);
  //     debug::print(&stone);
  //     test_scenario::return_to_sender(scenario, stone);
  //   };

  //   test_scenario::next_tx(scenario, admin);
  //   {
  //     let stoneReg = test_scenario::take_shared<StoneRegister>(scenario);
  //     debug::print(&stoneReg);
  //     test_scenario::return_shared(stoneReg);
  //   };
  //   test_scenario::end(scenario_val);
  // }
}
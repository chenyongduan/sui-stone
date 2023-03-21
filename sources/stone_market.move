module stone::stone_market {
  use sui::object::{ Self, UID, ID };
  use sui::tx_context::{ Self, TxContext };
  use sui::coin::{ Self, Coin };
  use sui::sui::{ SUI };
  use sui::transfer;
  use sui::pay;
  use sui::dynamic_object_field as dof;
  use stone::stone::{ Stone };
  use std::vector as vec;

  const ENotOwner: u64 = 0;

  const EAmountIncorrect: u64 = 1;

  struct StoneMarket<phantom T: key> has key  {
    id: UID,
  }

  struct Listing has key, store {
    id: UID,
    price: u64,
    owner: address,
  }

  fun init(ctx: &mut TxContext) {
    let id = object::new(ctx);
    transfer::share_object(StoneMarket<Stone> { id });
  }

  public entry fun list<T: key + store>(
      market: &mut StoneMarket<T>,
      item: T,
      price: u64,
      ctx: &mut TxContext
  )  {
    let id = object::new(ctx);
    let owner = tx_context::sender(ctx);
    let listing = Listing { id, price, owner };

    dof::add(&mut listing.id, true, item);
    dof::add(&mut market.id, object::id(&listing), listing);
  }

  public fun delist<T: key + store>(
    market: &mut StoneMarket<T>,
    listing_id: ID,
    ctx: &TxContext
  ): T {
    let Listing { id, price: _, owner } = dof::remove<ID, Listing>(&mut market.id, listing_id);
    let item = dof::remove(&mut id, true);

    assert!(tx_context::sender(ctx) == owner, ENotOwner);

    object::delete(id);
    item
  }

  entry fun delist_and_take<T: key + store>(
    market: &mut StoneMarket<T>,
    listing_id: ID,
    ctx: &TxContext
  ) {
    transfer::transfer(
      delist(market, listing_id, ctx),
      tx_context::sender(ctx)
    );
  }

  public fun purchase<T: key + store>(
    market: &mut StoneMarket<T>,
    listing_id: ID,
    paid: Coin<SUI>,
    _: &TxContext
  ): T {
    let Listing { id, price, owner } = dof::remove<ID, Listing>(&mut market.id, listing_id);
    let item = dof::remove(&mut id, true);

    assert!(price == coin::value(&paid), EAmountIncorrect);

    transfer::transfer(paid, owner);
    // if (dof::exists_(&market.id, owner)) {
    //   coin::join(dof::borrow_mut<address, Coin<SUI>>(&mut market.id, owner), paid);
    // } else {
    //   dof::add(&mut market.id, owner, paid);
    // };

    object::delete(id);
    item
  }

  entry fun purchase_and_take<T: key + store>(
    market: &mut StoneMarket<T>,
    listing_id: ID,
    paid: Coin<SUI>,
    ctx: &TxContext
  ) {
    transfer::transfer(
        purchase(market, listing_id, paid, ctx),
        tx_context::sender(ctx)
    )
  }

  entry fun purchase_and_take_mut<T: key + store>(
    market: &mut StoneMarket<T>,
    listing_id: ID,
    paid: &mut Coin<SUI>,
    ctx: &mut TxContext
  ) {
    let listing = dof::borrow<ID, Listing>(&market.id, *&listing_id);
    let coin = coin::split(paid, listing.price, ctx);
    purchase_and_take(market, listing_id, coin, ctx)
  }

  entry fun purchase_and_take_mul_coins<T: key + store>(
    market: &mut StoneMarket<T>,
    listing_id: ID,
    coins: vector<Coin<SUI>>,
    ctx: &mut TxContext
  ) {
    let listing = dof::borrow<ID, Listing>(&market.id, *&listing_id);

    let coin = vec::pop_back(&mut coins);
    pay::join_vec(&mut coin, coins);
    let paid = coin::split(&mut coin, listing.price, ctx);
    transfer::transfer(coin, tx_context::sender(ctx));
    
    purchase_and_take(market, listing_id, paid, ctx)
  }

  #[test]
  fun test_module() {
    use sui::test_scenario;
    use std::debug;
    use stone::stone::{Self, StoneRegister};
    use sui::tx_context;

    let admin = @0xBABE;
    let scenario_val = test_scenario::begin(admin);
    let scenario = &mut scenario_val;
    {
      init(test_scenario::ctx(scenario));
      stone::init_test(test_scenario::ctx(scenario));
    };

    test_scenario::next_tx(scenario, admin);
    {
      let coin = coin::mint_for_testing<SUI>(100, test_scenario::ctx(scenario));
      debug::print(&coin);
      transfer::transfer(coin, tx_context::sender(test_scenario::ctx(scenario)));

      let stoneReg = test_scenario::take_shared<StoneRegister>(scenario);
      stone::create_stone(&mut stoneReg, test_scenario::ctx(scenario));
      test_scenario::return_shared(stoneReg);
    };

    test_scenario::next_tx(scenario, admin); 
    {
      let coinSelf = test_scenario::take_from_sender<Coin<SUI>>(scenario);
      debug::print(&coinSelf);
      test_scenario::return_to_sender(scenario, coinSelf);
    };

    test_scenario::next_tx(scenario, admin);
    {
      let stone = test_scenario::take_from_sender<Stone>(scenario);
      let market = test_scenario::take_shared<StoneMarket<Stone>>(scenario);
      list(&mut market, stone, 20, test_scenario::ctx(scenario));
      debug::print(&market);
      test_scenario::return_shared(market);
    };

    test_scenario::end(scenario_val);
  }
}
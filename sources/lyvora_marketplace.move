module lyvora::lyvora_marketplace;

use sui::object::{Self, UID};
use sui::coin::{Self, Coin};
use sui::sui::SUI;
use sui::dynamic_object_field as dof;
use sui::balance::{Self, Balance};
use sui::clock::{Self, Clock};

public enum OrderStatus has store {
    Pending,
    Shipped,
    Completed,
    Cancelled,
}

public struct Marketplace has key {
    id: UID,
    fee_pbs: u64,
    admin: address,
}

public struct Store has key {
    id: UID,
    name: vector<u8>,
    description: vector<u8>,
    image_url: vector<u8>,
    products: vector<UID>,
    owner: address,
}

public struct Product has key, store {
    id: UID,
    name: vector<u8>,
    description: vector<u8>,
    image_url: vector<u8>,
    price: u64,
    stock: u64,
    store: address,
}


#[allow(lint(coin_field))]
public struct Order has key, store {
    id: UID,
    product: address,
    buyer: address,
    store: address,
    order_status: OrderStatus,
    shipping_address: vector<u8>,
    order_date: u64,
    total_price: u64,
    payment: Coin<SUI>,
}

const ENotStoreOwner: u64 = 0;
const EOutOfStock: u64 = 1;
const EProductPriceNotMatch: u64 = 2;

public fun list_product(
    marketplace: &mut Marketplace,
    store: &mut Store,
    name: vector<u8>,
    description: vector<u8>,
    image_url: vector<u8>,
    price: u64,
    stock: u64,
    ctx: &mut TxContext
) {
    // Logic to list a product in the store
    // This include adding the product to the store's product lists as a dynamic object field

    assert!(tx_context::sender(ctx) == store.owner, ENotStoreOwner);

    let product_id = object::new(ctx);
    let product_address = object::uid_to_address(&product_id);
    let product = Product {
        id: product_id,
        name: name,
        description: description,
        image_url: image_url,
        price: price,
        stock: stock,
        store: object::uid_to_address(&store.id),
    };

    dof::add(&mut marketplace.id, product_address, product);
}

public fun order_product(
    marketplace: &mut Marketplace,
    store: &mut Store,
    product: &Product,
    shipping_address: vector<u8>,
    payment: Coin<SUI>,
    count: u64,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // Logic to handle ordering a product
    // This include checking stock, processing payment, etc.

    assert!(count * product.price == coin::value(&payment), EProductPriceNotMatch);
    assert!(product.stock > 0, EOutOfStock);

    let order_id = object::new(ctx);
    let order_address = object::uid_to_address(&order_id);
    let order = Order {
        id: order_id,
        product: object::uid_to_address(&product.id),
        buyer: tx_context::sender(ctx),
        store: object::uid_to_address(&store.id),
        order_status: OrderStatus::Pending,
        shipping_address: shipping_address,
        order_date: clock::timestamp_ms(clock),
        total_price: count * product.price,
        payment: payment,
    };

    dof::add(&mut marketplace.id, order_address, order);
}

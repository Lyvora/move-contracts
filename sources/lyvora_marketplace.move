module lyvora::lyvora_marketplace;

use sui::object::{Self, UID};
use sui::coin::{Self, Coin};
use sui::sui::SUI;
use sui::dynamic_object_field as dof;
use sui::balance::{Self, Balance};
use sui::clock::{Self, Clock};
use std::fixed_point32;

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

public struct OrderHub has key {
    id: UID,
}

public struct StoreHub has key {
    id: UID,
}

public struct Store has key, store {
    id: UID,
    name: vector<u8>,
    description: vector<u8>,
    image_url: vector<u8>,
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
    seller: address,
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

fun init(ctx: &mut TxContext) {
        transfer::share_object(Marketplace { id: object::new(ctx),fee_pbs:2500,admin:tx_context::sender(ctx) });
        transfer::share_object(OrderHub { id: object::new(ctx) });
        transfer::share_object(StoreHub { id: object::new(ctx) });
}

fun calculate_fee(
    amount: u64,
    fee_pbs: u64,
    collateral_fee: u64) : u64
{
    let fee_fraction = fixed_point32::create_from_rational(fee_pbs,collateral_fee);
    let fee_amount = fixed_point32::multiply_u64(amount,fee_fraction);
    fee_amount
}

public fun new_store(
    storehub: &mut StoreHub,
    name: vector<u8>,
    description: vector<u8>,
    image_url: vector<u8>,
    ctx: &mut TxContext
) {
    // Logic to create a new store
    // This include creating a Store object and adding it to the marketplace's store list

    let store_id = object::new(ctx);
    let store_address = object::uid_to_address(&store_id);
    let store = Store {
        id: store_id,
        name: name,
        description: description,
        image_url: image_url,
        owner: tx_context::sender(ctx),
    };

    dof::add<address, Store>(&mut storehub.id, store_address, store);
}

public fun list_product(
    marketplace: &mut Marketplace,
    storehub: &mut StoreHub,
    store_address: address,
    name: vector<u8>,
    description: vector<u8>,
    image_url: vector<u8>,
    price: u64,
    stock: u64,
    ctx: &mut TxContext
) {
    // Logic to list a product in the store
    // This include adding the product to the store's product lists as a dynamic object field

    let store = dof::borrow<address, Store>(&mut storehub.id, store_address);

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
        seller: tx_context::sender(ctx),
    };

    dof::add<address, Product>(&mut marketplace.id, product_address, product);
}

public fun purchase_product(
    marketplace: &mut Marketplace,
    order_hub: &mut OrderHub,
    store: &mut Store,
    product_address: address,
    quantity: u64,
    shipping_address: vector<u8>,
    mut payment: Coin<SUI>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // Logic to handle ordering a product
    // This include checking stock, processing payment, etc.
    let product = dof::borrow_mut<address, Product>(&mut marketplace.id, product_address);

    assert!(quantity * product.price == coin::value(&payment), EProductPriceNotMatch);
    assert!(product.stock >= quantity, EOutOfStock);

    let coin_value = coin::value(&payment);
    let fee_amount = calculate_fee(coin_value,marketplace.fee_pbs,10000);
    let fee = coin::split(&mut payment,fee_amount,ctx);
    transfer::public_transfer(fee,marketplace.admin);

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
        total_price: quantity * product.price,
        payment: payment,
    };

    dof::add<address, Order>(&mut order_hub.id, order_address, order);

    product.stock = product.stock - quantity;
}

public fun delete_product(
    marketplace: &mut Marketplace,
    product_address: address,
    ctx: &mut TxContext
) {
    // Logic to delete a product from the store
    let product = dof::borrow_mut<address, Product>(&mut marketplace.id, product_address);
    assert!(tx_context::sender(ctx) == product.seller, ENotStoreOwner);

    let Product {
        id,
        name,
        description,
        image_url,
        price,
        stock,
        store,
        seller,
    } = dof::remove<address, Product>(&mut marketplace.id, product_address);

    object::delete(id);
}

// === Update Product Details ===
public fun update_product_name(
    marketplace: &mut Marketplace,
    product_address: address,
    new_name: vector<u8>,
    ctx: &mut TxContext
) {
    // Logic to change the name of a store
    let product = dof::borrow_mut<address, Product>(&mut marketplace.id, product_address);
    assert!(tx_context::sender(ctx) == product.seller, ENotStoreOwner);
    product.name = new_name;
}

public fun update_product_description(
    marketplace: &mut Marketplace,
    product_address: address,
    new_description: vector<u8>,
    ctx: &mut TxContext
) {
    // Logic to change the description of a store
    let product = dof::borrow_mut<address, Product>(&mut marketplace.id, product_address);
    assert!(tx_context::sender(ctx) == product.seller, ENotStoreOwner);
    product.description = new_description;
}

public fun update_product_image_url(
    marketplace: &mut Marketplace,
    product_address: address,
    new_image_url: vector<u8>,
    ctx: &mut TxContext
) {
    // Logic to change the image URL of a store
    let product = dof::borrow_mut<address, Product>(&mut marketplace.id, product_address);
    assert!(tx_context::sender(ctx) == product.seller, ENotStoreOwner);
    product.image_url = new_image_url;
}

public fun update_product_price(
    marketplace: &mut Marketplace,
    product_address: address,
    new_price: u64,
    ctx: &mut TxContext
) {
    // Logic to change the price of a store
    let product = dof::borrow_mut<address, Product>(&mut marketplace.id, product_address);
    assert!(tx_context::sender(ctx) == product.seller, ENotStoreOwner);
    product.price = new_price;
}

public fun update_product_stock(
    marketplace: &mut Marketplace,
    product_address: address,
    new_stock: u64,
    ctx: &mut TxContext
) {
    // Logic to change the stock of a store
    let product = dof::borrow_mut<address, Product>(&mut marketplace.id, product_address);
    assert!(tx_context::sender(ctx) == product.seller, ENotStoreOwner);
    product.stock = new_stock;
}



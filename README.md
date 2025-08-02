# Lyvora Marketplace Move smart contracts

Move smart contracts for Lyvora decentralized marketplace on Sui.  
Supports store creation, product listing, purchasing, and order management.

## Features

- **Store Management**
  - Create new stores
  - Update store details

- **Product Management**
  - List products for sale
  - Update product details (name, description, image, price, stock)
  - Delete products

- **Order Management**
  - Purchase products
  - Track order status
  - Store shipping and payment info

- **Marketplace Fees**
  - Configurable fee per transaction
  - Fee calculation and transfer to admin

## Main Structs

- `Marketplace`: Marketplace config and admin address
- `StoreHub`: Registry for stores
- `Store`: Seller's store
- `Product`: Listed product
- `OrderHub`: Registry for orders
- `Order`: Purchase record (buyer, product, payment, shipping info)

## Main Functions

- `init`: Initialize marketplace, store hub, and order hub
- `new_store`: Create a new store
- `list_product`: List a product for sale
- `purchase_product`: Buy a product, handle payment and fees
- `delete_product`: Remove a product
- `update_product_*`: Update product details

## Usage

Deploy the module to Sui and interact using Sui CLI or SDKs.

### Example Function Call (TypeScript SDK)

```typescript
const tx = new TransactionBlock();
tx.moveCall({
  target: 'your_package::lyvora_marketplace::purchase_product',
  arguments: [
    tx.object(marketplaceId),
    tx.object(orderHubId),
    tx.object(storeId),
    tx.pure(productAddress),
    tx.pure(quantity),
    tx.pure(shippingAddress),
    paymentCoin, // Coin<SUI>
    tx.object(clockId),
  ],
});
```

## Notes

- Payment uses `Coin<SUI>`, but for storage efficiency, consider `Balance<SUI>`.
- Only store owners can update or delete their products.
- All state changes are performed on-chain.

## License

MIT

---
**Questions or contributions? Open an issue or pull request.**
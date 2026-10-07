# products

## Purpose
Catalogue maintenance on Stockship catalogue collections: change a product's category/sub-category across its
pack-size siblings, report bulk/case drift, revert; toggle "visible in app" / "out of stock"; unified activity feed.
Nest modules: product-category, product-visibility.

## Entry points (all `/api/v2`)
- `product-category`: PATCH `:sku/category` (Scoped, no ScopedBy), GET `bulk-mismatch`, POST `logs/:id/revert` (Scoped), GET `logs`
- `product-visibility`: POST `toggle` (Scoped), GET `logs` (union of both log collections)

## Key files
`src/modules/product-category/product-category.service.ts`, `src/modules/product-visibility/{product-visibility.service.ts, schemas/}`

## Data
- product-category W: `cases`, `products` (bulkWrite), `product_category_update_logs` (append-only; revert = new row
  with `reverted_from`); R: `categories`, `subcategories` (cached 5 min), `bulks` (read-only by design)
- product-visibility W: `products`, `cases`, `combos`, `cases_updation_logs`; R `product_category_update_logs`

## Depends on
common raw-db, access. Not imported by other modules.

## Used by
- ADMIN: `/product-category/:sku/category`, `bulk-mismatch`, `logs/:id/revert` (`src/redux/productCategory.v2.api.ts`);
  `/product-visibility/toggle`, `logs` (`src/redux/productVisibility.v2.api.ts`).
- RVP, PORTAL: none.

## External services
None (catalogue collections are shared with Stockship; ownership UNVERIFIED).

## Gotchas
- The bulk's category is never cascaded; drift is reported instead. Per-SKU "previous" recorded for each sibling.
- Visibility response shape kept identical to the old Remix action; a toggle can legitimately match 0 docs.
- `sanitizeOutput` strips nested `_id`, so rows carry an `id` alias. Boot indexes on the log collections.

Last verified: 2026-10-07 @ 278fe58 (kartik)

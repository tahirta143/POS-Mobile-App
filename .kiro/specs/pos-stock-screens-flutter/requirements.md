# Requirements Document

## Introduction

This feature implements five fully functional Flutter screens for the POS mobile application, mirroring the existing React web screens. The screens are: Goods Receipt Note (GRN), Purchase Return, Define Customer, Sales Return, and Sales (Invoice). Each screen must follow the established Flutter project patterns using Provider for state management, ApiService for HTTP calls, and ThemeProvider with AppConstants for consistent dark/light theming. All screens replace existing stub implementations with complete, production-ready UI and business logic.

## Glossary

- **GRN**: Goods Receipt Note — a document acknowledging the receipt of goods against a pending purchase order.
- **PO**: Purchase Order — a pending purchase that has not yet been receipted.
- **Debit Note**: Record of a purchase return to a supplier, reducing the amount owed.
- **Credit Note**: Record of a sale return from a customer, reducing the customer's balance.
- **Screen**: A Flutter `StatefulWidget` that occupies the full body of the `MainScreen` scaffold.
- **Provider**: A `ChangeNotifier` class managing async state (loading, submitting, error) and list data, accessible via `context.read` / `context.watch`.
- **ApiService**: The existing HTTP client in `lib/services/api_service.dart` providing `get`, `post`, `put`, and `delete` methods using Bearer token authentication.
- **AppConstants**: Constants class in `lib/utils/constants.dart` defining color tokens (primaryTeal, darkBg, darkCard, darkBorder, lightBg, lightCard, lightBorder) and border radii.
- **ThemeProvider**: Provider exposing `lightTheme`, `darkTheme`, and `isDarkMode` for the app theme.
- **CustomAppBar**: Existing `PreferredSizeWidget` in `lib/widgets/custom_app_bar.dart` accepting `title`, `leading`, and optional `actions`.
- **CartRow**: A single line-item in a sales invoice composed of category, item, price, quantity, and calculated total.
- **Receipt Number**: Auto-generated sales invoice identifier in format `RCP-YYYYMMDD-HHMMSS-XXX`.
- **PurchaseModel**: Model for a completed/pending purchase, containing supplier info and a list of `PurchaseItemModel` items.
- **SaleInvoiceModel**: Model for a completed sale invoice, containing customer info, receipt number, paid amount, and a list of `SaleItemModel` items.
- **SalesReturnModel**: Model for a recorded sales return entry.
- **PurchaseReturnModel**: Model for a recorded purchase return (debit note) entry.
- **CustomerModel**: Model representing a registered customer with contact and payment details.
- **MultiProvider**: Flutter Provider tree in `main.dart` that must include all feature providers.

---

## Requirements

### Requirement 1: Goods Receipt Note (GRN) Screen

**User Story:** As a stock manager, I want to record the physical receipt of goods against pending purchase orders, so that inventory levels are updated and procurement is tracked accurately.

#### Acceptance Criteria

1. WHEN the GRN screen is displayed, THE GoodsReceiptProvider SHALL fetch all purchase orders with status `pending` from `GET /purchases?status=pending` and display them in a scrollable list showing reference, supplier name, date ordered, item count, and total valuation in PKR.
2. WHEN the list is loading, THE GRN Screen SHALL display a loading indicator in place of the list.
3. IF the pending orders list is empty after loading, THE GRN Screen SHALL display a "No pending goods receipts found" empty state message.
4. WHEN the user taps "Initiate GRN", THE GRN Screen SHALL display an Add dialog containing: a dropdown of pending purchase orders, a GRN Number text field (required), a GRN Date field defaulting to today's date, and a Remarks text area.
5. WHEN the user selects a purchase order from the dropdown in the Add dialog, THE GRN Screen SHALL display a read-only itemized table showing item name, category, inward quantity, acquisition rate (PKR), and line total (PKR) for each item in that order.
6. WHEN the user submits the Add dialog with a selected purchase order and a non-empty GRN Number, THE GoodsReceiptProvider SHALL POST to `/purchases/receipts` with `purchaseOrderId`, `grn_no`, `grn_date`, and `remarks`, then close the dialog and refresh the pending orders list.
7. IF the GRN submission fails, THE GRN Screen SHALL display a SnackBar with the server error message or a generic failure message.
8. THE GRN Screen SHALL accept a `VoidCallback? onMenuPressed` parameter and use `CustomAppBar` with title "Goods Receipt Note".
9. THE GRN Screen SHALL use `Theme.of(context)` colors for all backgrounds, cards, text, and borders, supporting both light and dark themes.
10. THE GRN Screen SHALL NOT provide edit or delete actions on GRN records (add and view only).

---

### Requirement 2: Purchase Return Screen

**User Story:** As a purchasing officer, I want to create and manage debit notes for returning goods to suppliers, so that supplier ledgers and stock levels are adjusted correctly.

#### Acceptance Criteria

1. WHEN the Purchase Return screen is displayed, THE PurchaseReturnProvider SHALL fetch all purchases from `GET /purchases` and all existing returns from `GET /purchase-returns`, displaying returns in a list showing Return ID (formatted as `DBT-XXXX`), Supplier name, Acquisition ID, Total Return amount in PKR, and Edit/Delete action buttons.
2. WHEN the list is loading, THE Purchase Return Screen SHALL display a loading indicator.
3. IF no returns exist, THE Purchase Return Screen SHALL display an empty state message.
4. WHEN the user taps "New Return", THE Purchase Return Screen SHALL display an Add dialog with a purchase reference dropdown populated from the fetched purchases list, showing supplier name and original reference as read-only info cards.
5. WHEN the user selects a purchase reference in the Add/Edit dialog, THE Purchase Return Screen SHALL display a return itemization table with columns: Item name, Inward Qty, Purchase Rate, Return Qty (editable number input, min 0, max = inward qty), and Amount (PKR).
6. WHEN the user changes a return quantity, THE Purchase Return Screen SHALL recalculate and display the total debit amount in real time.
7. WHEN the user submits the Add dialog with at least one item having a return quantity greater than zero, THE PurchaseReturnProvider SHALL POST to `/purchase-returns` with `purchaseId`, `supplierId`, `returnDate`, `items` array, and `reason`.
8. WHEN the user taps Edit on a return entry, THE Purchase Return Screen SHALL open the dialog pre-populated with the original purchase selected and return quantities from the existing return record.
9. WHEN the user submits an edit, THE PurchaseReturnProvider SHALL PUT to `/purchase-returns/:id` with the updated payload.
10. WHEN the user taps Delete and confirms, THE PurchaseReturnProvider SHALL DELETE `/purchase-returns/:id` and remove the entry from the list.
11. IF a submission or deletion fails, THE Purchase Return Screen SHALL display a SnackBar with the error message.
12. THE Purchase Return Screen SHALL accept a `VoidCallback? onMenuPressed` parameter and use `CustomAppBar` with title "Purchase Return".
13. THE Purchase Return Screen SHALL use `Theme.of(context)` colors throughout, supporting both light and dark themes.

---

### Requirement 3: Define Customer Screen

**User Story:** As a sales operator, I want to register and manage customer profiles with contact and payment preferences, so that invoices can be linked to customer accounts for accurate billing and history.

#### Acceptance Criteria

1. WHEN the Define Customer screen is displayed, THE CustomerProvider SHALL fetch all customers from `GET /customers` and display them in a list showing: Customer Name, Contact (mobile number + payment method badge), Address & Area (address + nearby landmark), Balance (PKR), and Edit/Delete action buttons.
2. WHEN the list is loading, THE Define Customer Screen SHALL display a loading indicator.
3. IF no customers exist, THE Define Customer Screen SHALL display an empty state message.
4. WHEN the user taps "Add Customer", THE Define Customer Screen SHALL open a dialog containing: Customer Name (required text field), Mobile No (tel input), Address (multi-line text area), Opening Balance (number input, defaults to 0), Nearby Landmark (text field), and Preferred Payment dropdown with options Cash, Credit, and Gift.
5. WHEN the user submits the Add dialog with a non-empty Customer Name, THE CustomerProvider SHALL POST to `/customers` with `customerName`, `address`, `mobileNumber`, `previousBalance`, `nearby`, and `paymentMethod`, then close the dialog and refresh the customer list.
6. WHEN the user taps Edit on a customer, THE Define Customer Screen SHALL open the dialog pre-populated with all fields from the selected customer.
7. WHEN the user submits an edit, THE CustomerProvider SHALL PUT to `/customers/:id` with the updated payload.
8. WHEN the user taps Delete and confirms, THE CustomerProvider SHALL DELETE `/customers/:id` and remove the customer from the list.
9. IF a submission or deletion fails, THE Define Customer Screen SHALL display a SnackBar with the error message.
10. THE Define Customer Screen SHALL accept a `VoidCallback? onMenuPressed` parameter and use `CustomAppBar` with title "Define Customer".
11. THE Define Customer Screen SHALL use `Theme.of(context)` colors throughout, supporting both light and dark themes.

---

### Requirement 4: Sales Return Screen

**User Story:** As a sales operator, I want to process merchandise returns against existing sale invoices or booking invoices and record credit notes, so that customer accounts and stock levels are adjusted accurately.

#### Acceptance Criteria

1. WHEN the Sales Return screen is displayed, THE SalesReturnProvider SHALL fetch sale invoices from `GET /sale-invoices`, booking invoices from `GET /bookings`, and existing returns from `GET /sale-returns`, displaying returns in a list showing: customer name, invoice reference, credit amount (PKR), return date, and Edit/Delete action buttons.
2. WHEN the list is loading, THE Sales Return Screen SHALL display a loading indicator.
3. IF no returns exist, THE Sales Return Screen SHALL display an empty state message.
4. THE Sales Return Screen SHALL display a tab switcher with two tabs: "Sale Invoices" and "Booking Invoices", defaulting to "Sale Invoices".
5. WHEN the user taps "New Return", THE Sales Return Screen SHALL open a dialog showing the tab switcher and a dropdown of invoices filtered by the active tab.
6. WHEN the user selects an invoice in the dialog, THE Sales Return Screen SHALL display info cards for Customer name, Invoice Reference, and Total Paid (PKR), and render a return items table with columns: Item name, Sold Qty, Unit Rate (PKR), Return Qty (editable number input, min 0, max = sold qty), and Credit (PKR).
7. WHEN the user changes a return quantity, THE Sales Return Screen SHALL recalculate gross return value, net credit (after discount), and display both in a summary section in real time.
8. THE Sales Return Screen SHALL provide a Discount on Return numeric input that reduces the net credit amount; the net credit SHALL NOT go below zero.
9. WHEN the user submits the dialog with at least one item having a return quantity greater than zero, THE SalesReturnProvider SHALL POST to `/sale-returns` with `saleInvoiceId`, `customerId`, `returnDate`, `items` array, `discount`, `totalAmount`, and `sourceType` ("sale" or "booking").
10. WHEN the user taps Edit on a return entry, THE Sales Return Screen SHALL open the dialog pre-populated with the invoice selected and return quantities from the existing record.
11. WHEN the user submits an edit, THE SalesReturnProvider SHALL PUT to `/sale-returns/:id` with the updated payload.
12. WHEN the user taps Delete and confirms, THE SalesReturnProvider SHALL DELETE `/sale-returns/:id` and remove the entry from the list.
13. IF a submission or deletion fails, THE Sales Return Screen SHALL display a SnackBar with the error message.
14. THE Sales Return Screen SHALL accept a `VoidCallback? onMenuPressed` parameter and use `CustomAppBar` with title "Sales Return".
15. THE Sales Return Screen SHALL use `Theme.of(context)` colors throughout, supporting both light and dark themes.

---

### Requirement 5: Sales Invoice Screen

**User Story:** As a cashier, I want to create and manage sale invoices with cart line items, customer lookup, financial summary, and settlement details, so that sales transactions are recorded accurately and customer balances are maintained.

#### Acceptance Criteria

1. WHEN the Sales Invoice screen is displayed, THE SalesInvoiceProvider SHALL fetch customers from `GET /customers`, categories from `GET /categories`, item details from `GET /item-details`, and sale invoices from `GET /sale-invoices`, displaying invoices in a list showing: Receipt No, Customer Name, Mobile, Sub-total (PKR), Payable (PKR), status chip (Paid/Partial/Unpaid), and Edit/Delete action buttons.
2. WHEN the list is loading, THE Sales Invoice Screen SHALL display a loading indicator.
3. IF no invoices exist, THE Sales Invoice Screen SHALL display an empty state message.
4. WHEN the user taps "New Invoice", THE Sales Invoice Screen SHALL open a dialog containing: a mobile/search field with customer autocomplete dropdown (triggered when input length >= 4 characters), a Customer Name text field, a read-only auto-generated Receipt Number (format `RCP-YYYYMMDD-HHMMSS-XXX`), and a Description/Note text field.
5. THE Sales Invoice Screen SHALL display a Cart Items section within the dialog containing one or more cart rows; each row SHALL have: a Category dropdown, an Item dropdown (filtered by selected category, disabled until category is chosen), a Price numeric input (auto-populated from item's `sale_price` when item is selected), a Quantity integer input (min 1), and a read-only Total (price × quantity).
6. WHEN the user selects an item in a cart row, THE Sales Invoice Screen SHALL automatically populate the Price field from the item's `sale_price` and recalculate the row total.
7. WHEN any cart row price or quantity changes, THE Sales Invoice Screen SHALL recalculate and display Gross Total (sum of all row totals), a Discount Amount input, and TOTAL PAYABLE (Gross Total minus Discount) in a Financial Summary section in real time.
8. THE Sales Invoice Screen SHALL display a Settlement Details section with a Payment Received numeric input and a computed Remaining Balance (TOTAL PAYABLE minus Payment Received, min 0).
9. THE Sales Invoice Screen SHALL allow adding new cart rows via an "Add Line" button and removing rows via a per-row delete button; at least one row SHALL remain at all times.
10. WHEN the user submits the dialog with at least one valid cart row (item selected, quantity > 0), THE SalesInvoiceProvider SHALL POST to `/sale-invoices` with `customerId`, `customerName`, `mobileNumber`, `receiptNo`, `description`, `discount`, `givenAmount`, `subTotal`, `payable`, `toBePaid`, `returnAmount`, `returnDescription`, and `items` array containing `itemId`, `quantity`, `price`, and `total` per row.
11. WHEN the user taps Edit on an invoice, THE Sales Invoice Screen SHALL open the dialog pre-populated with all fields and existing cart rows from the invoice record; the Receipt Number SHALL remain read-only.
12. WHEN the user submits an edit, THE SalesInvoiceProvider SHALL PUT to `/sale-invoices/:id` with the updated payload (excluding `receiptNo`).
13. WHEN the user taps Delete and confirms, THE SalesInvoiceProvider SHALL DELETE `/sale-invoices/:id` and remove the invoice from the list.
14. IF a submission or deletion fails, THE Sales Invoice Screen SHALL display a SnackBar with the error message.
15. THE Sales Invoice Screen SHALL accept a `VoidCallback? onMenuPressed` parameter and use `CustomAppBar` with title "Sales Receipt".
16. THE Sales Invoice Screen SHALL use `Theme.of(context)` colors throughout, supporting both light and dark themes.

---

### Requirement 6: Provider Registration and Missing Files

**User Story:** As a developer, I want all required providers registered in the app's dependency tree and all missing model/provider files created, so that every screen can access its state management without runtime errors.

#### Acceptance Criteria

1. THE Main App SHALL register `GoodsReceiptProvider`, `PurchaseReturnProvider`, `CustomerProvider`, `SalesReturnProvider`, and `SalesInvoiceProvider` in the `MultiProvider` in `main.dart`, each constructed with the shared `SharedPreferences` instance.
2. THE Project SHALL contain a `lib/models/sale_invoice_model.dart` file defining `SaleInvoiceModel` (with fields: id, receiptNo, customerName, customerId, mobileNumber, description, discount, givenAmount, subTotal, payable, toBePaid, status, items), `SaleItemModel` (with fields: itemId, itemName, categoryId, salePrice, qty, total), and `CartRowModel` (transient UI model with fields: id, categoryId, itemId, price, quantity, total).
3. THE Project SHALL contain a `lib/providers/sales_invoice_provider.dart` file implementing `SalesInvoiceProvider` as a `ChangeNotifier` with `_loading`, `_submitting`, and `_error` state fields; methods `fetchInitialData()` (customers, categories, items in parallel), `fetchInvoices()`, `saveInvoice(...)`, and `deleteInvoice(int id)`; and list getters for customers, categories, items, and invoices.
4. WHEN `SalesInvoiceProvider.fetchInitialData()` is called, THE SalesInvoiceProvider SHALL fetch `/customers`, `/categories`, and `/item-details` concurrently using parallel `Future` calls.
5. WHEN any provider method encounters a non-2xx HTTP response, THE Provider SHALL set `_error` to the server message or a descriptive fallback string and call `notifyListeners()`.
6. THE Sale Invoice Model's `fromJson` factory SHALL handle both List and Map response shapes for items, and SHALL use helper lambdas for null-safe `toDouble` and `toInt` conversions, consistent with the existing model pattern in the project.

---

### Requirement 7: Theming Consistency

**User Story:** As a user, I want every screen to respect the current dark or light theme so that the app has a visually consistent appearance regardless of theme setting.

#### Acceptance Criteria

1. THE Screen SHALL use `Theme.of(context).scaffoldBackgroundColor` for page backgrounds.
2. THE Screen SHALL use `Theme.of(context).cardColor` for card and dialog backgrounds.
3. THE Screen SHALL use `Theme.of(context).dividerColor` for border/divider colors.
4. THE Screen SHALL use `Theme.of(context).textTheme.bodyLarge` and `bodyMedium` styles for primary and secondary text.
5. THE Screen SHALL use `AppConstants.primaryTeal` as the accent color for action buttons, active states, value highlights, and section header accents.
6. WHEN the theme changes at runtime, THE Screen SHALL rebuild and apply the new theme colors without requiring a restart.

---

### Requirement 8: Error and Loading State Handling

**User Story:** As a user, I want clear feedback when data is loading or when an operation fails, so that I understand the app's state and can take corrective action.

#### Acceptance Criteria

1. WHEN a provider is in loading state, THE Screen SHALL display a `CircularProgressIndicator` with color `AppConstants.primaryTeal` centered in the list area.
2. WHEN a provider is in submitting state, THE Screen's submit button SHALL show a loading text label (e.g., "Saving...") and SHALL be disabled to prevent duplicate submissions.
3. WHEN a successful save or delete completes, THE Screen SHALL display a `SnackBar` with a success message using `ScaffoldMessenger.of(context).showSnackBar`.
4. WHEN an error occurs, THE Screen SHALL display a `SnackBar` with the error message using `ScaffoldMessenger.of(context).showSnackBar`.
5. IF a delete action is triggered, THE Screen SHALL display an `AlertDialog` confirmation prompt before calling the provider's delete method.

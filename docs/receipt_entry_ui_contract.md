# Receipt Entry UI Contract

This is the source of truth for the receipt-entry screens. Use ordinary user
language in the app. Do not introduce duplicate controls, developer wording,
or unlabeled actions.

## Receipt classification

1. A new receipt starts with **Please classify this receipt** and the
   Business, Personal, and Split selector at the top.
2. Directly below it is **Category (optional)** with one category dropdown.
   The user can leave the dropdown empty.
3. Below the dropdown are selectable options for **Mixed items** and **Not
   sure yet**. They are selection controls, not immediate navigation buttons;
   the user confirms the whole page with Continue.
4. The user chooses **Business**, **Personal**, or **Split** once.
5. Business and Personal are receipt-wide choices and are not repeated on the
   main receipt form or on its item forms.
6. Split makes classification available for each item. Choosing Split for an
   item opens the dedicated split allocation page.

## Add Receipt form

Order:

1. Vehicle and Work Profile context cards.
2. Equal-size Date and Time cards.
3. Receipt total.
4. Store information.
5. Optional action rows for Add Items and Add Receipt Photo.
6. Preview Receipt and Continue to Receipt Preview.

The receipt-wide classification is not repeated as a card, banner, snackbar,
or secondary prompt on this page.
Category is selected per item, not as a duplicate receipt-wide control.

## Add Item form

The form is a compact dark form with a small header: back, centered **Add
Item**, and a save/check control. Its order is:

1. Category picker at the top. The picker opens a drawer with pinned Cancel
   and Next controls.
2. For a Split receipt only: compact Business / Personal / Split controls.
   A Split item opens the focused allocation screen.
3. Item description.
4. Price per unit and Unit of measure on one readable row.
5. Quantity stepper with minus and plus buttons beside the calculated line
   total.
6. Optional printed line total, used only when a receipt prints a total but
   does not provide usable quantity and unit price.
7. Pinned Cancel and Save Item buttons clear of the system navigation area.

Category must not appear as a receipt-wide duplicate in the item form.
Do not show a duplicate line-total summary above the category picker. Inputs
must be dark, high contrast, and keep typed text visible. Unit choices include
each, piece, ounce, pound, quart, gallon, case, box, bag, pack, foot, inch,
service, and kWh.

## Receipt preview and save

The preview is a normal receipt document: store/address, receipt date/time,
classification, readable line items, tax, receipt total, and attached image
information. The preview offers Cancel, Edit Receipt, and Save Receipt.

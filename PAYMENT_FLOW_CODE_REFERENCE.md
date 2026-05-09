# Payment Flow Code Reference (Documentation Only)

This file is documentation only. It is not Dart source code and should not be placed under lib/.

---

## Plot Model: Tax-Aware Pricing

- Optional fields: `filerPrice`, `nonFilerPrice`
- Fallback: if tax-specific price is missing, use base `price`
- Supports Firestore keys `filerPrice`/`filer_price` and `nonFilerPrice`/`non_filer_price`

---

## Helper: Price Selection

Logic:
1) If filer and `filerPrice` exists -> use `filerPrice`
2) If non-filer and `nonFilerPrice` exists -> use `nonFilerPrice`
3) Otherwise -> use base `price`

---

## Payment Calculation (Full vs Installments)

- Installment years: 1 / 2 / 3
- Down payment:
  - 1 year = 60%
  - 2 years = 40%
  - 3 years = 20%
- Monthly installment:
  - `(total - downPayment) / (years * 12)`

---

## UI Flow Summary

1) Tax status selection (Filer / Non-Filer)
2) Payment type (Full / Installments)
3) Tenure (1 / 2 / 3 years) if installment
4) Summary card showing:
   - Selected price
   - Customer type
   - Plan
   - Pay now amount
   - Remaining + monthly installment (if installment)

---

## Notes

Keep all code examples inside the real Dart files under lib/. This file is just a readable reference.

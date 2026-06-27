# Odometer And Expense Edge Cases Backlog

This is parked while receipt camera capture is the active priority.

## Product Rules
- Any place in the app that accepts an odometer reading must update through the shared app-wide odometer controller.
- The app must not blindly accept odometer input. Fat-finger readings need to be caught before they poison mileage, MPG, recaps, or vehicle history.
- A receipt belongs on the purchase date/time, even when the user records it later.
- A backdated receipt odometer reading that is lower than the current vehicle odometer should be saved as historical mileage tied to that receipt, not used to roll the current odometer backward.
- A higher odometer reading can update the current app-wide odometer only after it passes the shared validation path.
- If a reading is unusually high, unusually low for the timeline, lower than current, or outside normal patterns, the app needs review/confirmation/correction flow before saving.

## Smart-Without-AI Behavior
- Track average daily miles per vehicle.
- Track typical mileage by weekday where there is enough history.
- Compare new readings against recent vehicle patterns.
- Support users who do not enable GPS trip tracking.
- Keep source metadata for odometer events, including module, receipt ID, work profile, and whether the reading changed the current odometer.

## Expense-Specific Rules
- Every expense receipt should be able to store receipt-level odometer mileage.
- Fuel line odometer details remain useful, but fuel lines should not be the only place mileage can be recorded.
- Backdated fuel receipts must not corrupt current MPG or current odometer state.
- Recaps must distinguish current odometer updates from historical receipt readings.

## Implementation Notes
- Use `GlobalOdometerController.updateFromText()` as the one shared write path.
- Store receipt-level `odometerReading` on `ExpenseReceiptRecord`.
- Include receipt-level odometer in local ledger, Firestore mirror documents, and exports.
- Keep historical/backdated readings in odometer history with `affectsCurrentReading: false`.
- Add tests for current-day updates, backdated lower readings, suspicious high readings, and receipt export/cloud document shape.

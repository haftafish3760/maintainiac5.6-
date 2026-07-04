# Maintaniac Edge Case Checklist

Every non-trivial feature must be designed against this checklist before it is called done.

## Device And Platform Support

- Does it work on older Android phones such as Galaxy S9 Plus class devices?
- Does it work on older iPhones from roughly the 2017 era when the Flutter/iOS toolchain allows it?
- Does it avoid raising Android `minSdk` or iOS deployment target without explicit approval?
- Does it avoid assuming flagship cameras, high RAM, fast CPUs, or large screens?
- Does it behave on small screens, large phones, tablets, desktop windows, and high text scaling?
- Does it avoid relying on one manufacturer behavior such as Samsung-only camera features?
- If a plugin excludes older devices, is there a fallback or has the tradeoff been approved?

## Storage And Offline Use

- Can the flow work fully offline when the user chooses manual/local mode?
- Is Hive or the approved local store the source of truth instead of temporary UI state?
- Is demo/seed data explicitly opt-in so it cannot become a real user's records?
- What happens when storage is low or the device has only 32 GB total capacity?
- Does the feature avoid storing unnecessarily large originals by default?
- Does it preserve enough proof for audit needs according to storage settings?
- Are drafts, receipt images, PDFs, exports, and attachments recoverable after app restart?
- Are duplicate files, failed saves, corrupt images, and missing files handled clearly?
- If the user uninstalls Maintaniac, have they been given a clear way to keep/export/move their records and receipt proof first?
- Does final saved receipt storage avoid holding user data hostage inside an app-only location?
- Are camera/crop/optimization temp files clearly treated as temporary working files, not final saved proof?
- Has the user accepted the storage mode before the app treats a receipt record and its proof files as durable?
- Are local-only users supported without Firebase, hosted backup, or mandatory cloud sync?
- Can the user choose or export to storage they control where the operating system allows it, such as local files, SD/external storage, a flash drive, Google Drive, iCloud, or another document provider?
- Does the flow support a guided year-end export path with date range, record types, receipt/proof inclusion, destination choice, storage estimate, and completion verification?

## Interruption And Lifecycle

- What happens if the user gets a phone call mid-flow?
- What happens if the user locks the screen, switches apps, receives a notification, or the OS pauses the app?
- What happens if the camera is interrupted or another app takes camera ownership?
- What happens if the OS kills the app while a receipt, expense, invoice, trip, inventory item, or maintenance record is in progress?
- Is progress draft-saved, or does the app ask whether to save, keep editing, or leave?
- Are long operations protected against double taps and repeated submissions?

## Navigation And Back Behavior

- Does every secondary screen show a visible back control?
- Does Android/iOS system back match the visible back behavior?
- Does back move one step backward inside multi-step flows instead of dumping the user on a home screen?
- Does accidental back ask to save progress when work would be lost?
- Do main bottom navigation buttons still return to section homes as expected?
- Can users recover from a wrong tap without restarting the whole workflow?

## Permissions And Providers

- Are permissions requested only after the user takes the related action?
- What happens if camera, photo library, files, location, notifications, or storage permission is denied?
- What happens if Google Drive, iCloud, OneDrive, Gmail, Yahoo, SMS/MMS, or another provider is missing, signed out, offline, or returns an unavailable file?
- Can the user continue manually when a provider, scanner, OCR, barcode reader, or GPS feature fails?

## Security And Privacy

- Is sensitive data local-first by default?
- Are receipts, mileage, locations, invoices, payments, customer information, and business records kept out of logs?
- Does any sync/upload/share/export action require explicit user intent?
- Is the user told what data leaves the phone and why?
- Are audit records preserved without exposing unnecessary personal data?
- Are filenames, exports, and attachments safe and understandable?

## Accuracy And Audit Readiness

- Are money, mileage, dates, taxes, quantities, totals, and inventory counts calculated from source records?
- Are derived summaries recalculated after back-dated edits?
- Are rounding rules consistent and visible where needed?
- Does the app warn when receipt line totals do not match the receipt total?
- Does OCR or parsing require user confirmation for important fields?
- Are manual corrections preserved with enough history to explain what changed?
- Can the user export records, receipts, and supporting proof for tax/audit work?
- Are CSV/export packages generated from source records and audit events rather than visible screen summaries?

## Receipt And Camera Flows

- Can the user take multiple photos for one receipt?
- Can the user retake, remove, reorder or review receipt images before saving when needed?
- Can the user crop with independent edges and preview fullscreen?
- Can the user choose storage/data-saver behavior and understand the quality tradeoff?
- What happens if the camera is blurry, dark, overexposed, glared, or cannot focus?
- Is there a manual fallback when OCR, edge detection, document scanning, torch, continuous focus/readability guidance, or PDF parsing is unavailable?
- Can PDF receipts and files from email/messages/file providers be attached later without forcing the user to move files manually?

## Inventory, Expenses, Invoices, And Jobs

- Does inventory know where stock belongs: company, active vehicle, named vehicle, job staging, or custom location?
- Can a user log a supply expense without using inventory?
- Can a user add inventory without a receipt?
- Can a user add receipt lines for items not in the catalog?
- Can invoice, job, expense, inventory, and vehicle links be traced without making the wrong module own the workflow?
- Are active/completed states clear where applicable?
- Are reports and exports updated when any linked record changes?

## Error And Recovery UX

- Does every failure have a useful message and a next action?
- Does the app avoid silent failure?
- Does it avoid blaming the user for app/provider/plugin problems?
- Is destructive action clearly labeled and confirmed when needed?
- Are disabled buttons explained by state, context, or nearby feedback?

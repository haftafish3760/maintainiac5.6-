# Maintenance Receipt Parsing Backlog

Status: note only. Do not start this lane until receipt camera capture is finished.

When the maintenance app work resumes, maintenance receipts should help the user
set up or update vehicle maintenance without requiring AI. If a receipt contains
enough information, Maintaniac should parse service type, vehicle context,
merchant, date, mileage where present, parts/labor hints, and maintenance cycle
reset candidates. The first dependency is the shared receipt camera/capture
system being reliable enough to take clear receipt photos, handle long receipts,
and hand readable images/text into parsing.


# Inventory Parser QA Harness Contract Completion Checklist

Scope: inventory parser/catalog QA harness structure and contract coverage only.

This checklist does not claim that executable parser behavior, golden receipt fixture volume, regression case volume, security fuzz depth, OCR, camera, UI, Expenses, Firebase live writes, or catalog item completeness are done.

## Completion Definition

The harness/contract layer is complete only when all checks below are true:

- every inventory parser QA suite file declares a stable suite ID
- every suite ID is unique
- every suite class is instantiated in `work_supply_parser_qa.dart`
- every suite ID appears in the master coverage matrix
- every suite ID appears in progress memory with a focused rerun command
- every focused rerun uses `PARSER_QA_SUITES=<suite>,qa.threshold_gate`
- the harness supports suite filtering so failed suites can be rerun surgically
- contract docs identify what is excluded from this layer and what comes next
- the master matrix separates `validated-local` from `release-ready`
- no harness contract requires live Firebase or Firestore writes
- the harness can report checked count, failures, severity, suite timing, and artifacts
- registry, matrix, and progress docs can be audited without running the full test suite

## Explicitly Not Completed By This Layer

These remain separate follow-up goals:

- executable parser behavior test depth
- golden receipt fixture volume
- regression lock fixture volume
- security/privacy/fuzz depth
- mutation execution depth
- property/metamorphic generated case volume
- full release-one residential item proof
- device/emulator validation
- live admin/Command One integration
- Firebase/Firestore cloud integration
- OCR/camera/PDF behavior

## Required Audit Commands

Run these only after harness/contract files change.

Registry-to-doc audit:

```powershell
$root='C:\Users\rjenk\Documents\Mainteniac 5.6'
Set-Location $root
$qaDir='test\support\work_supply_parser_qa'
$matrix='docs\inventory_parser_qa_master_coverage_matrix.md'
$progress='docs\inventory_parser_qa_progress_memory.md'
$mx=Get-Content -Raw $matrix
$pr=Get-Content -Raw $progress
$suiteIds=@()
foreach($file in Get-ChildItem $qaDir -Filter '*_qa.dart' -File){
  $text=Get-Content -Raw $file.FullName
  foreach($m in [regex]::Matches($text,"super\('([^']+)'\)")){
    $suiteIds += $m.Groups[1].Value
  }
}
$suiteIds=$suiteIds | Sort-Object -Unique
$missingMatrix=@()
$missingProgress=@()
foreach($id in $suiteIds){
  if($mx -notlike "*$id*"){ $missingMatrix += $id }
  if($pr -notlike "*$id*"){ $missingProgress += $id }
}
"suiteIds=$($suiteIds.Count) missingMatrix=$($missingMatrix.Count) missingProgress=$($missingProgress.Count)"
```

Registry instantiation audit:

```powershell
$root='C:\Users\rjenk\Documents\Mainteniac 5.6'
Set-Location $root
$qaDir='test\support\work_supply_parser_qa'
$registry='test\support\work_supply_parser_qa\work_supply_parser_qa.dart'
$reg=Get-Content -Raw $registry
$classNames=@()
foreach($file in Get-ChildItem $qaDir -Filter '*_qa.dart' -File){
  $text=Get-Content -Raw $file.FullName
  foreach($m in [regex]::Matches($text,'class\s+([A-Za-z0-9_]+)\s+extends\s+QaSuite')){
    $classNames += $m.Groups[1].Value
  }
}
$classNames=$classNames | Sort-Object -Unique
$missing=@()
foreach($class in $classNames){
  if($reg -notlike "*$class()*" -and $reg -notlike "*$class(),*"){
    $missing += $class
  }
}
"qaSuiteClasses=$($classNames.Count) missingInstantiations=$($missing.Count)"
```

Suite ID uniqueness audit:

```powershell
$root='C:\Users\rjenk\Documents\Mainteniac 5.6'
Set-Location $root
$qaDir='test\support\work_supply_parser_qa'
$ids=@()
foreach($file in Get-ChildItem $qaDir -Filter '*_qa.dart' -File){
  $text=Get-Content -Raw $file.FullName
  foreach($m in [regex]::Matches($text,"super\('([^']+)'\)")){
    $ids += [pscustomobject]@{Id=$m.Groups[1].Value; File=$file.Name}
  }
}
$dups=$ids | Group-Object Id | Where-Object Count -gt 1
"suiteIdRecords=$($ids.Count) uniqueSuiteIds=$(($ids.Id | Sort-Object -Unique).Count) duplicateIds=$($dups.Count)"
```

## Completion Evidence

Record evidence here after each audit:

- registry-to-doc audit: `suiteIds=142 missingMatrix=0 missingProgress=0`
- registry instantiation audit: `qaSuiteClasses=142 missingInstantiations=0`
- suite ID uniqueness audit: `suiteIdRecords=142 uniqueSuiteIds=142 duplicateIds=0`
- master coverage matrix gate: `inventory.master_coverage_matrix_contract,qa.threshold_gate` passed with `checked=102 failures=0 actualFailures=0`

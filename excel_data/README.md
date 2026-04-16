# 📂 Excel Data Folder

Place your 7 NGO Excel files here **exactly as received** from the NGO.

The import script (`supabase/import_excel_data.js`) will automatically detect them by filename.

## Expected Files

| Filename (must contain) | Zone | Centre in Supabase |
|---|---|---|
| `Udan Secondary Abhyasika_2025` | Udan | Udan Secondary Abhyasika |
| `Mirabai Primary Abhyasika_2025` | Mirabai | Mirabai Primary Abhyasika |
| `VESIT student data` | VESIT | VESIT Centre |
| `Tejaswini Primary Abhyasika_2025` | Tejaswini | Tejaswini Primary Abhyasika |
| `Raigad Primary Abhyasika_2025` | Raigad | Raigad Primary Abhyasika |
| `Shivneri Abhyasika_2025` | Shivneri | Shivneri Abhyasika |
| `Utkarsh Combine Abhyasika_2025` | Utkarsh | Utkarsh Combine Abhyasika |

> **Note:** The file doesn't need to be named exactly — the script does a **substring match** on the filename.
> e.g. `Udan Secondary Abhyasika_2025.xlsx` ✅ or `Udan Secondary Abhyasika_2025 (Final).xlsx` ✅

## Supported Formats
- `.xlsx` (recommended)
- `.xls`
- `.xlsm`

## After Placing Files
Follow the steps in `supabase/import_excel_data.js` comments, or see the full guide in the implementation plan.

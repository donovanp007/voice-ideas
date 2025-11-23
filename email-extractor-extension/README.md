# School Email Extractor - Chrome Extension v2.0

A powerful Chrome extension to automatically extract staff email addresses, names, and job titles from school websites with Google Sheets integration.

## Features

### Core Extraction
- **Smart extraction** - Extracts Name, Email, and Job Title together
- **Deep scan mode** - Finds hidden emails in staff cards, data attributes, scripts
- **Auto-detection** - Automatically detects school staff pages
- **Multiple sources** - Scans mailto links, tables, staff cards, hidden content

### Google Sheets Integration
- **Direct export** - Send data straight to your Google Sheet
- **Auto-append** - Each scrape adds rows with timestamp
- **Columns**: Name | Email | Job Title | Date | Time | Source URL

### Bulk Scanning
- **Multi-page scanning** - Paste multiple URLs and scan all at once
- **Background processing** - Pages open and close automatically
- **Progress tracking** - Visual progress bar during bulk scans

### History & Export
- **Extraction history** - All extractions saved with timestamps
- **View past extractions** - Re-access any previous scrape
- **Export to CSV** - Download data as spreadsheet
- **Copy all emails** - Quick clipboard copy

## Installation

1. Open Chrome and go to `chrome://extensions/`
2. Enable **Developer mode** (toggle in top right)
3. Click **Load unpacked**
4. Select the `email-extractor-extension` folder
5. Click the extension icon in your toolbar

## Google Sheets Setup

1. **Create a Google Sheet** or use an existing one
2. **Get the Sheet ID** from the URL:
   ```
   https://docs.google.com/spreadsheets/d/[THIS_IS_YOUR_SHEET_ID]/edit
   ```
3. **Share your sheet** - Set to "Anyone with the link can edit"
4. **Get an API Key**:
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Create a new project
   - Enable the Google Sheets API
   - Create an API Key under Credentials
5. **Configure the extension**:
   - Click the ⚙️ settings icon
   - Enter your Sheet ID and API Key
   - Test the connection

## Usage

### Single Page Extraction
1. Navigate to a school staff page
2. Click the extension icon
3. Click **Extract** or **Deep Scan**
4. View results with Name, Email, Job Title
5. Click 📊 to send to Google Sheets

### Bulk Scanning
1. Click the **Bulk Scan** tab
2. Paste URLs (one per line):
   ```
   https://school1.edu/staff
   https://school2.edu/faculty
   https://school3.edu/team
   ```
3. Click **Start Bulk Scan**
4. Watch progress as pages are scanned
5. Export all results to Sheets

### Keyboard Shortcuts
- `Alt+E` - Quick extract
- `Alt+D` - Deep scan

## Data Format

When exported to Google Sheets, data appears as:

| Name | Email | Job Title | Date | Time | Source URL |
|------|-------|-----------|------|------|------------|
| John Smith | jsmith@school.edu | Principal | 2024-01-15 | 14:30:00 | https://... |
| Jane Doe | jdoe@school.edu | Math Teacher | 2024-01-15 | 14:30:00 | https://... |

## How It Works

The extension uses multiple detection methods:

1. **Staff card detection** - Identifies common card layouts
2. **mailto: links** - Standard email links
3. **Table parsing** - Directory-style tables
4. **Data attributes** - Hidden data-email attributes
5. **Text analysis** - Pattern matching for obfuscated emails
6. **Job title patterns** - Recognizes common education titles

## Privacy

- All processing happens locally in your browser
- Data only goes to YOUR Google Sheet
- No data sent to any third-party servers
- History stored locally, clearable anytime

## Files

```
email-extractor-extension/
├── manifest.json      # Extension config
├── popup.html         # Main UI
├── popup.css          # Styles
├── popup.js           # UI logic
├── content.js         # Page extraction
├── background.js      # Service worker
├── settings.html      # Settings page
├── settings.js        # Settings logic
├── sheets.js          # Google Sheets API
├── icons/             # Extension icons
└── README.md          # This file
```

## Troubleshooting

**"Could not scan this page"**
- Some pages block content scripts
- Try refreshing the page first

**"Permission denied" on Sheets**
- Make sure your sheet is shared with "Anyone with link can edit"
- Verify your API key is correct

**No emails found**
- Try "Deep Scan" for hidden emails
- Check if the page uses JavaScript to load content

## License

MIT License

# School Email Extractor - Chrome Extension

A fast, automated Chrome extension to extract staff email addresses from school websites.

## Features

- **One-click extraction** - Extract all emails from any page instantly
- **Deep scan mode** - Thoroughly scans staff cards, hidden elements, and data attributes
- **Smart detection** - Finds emails in:
  - `mailto:` links
  - Data attributes (`data-email`, etc.)
  - Hidden text and title attributes
  - Inline scripts
  - Obfuscated formats (`name [at] school [dot] edu`)
- **Domain filtering** - Filter emails by domain
- **Export options** - Copy all or export to CSV
- **Keyboard shortcut** - `Alt+E` for quick extraction

## Installation

1. Open Chrome and go to `chrome://extensions/`
2. Enable **Developer mode** (toggle in top right)
3. Click **Load unpacked**
4. Select the `email-extractor-extension` folder
5. The extension icon will appear in your toolbar

## Usage

### Basic Extraction
1. Navigate to a school staff page
2. Click the extension icon
3. Click **Extract Emails**
4. View, filter, copy, or export results

### Deep Scan
Use **Deep Scan** for pages where emails are hidden in:
- Staff photo cards
- JavaScript data
- Encoded attributes

### Keyboard Shortcuts
- `Alt+E` - Quick extract from current page
- Right-click page → "Extract Emails from Page"

## How It Works

The extension scans the current page for email addresses using multiple methods:

1. **mailto: links** - Standard email links
2. **Data attributes** - Custom data-* attributes containing emails
3. **Text content** - Visible text on the page
4. **Event handlers** - onclick/onmouseover attributes
5. **Hidden content** - title, alt, aria-label attributes
6. **Staff cards** - Common school website patterns
7. **Scripts** - Inline JavaScript with email data

## Privacy

- All processing happens locally in your browser
- No data is sent to external servers
- Emails are stored temporarily per tab session

## Icon Setup

For the extension to display properly, create PNG icons from the SVG:
- icons/icon16.png (16x16)
- icons/icon32.png (32x32)
- icons/icon48.png (48x48)
- icons/icon128.png (128x128)

Or use an online SVG to PNG converter with `icons/icon.svg`.

## License

MIT License

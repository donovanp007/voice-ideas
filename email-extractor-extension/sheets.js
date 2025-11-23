// Google Sheets Integration Module

const SheetsAPI = {
  /**
   * Get settings from storage
   */
  async getSettings() {
    return new Promise(resolve => {
      chrome.storage.sync.get(['sheetId', 'sheetName', 'apiKey', 'includeTimestamp', 'includeUrl'], resolve);
    });
  },

  /**
   * Append data to Google Sheet
   * @param {Array} data - Array of {name, email, jobTitle} objects
   * @param {string} sourceUrl - URL where data was extracted from
   * @returns {Promise<{success: boolean, message: string, rowsAdded: number}>}
   */
  async appendToSheet(data, sourceUrl = '') {
    const settings = await this.getSettings();
    const { sheetId, sheetName, apiKey, includeTimestamp, includeUrl } = settings;

    if (!sheetId || !apiKey) {
      return { success: false, message: 'Google Sheets not configured. Go to Settings.' };
    }

    if (!data || data.length === 0) {
      return { success: false, message: 'No data to export' };
    }

    const timestamp = new Date().toISOString();
    const dateOnly = timestamp.split('T')[0];
    const timeOnly = timestamp.split('T')[1].split('.')[0];

    // Prepare rows
    const rows = data.map(item => {
      const row = [item.name || '', item.email || '', item.jobTitle || ''];

      if (includeTimestamp !== false) {
        row.push(dateOnly);
        row.push(timeOnly);
      }

      if (includeUrl !== false) {
        row.push(sourceUrl);
      }

      return row;
    });

    // Add header row if sheet is empty (first export)
    const headerRow = ['Name', 'Email', 'Job Title'];
    if (includeTimestamp !== false) {
      headerRow.push('Date', 'Time');
    }
    if (includeUrl !== false) {
      headerRow.push('Source URL');
    }

    try {
      // Check if sheet has data
      const checkResponse = await fetch(
        `https://sheets.googleapis.com/v4/spreadsheets/${sheetId}/values/${encodeURIComponent(sheetName)}!A1?key=${apiKey}`
      );

      let needsHeader = true;
      if (checkResponse.ok) {
        const checkData = await checkResponse.json();
        if (checkData.values && checkData.values.length > 0) {
          needsHeader = false;
        }
      }

      // Prepare request body
      const values = needsHeader ? [headerRow, ...rows] : rows;

      // Append data
      const appendResponse = await fetch(
        `https://sheets.googleapis.com/v4/spreadsheets/${sheetId}/values/${encodeURIComponent(sheetName)}!A:F:append?valueInputOption=USER_ENTERED&insertDataOption=INSERT_ROWS&key=${apiKey}`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            values: values
          })
        }
      );

      if (appendResponse.ok) {
        const result = await appendResponse.json();
        return {
          success: true,
          message: `Added ${rows.length} rows to Google Sheet`,
          rowsAdded: rows.length
        };
      } else {
        const error = await appendResponse.json();

        // Check if it's a permission error
        if (error.error?.code === 403) {
          return {
            success: false,
            message: 'Permission denied. Make sure your Sheet is shared with "Anyone with link can edit" or use a Service Account.'
          };
        }

        return {
          success: false,
          message: error.error?.message || 'Failed to append data'
        };
      }
    } catch (error) {
      return { success: false, message: `Network error: ${error.message}` };
    }
  },

  /**
   * Create headers in sheet if not present
   */
  async ensureHeaders() {
    const settings = await this.getSettings();
    const { sheetId, sheetName, apiKey, includeTimestamp, includeUrl } = settings;

    if (!sheetId || !apiKey) return false;

    const headerRow = ['Name', 'Email', 'Job Title'];
    if (includeTimestamp !== false) {
      headerRow.push('Date', 'Time');
    }
    if (includeUrl !== false) {
      headerRow.push('Source URL');
    }

    try {
      // Check first row
      const response = await fetch(
        `https://sheets.googleapis.com/v4/spreadsheets/${sheetId}/values/${encodeURIComponent(sheetName)}!A1:F1?key=${apiKey}`
      );

      if (response.ok) {
        const data = await response.json();
        if (!data.values || data.values.length === 0) {
          // Add headers
          await fetch(
            `https://sheets.googleapis.com/v4/spreadsheets/${sheetId}/values/${encodeURIComponent(sheetName)}!A1:F1?valueInputOption=USER_ENTERED&key=${apiKey}`,
            {
              method: 'PUT',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ values: [headerRow] })
            }
          );
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  },

  /**
   * Test connection to Google Sheets
   */
  async testConnection() {
    const settings = await this.getSettings();
    const { sheetId, apiKey } = settings;

    if (!sheetId || !apiKey) {
      return { success: false, message: 'Missing Sheet ID or API Key' };
    }

    try {
      const response = await fetch(
        `https://sheets.googleapis.com/v4/spreadsheets/${sheetId}?key=${apiKey}`
      );

      if (response.ok) {
        const data = await response.json();
        return { success: true, message: `Connected to "${data.properties.title}"` };
      } else {
        const error = await response.json();
        return { success: false, message: error.error?.message || 'Connection failed' };
      }
    } catch (error) {
      return { success: false, message: error.message };
    }
  }
};

// Export for use in other scripts
if (typeof module !== 'undefined') {
  module.exports = SheetsAPI;
}

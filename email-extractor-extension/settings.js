// Settings page JavaScript

document.addEventListener('DOMContentLoaded', () => {
  // Elements
  const sheetId = document.getElementById('sheetId');
  const sheetName = document.getElementById('sheetName');
  const apiKey = document.getElementById('apiKey');
  const testConnection = document.getElementById('testConnection');
  const sheetsStatus = document.getElementById('sheetsStatus');
  const autoDetect = document.getElementById('autoDetect');
  const autoExtract = document.getElementById('autoExtract');
  const includeTimestamp = document.getElementById('includeTimestamp');
  const includeUrl = document.getElementById('includeUrl');
  const saveHistory = document.getElementById('saveHistory');
  const clearHistory = document.getElementById('clearHistory');
  const saveStatus = document.getElementById('saveStatus');

  // Load saved settings
  loadSettings();

  // Auto-save on change
  const inputs = [sheetId, sheetName, apiKey];
  inputs.forEach(input => {
    input.addEventListener('input', debounce(saveSettings, 500));
  });

  const toggles = [autoDetect, autoExtract, includeTimestamp, includeUrl, saveHistory];
  toggles.forEach(toggle => {
    toggle.addEventListener('change', saveSettings);
  });

  // Test Google Sheets connection
  testConnection.addEventListener('click', async () => {
    const id = sheetId.value.trim();
    const key = apiKey.value.trim();
    const name = sheetName.value.trim() || 'Sheet1';

    if (!id || !key) {
      showStatus(sheetsStatus, 'Please enter Sheet ID and API Key', 'disconnected');
      return;
    }

    testConnection.disabled = true;
    testConnection.textContent = 'Testing...';

    try {
      // Test by trying to read the sheet metadata
      const response = await fetch(
        `https://sheets.googleapis.com/v4/spreadsheets/${id}?key=${key}`
      );

      if (response.ok) {
        const data = await response.json();
        showStatus(
          sheetsStatus,
          `✓ Connected to "${data.properties.title}"`,
          'connected'
        );

        // Check if sheet name exists
        const sheetExists = data.sheets.some(s => s.properties.title === name);
        if (!sheetExists) {
          showStatus(
            sheetsStatus,
            `✓ Connected, but tab "${name}" not found. Available: ${data.sheets.map(s => s.properties.title).join(', ')}`,
            'connected'
          );
        }
      } else {
        const error = await response.json();
        showStatus(
          sheetsStatus,
          `✗ Error: ${error.error?.message || 'Connection failed'}`,
          'disconnected'
        );
      }
    } catch (error) {
      showStatus(sheetsStatus, `✗ Network error: ${error.message}`, 'disconnected');
    }

    testConnection.disabled = false;
    testConnection.textContent = 'Test Connection';
  });

  // Clear history
  clearHistory.addEventListener('click', () => {
    if (confirm('Are you sure you want to clear all extraction history?')) {
      chrome.storage.local.remove('extractionHistory', () => {
        showSaveStatus('History cleared!', 'success');
      });
    }
  });

  /**
   * Load settings from storage
   */
  function loadSettings() {
    chrome.storage.sync.get([
      'sheetId', 'sheetName', 'apiKey',
      'autoDetect', 'autoExtract',
      'includeTimestamp', 'includeUrl', 'saveHistory'
    ], (result) => {
      sheetId.value = result.sheetId || '';
      sheetName.value = result.sheetName || 'Sheet1';
      apiKey.value = result.apiKey || '';
      autoDetect.checked = result.autoDetect || false;
      autoExtract.checked = result.autoExtract || false;
      includeTimestamp.checked = result.includeTimestamp !== false;
      includeUrl.checked = result.includeUrl !== false;
      saveHistory.checked = result.saveHistory !== false;
    });
  }

  /**
   * Save settings to storage
   */
  function saveSettings() {
    const settings = {
      sheetId: sheetId.value.trim(),
      sheetName: sheetName.value.trim() || 'Sheet1',
      apiKey: apiKey.value.trim(),
      autoDetect: autoDetect.checked,
      autoExtract: autoExtract.checked,
      includeTimestamp: includeTimestamp.checked,
      includeUrl: includeUrl.checked,
      saveHistory: saveHistory.checked
    };

    chrome.storage.sync.set(settings, () => {
      showSaveStatus('Settings saved!', 'success');
    });
  }

  /**
   * Show status message
   */
  function showStatus(element, message, type) {
    element.innerHTML = `<span class="status-badge ${type}">${message}</span>`;
  }

  /**
   * Show save status
   */
  function showSaveStatus(message, type) {
    saveStatus.textContent = message;
    saveStatus.className = `status ${type}`;
    setTimeout(() => {
      saveStatus.textContent = '';
      saveStatus.className = 'status';
    }, 2000);
  }

  /**
   * Debounce function
   */
  function debounce(func, wait) {
    let timeout;
    return function(...args) {
      clearTimeout(timeout);
      timeout = setTimeout(() => func.apply(this, args), wait);
    };
  }
});

// Popup JavaScript - Full Featured UI

document.addEventListener('DOMContentLoaded', () => {
  // Elements - Extract Tab
  const extractBtn = document.getElementById('extractBtn');
  const deepScanBtn = document.getElementById('deepScanBtn');
  const copyAllBtn = document.getElementById('copyAllBtn');
  const exportCsvBtn = document.getElementById('exportCsvBtn');
  const exportSheetsBtn = document.getElementById('exportSheetsBtn');
  const clearBtn = document.getElementById('clearBtn');
  const emailCount = document.getElementById('emailCount');
  const withNameCount = document.getElementById('withNameCount');
  const resultsBody = document.getElementById('resultsBody');
  const resultsContainer = document.getElementById('resultsContainer');
  const filtersSection = document.getElementById('filtersSection');
  const domainFilters = document.getElementById('domainFilters');
  const detectionBanner = document.getElementById('detectionBanner');
  const status = document.getElementById('status');

  // Elements - Bulk Tab
  const bulkUrls = document.getElementById('bulkUrls');
  const startBulkScan = document.getElementById('startBulkScan');
  const bulkProgress = document.getElementById('bulkProgress');
  const progressFill = document.getElementById('progressFill');
  const progressText = document.getElementById('progressText');
  const bulkResults = document.getElementById('bulkResults');
  const bulkTotalEmails = document.getElementById('bulkTotalEmails');
  const bulkPagesScanned = document.getElementById('bulkPagesScanned');
  const exportBulkBtn = document.getElementById('exportBulkBtn');
  const exportBulkCsvBtn = document.getElementById('exportBulkCsvBtn');

  // Elements - History Tab
  const historyList = document.getElementById('historyList');
  const clearHistoryBtn = document.getElementById('clearHistoryBtn');

  // Elements - Tabs
  const tabs = document.querySelectorAll('.tab');
  const tabContents = document.querySelectorAll('.tab-content');

  // State
  let currentResults = []; // Array of {name, email, jobTitle}
  let filteredResults = [];
  let activeDomainFilter = null;
  let bulkScanResults = [];
  let currentUrl = '';

  // Initialize
  init();

  async function init() {
    // Get current tab URL
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    currentUrl = tab.url;

    // Load stored results
    loadStoredResults();

    // Check for staff page
    checkStaffPage();

    // Load history
    loadHistory();

    // Setup event listeners
    setupEventListeners();
  }

  function setupEventListeners() {
    // Tabs
    tabs.forEach(tab => {
      tab.addEventListener('click', () => switchTab(tab.dataset.tab));
    });

    // Extract buttons
    extractBtn.addEventListener('click', () => extractEmails(false));
    deepScanBtn.addEventListener('click', () => extractEmails(true));

    // Action buttons
    copyAllBtn.addEventListener('click', copyAllEmails);
    exportCsvBtn.addEventListener('click', exportToCsv);
    exportSheetsBtn.addEventListener('click', exportToSheets);
    clearBtn.addEventListener('click', clearResults);

    // Bulk scan
    startBulkScan.addEventListener('click', startBulkScanProcess);
    exportBulkBtn.addEventListener('click', exportBulkToSheets);
    if (exportBulkCsvBtn) exportBulkCsvBtn.addEventListener('click', exportBulkToCsv);

    // History
    clearHistoryBtn.addEventListener('click', clearHistory);

    // Keyboard shortcuts
    document.addEventListener('keydown', (e) => {
      if (e.altKey && e.key === 'e') extractEmails(false);
      if (e.altKey && e.key === 'd') extractEmails(true);
    });
  }

  // Tab switching
  function switchTab(tabName) {
    tabs.forEach(t => t.classList.remove('active'));
    tabContents.forEach(tc => tc.classList.remove('active'));

    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
    document.getElementById(`tab-${tabName}`).classList.add('active');
  }

  // Check if current page is a staff page
  async function checkStaffPage() {
    try {
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });

      await injectContentScript(tab.id);

      chrome.tabs.sendMessage(tab.id, { action: 'detectStaffPage' }, (response) => {
        if (response && response.isStaffPage) {
          detectionBanner.style.display = 'flex';
        }
      });
    } catch (e) {}
  }

  // Inject content script if needed
  async function injectContentScript(tabId) {
    try {
      await chrome.scripting.executeScript({
        target: { tabId: tabId },
        files: ['content.js']
      });
    } catch (e) {
      // Script may already be injected
    }
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  // Extract emails from current page
  async function extractEmails(deepScan) {
    showStatus(deepScan ? 'Deep scanning...' : 'Extracting...', 'loading');
    extractBtn.disabled = true;
    deepScanBtn.disabled = true;

    try {
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
      currentUrl = tab.url;

      await injectContentScript(tab.id);

      chrome.tabs.sendMessage(
        tab.id,
        { action: 'extractWithContext', deepScan: deepScan },
        (response) => {
          extractBtn.disabled = false;
          deepScanBtn.disabled = false;

          if (chrome.runtime.lastError) {
            showStatus('Could not scan this page', 'error');
            return;
          }

          if (response && response.results) {
            // Merge with existing results
            const newResults = response.results;
            const mergedMap = new Map();

            [...currentResults, ...newResults].forEach(r => {
              const existing = mergedMap.get(r.email);
              if (existing) {
                if (!existing.name && r.name) existing.name = r.name;
                if (!existing.jobTitle && r.jobTitle) existing.jobTitle = r.jobTitle;
              } else {
                mergedMap.set(r.email, { ...r });
              }
            });

            currentResults = Array.from(mergedMap.values());

            // Store results
            chrome.storage.local.set({ [`results_${tab.id}`]: currentResults });

            // Save to history
            saveToHistory(currentResults, currentUrl);

            updateUI();
            showStatus(`Found ${newResults.length} contacts!`, 'success');
          } else {
            showStatus('No contacts found', 'error');
          }
        }
      );
    } catch (error) {
      extractBtn.disabled = false;
      deepScanBtn.disabled = false;
      showStatus('Error: ' + error.message, 'error');
    }
  }

  // Load stored results
  async function loadStoredResults() {
    try {
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
      chrome.storage.local.get([`results_${tab.id}`], (result) => {
        const stored = result[`results_${tab.id}`];
        if (stored && stored.length > 0) {
          currentResults = stored;
          updateUI();
        }
      });
    } catch (e) {}
  }

  // Update UI
  function updateUI() {
    const displayResults = activeDomainFilter ? filteredResults : currentResults;

    // Update counts
    emailCount.textContent = displayResults.length;
    withNameCount.textContent = displayResults.filter(r => r.name).length;

    // Show/hide sections
    if (currentResults.length > 0) {
      resultsContainer.style.display = 'block';
      filtersSection.style.display = 'block';
    } else {
      resultsContainer.style.display = 'none';
      filtersSection.style.display = 'none';
    }

    // Render table
    renderResultsTable(displayResults);

    // Render filters
    renderDomainFilters();
  }

  // Render results table
  function renderResultsTable(results) {
    resultsBody.innerHTML = '';

    results.forEach(result => {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td title="${escapeHtml(result.name || '-')}">${escapeHtml(result.name || '-')}</td>
        <td title="${escapeHtml(result.email)}">${escapeHtml(result.email)}</td>
        <td title="${escapeHtml(result.jobTitle || '-')}">${escapeHtml(result.jobTitle || '-')}</td>
        <td><button class="copy-btn" data-email="${escapeHtml(result.email)}">📋</button></td>
      `;
      resultsBody.appendChild(tr);
    });

    // Add copy handlers
    resultsBody.querySelectorAll('.copy-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const email = e.target.dataset.email;
        navigator.clipboard.writeText(email).then(() => {
          e.target.textContent = '✓';
          setTimeout(() => e.target.textContent = '📋', 1000);
        });
      });
    });
  }

  // Render domain filters
  function renderDomainFilters() {
    const domainCounts = {};
    currentResults.forEach(r => {
      const domain = r.email.split('@')[1] || 'unknown';
      domainCounts[domain] = (domainCounts[domain] || 0) + 1;
    });

    domainFilters.innerHTML = '';

    // All chip
    const allChip = document.createElement('span');
    allChip.className = `filter-chip ${!activeDomainFilter ? 'active' : ''}`;
    allChip.innerHTML = `All <span class="count">${currentResults.length}</span>`;
    allChip.addEventListener('click', () => {
      activeDomainFilter = null;
      filteredResults = [];
      updateUI();
    });
    domainFilters.appendChild(allChip);

    // Domain chips
    Object.entries(domainCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .forEach(([domain, count]) => {
        const chip = document.createElement('span');
        chip.className = `filter-chip ${activeDomainFilter === domain ? 'active' : ''}`;
        chip.innerHTML = `${escapeHtml(domain)} <span class="count">${count}</span>`;
        chip.addEventListener('click', () => {
          activeDomainFilter = domain;
          filteredResults = currentResults.filter(r => r.email.split('@')[1] === domain);
          updateUI();
        });
        domainFilters.appendChild(chip);
      });
  }

  // Copy all emails
  function copyAllEmails() {
    const results = filteredResults.length > 0 ? filteredResults : currentResults;
    if (results.length === 0) {
      showStatus('No emails to copy', 'error');
      return;
    }

    const text = results.map(r => r.email).join('\n');
    navigator.clipboard.writeText(text).then(() => {
      showStatus(`Copied ${results.length} emails!`, 'success');
    });
  }

  // Export to CSV
  function exportToCsv() {
    const results = filteredResults.length > 0 ? filteredResults : currentResults;
    if (results.length === 0) {
      showStatus('No data to export', 'error');
      return;
    }

    const timestamp = new Date().toISOString().split('T')[0];
    const headers = ['Name', 'Email', 'Job Title', 'Source URL', 'Date'];
    const rows = results.map(r => [
      r.name || '',
      r.email,
      r.jobTitle || '',
      currentUrl,
      timestamp
    ]);

    const csv = [headers, ...rows].map(row =>
      row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(',')
    ).join('\n');

    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `emails_${timestamp}.csv`;
    a.click();
    URL.revokeObjectURL(url);

    showStatus(`Exported ${results.length} contacts!`, 'success');
  }

  // Export to Google Sheets (optional)
  async function exportToSheets() {
    const results = filteredResults.length > 0 ? filteredResults : currentResults;
    if (results.length === 0) {
      showStatus('No data to export', 'error');
      return;
    }

    // Check if Sheets is configured
    const settings = await new Promise(resolve => {
      chrome.storage.sync.get(['sheetId', 'apiKey'], resolve);
    });

    if (!settings.sheetId || !settings.apiKey) {
      showStatus('Sheets not configured. Click ⚙️ Settings to set up.', 'error');
      return;
    }

    showStatus('Sending to Google Sheets...', 'loading');

    try {
      const response = await SheetsAPI.appendToSheet(results, currentUrl);
      if (response.success) {
        showStatus(response.message, 'success');
      } else {
        showStatus(response.message, 'error');
      }
    } catch (error) {
      showStatus('Error: ' + error.message, 'error');
    }
  }

  // Clear results
  async function clearResults() {
    currentResults = [];
    filteredResults = [];
    activeDomainFilter = null;
    updateUI();

    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    chrome.storage.local.remove(`results_${tab.id}`);
    showStatus('Cleared!', 'success');
  }

  // Bulk scan process
  async function startBulkScanProcess() {
    const urlsText = bulkUrls.value.trim();
    if (!urlsText) {
      showStatus('Please enter URLs to scan', 'error');
      return;
    }

    const urls = urlsText.split('\n')
      .map(u => u.trim())
      .filter(u => u && (u.startsWith('http://') || u.startsWith('https://')));

    if (urls.length === 0) {
      showStatus('No valid URLs found', 'error');
      return;
    }

    bulkScanResults = [];
    startBulkScan.disabled = true;
    bulkProgress.style.display = 'block';
    bulkResults.style.display = 'none';

    let completed = 0;

    for (const url of urls) {
      progressText.textContent = `${completed} / ${urls.length}`;
      progressFill.style.width = `${(completed / urls.length) * 100}%`;

      try {
        // Open tab, scan, close
        const tab = await chrome.tabs.create({ url: url, active: false });

        // Wait for page load
        await new Promise(resolve => {
          const listener = (tabId, info) => {
            if (tabId === tab.id && info.status === 'complete') {
              chrome.tabs.onUpdated.removeListener(listener);
              resolve();
            }
          };
          chrome.tabs.onUpdated.addListener(listener);
        });

        // Small delay for scripts to load
        await new Promise(r => setTimeout(r, 1500));

        // Inject and extract
        await injectContentScript(tab.id);

        const results = await new Promise(resolve => {
          chrome.tabs.sendMessage(tab.id, { action: 'extractWithContext', deepScan: true }, (response) => {
            resolve(response?.results || []);
          });
        });

        // Add source URL to results
        results.forEach(r => r.sourceUrl = url);
        bulkScanResults.push(...results);

        // Close tab
        chrome.tabs.remove(tab.id);
      } catch (e) {
        console.error(`Error scanning ${url}:`, e);
      }

      completed++;
    }

    progressText.textContent = `${completed} / ${urls.length}`;
    progressFill.style.width = '100%';

    // Show results
    bulkTotalEmails.textContent = bulkScanResults.length;
    bulkPagesScanned.textContent = urls.length;
    bulkResults.style.display = 'block';
    startBulkScan.disabled = false;

    // Save to history
    if (bulkScanResults.length > 0) {
      saveToHistory(bulkScanResults, `Bulk scan: ${urls.length} pages`);
    }
  }

  // Export bulk results to CSV
  function exportBulkToCsv() {
    if (bulkScanResults.length === 0) {
      showStatus('No bulk results to export', 'error');
      return;
    }

    const timestamp = new Date().toISOString().split('T')[0];
    const headers = ['Name', 'Email', 'Job Title', 'Source URL', 'Date'];
    const rows = bulkScanResults.map(r => [
      r.name || '',
      r.email,
      r.jobTitle || '',
      r.sourceUrl || '',
      timestamp
    ]);

    const csv = [headers, ...rows].map(row =>
      row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(',')
    ).join('\n');

    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `bulk_emails_${timestamp}.csv`;
    a.click();
    URL.revokeObjectURL(url);

    showStatus(`Exported ${bulkScanResults.length} contacts!`, 'success');
  }

  // Export bulk results to sheets (optional)
  async function exportBulkToSheets() {
    if (bulkScanResults.length === 0) {
      showStatus('No bulk results to export', 'error');
      return;
    }

    // Check if Sheets is configured
    const settings = await new Promise(resolve => {
      chrome.storage.sync.get(['sheetId', 'apiKey'], resolve);
    });

    if (!settings.sheetId || !settings.apiKey) {
      showStatus('Sheets not configured. Go to Settings or use CSV export.', 'error');
      return;
    }

    showStatus('Sending bulk results to Sheets...', 'loading');

    try {
      const response = await SheetsAPI.appendToSheet(bulkScanResults, 'Bulk Scan');
      if (response.success) {
        showStatus(response.message, 'success');
      } else {
        showStatus(response.message, 'error');
      }
    } catch (error) {
      showStatus('Error: ' + error.message, 'error');
    }
  }

  // History functions
  function saveToHistory(results, sourceUrl) {
    chrome.storage.sync.get(['saveHistory'], (settings) => {
      if (settings.saveHistory === false) return;

      chrome.storage.local.get(['extractionHistory'], (data) => {
        const history = data.extractionHistory || [];
        history.unshift({
          id: Date.now(),
          timestamp: new Date().toISOString(),
          url: sourceUrl,
          count: results.length,
          results: results.slice(0, 100) // Limit stored results
        });

        // Keep only last 50 entries
        chrome.storage.local.set({
          extractionHistory: history.slice(0, 50)
        });
      });
    });
  }

  function loadHistory() {
    chrome.storage.local.get(['extractionHistory'], (data) => {
      const history = data.extractionHistory || [];
      renderHistory(history);
    });
  }

  function renderHistory(history) {
    if (history.length === 0) {
      historyList.innerHTML = '<p class="empty-state">No extractions yet</p>';
      return;
    }

    historyList.innerHTML = history.map(item => `
      <div class="history-item" data-id="${item.id}">
        <div class="history-item-header">
          <span class="history-date">${formatDate(item.timestamp)}</span>
          <span class="history-count">${item.count} contacts</span>
        </div>
        <div class="history-url">${escapeHtml(item.url)}</div>
        <div class="history-actions">
          <button class="view-btn" data-id="${item.id}">View</button>
          <button class="export-btn" data-id="${item.id}">Export</button>
          <button class="delete-btn" data-id="${item.id}">Delete</button>
        </div>
      </div>
    `).join('');

    // Add event listeners
    historyList.querySelectorAll('.view-btn').forEach(btn => {
      btn.addEventListener('click', () => viewHistoryItem(parseInt(btn.dataset.id)));
    });

    historyList.querySelectorAll('.export-btn').forEach(btn => {
      btn.addEventListener('click', () => exportHistoryItem(parseInt(btn.dataset.id)));
    });

    historyList.querySelectorAll('.delete-btn').forEach(btn => {
      btn.addEventListener('click', () => deleteHistoryItem(parseInt(btn.dataset.id)));
    });
  }

  function viewHistoryItem(id) {
    chrome.storage.local.get(['extractionHistory'], (data) => {
      const history = data.extractionHistory || [];
      const item = history.find(h => h.id === id);
      if (item) {
        currentResults = item.results;
        filteredResults = [];
        activeDomainFilter = null;
        currentUrl = item.url;
        updateUI();
        switchTab('extract');
      }
    });
  }

  async function exportHistoryItem(id) {
    chrome.storage.local.get(['extractionHistory'], async (data) => {
      const history = data.extractionHistory || [];
      const item = history.find(h => h.id === id);
      if (item && item.results) {
        showStatus('Exporting to Sheets...', 'loading');
        const response = await SheetsAPI.appendToSheet(item.results, item.url);
        showStatus(response.success ? response.message : response.message, response.success ? 'success' : 'error');
      }
    });
  }

  function deleteHistoryItem(id) {
    chrome.storage.local.get(['extractionHistory'], (data) => {
      const history = data.extractionHistory || [];
      const filtered = history.filter(h => h.id !== id);
      chrome.storage.local.set({ extractionHistory: filtered }, () => {
        renderHistory(filtered);
      });
    });
  }

  function clearHistory() {
    if (confirm('Clear all extraction history?')) {
      chrome.storage.local.remove('extractionHistory', () => {
        renderHistory([]);
        showStatus('History cleared!', 'success');
      });
    }
  }

  // Utility functions
  function showStatus(message, type) {
    status.textContent = message;
    status.className = `status ${type}`;
    if (type !== 'loading') {
      setTimeout(() => {
        status.textContent = '';
        status.className = 'status';
      }, 3000);
    }
  }

  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  function formatDate(isoString) {
    const date = new Date(isoString);
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  }
});

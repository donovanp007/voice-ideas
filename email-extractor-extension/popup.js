// Popup JavaScript - UI Logic

document.addEventListener('DOMContentLoaded', () => {
  // Elements
  const extractBtn = document.getElementById('extractBtn');
  const deepScanBtn = document.getElementById('deepScanBtn');
  const copyAllBtn = document.getElementById('copyAllBtn');
  const exportCsvBtn = document.getElementById('exportCsvBtn');
  const clearBtn = document.getElementById('clearBtn');
  const emailCount = document.getElementById('emailCount');
  const uniqueCount = document.getElementById('uniqueCount');
  const emailList = document.getElementById('emailList');
  const resultsContainer = document.getElementById('resultsContainer');
  const filtersSection = document.getElementById('filtersSection');
  const domainFilters = document.getElementById('domainFilters');
  const status = document.getElementById('status');

  let currentEmails = [];
  let filteredEmails = [];
  let activeDomainFilter = null;

  // Load any stored emails for this tab
  loadStoredEmails();

  // Extract button click
  extractBtn.addEventListener('click', () => extractEmails(false));
  deepScanBtn.addEventListener('click', () => extractEmails(true));

  // Copy all emails
  copyAllBtn.addEventListener('click', () => {
    const emailsToCopy = filteredEmails.length > 0 ? filteredEmails : currentEmails;
    if (emailsToCopy.length === 0) {
      showStatus('No emails to copy', 'error');
      return;
    }

    const text = emailsToCopy.join('\n');
    navigator.clipboard.writeText(text).then(() => {
      showStatus(`Copied ${emailsToCopy.length} emails!`, 'success');
    }).catch(() => {
      showStatus('Failed to copy', 'error');
    });
  });

  // Export to CSV
  exportCsvBtn.addEventListener('click', () => {
    const emailsToExport = filteredEmails.length > 0 ? filteredEmails : currentEmails;
    if (emailsToExport.length === 0) {
      showStatus('No emails to export', 'error');
      return;
    }

    const csv = 'Email\n' + emailsToExport.join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);

    const a = document.createElement('a');
    a.href = url;
    a.download = `emails_${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();

    URL.revokeObjectURL(url);
    showStatus(`Exported ${emailsToExport.length} emails!`, 'success');
  });

  // Clear results
  clearBtn.addEventListener('click', () => {
    currentEmails = [];
    filteredEmails = [];
    activeDomainFilter = null;
    updateUI();
    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
      chrome.storage.local.remove(`emails_${tabs[0].id}`);
    });
    showStatus('Cleared!', 'success');
  });

  /**
   * Extract emails from current page
   */
  async function extractEmails(deepScan) {
    showStatus(deepScan ? 'Deep scanning...' : 'Extracting...', 'loading');
    extractBtn.disabled = true;
    deepScanBtn.disabled = true;

    try {
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });

      // First, try to inject content script if not already loaded
      try {
        await chrome.scripting.executeScript({
          target: { tabId: tab.id },
          files: ['content.js']
        });
      } catch (e) {
        // Script might already be injected, continue anyway
      }

      // Small delay to ensure script is ready
      await new Promise(resolve => setTimeout(resolve, 100));

      // Send message to content script
      chrome.tabs.sendMessage(
        tab.id,
        { action: 'extractEmails', deepScan: deepScan },
        (response) => {
          extractBtn.disabled = false;
          deepScanBtn.disabled = false;

          if (chrome.runtime.lastError) {
            showStatus('Could not scan this page', 'error');
            return;
          }

          if (response && response.emails) {
            // Merge with existing emails
            const newEmails = response.emails;
            const mergedSet = new Set([...currentEmails, ...newEmails]);
            currentEmails = Array.from(mergedSet).sort();

            // Store emails
            chrome.storage.local.set({ [`emails_${tab.id}`]: currentEmails });

            updateUI();
            showStatus(`Found ${newEmails.length} emails!`, 'success');
          } else {
            showStatus('No emails found', 'error');
          }
        }
      );
    } catch (error) {
      extractBtn.disabled = false;
      deepScanBtn.disabled = false;
      showStatus('Error: ' + error.message, 'error');
    }
  }

  /**
   * Load stored emails for current tab
   */
  async function loadStoredEmails() {
    try {
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
      chrome.storage.local.get([`emails_${tab.id}`], (result) => {
        const stored = result[`emails_${tab.id}`];
        if (stored && stored.length > 0) {
          currentEmails = stored;
          updateUI();
        }
      });
    } catch (e) {}
  }

  /**
   * Update the UI with current emails
   */
  function updateUI() {
    const displayEmails = activeDomainFilter ? filteredEmails : currentEmails;

    // Update counts
    emailCount.textContent = displayEmails.length;
    uniqueCount.textContent = currentEmails.length;

    // Show/hide results
    if (currentEmails.length > 0) {
      resultsContainer.style.display = 'block';
      filtersSection.style.display = 'block';
    } else {
      resultsContainer.style.display = 'none';
      filtersSection.style.display = 'none';
    }

    // Render email list
    renderEmailList(displayEmails);

    // Render domain filters
    renderDomainFilters();
  }

  /**
   * Render email list
   */
  function renderEmailList(emails) {
    emailList.innerHTML = '';

    emails.forEach((email, index) => {
      const domain = email.split('@')[1] || '';

      const item = document.createElement('div');
      item.className = 'email-item';
      item.style.animationDelay = `${index * 0.03}s`;

      item.innerHTML = `
        <span class="email-text">${escapeHtml(email)}</span>
        <span class="email-domain">${escapeHtml(domain)}</span>
        <button class="copy-single" data-email="${escapeHtml(email)}" title="Copy">📋</button>
      `;

      emailList.appendChild(item);
    });

    // Add copy handlers
    emailList.querySelectorAll('.copy-single').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const email = e.target.dataset.email;
        navigator.clipboard.writeText(email).then(() => {
          e.target.textContent = '✓';
          setTimeout(() => e.target.textContent = '📋', 1000);
        });
      });
    });
  }

  /**
   * Render domain filter chips
   */
  function renderDomainFilters() {
    const domainCounts = {};

    currentEmails.forEach(email => {
      const domain = email.split('@')[1] || 'unknown';
      domainCounts[domain] = (domainCounts[domain] || 0) + 1;
    });

    domainFilters.innerHTML = '';

    // Add "All" chip
    const allChip = document.createElement('span');
    allChip.className = `filter-chip ${!activeDomainFilter ? 'active' : ''}`;
    allChip.innerHTML = `All <span class="count">${currentEmails.length}</span>`;
    allChip.addEventListener('click', () => {
      activeDomainFilter = null;
      filteredEmails = [];
      updateUI();
    });
    domainFilters.appendChild(allChip);

    // Add domain chips
    Object.entries(domainCounts)
      .sort((a, b) => b[1] - a[1])
      .forEach(([domain, count]) => {
        const chip = document.createElement('span');
        chip.className = `filter-chip ${activeDomainFilter === domain ? 'active' : ''}`;
        chip.innerHTML = `${escapeHtml(domain)} <span class="count">${count}</span>`;
        chip.addEventListener('click', () => {
          activeDomainFilter = domain;
          filteredEmails = currentEmails.filter(e => e.split('@')[1] === domain);
          updateUI();
        });
        domainFilters.appendChild(chip);
      });
  }

  /**
   * Show status message
   */
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

  /**
   * Escape HTML to prevent XSS
   */
  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  // Keyboard shortcut
  document.addEventListener('keydown', (e) => {
    if (e.key === 'e' && e.altKey) {
      extractEmails(false);
    } else if (e.key === 'd' && e.altKey) {
      extractEmails(true);
    }
  });
});

// Background Service Worker

// Track extracted emails across sessions
let globalEmailStore = {};

// Listen for messages from content scripts
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'emailsFound') {
    // Store emails from auto-extraction
    const tabId = sender.tab?.id;
    if (tabId) {
      globalEmailStore[tabId] = {
        emails: request.emails,
        url: request.url,
        timestamp: Date.now()
      };

      // Update badge
      chrome.action.setBadgeText({
        text: request.emails.length.toString(),
        tabId: tabId
      });
      chrome.action.setBadgeBackgroundColor({
        color: '#00d4ff',
        tabId: tabId
      });
    }
  }

  if (request.action === 'getStoredEmails') {
    const tabId = request.tabId;
    sendResponse(globalEmailStore[tabId] || null);
  }

  return true;
});

// Clear stored emails when tab is closed
chrome.tabs.onRemoved.addListener((tabId) => {
  delete globalEmailStore[tabId];
  chrome.storage.local.remove(`emails_${tabId}`);
});

// Clear badge when navigating to new page
chrome.tabs.onUpdated.addListener((tabId, changeInfo) => {
  if (changeInfo.status === 'loading') {
    chrome.action.setBadgeText({ text: '', tabId: tabId });
    delete globalEmailStore[tabId];
  }
});

// Context menu for quick extraction
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: 'extractEmails',
    title: 'Extract Emails from Page',
    contexts: ['page']
  });

  chrome.contextMenus.create({
    id: 'extractDeep',
    title: 'Deep Scan for Emails',
    contexts: ['page']
  });
});

// Handle context menu clicks
chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === 'extractEmails' || info.menuItemId === 'extractDeep') {
    const deepScan = info.menuItemId === 'extractDeep';

    chrome.tabs.sendMessage(tab.id, {
      action: 'extractEmails',
      deepScan: deepScan
    }, (response) => {
      if (response && response.emails && response.emails.length > 0) {
        // Store and show badge
        globalEmailStore[tab.id] = {
          emails: response.emails,
          url: tab.url,
          timestamp: Date.now()
        };

        chrome.action.setBadgeText({
          text: response.emails.length.toString(),
          tabId: tab.id
        });
        chrome.action.setBadgeBackgroundColor({
          color: '#00d4ff',
          tabId: tab.id
        });

        // Store in local storage for popup
        chrome.storage.local.set({
          [`emails_${tab.id}`]: response.emails
        });
      }
    });
  }
});

// Keyboard shortcut command handler
chrome.commands.onCommand.addListener((command) => {
  chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
    if (tabs[0]) {
      if (command === 'extract-emails') {
        chrome.tabs.sendMessage(tabs[0].id, {
          action: 'extractEmails',
          deepScan: false
        });
      }
    }
  });
});

console.log('📧 Email Extractor background service worker loaded');
